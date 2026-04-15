import 'dart:async';

import 'package:get/get.dart';

import '../models/aviationstack_model.dart';
import '../services/api_exception.dart';
import '../services/app_api_service.dart';
import '../services/session_service.dart';

class AirportState {
  final RxString status = 'idle'.obs;
  final RxList<AviationFlight> arrivals = <AviationFlight>[].obs;
  final RxList<AviationFlight> departures = <AviationFlight>[].obs;
  final Rx<DateTime?> lastUpdated = Rx<DateTime?>(null);
  final Rx<String?> error = Rx<String?>(null);

  List<AviationFlight> get allFlights => [...arrivals, ...departures];

  void setLoading() {
    status.value = 'loading';
    error.value = null;
  }

  void setSuccess(
    List<AviationFlight> arr,
    List<AviationFlight> dep, {
    DateTime? updatedAt,
  }) {
    status.value = 'success';
    arrivals.assignAll(arr);
    departures.assignAll(dep);
    lastUpdated.value = updatedAt ?? DateTime.now();
  }

  void setError(String message) {
    status.value = 'error';
    error.value = message;
  }
}

class AviationController extends GetxController {
  final AppApiService _api = Get.find<AppApiService>();
  final SessionService _session = Get.find<SessionService>();

  final activeAirport = AirportState();
  final RxInt secondsUntilRefresh = 300.obs;

  Timer? _refreshTimer;
  Timer? _countdownTimer;
  int _refreshIntervalSeconds = 300;

  @override
  void onInit() {
    super.onInit();
    _startTimers();
    fetchFlights();
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    _countdownTimer?.cancel();
    super.onClose();
  }

  void _startTimers() {
    _refreshTimer?.cancel();
    _countdownTimer?.cancel();
    secondsUntilRefresh.value = _refreshIntervalSeconds;

    _refreshTimer = Timer.periodic(
      Duration(seconds: _refreshIntervalSeconds),
      (_) => fetchFlights(),
    );

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (secondsUntilRefresh.value > 0) {
        secondsUntilRefresh.value--;
      } else {
        secondsUntilRefresh.value = _refreshIntervalSeconds;
      }
    });
  }

  Future<void> fetchFlights() async {
    secondsUntilRefresh.value = _refreshIntervalSeconds;

    if (_session.activeStationCode.isEmpty) {
      activeAirport.setError('No active station selected.');
      return;
    }

    activeAirport.setLoading();

    try {
      final response = await _api
          .getStationFlights()
          .timeout(const Duration(seconds: 20));

      final arrivals = _parseFlights(response['arrivals']);
      final departures = _parseFlights(response['departures']);
      final cache = response['cache'];

      if (cache is Map<String, dynamic>) {
        final nextInterval = _readPositiveInt(cache['ttlSeconds']);
        if (nextInterval != null && nextInterval != _refreshIntervalSeconds) {
          _refreshIntervalSeconds = nextInterval;
          _startTimers();
        } else {
          secondsUntilRefresh.value = _refreshIntervalSeconds;
        }

        activeAirport.setSuccess(
          arrivals,
          departures,
          updatedAt: _parseDateTime(cache['fetchedAt']),
        );
        return;
      }

      activeAirport.setSuccess(arrivals, departures);
    } on ApiException catch (error) {
      activeAirport.setError(error.message);
    } on TimeoutException {
      activeAirport.setError('Flight request timed out.');
    } catch (_) {
      activeAirport.setError('Unable to load flights right now.');
    }
  }

  List<AviationFlight> _parseFlights(dynamic raw) {
    if (raw is! List) {
      return const <AviationFlight>[];
    }

    return raw
        .whereType<Map>()
        .map((item) => AviationFlight.fromApiJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  int? _readPositiveInt(dynamic value) {
    final parsed = int.tryParse(value?.toString() ?? '');
    if (parsed == null || parsed <= 0) {
      return null;
    }
    return parsed;
  }

  DateTime? _parseDateTime(dynamic value) {
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) {
      return null;
    }

    try {
      return DateTime.parse(raw).toLocal();
    } catch (_) {
      return null;
    }
  }

  String timeAgo(DateTime? time) {
    if (time == null) return 'Never';
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    return '${diff.inMinutes}m ago';
  }
}
