import 'dart:io';

import 'package:avislap/data/seat_map_config.dart' as seat_map_config;
import 'package:avislap/services/api_exception.dart';
import 'package:avislap/services/app_api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class _HOColors {
  static const Color primary = Color(0xFF3D5AFE);
  static const Color background = Color(0xFFF5F6FA);
  static const Color textDark = Color(0xFF1A1A2E);
  static const Color textMuted = Color(0xFF7B8794);
  static const Color border = Color(0xFFE4E7EF);
  static const Color seat = Color(0xFF9AA5B1);
  static const Color orange = Color(0xFFFF9800);
  static const Color blue = Color(0xFF2196F3);
  static const Color green = Color(0xFF22C55E);
  static const Color red = Color(0xFFEF4444);
}

class HiddenObjectAuditListItem {
  HiddenObjectAuditListItem({
    required this.id,
    required this.sessionAt,
    required this.auditorName,
    required this.shipNumber,
    required this.aircraftTypeName,
    required this.status,
    required this.total,
    required this.orange,
    required this.blue,
    required this.green,
    required this.red,
  });

  final String id;
  final DateTime sessionAt;
  final String auditorName;
  final String shipNumber;
  final String aircraftTypeName;
  final String status;
  final int total;
  final int orange;
  final int blue;
  final int green;
  final int red;

  factory HiddenObjectAuditListItem.fromMap(Map<String, dynamic> map) {
    final counts = _asMap(map['counts']);
    return HiddenObjectAuditListItem(
      id: map['id']?.toString() ?? '',
      sessionAt:
          DateTime.tryParse(map['sessionAt']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
      auditorName: map['auditorName']?.toString() ?? 'Unknown',
      shipNumber: map['shipNumber']?.toString() ?? '',
      aircraftTypeName: map['aircraftTypeName']?.toString() ?? '',
      status: map['status']?.toString() ?? 'SETUP',
      total: _toInt(counts['total']),
      orange: _toInt(counts['orange']),
      blue: _toInt(counts['blue']),
      green: _toInt(counts['green']),
      red: _toInt(counts['red']),
    );
  }
}

class HiddenObjectFleetOption {
  HiddenObjectFleetOption({
    required this.id,
    required this.shipNumber,
    required this.displayName,
    required this.aircraftTypeId,
    required this.aircraftTypeName,
  });

  final String id;
  final String shipNumber;
  final String displayName;
  final String aircraftTypeId;
  final String aircraftTypeName;

  factory HiddenObjectFleetOption.fromMap(Map<String, dynamic> map) {
    final aircraftType = _asMap(map['aircraftType']);
    return HiddenObjectFleetOption(
      id: map['id']?.toString() ?? '',
      shipNumber: map['shipNumber']?.toString() ?? '',
      displayName: map['displayName']?.toString() ?? '',
      aircraftTypeId: aircraftType['id']?.toString() ?? '',
      aircraftTypeName: aircraftType['name']?.toString() ?? '',
    );
  }
}

class HiddenObjectAircraftOption {
  HiddenObjectAircraftOption({
    required this.id,
    required this.name,
    required this.seatMap,
  });

  final String id;
  final String name;
  final seat_map_config.AircraftSeatMap? seatMap;

  factory HiddenObjectAircraftOption.fromMap(Map<String, dynamic> map) {
    final name = map['name']?.toString() ?? '';
    seat_map_config.AircraftSeatMap? parsedSeatMap;
    final rawSeatMap = map['seatMap'];
    if (rawSeatMap is Map) {
      try {
        parsedSeatMap = seat_map_config.AircraftSeatMap.fromJson(
          Map<String, dynamic>.from(rawSeatMap),
          fallbackName: name,
        );
      } catch (_) {
        parsedSeatMap = seat_map_config.defaultAircraftSeatMaps[name];
      }
    } else {
      parsedSeatMap = seat_map_config.defaultAircraftSeatMaps[name];
    }

    return HiddenObjectAircraftOption(
      id: map['id']?.toString() ?? '',
      name: name,
      seatMap: parsedSeatMap,
    );
  }
}

class HiddenObjectLocation {
  HiddenObjectLocation({
    required this.id,
    required this.locationCode,
    required this.locationLabel,
    required this.sectionLabel,
    required this.locationType,
    required this.status,
    required this.subLocation,
    required this.photoFileIds,
    required this.subLocationOptions,
    required this.foundByName,
  });

  final String id;
  final String locationCode;
  final String locationLabel;
  final String sectionLabel;
  final String locationType;
  final String status;
  final String subLocation;
  final List<String> photoFileIds;
  final List<String> subLocationOptions;
  final String foundByName;

