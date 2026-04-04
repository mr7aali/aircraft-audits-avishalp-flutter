import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response;
import '../config/aviationstack_config.dart';
import '../models/aviationstack_model.dart';
import '../services/session_service.dart';

class AirportState {
  final RxString status = 'idle'.obs;
  final RxList<AviationFlight> data = <AviationFlight>[].obs;
  final Rx<DateTime?> lastUpdated = Rx<DateTime?>(null);
  final Rx<String?> error = Rx<String?>(null);

  void setLoading() {
    status.value = 'loading';
    error.value = null;
  }

  void setSuccess(List<AviationFlight> newData) {
    status.value = 'success';
    data.assignAll(newData);
    lastUpdated.value = DateTime.now();
  }

  void setError(String message) {
    status.value = 'error';
    error.value = message;
  }
}

class AviationController extends GetxController {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  final SessionService _session = Get.find<SessionService>();

  // Use a single active state for the selected station
  final activeAirport = AirportState();

  final RxInt secondsUntilRefresh = 1800.obs; // 30 minutes
  Timer? _refreshTimer;
  Timer? _countdownTimer;

  @override
  void onInit() {
    super.onInit();
    fetchFlights();
    _startTimers();
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    _countdownTimer?.cancel();
    super.onClose();
  }

  void _startTimers() {
    // 30 minutes = 1800 seconds
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 30),
      (_) => fetchFlights(),
    );
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (secondsUntilRefresh.value > 0) {
        secondsUntilRefresh.value--;
      } else {
        secondsUntilRefresh.value = 1800;
      }
    });
  }

  Future<void> fetchFlights() async {
    // Reset countdown on manual or auto refresh
    secondsUntilRefresh.value = 1800;

    final stationCode = _session.activeStationCode;
    // Fallback IATA can be anything, but we'll use JFK if none is selected
    final iata = stationCode.isEmpty ? 'JFK' : stationCode;

    try {
      await _fetchAirportData(
        iata,
        activeAirport,
      ).timeout(const Duration(seconds: 15));
    } catch (e) {
      if (activeAirport.status.value == 'loading') {
        activeAirport.setError('Network request timed out.');
      }
    }
  }

  Future<void> _fetchAirportData(
    String iata,
    AirportState state, {
    bool isRetry = false,
  }) async {
    state.setLoading();

    try {
      final Map<String, dynamic> params = {
        'access_key': AviationStackConfig.apiKey,
        'arr_iata': iata,
        'limit': '100',
        'dep_iata': iata,
      };

      if (!isRetry) {
        params['flight_status'] = 'active';
      }

      String url = AviationStackConfig.baseUrl;
      Response response;

      if (kIsWeb) {
        final uri = Uri.parse(url).replace(queryParameters: params);
        final proxyUrl =
            'https://api.codetabs.com/v1/proxy/?quest=${Uri.encodeComponent(uri.toString())}';
        response = await _dio
            .get(proxyUrl)
            .timeout(const Duration(seconds: 15));
      } else {
        response = await _dio
            .get(url, queryParameters: params)
            .timeout(const Duration(seconds: 15));
      }

      if (response.statusCode == 200) {
        var data = response.data;
        if (data is String) {
          try {
            data = jsonDecode(data);
          } catch (e) {
            throw Exception('Failed to parse API response: $e');
          }
        }

        if (data is Map && data.containsKey('error')) {
          final errorObj = data['error'];
          final errorMsg = errorObj['message'] ?? 'API Error';
          final errorCode = errorObj['code']?.toString() ?? '';

          if (errorCode == 'invalid_access_key')
            throw Exception('Invalid API Access Key.');
          if (errorCode == 'usage_limit_reached')
            throw Exception('Monthly Limit Reached.');
          if (errorCode == 'function_access_restricted')
            throw Exception('Plan restricted: Use HTTP, not HTTPS.');

          throw Exception('API: $errorMsg ($errorCode)');
        }

        if (data is Map) {
          final rawData = data['data'];
          if (rawData is List) {
            if (rawData.isEmpty && !isRetry) {
              return _fetchAirportData(iata, state, isRetry: true);
            }
            final processedData = _processRawData(rawData);
            state.setSuccess(processedData);
            return;
          }
        }

        if (!isRetry) return _fetchAirportData(iata, state, isRetry: true);
        throw Exception('No data list in API response.');
      } else {
        throw Exception('Server Status: ${response.statusCode}');
      }
    } on DioException catch (e) {
      String msg = 'Network Error';
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        msg = 'Connection Timed Out (Check Network)';
      } else if (e.type == DioExceptionType.badResponse) {
        msg = 'Invalid API Response (${e.response?.statusCode})';
      } else if (e.message != null && e.message!.contains('XMLHttpRequest')) {
        msg =
            'CORS Blocked or Mixed Content. Use a proxy or disable web security for local testing.';
      } else {
        msg = e.message ?? 'Unknown Connection Error';
      }
      state.setError(msg);
    } catch (e) {
      state.setError(e.toString().replaceAll('Exception:', '').trim());
    }
  }

  List<AviationFlight> _processRawData(List<dynamic> rawData) {
    if (rawData.isEmpty) return [];

    final allFlights = <AviationFlight>[];
    for (var item in rawData) {
      try {
        if (item is Map<String, dynamic>) {
          allFlights.add(AviationFlight.fromJson(item));
        }
      } catch (e) {
        continue;
      }
    }

    if (allFlights.isEmpty) return [];

    final filtered = allFlights.where((f) {
      return f.departureIata != "—" || f.arrivalIata != "—";
    }).toList();

    final deduplicated = <String, AviationFlight>{};
    for (var f in filtered) {
      if (!deduplicated.containsKey(f.flightNumber)) {
        deduplicated[f.flightNumber] = f;
      }
    }

    final result = deduplicated.values.toList();

    try {
      result.sort((a, b) {
        if (a.status == 'active' && b.status != 'active') return -1;
        if (a.status != 'active' && b.status == 'active') return 1;

        if (a.arrivalTime == null && b.arrivalTime == null) return 0;
        if (a.arrivalTime == null) return 1;
        if (b.arrivalTime == null) return -1;
        return a.arrivalTime!.compareTo(b.arrivalTime!);
      });
    } catch (e) {
      // Sorting error doesn't crash the fetch
    }

    return result;
  }

  String timeAgo(DateTime? time) {
    if (time == null) return 'Never';
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    return '${diff.inMinutes}m ago';
  }
}
