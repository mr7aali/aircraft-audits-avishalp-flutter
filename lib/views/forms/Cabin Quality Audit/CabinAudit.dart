import 'dart:io';
import 'dart:math' as math;
import 'package:avislap/views/forms/Cabin%20Quality%20Audit/CabinQualityAuditList.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:signature/signature.dart';

import '../../../data/seat_map_config.dart' as seat_map_config;
import '../../../services/api_exception.dart';
import '../../../services/app_api_service.dart';
import '../../../services/session_service.dart';

// ─────────────────────────────────────────────
// COLORS
// ─────────────────────────────────────────────
class _C {
  static const Color primary = Color(0xFF3D5AFE);
  static const Color bg = Color(0xFFF5F6FA);
  static const Color white = Color(0xFFFFFFFF);
  static const Color dark = Color(0xFF1A1A2E);
  static const Color grey = Color(0xFF8891A4);
  static const Color border = Color(0xFFE4E7EF);
  static const Color seatColor = Color(0xFF6B7B99);
  static const Color green = Color(0xFF22C55E);
  static const Color red = Color(0xFFEF4444);
  static const Color planeGrey = Color(0xFFEDEFF4);
}

// ─────────────────────────────────────────────
// CHECK ITEMS PER AREA TYPE  ← FIXED
// ─────────────────────────────────────────────
class AuditCheckItems {
  // Area-specific sub-categories
  static const Map<String, List<String>> areaItems = {
    'lav': [
      'Soap Dispenser',
      'Trash / Bin',
      'Mirror',
      'Toilet / Bowl',
      'Floor',
      'Sink',
      'Paper Towels',
      'Air Freshener',
    ],
    'galley': [
      'Trash',
      'Counter / Surface',
      'Oven / Microwave',
      'Coffee Maker',
      'Storage Compartments',
      'Floor',
    ],
    'jump_seat': [
      'Seat Cushion',
      'Seat Belt / Harness',
      'Seat Pocket',
      'Life Vest Pouch',
      'Side Console',
      'Under Seat',
    ],
    'first_class': [
      'Seat Recline',
      'IFE Screen',
      'Tray Table',
      'Headrest / Pillow',
      'Blanket',
      'Seat Pocket',
      'Armrest',
      'Floor / Carpet',
    ],
    'comfort': [
      'Seat',
      'Tray Table',
      'IFE Screen',
      'Overhead Bin',
      'Seat Pocket',
      'Floor / Carpet',
    ],
    'main_cabin': [
      'Seat Back Trash',
      'Tray Table',
      'IFE Screen',
      'Floor / Carpet',
      'Overhead Bin',
      'Seat Pocket',
      'Armrest',
    ],
  };

  static List<String> forArea(String areaType) =>
      areaItems[areaType] ?? areaItems['main_cabin']!;
}

// ─────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────
class AircraftSeatMap {
  final String name;
  final List<SeatSection> sections;
  final bool hasFirstClassArc;
  AircraftSeatMap({
    required this.name,
    required this.sections,
    this.hasFirstClassArc = false,
  });
}

class SeatSection {
  final String name;
  final int startRow;
  final int endRow;
  final List<String> leftCols;
  final List<String> rightCols;
  final String? areaType;
  final bool hasExitBefore;
  final bool hasExitAfter;
  final List<AmenityRow>? amenitiesBefore;
  final List<AmenityRow>? amenitiesAfter;
  final List<int>? skipRows;
  SeatSection({
    required this.name,
    required this.startRow,
    required this.endRow,
    required this.leftCols,
    required this.rightCols,
    this.areaType,
    this.hasExitBefore = false,
    this.hasExitAfter = false,
    this.amenitiesBefore,
    this.amenitiesAfter,
    this.skipRows,
  });
}

class AmenityRow {
  final String? leftSvg;
  final String? leftId;
  final String? rightSvg;
  final String? rightId;
  final bool centerOnly;
  final String? customLabel;
  AmenityRow({
    this.leftSvg,
    this.leftId,
    this.rightSvg,
    this.rightId,
    this.centerOnly = false,
    this.customLabel,
  });

  String get effectiveAmenityId =>
      rightId ?? leftId ?? customLabel ?? 'Amenity';

  String get effectiveSvgAsset =>
      rightSvg ?? leftSvg ?? seat_map_config.kSeatMapToiletAsset;
}

// ─────────────────────────────────────────────
// CONTROLLER
// ─────────────────────────────────────────────
class CabinAudit extends GetxController {
  final selectedAircraft = 'Boeing 757-300 (75Y)'.obs;
  final selectedGate = 'Gate - A'.obs;
  final selectedCleanType = 'Charter'.obs;
  final supervisorName = ''.obs;

  // auditedSeats stores seatId → overall status ('pass'/'fail'/'na')
  final auditedSeats = <String, String>{}.obs;

  // checkItemStatuses stores 'seatId|itemName' → 'pass'/'fail'/'na'
  final checkItemStatuses = <String, String>{}.obs;

  final List<String> aircraftOptions = List<String>.from(
    seat_map_config.defaultAircraftSeatMaps.keys,
  );
  final List<String> gateOptions = [
    'Gate - A',
    'Gate - B',
    'Gate - C',
    'Gate - D',
  ];
  final List<String> cleanTypeOptions = [
    'Charter',
    'Diversion',
    'DCS Turn',
    'MSGT Turn',
    'RAD – Remain All Day',
    'RON – Remain Over Night',
    'Security Search',
  ];

  Map<String, AircraftSeatMap> aircraftMaps = <String, AircraftSeatMap>{};

  @override
  void onInit() {
    super.onInit();
    _initAircraftMaps();
    ever(selectedAircraft, (_) {
      auditedSeats.clear();
      checkItemStatuses.clear();
      checkItemImages.clear();
      checkItemTags.clear();
      mandatoryAreas.clear();
    });
    ever(selectedCleanType, (_) {
      mandatoryAreas.clear();
    });
  }

  void _initAircraftMaps() {
    aircraftMaps = _convertSeatMaps(seat_map_config.defaultAircraftSeatMaps);
  }