  factory HiddenObjectLocation.fromMap(Map<String, dynamic> map) {
    return HiddenObjectLocation(
      id: map['id']?.toString() ?? '',
      locationCode: map['locationCode']?.toString() ?? '',
      locationLabel: map['locationLabel']?.toString() ?? '',
      sectionLabel: map['sectionLabel']?.toString() ?? '',
      locationType: map['locationType']?.toString() ?? '',
      status: map['status']?.toString() ?? 'ORANGE',
      subLocation: map['subLocation']?.toString() ?? '',
      photoFileIds: _asStringList(map['photoFileIds']),
      subLocationOptions: _asStringList(map['subLocationOptions']),
      foundByName: map['foundByName']?.toString() ?? '',
    );
  }
}

class HiddenObjectAuditDetail {
  HiddenObjectAuditDetail({
    required this.id,
    required this.sessionAt,
    required this.status,
    required this.shipNumber,
    required this.aircraftTypeId,
    required this.aircraftTypeName,
    required this.seatMap,
    required this.auditorName,
    required this.auditorRole,
    required this.objectsToHideCount,
    required this.total,
    required this.orange,
    required this.blue,
    required this.green,
    required this.red,
    required this.canActivate,
    required this.canClose,
    required this.locations,
  });

  final String id;
  final DateTime sessionAt;
  final String status;
  final String shipNumber;
  final String aircraftTypeId;
  final String aircraftTypeName;
  final seat_map_config.AircraftSeatMap? seatMap;
  final String auditorName;
  final String auditorRole;
  final int objectsToHideCount;
  final int total;
  final int orange;
  final int blue;
  final int green;
  final int red;
  final bool canActivate;
  final bool canClose;
  final List<HiddenObjectLocation> locations;

  Map<String, HiddenObjectLocation> get locationMap => {
    for (final location in locations) location.locationCode: location,
  };

  factory HiddenObjectAuditDetail.fromMap(Map<String, dynamic> map) {
    final aircraftType = _asMap(map['aircraftType']);
    final counts = _asMap(map['counts']);
    final aircraftName = aircraftType['name']?.toString() ?? '';
    seat_map_config.AircraftSeatMap? parsedSeatMap;
    final rawSeatMap = aircraftType['seatMap'];
    if (rawSeatMap is Map) {
      try {
        parsedSeatMap = seat_map_config.AircraftSeatMap.fromJson(
          Map<String, dynamic>.from(rawSeatMap),
          fallbackName: aircraftName,
        );
      } catch (_) {
        parsedSeatMap = seat_map_config.defaultAircraftSeatMaps[aircraftName];
      }
    } else {
      parsedSeatMap = seat_map_config.defaultAircraftSeatMaps[aircraftName];
    }

    return HiddenObjectAuditDetail(
      id: map['id']?.toString() ?? '',
      sessionAt:
          DateTime.tryParse(map['sessionAt']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
      status: map['status']?.toString() ?? 'SETUP',
      shipNumber: map['shipNumber']?.toString() ?? '',
      aircraftTypeId: aircraftType['id']?.toString() ?? '',
      aircraftTypeName: aircraftName,
      seatMap: parsedSeatMap,
      auditorName: _asMap(map['auditor'])['name']?.toString() ?? '',
      auditorRole: _asMap(map['auditor'])['role']?.toString() ?? '',
      objectsToHideCount: _toInt(map['objectsToHideCount']),
      total: _toInt(counts['total']),
      orange: _toInt(counts['orange']),
      blue: _toInt(counts['blue']),
      green: _toInt(counts['green']),
      red: _toInt(counts['red']),
      canActivate: map['canActivate'] == true,
      canClose: map['canClose'] == true,
      locations: _asListOfMaps(
        map['locations'],
      ).map(HiddenObjectLocation.fromMap).toList(),
    );
  }
}

class HiddenObjectAuditListScreen extends StatefulWidget {
  const HiddenObjectAuditListScreen({super.key});