  Map<String, AircraftSeatMap> _convertSeatMaps(
    Map<String, seat_map_config.AircraftSeatMap> source,
  ) {
    return source.map(
      (key, value) => MapEntry(
        key,
        AircraftSeatMap(
          name: value.name,
          hasFirstClassArc: value.hasFirstClassArc,
          sections: value.sections
              .map(
                (section) => SeatSection(
                  name: section.name,
                  startRow: section.startRow,
                  endRow: section.endRow,
                  leftCols: List<String>.from(section.leftCols),
                  rightCols: List<String>.from(section.rightCols),
                  areaType: section.areaType,
                  hasExitBefore: section.hasExitBefore,
                  hasExitAfter: section.hasExitAfter,
                  amenitiesBefore: section.amenitiesBefore
                      ?.map(
                        (amenity) => AmenityRow(
                          leftSvg: amenity.leftSvg,
                          leftId: amenity.leftId,
                          rightSvg: amenity.rightSvg,
                          rightId: amenity.rightId,
                          centerOnly: amenity.centerOnly,
                          customLabel: amenity.customLabel,
                        ),
                      )
                      .toList(),
                  amenitiesAfter: section.amenitiesAfter
                      ?.map(
                        (amenity) => AmenityRow(
                          leftSvg: amenity.leftSvg,
                          leftId: amenity.leftId,
                          rightSvg: amenity.rightSvg,
                          rightId: amenity.rightId,
                          centerOnly: amenity.centerOnly,
                          customLabel: amenity.customLabel,
                        ),
                      )
                      .toList(),
                  skipRows: section.skipRows == null
                      ? null
                      : List<int>.from(section.skipRows!),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  AircraftSeatMap get currentAircraftMap =>
      aircraftMaps[selectedAircraft.value] ?? aircraftMaps.values.first;

  final RxSet<String> mandatoryAreas = <String>{}.obs;

  void generateMandatoryAreas() {
    mandatoryAreas.clear();
    final map = currentAircraftMap;
    final List<String> allValidAreas = [];

    for (final section in map.sections) {
      if (section.skipRows ==
          null) {} // Just to suppress unused warning conceptually
      for (int r = section.startRow; r <= section.endRow; r++) {
        if (section.skipRows?.contains(r) ?? false) continue;
        for (final col in section.leftCols) {
          if (col.isNotEmpty) allValidAreas.add('$r$col');
        }
        for (final col in section.rightCols) {
          if (col.isNotEmpty) allValidAreas.add('$r$col');
        }
      }
      if (section.amenitiesBefore != null) {
        for (final a in section.amenitiesBefore!) {
          if (a.customLabel != null) {
            allValidAreas.add(a.effectiveAmenityId);
          } else if (a.centerOnly) {
            allValidAreas.add(a.effectiveAmenityId);
          } else {
            if (a.leftId != null) allValidAreas.add(a.leftId!);
            if (a.rightId != null) allValidAreas.add(a.rightId!);
          }
        }
      }
      if (section.amenitiesAfter != null) {
        for (final a in section.amenitiesAfter!) {
          if (a.customLabel != null) {
            allValidAreas.add(a.effectiveAmenityId);
          } else if (a.centerOnly) {
            allValidAreas.add(a.effectiveAmenityId);
          } else {
            if (a.leftId != null) allValidAreas.add(a.leftId!);
            if (a.rightId != null) allValidAreas.add(a.rightId!);
          }
        }
      }
    }

    if (allValidAreas.isEmpty) return;

    allValidAreas.shuffle(math.Random());

    int targetCount = 0;
    final cleanType = selectedCleanType.value.toLowerCase();
    if (cleanType.contains('dcs turn')) {
      targetCount = 8;
    } else if (cleanType.contains('over night') ||
        cleanType.contains('all day')) {
      targetCount = 20;
    } else if (cleanType.contains('charter')) {
      targetCount = 12;
    } else if (cleanType.contains('diversion')) {
      targetCount = 10;
    } else if (cleanType.contains('security')) {
      targetCount = 5;
    } else if (cleanType.contains('msgt')) {
      targetCount = 10;
    } else {
      targetCount = 8;
    }

    if (targetCount > allValidAreas.length) {
      targetCount = allValidAreas.length;
    }

    mandatoryAreas.addAll(allValidAreas.take(targetCount));
  }

  void markSeat(String id, String status) => auditedSeats[id] = status;
  void clearSeat(String id) => auditedSeats.remove(id);

  // Per check-item images and tags
  final checkItemImages = <String, RxList<File>>{};
  final checkItemTags = <String, RxList<String>>{};

  // ── FIXED: setCheckItem now auto-fails parent if any sub-item fails ──
  void setCheckItem(String seatId, String itemName, String status) {
    final key = '$seatId|$itemName';
    checkItemStatuses[key] = status;

    if (status == 'na') {
      checkItemImages.remove(key);
      checkItemTags.remove(key);
    }

    // Derive overall seat status — ANY fail = parent fails
    final itemsForSeat = checkItemStatuses.keys
        .where((k) => k.startsWith('$seatId|'))
        .toList();

    final hasAnyFail = itemsForSeat.any((k) => checkItemStatuses[k] == 'fail');
    final hasAnyPass = itemsForSeat.any((k) => checkItemStatuses[k] == 'pass');

    if (hasAnyFail) {
      auditedSeats[seatId] = 'fail';
    } else if (hasAnyPass) {
      auditedSeats[seatId] = 'pass';
    } else {
      // All N/A → reset to unaudited
      auditedSeats.remove(seatId);
    }
  }

  String getCheckItem(String seatId, String itemName) {
    return checkItemStatuses['$seatId|$itemName'] ?? 'na';
  }

  // ── FIXED: Determine area type for the given seat/amenity ID ──
  String getSectionForSeat(String seatId) {
    final idLower = seatId.toLowerCase();

    // LAV / restroom amenity IDs
    if (idLower.contains('lav') || idLower == 'closet') return 'lav';

    // Galley amenity IDs
    if (idLower.contains('galley')) return 'galley';

    if (idLower.contains('jump seat')) return 'jump_seat';

    // Parse row number from seat IDs like "14A", "3B"
    final rowStr = seatId.replaceAll(RegExp(r'[A-Za-z\s]'), '');
    final rowNum = int.tryParse(rowStr) ?? 0;

    final map = currentAircraftMap;
    for (final section in map.sections) {
      if (rowNum >= section.startRow && rowNum <= section.endRow) {
        final areaType = section.areaType?.toLowerCase();
        if (areaType == 'first_class' ||
            areaType == 'comfort' ||
            areaType == 'main_cabin') {
          return areaType!;
        }

        final sName = section.name.toLowerCase();
        if (sName.contains('first') || sName.contains('business')) {
          return 'first_class';
        }
        if (sName.contains('comfort')) return 'comfort';
        return 'main_cabin';
      }
    }
    return 'main_cabin';
  }

  // ── FIXED: Returns area-specific check items ──
  List<String> getCheckItemsForSeat(String seatId) {
    final areaType = getSectionForSeat(seatId);
    return AuditCheckItems.forArea(areaType);
  }

  // ── FIXED: Returns the display title for the bottom sheet ──
  // Shows the actual area/seat ID as the primary title
  // and a friendly category label as subtitle
  String getAreaTitle(String seatId) {
    return seatId; // e.g. "LAV FWD", "14A", "Galley AFT"
  }

  String getSectionLabel(String seatId) {
    final section = getSectionForSeat(seatId);
    switch (section) {
      case 'lav':
        return 'Lav / Restroom';
      case 'galley':
        return 'Galley';
      case 'jump_seat':
        return 'Jump Seat';
      case 'first_class':
        return 'First Class';
      case 'comfort':
        return 'Comfort+';
      default:
        return 'Main Cabin';
    }
  }
}

// ─────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────
class CabinAuditScreen extends StatefulWidget {
  const CabinAuditScreen({super.key});
  @override
  State<CabinAuditScreen> createState() => _CabinAuditScreenState();
}

class _CabinAuditScreenState extends State<CabinAuditScreen> {
  final _ctrl = Get.put(CabinAudit());
  final AppApiService _api = Get.find<AppApiService>();
  final SessionService _session = Get.find<SessionService>();
  final _supervisorCtrl = TextEditingController();
  final _otherFindingsCtrl = TextEditingController();
  final _additionalNotesCtrl = TextEditingController();

  // Steps: 0 = Job Details, 1 = Seat Map, 2 = Notes
  int _step = 0;

  final RxList<File> _selectedImages = <File>[].obs;
  final ImagePicker _picker = ImagePicker();
  final Map<String, String> _gateIdsByLabel = <String, String>{};
  final Map<String, String> _cleanTypeIdsByLabel = <String, String>{};
  final Map<String, String> _checklistIdsByLabel = <String, String>{};
  bool _isLoading = true;
  bool _isSubmitting = false;

  final SignatureController signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      _selectedImages.addAll(images.map((img) => File(img.path)));
    }
  }

  static String _todayDate() {
    final n = DateTime.now();
    return '${n.month.toString().padLeft(2, '0')}/'
        '${n.day.toString().padLeft(2, '0')}/${n.year}';
  }

  @override
  void initState() {
    super.initState();
    _loadFormData();
  }

  @override
  void dispose() {
    _supervisorCtrl.dispose();
    _otherFindingsCtrl.dispose();
    _additionalNotesCtrl.dispose();
    signatureController.dispose();
    super.dispose();
  }

  Future<void> _loadFormData() async {
    setState(() => _isLoading = true);

    try {
      final stationId = _session.activeStationId;
      if (stationId.isEmpty) {
        throw Exception('No active station selected');
      }

      final results = await Future.wait([
        _api.getGates(stationId),
        _api.getCleanTypes(),
        _api.getCabinQualityChecklistItems(),
        _api.getAircraftTypes(),
      ]);

      final gates = List<Map<String, dynamic>>.from(results[0]);
      final cleanTypes = List<Map<String, dynamic>>.from(results[1]);
      final checklist = List<Map<String, dynamic>>.from(results[2]);
      final aircraftTypes = List<Map<String, dynamic>>.from(results[3]);

      _gateIdsByLabel.clear();
      _ctrl.gateOptions.clear();
      for (final gate in gates) {
        final gateId = gate['id']?.toString() ?? '';
        final gateCode = gate['gateCode']?.toString().trim() ?? '';
        if (gateId.isEmpty || gateCode.isEmpty) {
          continue;
        }
        final label = gateCode.toLowerCase().startsWith('gate ')
            ? gateCode
            : 'Gate $gateCode';
        _gateIdsByLabel[label] = gateId;
        _ctrl.gateOptions.add(label);
      }
      if (_ctrl.gateOptions.isNotEmpty) {
        _ctrl.selectedGate.value = _ctrl.gateOptions.first;
      }

      _cleanTypeIdsByLabel.clear();
      _ctrl.cleanTypeOptions.clear();
      for (final cleanType in cleanTypes) {
        final cleanTypeId = cleanType['id']?.toString() ?? '';
        final name = cleanType['name']?.toString().trim() ?? '';
        if (cleanTypeId.isEmpty || name.isEmpty) {
          continue;
        }
        _cleanTypeIdsByLabel[name] = cleanTypeId;
        _ctrl.cleanTypeOptions.add(name);
      }
      if (_ctrl.cleanTypeOptions.isNotEmpty) {
        _ctrl.selectedCleanType.value = _ctrl.cleanTypeOptions.first;
      }

      final syncedAircraftMaps = _ctrl._convertSeatMaps(
        seat_map_config.buildAircraftSeatMapsFromApi(aircraftTypes),
      );
      if (syncedAircraftMaps.isNotEmpty) {
        _ctrl.aircraftMaps = syncedAircraftMaps;
        _ctrl.aircraftOptions
          ..clear()
          ..addAll(syncedAircraftMaps.keys);
      }
      if (_ctrl.aircraftOptions.isNotEmpty &&
          !_ctrl.aircraftOptions.contains(_ctrl.selectedAircraft.value)) {
        _ctrl.selectedAircraft.value = _ctrl.aircraftOptions.first;
      }

      _checklistIdsByLabel.clear();
      for (final item in checklist) {
        final checklistId = item['id']?.toString() ?? '';
        final label = item['label']?.toString().trim() ?? '';
        if (checklistId.isEmpty || label.isEmpty) {
          continue;
        }
        _checklistIdsByLabel[label] = checklistId;
      }

      if (_session.fullName.isNotEmpty) {
        _supervisorCtrl.text = _session.fullName;
      } else if (_session.firstName.isNotEmpty) {
        _supervisorCtrl.text = _session.firstName;
      }
    } on ApiException catch (error) {
      Get.snackbar(
        'Form Unavailable',
        error.message,
        backgroundColor: _C.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } catch (_) {
      Get.snackbar(
        'Form Unavailable',
        'Unable to load gate and checklist data right now.',
        backgroundColor: _C.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _C.bg,
        appBar: _buildAppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: _C.bg,
      appBar: _buildAppBar(),
      body: _step == 0
          ? _buildStep0()
          : _step == 1
          ? _buildStep1()
          : _buildStep2(),
    );
  }

  // ── App Bar ──────────────────────────────────────────────
  AppBar _buildAppBar() => AppBar(
    backgroundColor: _C.white,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    leading: IconButton(
      icon: Icon(Icons.arrow_back_rounded, color: _C.primary, size: 22.sp),
      onPressed: () => _step > 0 ? setState(() => _step--) : Get.back(),
    ),
    title: Text(
      'Cabin Quality Audit',
      style: GoogleFonts.dmSans(
        fontSize: 17.sp,
        fontWeight: FontWeight.w600,
        color: _C.primary,
      ),
    ),
    centerTitle: true,
    actions: [
      IconButton(
        icon: Icon(Icons.info_outline_rounded, color: _C.primary, size: 22.sp),
        onPressed: _showInstructions,
      ),
    ],
  );

  // ── STEP 0: Job Details ──────────────────────────────────
  Widget _buildStep0() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('Date and Time *'),
                _pillField(
                  child: Row(
                    children: [
                      Expanded(child: Text(_todayDate(), style: _fieldStyle())),
                      Icon(
                        Icons.calendar_month_outlined,
                        size: 20.sp,
                        color: _C.grey,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
                _label('Supervisor / Lead *'),
                _pillTextField(controller: _supervisorCtrl, hint: 'John Doe'),
                SizedBox(height: 16.h),
                _label('Gate *'),
                Obx(
                  () => _pillDropdown(
                    value: _ctrl.selectedGate.value,
                    items: _ctrl.gateOptions,
                    onChanged: (v) => _ctrl.selectedGate.value = v!,
                  ),
                ),
                SizedBox(height: 16.h),
                _label('Type of Clean *'),
                Obx(
                  () => _pillDropdown(
                    value: _ctrl.selectedCleanType.value,
                    items: _ctrl.cleanTypeOptions,
                    onChanged: (v) => _ctrl.selectedCleanType.value = v!,
                  ),
                ),
              ],
            ),
          ),
        ),
        _nextButton(() {
          if (_ctrl.mandatoryAreas.isEmpty) {
            _ctrl.generateMandatoryAreas();
          }
          setState(() => _step = 1);
        }),
      ],
    );
  }

  // ── STEP 1: Inspection Checklist + Seat Map ──────────────
  Widget _buildStep1() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 24.h),
                Text(
                  'Inspection Checklist',
                  style: GoogleFonts.dmSans(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: _C.primary,
                  ),
                ),
                SizedBox(height: 16.h),
                _label('Type of Aircraft *'),

                Obx(
                  () => _pillDropdown(
                    value: _ctrl.selectedAircraft.value,
                    items: _ctrl.aircraftOptions,
                    onChanged: (v) => _ctrl.selectedAircraft.value = v!,
                    suffixIcon: Icons.search_rounded,
                  ),
                ),
                SizedBox(height: 16.h),
                Obx(() {
                  if (_ctrl.mandatoryAreas.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  int audited = _ctrl.mandatoryAreas
                      .where((m) => _ctrl.auditedSeats.containsKey(m))
                      .length;
                  bool allDone = audited == _ctrl.mandatoryAreas.length;
                  return Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: allDone
                          ? _C.green.withValues(alpha: 0.1)
                          : Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: allDone ? _C.green : Colors.orange,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              allDone
                                  ? Icons.check_circle_rounded
                                  : Icons.warning_amber_rounded,
                              color: allDone
                                  ? _C.green
                                  : Colors.orange.shade800,
                              size: 20.sp,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'Randomly System Areas ($audited / ${_ctrl.mandatoryAreas.length})',
                              style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.sp,
                                color: allDone
                                    ? _C.green
                                    : Colors.orange.shade800,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        Wrap(
                          spacing: 8.w,
                          runSpacing: 6.h,
                          children: _ctrl.mandatoryAreas.map((m) {
                            bool isDone = _ctrl.auditedSeats.containsKey(m);
                            return Text(
                              m,
                              style: GoogleFonts.dmSans(
                                fontSize: 12.sp,
                                fontWeight: isDone
                                    ? FontWeight.normal
                                    : FontWeight.w600,
                                color: isDone ? _C.green : _C.dark,
                                decoration: isDone
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  );
                }),
                SizedBox(height: 16.h),
                _buildLegend(),
                SizedBox(height: 16.h),
                _buildSeatMap(),
                SizedBox(height: 16.h),
              ],
            ),
          ),
        ),
        _nextButton(() {
          final missing = _ctrl.mandatoryAreas
              .where((m) => !_ctrl.auditedSeats.containsKey(m))
              .toList();
          if (missing.isNotEmpty) {
            Get.snackbar(
              'Incomplete',
              'Please audit all required system-selected areas.',
              backgroundColor: _C.red,
              colorText: Colors.white,
              snackPosition: SnackPosition.TOP,
            );
            return;
          }
          setState(() => _step = 2);
        }),
      ],
    );
  }

  Widget _buildLegend() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _legendDot(_C.green, 'Pass'),
          SizedBox(width: 12.w),
          _legendDot(_C.red, 'Fail'),
          SizedBox(width: 12.w),
          _legendDot(_C.seatColor, 'Not audited'),
          SizedBox(width: 12.w),
          Row(
            children: [
              Container(
                width: 10.w,
                height: 10.h,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.orange, width: 2),
                ),
              ),
              SizedBox(width: 4.w),
              Text(
                'Mandatory',
                style: GoogleFonts.dmSans(fontSize: 10.sp, color: _C.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10.w,
          height: 10.h,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 4.w),
        Text(
          label,
          style: GoogleFonts.dmSans(fontSize: 10.sp, color: _C.grey),
        ),
      ],
    );
  }

  // ── STEP 2: Notes + Submit ───────────────────────────────
  Widget _buildStep2() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('Other Findings'),
                _multilineField(
                  'Enter any additional findings or notes...',
                  controller: _otherFindingsCtrl,
                ),
                SizedBox(height: 16.h),
                _label('Additional Notes'),
                _multilineField(
                  'Enter any additional findings or notes...',
                  controller: _additionalNotesCtrl,
                ),
                SizedBox(height: 16.h),
                _label('Pictures'),
                _uploadBox(),
                SizedBox(height: 12.h),
                Obx(
                  () => _selectedImages.isEmpty
                      ? const SizedBox.shrink()
                      : Wrap(
                          spacing: 8.w,
                          runSpacing: 8.h,
                          children: _selectedImages.map((file) {
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8.r),
                                  child: Image.file(
                                    file,
                                    width: 80.w,
                                    height: 80.w,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => _selectedImages.remove(file),
                                    child: Container(
                                      padding: EdgeInsets.all(2.r),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 14.sp,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                ),
                SizedBox(height: 16.h),
                // Digital Signature
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: _C.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.draw_rounded,
                                color: _C.primary,
                                size: 20.sp,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                'Digital Signature',
                                style: GoogleFonts.dmSans(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                ' *',
                                style: GoogleFonts.dmSans(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => signatureController.clear(),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 6.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Text(
                                'Clear',
                                style: GoogleFonts.dmSans(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12.r),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            border: Border.all(
                              color: _C.primary.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Center(
                                  child: Text(
                                    'Sign Here',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 24.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.withValues(alpha: 0.3),
                                    ),
                                  ),
                                ),
                              ),
                              Signature(
                                controller: signatureController,
                                height: 140.h,
                                backgroundColor: Colors.transparent,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        _submitButton(),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // SEAT MAP
  // ─────────────────────────────────────────────
  Widget _buildSeatMap() {
    double planeWidth = 330.w; // Making it wide enough to contain the seats
    return Obx(() {
      final aircraftMap = _ctrl.currentAircraftMap;
      return SizedBox(
        width: planeWidth,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // BACKGROUND SHAPE
            Positioned.fill(
              child: Column(
                children: [
                  ClipRect(
                    child: Align(
                      alignment: Alignment.topCenter,
                      heightFactor: 0.95,
                      child: Image.asset(
                        'assets/images/nose.png',
                        width: planeWidth * 1.08,
                        fit: BoxFit.fitWidth,
                        color: _C.planeGrey,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(width: planeWidth, color: _C.planeGrey),
                  ),
                  ClipRect(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      heightFactor: 0.90,
                      child: Image.asset(
                        'assets/images/tail.png',
                        width: planeWidth * 1.06,
                        fit: BoxFit.fitWidth,
                        color: _C.planeGrey,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // FOREGROUND SEAT MAP
            Container(
              constraints: BoxConstraints(
                minHeight:
                    planeWidth * 2.0, // Safely larger than nose+tail combined
              ),
              child: Column(
                children: [
                  SizedBox(height: 110.h),
                  _buildCockpitWindows(),
                  SizedBox(
                    height: 100.h,
                  ), // Push seats further down the nose shape

                  ...aircraftMap.sections.map(
                    (section) => _buildSection(section),
                  ),
                  SizedBox(
                    height: 320.h,
                  ), // Keep seats & exit rows out of the narrowing tail section
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildCockpitWindows() {
    int windowCount = 6;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(windowCount, (i) {
        double indexOffset = i - (windowCount - 1) / 2;
        double angle = indexOffset * 0.25;
        double yOffset = math.pow(indexOffset.abs(), 2) * 4;
        return Transform.translate(
          offset: Offset(0, yOffset),
          child: Transform.rotate(
            angle: angle,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 2.w),
              width: 24.w,
              height: 18.h,
              decoration: BoxDecoration(
                color: const Color(0xFF5D6E7E),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSection(SeatSection section) {
    return Column(
      children: [
        if (section.amenitiesBefore != null)
          ...section.amenitiesBefore!.map((amenity) {
            if (amenity.customLabel != null) {
              return _buildCustomAmenityRow(amenity);
            }
            return _buildAmenityRow(
              leftSvg: amenity.leftSvg,
              leftId: amenity.leftId,
              rightSvg: amenity.rightSvg,
              rightId: amenity.rightId,
              centerOnly: amenity.centerOnly,
            );
          }),
        if (section.hasExitBefore) _buildExitRow(),
        SizedBox(height: 4.h),
        if (section.name.isNotEmpty) _buildSectionLabel(section.name),
        SizedBox(height: 4.h),
        _buildColHeaders([...section.leftCols, '', ...section.rightCols]),
        SizedBox(height: 4.h),
        ...List.generate(section.endRow - section.startRow + 1, (i) {
          final rowNum = section.startRow + i;
          if (section.skipRows != null && section.skipRows!.contains(rowNum)) {
            return _buildSeatRow(
              rowNum: rowNum,
              leftCols: ['', ''],
              rightCols: section.rightCols,
            );
          }
          return _buildSeatRow(
            rowNum: rowNum,
            leftCols: section.leftCols,
            rightCols: section.rightCols,
          );
        }),
        SizedBox(height: 16.h),
        if (section.hasExitAfter) _buildExitRow(),
        if (section.amenitiesAfter != null)
          ...section.amenitiesAfter!.map(
            (amenity) => amenity.customLabel != null
                ? _buildCustomAmenityRow(amenity)
                : _buildAmenityRow(
                    leftSvg: amenity.leftSvg,
                    leftId: amenity.leftId,
                    rightSvg: amenity.rightSvg,
                    rightId: amenity.rightId,
                    centerOnly: amenity.centerOnly,
                  ),
          ),
      ],
    );
  }

  Widget _buildColHeaders(List<String> cols) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: cols
            .map(
              (c) => c.isEmpty
                  ? SizedBox(width: 28.w)
                  : SizedBox(
                      width: 34.w,
                      child: Center(
                        child: Text(
                          c,
                          style: GoogleFonts.dmSans(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: _C.grey,
                          ),
                        ),
                      ),
                    ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildSeatRow({
    required int rowNum,
    required List<String> leftCols,
    required List<String> rightCols,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ...leftCols.map(
            (col) => col.isEmpty ? SizedBox(width: 34.w) : _seat('$rowNum$col'),
          ),
          SizedBox(
            width: 28.w,
            child: Center(
              child: Text(
                '$rowNum',
                style: GoogleFonts.dmSans(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: _C.grey,
                ),
              ),
            ),
          ),
          ...rightCols.map(
            (col) => col.isEmpty ? SizedBox(width: 34.w) : _seat('$rowNum$col'),
          ),
        ],
      ),
    );
  }

  Widget _seat(String id) {
    return Obx(() {
      final status = _ctrl.auditedSeats[id];
      final isMandatory = _ctrl.mandatoryAreas.contains(id);
      final color = status == 'pass'
          ? _C.green
          : status == 'fail'
          ? _C.red
          : _C.seatColor;
      return GestureDetector(
        onTap: () => _showSeatSheet(id),
        child: Container(
          width: 30.w,
          height: 32.h,
          margin: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
          child: CustomPaint(
            painter: _SeatPainter(color: color, isMandatory: isMandatory),
          ),
        ),
      );
    });
  }

  Widget _buildAmenityRow({
    String? leftSvg,
    String? leftId,
    String? rightSvg,
    String? rightId,
    bool centerOnly = false,
  }) {
    if (centerOnly) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 6.h),
        child: _amenityBox(rightSvg!, rightId!),
      );
    }
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 40.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (leftSvg != null && leftId != null)
            _amenityBox(leftSvg, leftId)
          else
            SizedBox(width: 44.w),
          if (rightSvg != null && rightId != null)
            _amenityBox(rightSvg, rightId)
          else
            SizedBox(width: 44.w),
        ],
      ),
    );
  }

  Widget _amenityBox(String svgPath, String id) {
    return Obx(() {
      final status = _ctrl.auditedSeats[id];
      final isMandatory = _ctrl.mandatoryAreas.contains(id);

      final color = status == 'pass'
          ? _C.green
          : status == 'fail'
          ? _C.red
          : _C.seatColor;

      return GestureDetector(
        onTap: () => _showSeatSheet(id),
        child: Container(
          width: 44.w,
          height: 44.h,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10.r),
            border: isMandatory && status == null
                ? Border.all(color: Colors.orange, width: 2.5)
                : null,
          ),
          child: Center(
            child: SvgPicture.asset(
              svgPath,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
              width: 22.sp,
              height: 22.sp,
            ),
          ),
        ),
      );
    });
  }

  Widget _buildExitRow() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5.h, horizontal: 40.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '◁ Exit',
            style: GoogleFonts.dmSans(
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
              color: _C.grey,
            ),
          ),
          Text(
            'Exit ▷',
            style: GoogleFonts.dmSans(
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
              color: _C.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomAmenityRow(AmenityRow amenity) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 40.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            amenity.customLabel ?? amenity.effectiveAmenityId,
            style: GoogleFonts.dmSans(
              fontSize: 12.sp,
              color: _C.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          _amenityBox(amenity.effectiveSvgAsset, amenity.effectiveAmenityId),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String t) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Center(
        child: Text(
          t,
          style: GoogleFonts.dmSans(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: _C.dark,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // SEAT / AREA BOTTOM SHEET  ← FIXED
  // ─────────────────────────────────────────────
  void _showSeatSheet(String id) {
    final checkItems = _ctrl.getCheckItemsForSeat(id);

    // ── FIXED: Title = actual area ID (e.g. "LAV FWD", "14A") ──
    final areaTitle = _ctrl.getAreaTitle(id);
    // ── Subtitle = friendly category label ──
    final categoryLabel = _ctrl.getSectionLabel(id);

    final Map<String, RxString> itemStatuses = {
      for (final item in checkItems) item: _ctrl.getCheckItem(id, item).obs,
    };

    final RxList<File> seatImages = <File>[].obs;
    final notesCtrl = TextEditingController();
    final RxList<String> tags = <String>[].obs;
    final picker = ImagePicker();

    Future<void> pickImages() async {
      final picked = await picker.pickMultiImage();
      if (picked.isNotEmpty) {
        seatImages.addAll(picked.map((x) => File(x.path)));
      }
    }

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, ss) => Material(
          color: Colors.transparent,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.92,
            decoration: BoxDecoration(
              color: _C.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
            ),
            child: Column(
              children: [
                // drag handle
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  child: Center(
                    child: Container(
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: _C.border,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── FIXED: Show actual area ID as big title ──
                        Text(
                          areaTitle,
                          style: GoogleFonts.dmSans(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w700,
                            color: _C.primary,
                          ),
                        ),
                        // ── Category label as subtitle ──
                        Text(
                          categoryLabel,
                          style: GoogleFonts.dmSans(
                            fontSize: 13.sp,
                            color: _C.grey,
                          ),
                        ),
                        SizedBox(height: 12.h),

                        // ── Live Score Card ──────────────────────
                        Obx(() {
                          // Count pass/fail/na from current itemStatuses
                          int passCount = 0;
                          int failCount = 0;
                          int totalChecked = 0;
                          for (final item in checkItems) {
                            final s = itemStatuses[item]!.value;
                            if (s == 'pass') {
                              passCount++;
                              totalChecked++;
                            } else if (s == 'fail') {
                              failCount++;
                              totalChecked++;
                            }
                          }
                          // Any fail → overall FAIL (Hirtik's rule)
                          final hasAnyFail = failCount > 0;
                          final scorePercent = totalChecked == 0
                              ? 0.0
                              : (passCount / totalChecked) * 100;
                          final overallColor = hasAnyFail
                              ? _C.red
                              : (passCount > 0 ? _C.green : _C.grey);
                          final overallLabel = hasAnyFail
                              ? 'FAIL'
                              : (passCount > 0 ? 'PASS' : 'NOT CHECKED');

                          return Container(
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: overallColor.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: overallColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                // Score circle
                                Container(
                                  width: 52.w,
                                  height: 52.h,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: overallColor,
                                  ),
                                  child: Center(
                                    child: Text(
                                      totalChecked == 0
                                          ? 'N/A'
                                          : '${scorePercent.toStringAsFixed(0)}%',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        overallLabel,
                                        style: GoogleFonts.dmSans(
                                          fontSize: 15.sp,
                                          fontWeight: FontWeight.w700,
                                          color: overallColor,
                                        ),
                                      ),
                                      SizedBox(height: 2.h),
                                      Text(
                                        '$passCount Pass  •  $failCount Fail  •  ${checkItems.length - totalChecked} N/A',
                                        style: GoogleFonts.dmSans(
                                          fontSize: 11.sp,
                                          color: _C.grey,
                                        ),
                                      ),
                                      if (hasAnyFail) ...[
                                        SizedBox(height: 3.h),
                                        Text(
                                          'Any failed item = area FAIL',
                                          style: GoogleFonts.dmSans(
                                            fontSize: 10.sp,
                                            color: _C.red,
                                            fontWeight: FontWeight.w600,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        SizedBox(height: 16.h),

                        // Info note
                        Container(
                          padding: EdgeInsets.all(10.w),
                          decoration: BoxDecoration(
                            color: _C.bg,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            'Mark each item Pass, Fail, or N/A. '
                            'Items not checked are N/A by default. '
                            'Any failed item will automatically fail this area.',
                            style: GoogleFonts.dmSans(
                              fontSize: 11.sp,
                              color: _C.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                        SizedBox(height: 20.h),

                        // ── Check Items List ──
                        ...checkItems.map((item) {
                          return Obx(() {
                            final status = itemStatuses[item]!.value;
                            return _buildCheckItemRow(
                              seatId: id,
                              itemName: item,
                              status: status,
                              ctrl: _ctrl,
                              onPass: () => ss(() {
                                itemStatuses[item]!.value = 'pass';
                                _ctrl.checkItemStatuses['$id|$item'] = 'pass';
                                _ctrl.setCheckItem(id, item, 'pass');
                              }),
                              onFail: () => ss(() {
                                itemStatuses[item]!.value = 'fail';
                                _ctrl.checkItemStatuses['$id|$item'] = 'fail';
                                _ctrl.setCheckItem(id, item, 'fail');
                              }),
                              onNA: () => ss(() {
                                itemStatuses[item]!.value = 'na';
                                _ctrl.setCheckItem(id, item, 'na');
                              }),
                            );
                          });
                        }),

                        SizedBox(height: 20.h),

                        // Upload Images (area-level)
                        _sheetLabel('Upload Images (optional)'),
                        _uploadRow(onTap: pickImages),
                        SizedBox(height: 10.h),
                        _thumbsRow(seatImages),
                        SizedBox(height: 16.h),

                        // Notes (area-level)
                        _sheetLabel('Notes / Findings (optional)'),
                        _uncleanedField(ctrl: notesCtrl, tags: tags),
                        SizedBox(height: 20.h),
                      ],
                    ),
                  ),
                ),

                // Cancel / Apply buttons
                Container(
                  padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
                  decoration: BoxDecoration(
                    color: _C.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Get.back(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _C.primary,
                            side: BorderSide(color: _C.primary, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25.r),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.dmSans(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            for (final item in checkItems) {
                              _ctrl.setCheckItem(
                                id,
                                item,
                                itemStatuses[item]!.value,
                              );
                            }
                            Get.back();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _C.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25.r),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            elevation: 0,
                          ),
                          child: Text(
                            'Apply',
                            style: GoogleFonts.dmSans(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
    );
  }

  // ── Check Item Row  ← FIXED: image + hashtag show on pass OR fail ──
  Widget _buildCheckItemRow({
    required String seatId,
    required String itemName,
    required String status,
    required CabinAudit ctrl,
    required VoidCallback onPass,
    required VoidCallback onFail,
    required VoidCallback onNA,
  }) {
    final key = '$seatId|$itemName';
    // Show upload + hashtag when pass or fail (not N/A)
    final hasDetails = status == 'pass' || status == 'fail';

    final imagesList = ctrl.checkItemImages.putIfAbsent(
      key,
      () => <File>[].obs,
    );
    final tagsList = ctrl.checkItemTags.putIfAbsent(key, () => <String>[].obs);

    final picker = ImagePicker();

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: _C.bg,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: status == 'pass'
              ? _C.green.withValues(alpha: 0.4)
              : status == 'fail'
              ? _C.red.withValues(alpha: 0.4)
              : _C.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  itemName,
                  style: GoogleFonts.dmSans(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: _C.dark,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              _miniStatusBtn('P', status == 'pass', _C.green, onPass),
              SizedBox(width: 6.w),
              _miniStatusBtn('F', status == 'fail', _C.red, onFail),
              SizedBox(width: 6.w),
              _miniStatusBtn('N/A', status == 'na', _C.grey, onNA),
            ],
          ),

          // ── Image upload + hashtag per check item ──
          if (hasDetails) ...[
            SizedBox(height: 12.h),
            _sheetLabel('Upload image for "$itemName":'),
            _uploadRow(
              onTap: () async {
                final picked = await picker.pickMultiImage();
                if (picked.isNotEmpty) {
                  imagesList.addAll(picked.map((x) => File(x.path)));
                }
              },
            ),
            SizedBox(height: 10.h),
            _thumbsRow(imagesList),
            SizedBox(height: 10.h),
            _sheetLabel('Select Hashtags:'),
            _itemHashtagField(tags: tagsList),
          ],
        ],
      ),
    );
  }

  Widget _itemHashtagField({required RxList<String> tags}) {
    return Container(
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: _C.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(
            () => tags.isEmpty
                ? const SizedBox.shrink()
                : Container(
                    padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 4.h),
                    child: Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: tags.map((tag) {
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: _C.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: _C.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                tag,
                                style: GoogleFonts.dmSans(
                                  fontSize: 12.sp,
                                  color: _C.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 4.w),
                              GestureDetector(
                                onTap: () => tags.remove(tag),
                                child: Icon(
                                  Icons.close,
                                  size: 14.sp,
                                  color: _C.primary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: tags.isEmpty
                  ? BorderRadius.circular(20.r)
                  : BorderRadius.vertical(bottom: Radius.circular(20.r)),
              onTap: () => _showPredefinedTagsModal(tags),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                child: Row(
                  children: [
                    Icon(Icons.tag_rounded, size: 20.sp, color: _C.grey),
                    SizedBox(width: 8.w),
                    Text(
                      'Select Hashtags',
                      style: GoogleFonts.dmSans(
                        fontSize: 14.sp,
                        color: _C.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPredefinedTagsModal(RxList<String> tags) {
    final predefinedTags = [
      '#Dirty',
      '#Broken',
      '#Missing',
      '#Stained',
      '#Replaced',
      '#Scratched',
      '#Malfunctioning',
      '#Torn',
      '#Wet',
      '#NeedsCleaning',
    ];

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Hashtags',
              style: GoogleFonts.dmSans(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: _C.primary,
              ),
            ),
            SizedBox(height: 16.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: predefinedTags.map((tag) {
                return Obx(() {
                  final isSelected = tags.contains(tag);
                  return GestureDetector(
                    onTap: () {
                      if (isSelected) {
                        tags.remove(tag);
                      } else {
                        tags.add(tag);
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? _C.primary : _C.bg,
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: isSelected ? _C.primary : _C.border,
                        ),
                      ),
                      child: Text(
                        tag,
                        style: GoogleFonts.dmSans(
                          fontSize: 13.sp,
                          color: isSelected ? Colors.white : _C.dark,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                });
              }).toList(),
            ),
            SizedBox(height: 12.h),
          ],
        ),
      ),
    );
  }

  Widget _miniStatusBtn(
    String label,
    bool selected,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: selected ? color : _C.border, width: 1.5),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 11.sp,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : _C.grey,
          ),
        ),
      ),
    );
  }

  // ── Upload button ────────────────────────────
  Widget _uploadRow({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50.h,
        decoration: BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.circular(25.r),
          border: Border.all(color: _C.border, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_upload_outlined, size: 20.sp, color: _C.grey),
            SizedBox(width: 8.w),
            Text(
              'Upload an image',
              style: GoogleFonts.dmSans(fontSize: 14.sp, color: _C.grey),
            ),
          ],
        ),
      ),
    );
  }

  // ── Thumbnails horizontal row ────────────────
  Widget _thumbsRow(RxList<File> imgs) {
    return Obx(
      () => imgs.isEmpty
          ? const SizedBox.shrink()
          : SizedBox(
              height: 76.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: imgs.length,
                itemBuilder: (_, i) => Stack(
                  children: [
                    Container(
                      width: 68.w,
                      height: 68.h,
                      margin: EdgeInsets.only(right: 8.w),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: _C.border, width: 1),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.r),
                        child: Image.file(imgs[i], fit: BoxFit.cover),
                      ),
                    ),
                    Positioned(
                      top: 2,
                      right: 10,
                      child: GestureDetector(
                        onTap: () => imgs.removeAt(i),
                        child: Container(
                          padding: EdgeInsets.all(2.r),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 13.sp,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Notes field with hashtag chips ──────────
  Widget _uncleanedField({
    required TextEditingController ctrl,
    required RxList<String> tags,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: _C.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(
            () => tags.isEmpty
                ? const SizedBox.shrink()
                : Container(
                    padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 4.h),
                    child: Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: tags.map((tag) {
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: _C.primary,
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                tag,
                                style: GoogleFonts.dmSans(
                                  fontSize: 12.sp,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(width: 6.w),
                              GestureDetector(
                                onTap: () => tags.remove(tag),
                                child: Icon(
                                  Icons.close,
                                  size: 13.sp,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ),
          TextField(
            controller: ctrl,
            maxLines: 4,
            style: GoogleFonts.dmSans(fontSize: 14.sp, color: _C.dark),
            decoration: InputDecoration(
              hintText: 'Enter any additional findings or notes...',
              hintStyle: GoogleFonts.dmSans(fontSize: 14.sp, color: _C.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(14.w),
            ),
            onChanged: (text) {
              if (text.endsWith(' ') && text.trim().startsWith('#')) {
                final words = text.trim().split(' ');
                final last = words.last;
                if (last.startsWith('#') && last.length > 1) {
                  tags.add(last);
                  ctrl.text = text.replaceAll(last, '').trim();
                  ctrl.selection = TextSelection.fromPosition(
                    TextPosition(offset: ctrl.text.length),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  // ── Sheet label ──────────────────────────────
  Widget _sheetLabel(String text, {bool required = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: RichText(
        text: TextSpan(
          text: text,
          style: GoogleFonts.dmSans(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: _C.primary,
          ),
          children: required
              ? [
                  TextSpan(
                    text: ' *',
                    style: TextStyle(color: _C.red),
                  ),
                ]
              : [],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // SHARED HELPERS
  // ─────────────────────────────────────────────
  Widget _label(String t) => Padding(
    padding: EdgeInsets.only(bottom: 8.h),
    child: Text(
      t,
      style: GoogleFonts.dmSans(
        fontSize: 12.sp,
        fontWeight: FontWeight.w600,
        color: _C.primary,
      ),
    ),
  );

  TextStyle _fieldStyle() =>
      GoogleFonts.dmSans(fontSize: 15.sp, color: _C.dark);

  Widget _pillField({required Widget child}) => Container(
    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
    decoration: BoxDecoration(
      color: _C.white,
      borderRadius: BorderRadius.circular(30.r),
      border: Border.all(color: _C.border),
    ),
    child: child,
  );

  Widget _pillTextField({
    required TextEditingController controller,
    required String hint,
  }) => TextField(
    controller: controller,
    style: _fieldStyle(),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.dmSans(fontSize: 15.sp, color: _C.grey),
      filled: true,
      fillColor: _C.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30.r),
        borderSide: BorderSide(color: _C.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30.r),
        borderSide: BorderSide(color: _C.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30.r),
        borderSide: BorderSide(color: _C.primary, width: 1.5),
      ),
    ),
  );

  Widget _pillDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    IconData? suffixIcon,
  }) => LayoutBuilder(
    builder: (context, constraints) {
      return PopupMenuButton<String>(
        onSelected: onChanged,
        offset: Offset(0, 58.h),
        constraints: BoxConstraints(
          minWidth: constraints.maxWidth,
          maxWidth: constraints.maxWidth,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        itemBuilder: (context) => items
            .map(
              (i) => PopupMenuItem(
                value: i,
                height: 40.h,
                child: Text(i, style: _fieldStyle()),
              ),
            )
            .toList(),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: _C.white,
            borderRadius: BorderRadius.circular(30.r),
            border: Border.all(color: _C.border),
          ),
          child: Row(
            children: [
              Expanded(child: Text(value, style: _fieldStyle())),
              Icon(
                suffixIcon ?? Icons.keyboard_arrow_down_rounded,
                color: _C.grey,
                size: 20.sp,
              ),
            ],
          ),
        ),
      );
    },
  );

  Widget _multilineField(String hint, {TextEditingController? controller}) =>
      TextField(
        controller: controller,
        maxLines: 4,
        style: _fieldStyle(),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.dmSans(fontSize: 14.sp, color: _C.grey),
          filled: true,
          fillColor: _C.white,
          contentPadding: EdgeInsets.all(16.w),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide(color: _C.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide(color: _C.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide(color: _C.primary, width: 1.5),
          ),
        ),
      );

  Widget _uploadBox() => GestureDetector(
    onTap: _pickImages,
    child: Container(
      height: 52.h,
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: _C.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_upload_outlined, size: 20.sp, color: _C.grey),
          SizedBox(width: 8.w),
          Text(
            'Upload images',
            style: GoogleFonts.dmSans(fontSize: 14.sp, color: _C.grey),
          ),
        ],
      ),
    ),
  );

  Future<List<String>> _uploadFiles(List<File> files) async {
    final fileIds = <String>[];
    for (final file in files) {
      final uploaded = await _api.uploadFile(file, category: 'IMAGE');
      final fileId = uploaded['id'] as String?;
      if (fileId != null && fileId.isNotEmpty) {
        fileIds.add(fileId);
      }
    }
    return fileIds;
  }

  Future<String> _uploadSignature() async {
    final bytes = await signatureController.toPngBytes();
    if (bytes == null || bytes.isEmpty) {
      throw const ApiException('A signature is required before submission.');
    }

    final tempDir = await getTemporaryDirectory();
    final file = File(
      '${tempDir.path}/cabin-quality-signature-${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(bytes, flush: true);

    final uploaded = await _api.uploadFile(file, category: 'SIGNATURE');
    final fileId = uploaded['id'] as String?;
    if (fileId == null || fileId.isEmpty) {
      throw const ApiException('Unable to upload the signature.');
    }

    return fileId;
  }

  String _normalizeLabel(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }

  String _responseFromStatuses(Iterable<String> statuses) {
    final normalized = statuses
        .map((status) => status.trim().toLowerCase())
        .where((status) => status.isNotEmpty && status != 'na')
        .toList();

    if (normalized.any((status) => status == 'fail')) {
      return 'NO';
    }
    if (normalized.any((status) => status == 'pass')) {
      return 'YES';
    }
    return 'NA';
  }

  bool _seatMatchesLabel(String seatId, String checklistLabel) {
    final normalizedSeat = seatId.toLowerCase();
    final section = _ctrl.getSectionForSeat(seatId);

    switch (_normalizeLabel(checklistLabel)) {
      case 'firstclass':
        return section == 'first_class';
      case 'frontgalley':
        return normalizedSeat.contains('galley fwd');
      case 'backgalley':
        return normalizedSeat.contains('galley aft') ||
            (normalizedSeat.contains('galley') &&
                !normalizedSeat.contains('fwd'));
      case 'frontlavs':
        return normalizedSeat.contains('lav fwd');
      case 'midlavs':
        return normalizedSeat.contains('lav mid');
      case 'aftlavs':
        return normalizedSeat.contains('lav aft') ||
            normalizedSeat == 'lav l' ||
            normalizedSeat == 'lav r';
      default:
        return false;
    }
  }

  bool _itemMatchesLabel(String itemName, String checklistLabel) {
    final normalizedItem = _normalizeLabel(itemName);
    switch (_normalizeLabel(checklistLabel)) {
      case 'floorcarpets':
        return normalizedItem.contains('floor');
      case 'seatbacktrash':
        return normalizedItem == 'seatbacktrash' ||
            normalizedItem == 'seatpocket';
      case 'traytables':
        return normalizedItem.contains('traytable');
      case 'ifescreens':
        return normalizedItem.contains('ifescreen') ||
            normalizedItem.contains('ifeunit');
      default:
        return false;
    }
  }

  Future<Map<String, List<String>>> _uploadCheckItemImageIds() async {
    final uploadedByKey = <String, List<String>>{};

    for (final entry in _ctrl.checkItemImages.entries) {
      final files = entry.value.toList();
      uploadedByKey[entry.key] = files.isEmpty
          ? const []
          : await _uploadFiles(files);
    }

    return uploadedByKey;
  }

  Future<List<Map<String, dynamic>>> _buildChecklistResponses(
    Map<String, List<String>> uploadedImageIdsByKey,
  ) async {
    final responses = <Map<String, dynamic>>[];

    for (final entry in _checklistIdsByLabel.entries) {
      final checklistLabel = entry.key;
      final matchedEntries = _ctrl.checkItemStatuses.entries.where((
        statusEntry,
      ) {
        final separatorIndex = statusEntry.key.indexOf('|');
        if (separatorIndex < 0) {
          return false;
        }

        final seatId = statusEntry.key.substring(0, separatorIndex);
        final itemName = statusEntry.key.substring(separatorIndex + 1);

        return _seatMatchesLabel(seatId, checklistLabel) ||
            _itemMatchesLabel(itemName, checklistLabel);
      }).toList();

      final imageFileIds = <String>[];
      for (final matched in matchedEntries) {
        imageFileIds.addAll(uploadedImageIdsByKey[matched.key] ?? const []);
      }

      responses.add({
        'checklistItemId': entry.value,
        'response': _responseFromStatuses(
          matchedEntries.map((matched) => matched.value),
        ),
        'imageFileIds': imageFileIds,
      });
    }

    return responses;
  }

  List<Map<String, dynamic>> _buildDetailedAreaResults(
    Map<String, List<String>> uploadedImageIdsByKey,
  ) {
    final areaIds = _ctrl.auditedSeats.keys.toList()..sort();
    final areaResults = <Map<String, dynamic>>[];

    for (final areaId in areaIds) {
      final checkItems = _ctrl.getCheckItemsForSeat(areaId);
      final detailedItems = <Map<String, dynamic>>[];

      for (final itemName in checkItems) {
        final key = '$areaId|$itemName';
        final status = _ctrl.getCheckItem(areaId, itemName);

        detailedItems.add({
          'itemName': itemName,
          'status': status,
          'imageFileIds': uploadedImageIdsByKey[key] ?? const <String>[],
          'hashtags': (_ctrl.checkItemTags[key] ?? <String>[].obs)
              .map((tag) => tag.trim())
              .where((tag) => tag.isNotEmpty)
              .toList(),
        });
      }

      areaResults.add({
        'areaId': areaId,
        'sectionLabel': _ctrl.getSectionLabel(areaId),
        'checkItems': detailedItems,
      });
    }

    return areaResults;
  }

  String _buildAdditionalNotes() {
    final notes = _additionalNotesCtrl.text.trim();

    final adhocAreas = _ctrl.auditedSeats.keys
        .where((id) => !_ctrl.mandatoryAreas.contains(id))
        .toList();

    final metadata = <String>[
      if (_ctrl.selectedAircraft.value.trim().isNotEmpty)
        'Aircraft: ${_ctrl.selectedAircraft.value.trim()}',
      if (_supervisorCtrl.text.trim().isNotEmpty)
        'Supervisor/Lead: ${_supervisorCtrl.text.trim()}',
      if (adhocAreas.isNotEmpty)
        'Ad-hoc Audited Areas (Extra Observations): ${adhocAreas.join(", ")}',
    ].join('\n');

    final combined = [
      if (notes.isNotEmpty) notes,
      if (metadata.isNotEmpty) metadata,
    ].join('\n\n');

    return combined;
  }

  Future<void> _submitReport() async {
    if (_isSubmitting) {
      return;
    }

    final gateId = _gateIdsByLabel[_ctrl.selectedGate.value];
    final cleanTypeId = _cleanTypeIdsByLabel[_ctrl.selectedCleanType.value];
    if (gateId == null || gateId.isEmpty) {
      Get.snackbar(
        'Incomplete',
        'Please select a valid gate before submitting.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    if (cleanTypeId == null || cleanTypeId.isEmpty) {
      Get.snackbar(
        'Incomplete',
        'Please select a clean type before submitting.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final signatureFileId = await _uploadSignature();
      final generalPictureFileIds = await _uploadFiles(
        _selectedImages.toList(),
      );
      final uploadedImageIdsByKey = await _uploadCheckItemImageIds();
      final responses = await _buildChecklistResponses(uploadedImageIdsByKey);
      final areaResults = _buildDetailedAreaResults(uploadedImageIdsByKey);

      await _api.createCabinQualityAudit({
        'gateId': gateId,
        'cleanTypeId': cleanTypeId,
        'responses': responses,
        'areaResults': areaResults,
        'signatureFileId': signatureFileId,
        'otherFindings': _otherFindingsCtrl.text.trim(),
        'additionalNotes': _buildAdditionalNotes(),
        'generalPictureFileIds': generalPictureFileIds,
      });

      if (Get.isRegistered<CabinQualityAuditListController>()) {
        await Get.find<CabinQualityAuditListController>().loadAudits();
      }

      if (!mounted) {
        return;
      }

      Get.snackbar(
        'Success',
        'Audit report submitted!',
        backgroundColor: _C.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      Get.off(() => const CabinQualityAuditListScreen());
    } on ApiException catch (error) {
      Get.snackbar(
        'Submission Failed',
        error.message,
        backgroundColor: _C.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } catch (_) {
      Get.snackbar(
        'Submission Failed',
        'Unable to submit the cabin quality audit right now.',
        backgroundColor: _C.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _nextButton(VoidCallback onTap) => Container(
    color: _C.white,
    padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52.h,
        decoration: BoxDecoration(
          color: _C.primary,
          borderRadius: BorderRadius.circular(30.r),
        ),
        alignment: Alignment.center,
        child: Text(
          'NEXT',
          style: GoogleFonts.dmSans(
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
      ),
    ),
  );

  Widget _submitButton() => Container(
    color: _C.white,
    padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
    child: GestureDetector(
      onTap: _isSubmitting ? null : _submitReport,
      child: Container(
        height: 52.h,
        decoration: BoxDecoration(
          color: _isSubmitting ? _C.border : _C.primary,
          borderRadius: BorderRadius.circular(30.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isSubmitting) ...[
              SizedBox(
                width: 18.w,
                height: 18.h,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 10.w),
            ] else ...[
              Icon(Icons.send_rounded, color: Colors.white, size: 18.sp),
              SizedBox(width: 10.w),
            ],
            Text(
              _isSubmitting ? 'SUBMITTING...' : 'SEND AUDIT REPORT',
              style: GoogleFonts.dmSans(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  void _showInstructions() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: _C.primary, size: 24.sp),
            SizedBox(width: 8.w),
            Text(
              'Instructions',
              style: GoogleFonts.dmSans(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          'Tap any seat or area to audit it. '
          'Mark each sub-item as Pass, Fail, or N/A. '
          'If any sub-item fails, the area is automatically marked Fail. '
          'Items not audited are N/A by default.',
          style: GoogleFonts.dmSans(
            fontSize: 13.sp,
            color: _C.grey,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Got it',
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w600,
                color: _C.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// PAINTERS
// ─────────────────────────────────────────────
class _SeatPainter extends CustomPainter {
  final Color color;
  final bool isMandatory;
  const _SeatPainter({required this.color, this.isMandatory = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w, h * 0.58),
        const Radius.circular(5),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-1, h * 0.55, w + 2, h * 0.38),
        const Radius.circular(4),
      ),
      paint,
    );

    final armPaint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-3, h * 0.25, 4, h * 0.45),
        const Radius.circular(2),
      ),
      armPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w - 1, h * 0.25, 4, h * 0.45),
        const Radius.circular(2),
      ),
      armPaint,
    );

    if (isMandatory && color == _C.seatColor) {
      final borderPaint = Paint()
        ..color = Colors.orange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-1, -1, w + 2, h * 0.95 + 2),
          const Radius.circular(5),
        ),
        borderPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SeatPainter old) => old.color != color;
}

// ignore: unused_element
class _PlaneSilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {}

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