  @override
  State<HiddenObjectAuditListScreen> createState() =>
      _HiddenObjectAuditListScreenState();
}

class _HiddenObjectAuditListScreenState
    extends State<HiddenObjectAuditListScreen> {
  final AppApiService _api = Get.find<AppApiService>();
  final List<HiddenObjectAuditListItem> _items = <HiddenObjectAuditListItem>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final response = await _api.listHiddenObjectAudits(
        queryParameters: {'page': 1, 'limit': 100},
      );
      final items = _asListOfMaps(
        response['items'],
      ).map(HiddenObjectAuditListItem.fromMap).toList();
      setState(() {
        _items
          ..clear()
          ..addAll(items);
      });
    } on ApiException catch (error) {
      Get.snackbar(
        'Hidden Object Audits',
        error.message,
        backgroundColor: _HOColors.red,
        colorText: Colors.white,
      );
    } catch (_) {
      Get.snackbar(
        'Hidden Object Audits',
        'Unable to load hidden object audits right now.',
        backgroundColor: _HOColors.red,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _openWorkflow({String? auditId}) async {
    await Get.to(
      () => HiddenObjectAuditWorkflowScreen(auditId: auditId),
      transition: Transition.rightToLeft,
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _HOColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Hidden Object Audit',
          style: GoogleFonts.dmSans(
            color: _HOColors.textDark,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: _HOColors.textDark),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _HOColors.primary,
        onPressed: () => _openWorkflow(),
        icon: const Icon(Icons.add),
        label: const Text('New Audit'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
            ? ListView(
                children: [
                  SizedBox(height: 120.h),
                  Icon(
                    Icons.search_off_rounded,
                    size: 72.sp,
                    color: _HOColors.textMuted,
                  ),
                  SizedBox(height: 16.h),
                  Center(
                    child: Text(
                      'No hidden object audits yet.',
                      style: GoogleFonts.dmSans(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: _HOColors.textDark,
                      ),
                    ),
                  ),
                ],
              )
            : ListView.separated(
                padding: EdgeInsets.all(16.w),
                itemCount: _items.length,
                separatorBuilder: (_, _) => SizedBox(height: 12.h),
                itemBuilder: (_, index) {
                  final item = _items[index];
                  return GestureDetector(
                    onTap: () => _openWorkflow(auditId: item.id),
                    child: Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: _HOColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.shipNumber,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 17.sp,
                                    fontWeight: FontWeight.w700,
                                    color: _HOColors.textDark,
                                  ),
                                ),
                              ),
                              _statusChip(item.status),
                            ],
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            item.aircraftTypeName,
                            style: GoogleFonts.dmSans(
                              fontSize: 13.sp,
                              color: _HOColors.textMuted,
                            ),
                          ),
                          SizedBox(height: 10.h),
                          Text(
                            '${item.auditorName} - ${DateFormat('MMM d, y - h:mm a').format(item.sessionAt)}',
                            style: GoogleFonts.dmSans(
                              fontSize: 12.sp,
                              color: _HOColors.textMuted,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Wrap(
                            spacing: 8.w,
                            runSpacing: 8.h,
                            children: [
                              _metricChip(
                                'Orange',
                                item.orange,
                                _HOColors.orange,
                              ),
                              _metricChip('Blue', item.blue, _HOColors.blue),
                              _metricChip('Green', item.green, _HOColors.green),
                              _metricChip('Red', item.red, _HOColors.red),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class HiddenObjectAuditWorkflowScreen extends StatefulWidget {
  const HiddenObjectAuditWorkflowScreen({super.key, this.auditId});

  final String? auditId;

  @override
  State<HiddenObjectAuditWorkflowScreen> createState() =>
      _HiddenObjectAuditWorkflowScreenState();
}

class _HiddenObjectAuditWorkflowScreenState
    extends State<HiddenObjectAuditWorkflowScreen> {
  final AppApiService _api = Get.find<AppApiService>();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _objectCountCtrl = TextEditingController(
    text: '3',
  );

  final List<HiddenObjectFleetOption> _fleetOptions =
      <HiddenObjectFleetOption>[];
  final List<HiddenObjectAircraftOption> _aircraftOptions =
      <HiddenObjectAircraftOption>[];

  bool _loading = true;
  bool _saving = false;
  String? _selectedShipNumber;
  String? _selectedAircraftTypeId;
  HiddenObjectAuditDetail? _detail;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  @override
  void dispose() {
    _objectCountCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    setState(() => _loading = true);
    try {
      if (widget.auditId == null) {
        await _loadCreateOptions();
      } else {
        final detail = await _api.getHiddenObjectAudit(widget.auditId!);
        setState(() {
          _detail = HiddenObjectAuditDetail.fromMap(detail);
        });
      }
    } on ApiException catch (error) {
      Get.snackbar(
        'Hidden Object Audit',
        error.message,
        backgroundColor: _HOColors.red,
        colorText: Colors.white,
      );
    } catch (_) {
      Get.snackbar(
        'Hidden Object Audit',
        'Unable to load this workflow right now.',
        backgroundColor: _HOColors.red,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadCreateOptions() async {
    final fleet = await _api.getFleetAircraft();
    final aircraftTypes = await _api.getAircraftTypes();
    final fleetOptions = fleet.map(HiddenObjectFleetOption.fromMap).toList();
    final aircraftOptions = aircraftTypes
        .map(HiddenObjectAircraftOption.fromMap)
        .toList();

    setState(() {
      _fleetOptions
        ..clear()
        ..addAll(fleetOptions);
      _aircraftOptions
        ..clear()
        ..addAll(aircraftOptions);
      _selectedShipNumber ??= fleetOptions.isNotEmpty
          ? fleetOptions.first.shipNumber
          : null;
      _selectedAircraftTypeId ??= fleetOptions.isNotEmpty
          ? fleetOptions.first.aircraftTypeId
          : aircraftOptions.isNotEmpty
          ? aircraftOptions.first.id
          : null;
    });
  }

  HiddenObjectFleetOption? get _selectedFleet => _fleetOptions.firstWhereOrNull(
    (item) => item.shipNumber == _selectedShipNumber,
  );

  seat_map_config.AircraftSeatMap? get _currentSeatMap {
    if (_detail != null) {
      return _detail!.seatMap;
    }

    return _aircraftOptions
        .firstWhereOrNull((item) => item.id == _selectedAircraftTypeId)
        ?.seatMap;
  }

  Future<void> _createAudit() async {
    final shipNumber = _selectedShipNumber?.trim() ?? '';
    final aircraftTypeId = _selectedAircraftTypeId?.trim() ?? '';
    final objectCount = int.tryParse(_objectCountCtrl.text.trim()) ?? 0;

    if (shipNumber.isEmpty || aircraftTypeId.isEmpty || objectCount <= 0) {
      Get.snackbar(
        'Create Audit',
        'Select ship number, aircraft type, and a valid object count.',
        backgroundColor: _HOColors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final response = await _api.createHiddenObjectAudit({
        'shipNumber': shipNumber,
        'aircraftTypeId': aircraftTypeId,
        'numberOfObjectsToHide': objectCount,
      });
      setState(() {
        _detail = HiddenObjectAuditDetail.fromMap(response);
      });
      Get.snackbar(
        'Audit Created',
        'Targets generated. Tap each orange location to confirm the hiding point.',
        backgroundColor: _HOColors.green,
        colorText: Colors.white,
      );
    } on ApiException catch (error) {
      Get.snackbar(
        'Create Audit',
        error.message,
        backgroundColor: _HOColors.red,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _refreshDetail() async {
    if (_detail == null) {
      return;
    }
    final response = await _api.getHiddenObjectAudit(_detail!.id);
    setState(() {
      _detail = HiddenObjectAuditDetail.fromMap(response);
    });
  }

  Future<void> _activateAudit() async {
    if (_detail == null) return;
    setState(() => _saving = true);
    try {
      final response = await _api.activateHiddenObjectAudit(_detail!.id);
      setState(() {
        _detail = HiddenObjectAuditDetail.fromMap(response);
      });
      Get.snackbar(
        'Audit Active',
        'Agents can now begin searching. Blue locations will move to green or red.',
        backgroundColor: _HOColors.green,
        colorText: Colors.white,
      );
    } on ApiException catch (error) {
      Get.snackbar(
        'Activate Audit',
        error.message,
        backgroundColor: _HOColors.red,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _closeAudit() async {
    if (_detail == null) return;
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Close Audit?'),
            content: const Text(
              'Any remaining blue locations will be marked red as not found.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Close Audit'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;

    setState(() => _saving = true);
    try {
      final response = await _api.closeHiddenObjectAudit(_detail!.id);
      setState(() {
        _detail = HiddenObjectAuditDetail.fromMap(response);
      });
      Get.snackbar(
        'Audit Closed',
        'Remaining active locations were finalized.',
        backgroundColor: _HOColors.green,
        colorText: Colors.white,
      );
    } on ApiException catch (error) {
      Get.snackbar(
        'Close Audit',
        error.message,
        backgroundColor: _HOColors.red,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _showLocationSheet(HiddenObjectLocation location) async {
    if (_detail == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LocationActionSheet(
        auditId: _detail!.id,
        auditStatus: _detail!.status,
        location: location,
        api: _api,
        picker: _picker,
        onUpdated: (detailMap) {
          setState(() {
            _detail = HiddenObjectAuditDetail.fromMap(detailMap);
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;

    return Scaffold(
      backgroundColor: _HOColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          detail == null ? 'Create Hidden Object Audit' : detail.shipNumber,
          style: GoogleFonts.dmSans(
            color: _HOColors.textDark,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: _HOColors.textDark),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : detail == null
          ? _buildCreateView()
          : RefreshIndicator(
              onRefresh: _refreshDetail,
              child: ListView(
                padding: EdgeInsets.all(16.w),
                children: [
                  _buildSummaryCard(detail),
                  SizedBox(height: 12.h),
                  _buildActionCard(detail),
                  SizedBox(height: 12.h),
                  _buildLegendCard(),
                  SizedBox(height: 12.h),
                  if (detail.seatMap != null)
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18.r),
                        border: Border.all(color: _HOColors.border),
                      ),
                      child: _HiddenObjectSeatMap(
                        seatMap: detail.seatMap!,
                        locationsByCode: detail.locationMap,
                        onLocationTap: _showLocationSheet,
                      ),
                    )
                  else
                    Container(
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18.r),
                        border: Border.all(color: _HOColors.border),
                      ),
                      child: Text(
                        'Seat map configuration is unavailable for this aircraft type.',
                        style: GoogleFonts.dmSans(
                          color: _HOColors.textMuted,
                          fontSize: 13.sp,
                        ),
                      ),
                    ),
                  SizedBox(height: 12.h),
                  ...detail.locations.map(
                    (location) => Padding(
                      padding: EdgeInsets.only(bottom: 10.h),
                      child: GestureDetector(
                        onTap: () => _showLocationSheet(location),
                        child: Container(
                          padding: EdgeInsets.all(14.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(color: _HOColors.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 12.w,
                                height: 12.w,
                                decoration: BoxDecoration(
                                  color: _statusColor(location.status),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      location.locationLabel,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w700,
                                        color: _HOColors.textDark,
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      [
                                        location.sectionLabel,
                                        if (location.subLocation.isNotEmpty)
                                          location.subLocation,
                                      ].join(' - '),
                                      style: GoogleFonts.dmSans(
                                        fontSize: 12.sp,
                                        color: _HOColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _statusChip(location.status),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCreateView() {
    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        Container(
          padding: EdgeInsets.all(18.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: _HOColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create Audit Session',
                style: GoogleFonts.dmSans(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: _HOColors.textDark,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Choose a ship, confirm the aircraft type, and generate random hiding targets.',
                style: GoogleFonts.dmSans(
                  fontSize: 13.sp,
                  color: _HOColors.textMuted,
                ),
              ),
              SizedBox(height: 18.h),
              _fieldLabel('Ship Number'),
              SizedBox(height: 8.h),
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value:
                    _fleetOptions.any(
                      (item) => item.shipNumber == _selectedShipNumber,
                    )
                    ? _selectedShipNumber
                    : null,
                decoration: _inputDecoration(),
                items: _fleetOptions
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item.shipNumber,
                        child: Text(
                          item.displayName.isEmpty
                              ? '${item.shipNumber} - ${item.aircraftTypeName}'
                              : '${item.shipNumber} - ${item.displayName}',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  final selected = _fleetOptions.firstWhereOrNull(
                    (item) => item.shipNumber == value,
                  );
                  setState(() {
                    _selectedShipNumber = value;
                    if (selected != null) {
                      _selectedAircraftTypeId = selected.aircraftTypeId;
                    }
                  });
                },
              ),
              SizedBox(height: 16.h),
              _fieldLabel('Aircraft Type'),
              SizedBox(height: 8.h),
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value:
                    _aircraftOptions.any(
                      (item) => item.id == _selectedAircraftTypeId,
                    )
                    ? _selectedAircraftTypeId
                    : null,
                decoration: _inputDecoration(),
                items: _aircraftOptions
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item.id,
                        child: Text(item.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedAircraftTypeId = value),
              ),
              SizedBox(height: 16.h),
              _fieldLabel('Number of Objects to Hide'),
              SizedBox(height: 8.h),
              TextField(
                controller: _objectCountCtrl,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration(hintText: 'Enter a whole number'),
              ),
              if (_selectedFleet != null) ...[
                SizedBox(height: 14.h),
                Text(
                  'Registry match: ${_selectedFleet!.shipNumber} uses ${_selectedFleet!.aircraftTypeName}.',
                  style: GoogleFonts.dmSans(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: _HOColors.primary,
                  ),
                ),
              ],
              if (_currentSeatMap != null) ...[
                SizedBox(height: 18.h),
                Text(
                  'Seat map preview',
                  style: GoogleFonts.dmSans(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: _HOColors.textDark,
                  ),
                ),
                SizedBox(height: 8.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: _HOColors.border),
                  ),
                  child: _HiddenObjectSeatMap(
                    seatMap: _currentSeatMap!,
                    locationsByCode: const <String, HiddenObjectLocation>{},
                    onLocationTap: (_) {},
                  ),
                ),
              ],
              SizedBox(height: 20.h),
              SizedBox(
                height: 52.h,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _HOColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  onPressed: _saving ? null : _createAudit,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Generate Targets',
                          style: GoogleFonts.dmSans(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(HiddenObjectAuditDetail detail) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: _HOColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${detail.shipNumber} - ${detail.aircraftTypeName}',
                  style: GoogleFonts.dmSans(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: _HOColors.textDark,
                  ),
                ),
              ),
              _statusChip(detail.status),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            '${detail.auditorName} - ${detail.auditorRole}',
            style: GoogleFonts.dmSans(
              fontSize: 13.sp,
              color: _HOColors.textMuted,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            DateFormat('MMM d, y - h:mm a').format(detail.sessionAt),
            style: GoogleFonts.dmSans(
              fontSize: 12.sp,
              color: _HOColors.textMuted,
            ),
          ),
          SizedBox(height: 16.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              _metricChip('Orange', detail.orange, _HOColors.orange),
              _metricChip('Blue', detail.blue, _HOColors.blue),
              _metricChip('Green', detail.green, _HOColors.green),
              _metricChip('Red', detail.red, _HOColors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(HiddenObjectAuditDetail detail) {
    final message = detail.status == 'SETUP'
        ? 'Tap each orange location, choose a sub-location, and upload a hiding photo.'
        : detail.status == 'ACTIVE'
        ? 'Blue locations are still being searched. Mark them green when found, then close the audit.'
        : 'This audit is closed. Green means found, red means not found.';

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: _HOColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: GoogleFonts.dmSans(
              fontSize: 13.sp,
              color: _HOColors.textMuted,
            ),
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              if (detail.canActivate)
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _HOColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                    onPressed: _saving ? null : _activateAudit,
                    child: Text(
                      'Start Live Audit',
                      style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              if (detail.canActivate && detail.canClose) SizedBox(width: 12.w),
              if (detail.canClose)
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _HOColors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                    onPressed: _saving ? null : _closeAudit,
                    child: Text(
                      'Close Audit',
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w700,
                        color: _HOColors.red,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: _HOColors.border),
      ),
      child: Wrap(
        spacing: 12.w,
        runSpacing: 12.h,
        children: [
          _legendItem('Orange', _HOColors.orange),
          _legendItem('Blue', _HOColors.blue),
          _legendItem('Green', _HOColors.green),
          _legendItem('Red', _HOColors.red),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10.w,
          height: 10.w,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 6.w),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 12.sp,
            color: _HOColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.dmSans(
        fontSize: 12.sp,
        fontWeight: FontWeight.w700,
        color: _HOColors.textDark,
      ),
    );
  }

  InputDecoration _inputDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: const BorderSide(color: _HOColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: const BorderSide(color: _HOColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: const BorderSide(color: _HOColors.primary),
      ),
    );
  }
}

class _LocationActionSheet extends StatefulWidget {
  const _LocationActionSheet({
    required this.auditId,
    required this.auditStatus,
    required this.location,
    required this.api,
    required this.picker,
    required this.onUpdated,
  });

  final String auditId;
  final String auditStatus;
  final HiddenObjectLocation location;
  final AppApiService api;
  final ImagePicker picker;
  final ValueChanged<Map<String, dynamic>> onUpdated;

  @override
  State<_LocationActionSheet> createState() => _LocationActionSheetState();
}

class _LocationActionSheetState extends State<_LocationActionSheet> {
  late String _selectedSubLocation;
  late List<String> _photoFileIds;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedSubLocation = widget.location.subLocation.isNotEmpty
        ? widget.location.subLocation
        : widget.location.subLocationOptions.isNotEmpty
        ? widget.location.subLocationOptions.first
        : '';
    _photoFileIds = List<String>.from(widget.location.photoFileIds);
  }

  Future<void> _pickAndUploadPhoto() async {
    try {
      final picked = await widget.picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (picked == null) {
        return;
      }

      setState(() => _saving = true);
      final uploaded = await widget.api.uploadFile(
        File(picked.path),
        category: 'IMAGE',
      );
      final fileId = uploaded['id']?.toString().trim() ?? '';
      if (fileId.isEmpty) {
        throw const ApiException('Photo upload did not return a file id.');
      }
      setState(() {
        _photoFileIds = <String>[fileId];
      });
    } on ApiException catch (error) {
      Get.snackbar(
        'Upload Photo',
        error.message,
        backgroundColor: _HOColors.red,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _confirmLocation() async {
    if (_selectedSubLocation.trim().isEmpty || _photoFileIds.isEmpty) {
      Get.snackbar(
        'Confirm Location',
        'Choose a sub-location and upload a photo first.',
        backgroundColor: _HOColors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final response = await widget.api.confirmHiddenObjectLocation(
        auditId: widget.auditId,
        locationId: widget.location.id,
        payload: {
          'subLocation': _selectedSubLocation,
          'photoFileIds': _photoFileIds,
        },
      );
      widget.onUpdated(response);
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (error) {
      Get.snackbar(
        'Confirm Location',
        error.message,
        backgroundColor: _HOColors.red,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _markFound() async {
    setState(() => _saving = true);
    try {
      final response = await widget.api.markHiddenObjectFound(
        auditId: widget.auditId,
        locationId: widget.location.id,
      );
      widget.onUpdated(response);
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (error) {
      Get.snackbar(
        'Mark Found',
        error.message,
        backgroundColor: _HOColors.red,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageHeaders = widget.api.buildImageHeaders();
    final photoUrls = _photoFileIds
        .map(widget.api.buildFileContentUrl)
        .toList(growable: false);

    return Container(
      padding: EdgeInsets.fromLTRB(
        16.w,
        16.h,
        16.w,
        MediaQuery.of(context).viewInsets.bottom + 24.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: _HOColors.border,
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.location.locationLabel,
                  style: GoogleFonts.dmSans(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: _HOColors.textDark,
                  ),
                ),
              ),
              _statusChip(widget.location.status),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            widget.location.sectionLabel,
            style: GoogleFonts.dmSans(
              fontSize: 13.sp,
              color: _HOColors.textMuted,
            ),
          ),
          SizedBox(height: 16.h),
          if (widget.auditStatus == 'SETUP') ...[
            Text(
              'Sub-location',
              style: GoogleFonts.dmSans(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: _HOColors.textDark,
              ),
            ),
            SizedBox(height: 8.h),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _selectedSubLocation.isEmpty ? null : _selectedSubLocation,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: const BorderSide(color: _HOColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: const BorderSide(color: _HOColors.border),
                ),
              ),
              items: widget.location.subLocationOptions
                  .map(
                    (option) => DropdownMenuItem<String>(
                      value: option,
                      child: Text(option),
                    ),
                  )
                  .toList(),
              onChanged: (value) =>
                  setState(() => _selectedSubLocation = value ?? ''),
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _saving ? null : _pickAndUploadPhoto,
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: Text(
                      _photoFileIds.isEmpty ? 'Capture Photo' : 'Replace Photo',
                    ),
                  ),
                ),
              ],
            ),
            if (photoUrls.isNotEmpty) ...[
              SizedBox(height: 12.h),
              SizedBox(
                height: 90.h,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: photoUrls.length,
                  separatorBuilder: (_, _) => SizedBox(width: 8.w),
                  itemBuilder: (_, index) => ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: Image.network(
                      photoUrls[index],
                      width: 90.w,
                      height: 90.h,
                      fit: BoxFit.cover,
                      headers: imageHeaders,
                    ),
                  ),
                ),
              ),
            ],
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _HOColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                onPressed: _saving ? null : _confirmLocation,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Confirm Hiding Location',
                        style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ] else if (widget.auditStatus == 'ACTIVE' &&
              widget.location.status == 'BLUE') ...[
            Text(
              widget.location.subLocation.isEmpty
                  ? 'Agents are searching this location.'
                  : 'Agents are searching ${widget.location.subLocation}.',
              style: GoogleFonts.dmSans(
                fontSize: 13.sp,
                color: _HOColors.textMuted,
              ),
            ),
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _HOColors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                onPressed: _saving ? null : _markFound,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Mark Found',
                        style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ] else ...[
            Text(
              widget.location.subLocation.isEmpty
                  ? 'No extra details were recorded for this location.'
                  : 'Sub-location: ${widget.location.subLocation}',
              style: GoogleFonts.dmSans(
                fontSize: 13.sp,
                color: _HOColors.textMuted,
              ),
            ),
            if (widget.location.foundByName.isNotEmpty) ...[
              SizedBox(height: 10.h),
              Text(
                'Found by ${widget.location.foundByName}',
                style: GoogleFonts.dmSans(
                  fontSize: 13.sp,
                  color: _HOColors.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _HiddenObjectSeatMap extends StatelessWidget {
  const _HiddenObjectSeatMap({
    required this.seatMap,
    required this.locationsByCode,
    required this.onLocationTap,
  });

  final seat_map_config.AircraftSeatMap seatMap;
  final Map<String, HiddenObjectLocation> locationsByCode;
  final ValueChanged<HiddenObjectLocation> onLocationTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: seatMap.sections.map(_buildSection).toList(),
    );
  }

  Widget _buildSection(seat_map_config.SeatSection section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (section.name.isNotEmpty) ...[
          Text(
            section.name,
            style: GoogleFonts.dmSans(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: _HOColors.textDark,
            ),
          ),
          SizedBox(height: 8.h),
        ],
        if (section.amenitiesBefore != null)
          ...section.amenitiesBefore!.map(_buildAmenityRow),
        ...List.generate(section.endRow - section.startRow + 1, (index) {
          final row = section.startRow + index;
          final skipRow = section.skipRows?.contains(row) == true;
          return Padding(
            padding: EdgeInsets.only(bottom: 6.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...section.leftCols.map(
                  (col) =>
                      skipRow ? SizedBox(width: 30.w) : _buildSeat('$row$col'),
                ),
                SizedBox(
                  width: 28.w,
                  child: Center(
                    child: Text(
                      '$row',
                      style: GoogleFonts.dmSans(
                        fontSize: 10.sp,
                        color: _HOColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                ...section.rightCols.map(
                  (col) =>
                      skipRow ? SizedBox(width: 30.w) : _buildSeat('$row$col'),
                ),
              ],
            ),
          );
        }),
        if (section.amenitiesAfter != null)
          ...section.amenitiesAfter!.map(_buildAmenityRow),
        SizedBox(height: 14.h),
      ],
    );
  }

  Widget _buildSeat(String code) {
    final location = locationsByCode[code];
    final color = location == null
        ? _HOColors.seat
        : _statusColor(location.status);
    return GestureDetector(
      onTap: location == null ? null : () => onLocationTap(location),
      child: Container(
        width: 28.w,
        height: 30.h,
        margin: EdgeInsets.symmetric(horizontal: 2.w),
        child: CustomPaint(painter: _SeatPainter(color: color)),
      ),
    );
  }

  Widget _buildAmenityRow(seat_map_config.AmenityRow amenity) {
    if (amenity.centerOnly) {
      final location = locationsByCode[amenity.effectiveAmenityId];
      return Padding(
        padding: EdgeInsets.only(bottom: 8.h),
        child: Align(
          child: _buildAmenityBox(
            id: amenity.effectiveAmenityId,
            asset: amenity.effectiveSvgAsset,
            location: location,
          ),
        ),
      );
    }

    final leftLocation = amenity.leftId == null
        ? null
        : locationsByCode[amenity.leftId];
    final rightLocation = amenity.rightId == null
        ? null
        : locationsByCode[amenity.rightId];

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (amenity.leftId != null && amenity.leftSvg != null)
            _buildAmenityBox(
              id: amenity.leftId!,
              asset: amenity.leftSvg!,
              location: leftLocation,
            )
          else
            SizedBox(width: 46.w),
          if (amenity.rightId != null && amenity.rightSvg != null)
            _buildAmenityBox(
              id: amenity.rightId!,
              asset: amenity.rightSvg!,
              location: rightLocation,
            )
          else
            SizedBox(width: 46.w),
        ],
      ),
    );
  }

  Widget _buildAmenityBox({
    required String id,
    required String asset,
    required HiddenObjectLocation? location,
  }) {
    final color = location == null
        ? _HOColors.seat
        : _statusColor(location.status);
    return GestureDetector(
      onTap: location == null ? null : () => onLocationTap(location),
      child: Container(
        width: 46.w,
        height: 46.h,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Center(
          child: SvgPicture.asset(
            asset,
            width: 20.sp,
            height: 20.sp,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }
}

class _SeatPainter extends CustomPainter {
  const _SeatPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height * 0.58),
        const Radius.circular(5),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          -1,
          size.height * 0.56,
          size.width + 2,
          size.height * 0.34,
        ),
        const Radius.circular(4),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _SeatPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

Widget _statusChip(String status) {
  final color = _statusColor(status);
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(20.r),
    ),
    child: Text(
      status,
      style: GoogleFonts.dmSans(
        fontSize: 11.sp,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    ),
  );
}

Widget _metricChip(String label, int value, Color color) {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20.r),
    ),
    child: Text(
      '$label: $value',
      style: GoogleFonts.dmSans(
        fontSize: 11.sp,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    ),
  );
}

Color _statusColor(String status) {
  switch (status.toUpperCase()) {
    case 'ORANGE':
    case 'SETUP':
      return _HOColors.orange;
    case 'BLUE':
    case 'ACTIVE':
      return _HOColors.blue;
    case 'GREEN':
    case 'PASS':
      return _HOColors.green;
    case 'RED':
    case 'CLOSED':
    case 'FAIL':
      return _HOColors.red;
    default:
      return _HOColors.seat;
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, entry) => MapEntry(key.toString(), entry));
  }
  return <String, dynamic>{};
}

List<Map<String, dynamic>> _asListOfMaps(dynamic value) {
  if (value is! List) {
    return const <Map<String, dynamic>>[];
  }
  return value.map(_asMap).toList();
}

List<String> _asStringList(dynamic value) {
  if (value is! List) {
    return const <String>[];
  }
  return value
      .map((entry) => entry.toString().trim())
      .where((entry) => entry.isNotEmpty)
      .toList();
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
