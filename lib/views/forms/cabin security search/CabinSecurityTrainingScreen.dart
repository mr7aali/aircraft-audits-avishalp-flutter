import 'package:avislap/utils/app_colors.dart';
import 'package:avislap/views/forms/cabin%20security%20search/cabin_secuirity.dart';
import 'package:avislap/views/forms/cabin%20security%20search/training_filter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

// =====================
// COLORS
// =====================
class _Colors {
  static const Color primary = Color(0xFF3D5AFE);
  static const Color background = Color(0xFFF5F6FA);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1A1A2E);
  static const Color textGrey = Color(0xFF9E9E9E);
  static const Color dotColor = Color(0xFF9E9E9E);
  static const Color namePrimary = Color(0xFF3D5AFE);
  static const Color divider = Color(0xFFEEEEEE);
  // Doc: PASS = Green, FAIL = Red
  static const Color pass = Color(0xFF22C55E);
  static const Color fail = Color(0xFFEF4444);
  static const Color newAuditBtn = Color(0xFF3D5AFE);
}

// =====================
// MODEL
// =====================
class TrainingItem {
  final String id;
  final String observerName;
  final String observerImage;
  final String date;
  final String time;
  final DateTime dateTime;
  final String gate;
  final String shipNumber;
  final String role;
  final String locationImage;
  final String locationImage2;
  final bool isPassed;
  final List<CabinSecurityAreaResult> areaResults;
  final String otherFindings;
  final String additionalNotes;

  // ── Extra detail fields from cabin_secuirity.dart ──────
  final String aircraft;
  final String supervisorName;
  final String supervisorRole;
  final List<String> selectedAreas;

  TrainingItem({
    required this.id,
    required this.observerName,
    required this.observerImage,
    required this.date,
    required this.time,
    required this.dateTime,
    required this.gate,
    this.shipNumber = '',
    this.role = '',
    required this.locationImage,
    required this.locationImage2,
    required this.isPassed,
    this.areaResults = const [],
    this.otherFindings = '',
    this.additionalNotes = '',
    this.aircraft = '',
    this.supervisorName = '',
    this.supervisorRole = '',
    this.selectedAreas = const [],
  });

  int get passAreaCount => areaResults.where((r) => r.status == 'pass').length;
  int get failAreaCount => areaResults.where((r) => r.status == 'fail').length;

  double get scorePercent {
    if (areaResults.isEmpty) return 0;
    return (passAreaCount / areaResults.length) * 100;
  }
}

// =====================
// CONTROLLER
// =====================
class CabinSecurityController extends GetxController {
  final RxList<TrainingItem> _allTrainings = <TrainingItem>[].obs;
  final RxList<TrainingItem> filteredTrainings = <TrainingItem>[].obs;
  final RxInt expandedAreaIndex = (-1).obs;

  void toggleArea(int index) {
    if (expandedAreaIndex.value == index) {
      expandedAreaIndex.value = -1;
    } else {
      expandedAreaIndex.value = index;
    }
  }

  final RxString filterName = ''.obs;
  final RxString filterFromDate = ''.obs;
  final RxString filterToDate = ''.obs;
  // Doc: Pass/Fail multi-checkbox — both, one, or neither can be selected
  final RxSet<String> filterResults = <String>{}.obs; // values: 'pass', 'fail'

  bool get hasActiveFilter =>
      filterName.isNotEmpty ||
      filterFromDate.isNotEmpty ||
      filterToDate.isNotEmpty ||
      filterResults.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    _allTrainings.assignAll([
      TrainingItem(
        id: '4',
        observerName: 'Guy Hawkins',
        observerImage: 'assets/images/nirob.jpg',
        date: 'Dec 16, 2024',
        time: '11:30 AM',
        dateTime: DateTime(2024, 12, 16, 11, 30),
        gate: 'Gate A-03',
        shipNumber: 'N123DL',
        role: 'Supervisor',
        aircraft: 'Boeing 757-300 (75Y)',
        supervisorName: 'Guy Hawkins',
        supervisorRole: 'Supervisor',
        selectedAreas: ['Front Galley', 'FWD LAV', 'Overhead Bins'],
        locationImage: 'assets/images/indor.png',
        locationImage2: 'assets/images/window.png',
        isPassed: true,
        areaResults: [
          CabinSecurityAreaResult(
            area: 'Front Galley',
            status: 'pass',
            pictures: ['assets/images/indor.png', 'assets/images/window.png'],
            subItems: [
              CabinSecuritySubItem(name: 'Counter / Surface', status: 'pass'),
              CabinSecuritySubItem(
                name: 'Storage Compartments',
                status: 'pass',
              ),
              CabinSecuritySubItem(name: 'Oven / Microwave', status: 'pass'),
              CabinSecuritySubItem(name: 'Coffee Maker', status: 'pass'),
              CabinSecuritySubItem(name: 'Trash', status: 'pass'),
              CabinSecuritySubItem(name: 'Floor', status: 'pass'),
            ],
          ),
          CabinSecurityAreaResult(
            area: 'FWD LAV',
            status: 'pass',
            subItems: [
              CabinSecuritySubItem(name: 'Trash Bin', status: 'pass'),
              CabinSecuritySubItem(name: 'Under Sink', status: 'pass'),
              CabinSecuritySubItem(name: 'Mirror / Cabinet', status: 'pass'),
              CabinSecuritySubItem(name: 'Toilet Area', status: 'pass'),
              CabinSecuritySubItem(name: 'Floor', status: 'pass'),
              CabinSecuritySubItem(name: 'Counter', status: 'pass'),
            ],
          ),
          CabinSecurityAreaResult(
            area: 'Overhead Bins',
            status: 'pass',
            subItems: [
              CabinSecuritySubItem(name: 'Bin Row 1–6', status: 'pass'),
              CabinSecuritySubItem(name: 'Bin Row 7–14', status: 'pass'),
            ],
          ),
        ],
        otherFindings: '',
        additionalNotes: 'All agents performed well.',
      ),
      TrainingItem(
        id: '3',
        observerName: 'Theresa Webb',
        observerImage: 'assets/images/nirob.jpg',
        date: 'Dec 15, 2024',
        time: '4:15 PM',
        dateTime: DateTime(2024, 12, 15, 16, 15),
        gate: 'Gate C-07',
        shipNumber: 'N456AA',
        role: 'Duty Manager',
        aircraft: 'Boeing 737-800',
        supervisorName: 'Theresa Webb',
        supervisorRole: 'Duty Manager',
        selectedAreas: ['Main Cabin', 'Rear Galley'],
        locationImage: 'assets/images/indor.png',
        locationImage2: 'assets/images/window.png',
        isPassed: true,
        areaResults: [
          CabinSecurityAreaResult(
            area: 'Main Cabin',
            status: 'pass',
            subItems: [
              CabinSecuritySubItem(name: 'Seat Cushion', status: 'pass'),
              CabinSecuritySubItem(name: 'Seat Back Pocket', status: 'pass'),
              CabinSecuritySubItem(name: 'Overhead Bin', status: 'pass'),
              CabinSecuritySubItem(name: 'Tray Table', status: 'pass'),
              CabinSecuritySubItem(name: 'Under Seat', status: 'pass'),
              CabinSecuritySubItem(name: 'Floor / Carpet', status: 'pass'),
            ],
          ),
          CabinSecurityAreaResult(
            area: 'Rear Galley',
            status: 'pass',
            subItems: [
              CabinSecuritySubItem(name: 'Counter / Surface', status: 'pass'),
              CabinSecuritySubItem(
                name: 'Storage Compartments',
                status: 'pass',
              ),
              CabinSecuritySubItem(name: 'Oven / Microwave', status: 'pass'),
              CabinSecuritySubItem(name: 'Trash', status: 'pass'),
              CabinSecuritySubItem(name: 'Floor', status: 'pass'),
            ],
          ),
        ],
      ),
      TrainingItem(
        id: '2',
        observerName: 'Kristin Watson',
        observerImage: 'assets/images/mursalin.jpg',
        date: 'Dec 15, 2024',
        time: '9:00 AM',
        dateTime: DateTime(2024, 12, 15, 9, 0),
        gate: 'Gate B-04',
        shipNumber: 'N789UA',
        role: 'Supervisor',
        aircraft: 'Airbus A320',
        supervisorName: 'Kristin Watson',
        supervisorRole: 'Supervisor',
        selectedAreas: ['Seat Pockets', 'AFT LAV L', 'Main Cabin'],
        locationImage: 'assets/images/indor.png',
        locationImage2: 'assets/images/window.png',
        isPassed: false,
        areaResults: [
          CabinSecurityAreaResult(
            area: 'Seat Pockets',
            status: 'fail',
            subItems: [
              CabinSecuritySubItem(name: 'Row 1–10 Pockets', status: 'pass'),
              CabinSecuritySubItem(name: 'Row 11–20 Pockets', status: 'fail'),
            ],
          ),
          CabinSecurityAreaResult(
            area: 'AFT LAV L',
            status: 'fail',
            subItems: [
              CabinSecuritySubItem(name: 'Trash Bin', status: 'pass'),
              CabinSecuritySubItem(name: 'Under Sink', status: 'fail'),
              CabinSecuritySubItem(name: 'Mirror / Cabinet', status: 'pass'),
              CabinSecuritySubItem(name: 'Toilet Area', status: 'pass'),
            ],
          ),
          CabinSecurityAreaResult(
            area: 'Main Cabin',
            status: 'pass',
            subItems: [
              CabinSecuritySubItem(name: 'Seat Cushion', status: 'pass'),
              CabinSecuritySubItem(name: 'Tray Table', status: 'pass'),
            ],
          ),
        ],
        otherFindings: 'Test object not found under seat 22B.',
        additionalNotes: 'Retraining scheduled for next shift.',
      ),
      TrainingItem(
        id: '1',
        observerName: 'Jane Cooper',
        observerImage: 'assets/images/nirob.jpg',
        date: 'Dec 14, 2024',
        time: '2:30 PM',
        dateTime: DateTime(2024, 12, 14, 14, 30),
        gate: 'Gate A-12',
        shipNumber: 'N321DL',
        role: 'General Manager',
        aircraft: 'Boeing 757-300 (75Y)',
        supervisorName: 'Jane Cooper',
        supervisorRole: 'General Manager',
        selectedAreas: ['Overhead Bins', 'Front Galley'],
        locationImage: 'assets/images/indor.png',
        locationImage2: 'assets/images/window.png',
        isPassed: false,
        areaResults: [
          CabinSecurityAreaResult(
            area: 'Overhead Bins',
            status: 'fail',
            subItems: [
              CabinSecuritySubItem(name: 'Bin Row 1-6', status: 'pass'),
              CabinSecuritySubItem(name: 'Bin Row 7-14', status: 'fail'),
            ],
          ),
          CabinSecurityAreaResult(
            area: 'Front Galley',
            status: 'pass',
            subItems: [
              CabinSecuritySubItem(name: 'Counter / Surface', status: 'pass'),
              CabinSecuritySubItem(name: 'Trash', status: 'pass'),
            ],
          ),
        ],
        otherFindings: 'Overhead bin in row 14 missed.',
      ),
    ]);
    _applyFilter();
  }

  void applyFilter({
    required String name,
    required String fromDate,
    required String toDate,
    required Set<String> results,
  }) {
    filterName.value = name;
    filterFromDate.value = fromDate;
    filterToDate.value = toDate;
    filterResults.assignAll(results);
    _applyFilter();
  }

  void clearFilter() {
    filterName.value = '';
    filterFromDate.value = '';
    filterToDate.value = '';
    filterResults.clear();
    _applyFilter();
  }

  void _applyFilter() {
    var list = List<TrainingItem>.from(_allTrainings);

    // Auditor name filter — dynamic search
    if (filterName.isNotEmpty) {
      list = list
          .where(
            (t) => t.observerName.toLowerCase().contains(
              filterName.value.toLowerCase(),
            ),
          )
          .toList();
    }

    // Doc: Date range filter — From/To. "From" cannot be after "To".
    if (filterFromDate.isNotEmpty || filterToDate.isNotEmpty) {
      DateTime? from;
      DateTime? to;
      try {
        if (filterFromDate.isNotEmpty) {
          from = _parseFilterDate(filterFromDate.value);
        }
        if (filterToDate.isNotEmpty) {
          // Include the full "To" day (up to end of day)
          final d = _parseFilterDate(filterToDate.value);
          to = DateTime(d.year, d.month, d.day, 23, 59, 59);
        }
      } catch (_) {}

      if (from != null || to != null) {
        list = list.where((t) {
          if (from != null && t.dateTime.isBefore(from)) return false;
          if (to != null && t.dateTime.isAfter(to)) return false;
          return true;
        }).toList();
      }
    }

    // Doc: Pass/Fail multi-checkbox.
    // Selecting both (or neither) shows all records.
    // Selecting only "Pass" shows passed; only "Fail" shows failed.
    if (filterResults.length == 1) {
      final onlyPass = filterResults.contains('pass');
      list = list.where((t) => onlyPass ? t.isPassed : !t.isPassed).toList();
    }

    // Doc: "Displays records in descending chronological order (Newest first)"
    list.sort((a, b) => b.dateTime.compareTo(a.dateTime));

    filteredTrainings.assignAll(list);
  }

  /// Parses date strings in the formats used by the filter sheet (mm/dd/yyyy).
  DateTime _parseFilterDate(String value) {
    final parts = value.split('/');
    if (parts.length == 3) {
      final month = int.parse(parts[0]);
      final day = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      return DateTime(year, month, day);
    }
    throw FormatException('Invalid date format: $value');
  }
}

// =====================
// SCREEN
// =====================
class CabinSecurityScreen extends StatefulWidget {
  const CabinSecurityScreen({super.key});

  @override
  State<CabinSecurityScreen> createState() => _CabinSecurityScreenState();
}

class _CabinSecurityScreenState extends State<CabinSecurityScreen> {
  late final CabinSecurityController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(CabinSecurityController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Colors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(),
                    SizedBox(height: 12.h),
                    _buildTrainingList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── App Bar ─────────────────────────────────────────────
  Widget _buildAppBar() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Icon(Icons.arrow_back, color: _Colors.primary, size: 22.sp),
          ),
          Expanded(
            child: Text(
              'Cabin Security Search Training',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: _Colors.primary,
                height: 1.3,
              ),
            ),
          ),
          // Filter icon — active dot when filter applied
          Obx(() {
            final active = controller.hasActiveFilter;
            return Stack(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.tune_rounded,
                    color: AppColors.mainAppColor,
                    size: 24.sp,
                  ),
                  onPressed: _showFilterSheet,
                ),
                if (active)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 8.w,
                      height: 8.h,
                      decoration: const BoxDecoration(
                        color: _Colors.fail,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ── Section Header ───────────────────────────────────────
  Widget _buildSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // "Past Trainings" heading
        Row(
          children: [
            Container(
              width: 4.w,
              height: 22.h,
              decoration: BoxDecoration(
                color: _Colors.primary,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(width: 10.w),
            Text(
              'Past Trainings',
              style: GoogleFonts.poppins(
                fontSize: 17.sp,
                fontWeight: FontWeight.w700,
                color: _Colors.textDark,
              ),
            ),
          ],
        ),

        // Doc: "+ Conduct New Search" button
        GestureDetector(
          onTap: () => Get.to(() => const CabinQualityAuditScreenN()),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: _Colors.newAuditBtn,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              '+ Conduct New Search',
              style: GoogleFonts.poppins(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Training List ────────────────────────────────────────
  Widget _buildTrainingList() {
    return Obx(() {
      final trainings = controller.filteredTrainings;

      if (trainings.isEmpty) {
        return Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 40.h),
            child: Column(
              children: [
                Icon(
                  Icons.search_off_rounded,
                  color: _Colors.textGrey,
                  size: 48.sp,
                ),
                SizedBox(height: 12.h),
                Text(
                  'No trainings found',
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    color: _Colors.textGrey,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: trainings.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: _Colors.divider),
        itemBuilder: (_, index) => _buildTrainingCard(trainings[index]),
      );
    });
  }

  // ── Training Card ────────────────────────────────────────
  Widget _buildTrainingCard(TrainingItem item) {
    return InkWell(
      // Doc: "Click on card opens record in view-only"
      onTap: () => _showViewOnlyDetail(item),
      child: Container(
        color: _Colors.cardBg,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar — border reflects pass/fail
            Stack(
              children: [
                Container(
                  padding: EdgeInsets.all(3.r),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: item.isPassed ? _Colors.pass : _Colors.fail,
                      width: 2.5.w,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 26.r,
                    backgroundImage: AssetImage(item.observerImage),
                    backgroundColor: Colors.grey.shade200,
                    onBackgroundImageError: (_, __) {},
                  ),
                ),
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    width: 13.w,
                    height: 13.h,
                    decoration: BoxDecoration(
                      color: item.isPassed ? _Colors.pass : _Colors.fail,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(width: 12.w),

            // Middle content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 4.h),

                  // Auditor Name
                  Text(
                    item.observerName,
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: _Colors.namePrimary,
                    ),
                  ),
                  SizedBox(height: 4.h),

                  // Training Date • Time
                  Row(
                    children: [
                      Text(
                        item.date,
                        style: GoogleFonts.poppins(
                          fontSize: 11.sp,
                          color: _Colors.textGrey,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        child: Container(
                          width: 3.w,
                          height: 3.h,
                          decoration: const BoxDecoration(
                            color: _Colors.dotColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Text(
                        item.time,
                        style: GoogleFonts.poppins(
                          fontSize: 11.sp,
                          color: _Colors.textGrey,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 5.h),

                  // Gate
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 12.sp,
                        color: _Colors.textGrey,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        item.gate,
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: _Colors.textDark,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),

                  // Doc: PASS = Green text, FAIL = Red text
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 3.h,
                    ),
                    decoration: BoxDecoration(
                      color: item.isPassed
                          ? _Colors.pass.withValues(alpha: 0.1)
                          : _Colors.fail.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6.r),
                      border: Border.all(
                        color: item.isPassed
                            ? _Colors.pass.withValues(alpha: 0.4)
                            : _Colors.fail.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      item.isPassed ? 'PASS' : 'FAIL',
                      style: GoogleFonts.poppins(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: item.isPassed ? _Colors.pass : _Colors.fail,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 10.w),

            // Doc: "Displays up to 2-3 thumbnails"
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildLocationImage(item.locationImage),
                SizedBox(height: 6.h),
                _buildLocationImage(item.locationImage2),
                SizedBox(height: 4.h),
                Icon(
                  Icons.chevron_right_rounded,
                  color: _Colors.textGrey,
                  size: 18.sp,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Location Image thumbnail ─────────────────────────────
  Widget _buildLocationImage(String imagePath) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.r),
      child: Image.asset(
        imagePath,
        width: 64.w,
        height: 56.h,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 64.w,
          height: 56.h,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(
            Icons.image_outlined,
            color: Colors.grey.shade400,
            size: 22.sp,
          ),
        ),
      ),
    );
  }

  // ── View-Only Detail Sheet ───────────────────────────────
  void _showViewOnlyDetail(TrainingItem item) {
    final scoreColor = item.isPassed ? _Colors.pass : _Colors.fail;

    Get.bottomSheet(
      DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollCtrl) => Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F6FA),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(
            children: [
              // ── Drag handle + top bar ─────────────────
              Container(
                color: Colors.white,
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 12.h, bottom: 8.h),
                      child: Center(
                        child: Container(
                          width: 40.w,
                          height: 4.h,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE4E7EF),
                            borderRadius: BorderRadius.circular(2.r),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 10.h,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.lock_outline_rounded,
                                  color: _Colors.primary,
                                  size: 12.sp,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  'View Only',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w600,
                                    color: _Colors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 14.w,
                              vertical: 5.h,
                            ),
                            decoration: BoxDecoration(
                              color: scoreColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color: scoreColor.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              item.isPassed ? 'PASS' : 'FAIL',
                              style: GoogleFonts.poppins(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: scoreColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  controller: scrollCtrl,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Score Card ───────────────────────
                      Container(
                        margin: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 4.h),
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: scoreColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: scoreColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 64.w,
                              height: 64.h,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: scoreColor,
                              ),
                              child: Center(
                                child: Text(
                                  '${item.scorePercent.toStringAsFixed(0)}%',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 14.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.isPassed
                                        ? 'Search Passed'
                                        : 'Search Failed',
                                    style: GoogleFonts.poppins(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w700,
                                      color: scoreColor,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    '${item.areaResults.length} areas inspected  •  ${item.failAreaCount} failed',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12.sp,
                                      color: _Colors.textGrey,
                                    ),
                                  ),
                                  if (!item.isPassed) ...[
                                    SizedBox(height: 3.h),
                                    Text(
                                      'Any failed area = search FAIL',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10.sp,
                                        color: _Colors.fail,
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
                      ),

                      // ── Info Card ────────────────────────
                      Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 4.h,
                        ),
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 4.w,
                                  height: 22.h,
                                  decoration: BoxDecoration(
                                    color: _Colors.primary,
                                    borderRadius: BorderRadius.circular(2.r),
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: Text(
                                    item.observerName,
                                    style: GoogleFonts.poppins(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w700,
                                      color: _Colors.namePrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 14.h),
                            _detailRow(
                              Icons.access_time_rounded,
                              '${item.date}  •  ${item.time}',
                              isGrey: true,
                            ),
                            SizedBox(height: 8.h),
                            if (item.role.isNotEmpty) ...[
                              _detailRow(Icons.badge_outlined, item.role),
                              SizedBox(height: 8.h),
                            ],
                            _detailRow(
                              Icons.location_on_outlined,
                              item.gate,
                              bold: true,
                            ),
                            SizedBox(height: 8.h),
                            if (item.shipNumber.isNotEmpty) ...[
                              _detailRow(
                                Icons.flight_rounded,
                                'Ship #  ${item.shipNumber}',
                              ),
                              SizedBox(height: 8.h),
                            ],
                            if (item.aircraft.isNotEmpty) ...[
                              _detailRow(
                                Icons.airplanemode_active_rounded,
                                item.aircraft,
                              ),
                              SizedBox(height: 8.h),
                            ],
                            if (item.supervisorName.isNotEmpty)
                              _detailRow(
                                Icons.person_outline_rounded,
                                '${item.supervisorName}  •  ${item.supervisorRole}',
                              ),
                          ],
                        ),
                      ),

                      // ── Inspection Checklist Card ─────────
                      if (item.areaResults.isNotEmpty) ...[
                        Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 14.h,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 4.w,
                                      height: 20.h,
                                      decoration: BoxDecoration(
                                        color: _Colors.primary,
                                        borderRadius: BorderRadius.circular(
                                          2.r,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 10.w),
                                    Text(
                                      'Inspection Checklist',
                                      style: GoogleFonts.poppins(
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.w700,
                                        color: _Colors.textDark,
                                      ),
                                    ),
                                    const Spacer(),
                                    _miniChip(
                                      '${item.passAreaCount} Pass',
                                      _Colors.pass,
                                    ),
                                    SizedBox(width: 6.w),
                                    _miniChip(
                                      '${item.failAreaCount} Fail',
                                      _Colors.fail,
                                    ),
                                  ],
                                ),
                              ),
                              Divider(
                                height: 1,
                                color: const Color(0xFFEEEEEE),
                              ),
                              ...List.generate(item.areaResults.length, (
                                index,
                              ) {
                                final area = item.areaResults[index];
                                return Obx(() {
                                  final isExpanded =
                                      controller.expandedAreaIndex.value ==
                                      index;
                                  return _buildViewOnlyAreaTile(
                                    area,
                                    index,
                                    isExpanded,
                                  );
                                });
                              }),
                              SizedBox(height: 4.h),
                            ],
                          ),
                        ),
                      ],

                      // ── Photos Card ──────────────────────
                      Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 4.h,
                        ),
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 4.w,
                                  height: 20.h,
                                  decoration: BoxDecoration(
                                    color: _Colors.primary,
                                    borderRadius: BorderRadius.circular(2.r),
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                Text(
                                  'Photos',
                                  style: GoogleFonts.poppins(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w700,
                                    color: _Colors.textDark,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12.h),
                            Row(
                              children: [
                                _buildLocationImage(item.locationImage),
                                SizedBox(width: 8.w),
                                _buildLocationImage(item.locationImage2),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // ── Other Findings Card ──────────────
                      if (item.otherFindings.isNotEmpty) ...[
                        Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 4.h,
                          ),
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 4.w,
                                    height: 20.h,
                                    decoration: BoxDecoration(
                                      color: _Colors.primary,
                                      borderRadius: BorderRadius.circular(2.r),
                                    ),
                                  ),
                                  SizedBox(width: 10.w),
                                  Text(
                                    'Other Findings',
                                    style: GoogleFonts.poppins(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w700,
                                      color: _Colors.textDark,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10.h),
                              Text(
                                item.otherFindings,
                                style: GoogleFonts.poppins(
                                  fontSize: 13.sp,
                                  color: _Colors.textGrey,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // ── Additional Notes Card ────────────
                      if (item.additionalNotes.isNotEmpty) ...[
                        Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 4.h,
                          ),
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 4.w,
                                    height: 20.h,
                                    decoration: BoxDecoration(
                                      color: _Colors.primary,
                                      borderRadius: BorderRadius.circular(2.r),
                                    ),
                                  ),
                                  SizedBox(width: 10.w),
                                  Text(
                                    'Additional Notes',
                                    style: GoogleFonts.poppins(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w700,
                                      color: _Colors.textDark,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10.h),
                              Text(
                                item.additionalNotes,
                                style: GoogleFonts.poppins(
                                  fontSize: 13.sp,
                                  color: _Colors.textGrey,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // ── View-only warning ────────────────
                      Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 4.h,
                        ),
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(
                            color: const Color(
                              0xFFFFCC02,
                            ).withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 16.sp,
                              color: const Color(0xFFF59E0B),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                'This record is view-only and cannot be modified after submission.',
                                style: GoogleFonts.poppins(
                                  fontSize: 11.sp,
                                  color: const Color(0xFF92400E),
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Close button ─────────────────────
                      Padding(
                        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 28.h),
                        child: SizedBox(
                          width: double.infinity,
                          height: 50.h,
                          child: ElevatedButton(
                            onPressed: () => Get.back(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _Colors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25.r),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Close',
                              style: GoogleFonts.poppins(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildViewOnlyAreaTile(
    CabinSecurityAreaResult area,
    int index,
    bool isExpanded,
  ) {
    final areaPass = area.status == 'pass';
    final areaColor = areaPass ? _Colors.pass : _Colors.fail;
    return Column(
      children: [
        InkWell(
          onTap: () => controller.toggleArea(index),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Row(
              children: [
                Container(
                  width: 38.w,
                  height: 38.h,
                  decoration: BoxDecoration(
                    color: areaColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    _areaIcon(area.area),
                    color: areaColor,
                    size: 18.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        area.area,
                        style: GoogleFonts.poppins(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: _Colors.textDark,
                        ),
                      ),
                      if (area.subItems.isNotEmpty)
                        Text(
                          '${area.passCount} Pass  ${area.failCount} Fail  ${area.naCount} N/A',
                          style: GoogleFonts.poppins(
                            fontSize: 11.sp,
                            color: _Colors.textGrey,
                          ),
                        ),
                      SizedBox(height: 5.h),
                      LayoutBuilder(
                        builder: (_, constraints) {
                          final pct = area.scorePercent / 100;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4.r),
                                child: Stack(
                                  children: [
                                    Container(
                                      height: 4.h,
                                      width: constraints.maxWidth,
                                      color: areaColor.withValues(alpha: 0.15),
                                    ),
                                    Container(
                                      height: 4.h,
                                      width: constraints.maxWidth * pct,
                                      color: areaColor,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 3.h),
                              Text(
                                '${area.scorePercent.toStringAsFixed(0)}% score',
                                style: GoogleFonts.poppins(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w600,
                                  color: areaColor,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 10.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: areaColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: areaColor.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    areaPass ? 'Pass' : 'Fail',
                    style: GoogleFonts.poppins(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: areaColor,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                AnimatedRotation(
                  turns: isExpanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: _Colors.textGrey,
                    size: 20.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded) _buildExpandedItemsList(area),
        Divider(height: 1, color: const Color(0xFFEEEEEE)),
      ],
    );
  }

  Widget _buildExpandedItemsList(CabinSecurityAreaResult area) {
    if (area.subItems.isEmpty && area.pictures.isEmpty)
      return const SizedBox.shrink();
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: _Colors.background,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...area.subItems.map((item) {
            Color itemColor = _Colors.textGrey;
            IconData itemIcon = Icons.remove_circle_outline_rounded;
            if (item.status == 'pass') {
              itemColor = _Colors.pass;
              itemIcon = Icons.check_circle_rounded;
            } else if (item.status == 'fail') {
              itemColor = _Colors.fail;
              itemIcon = Icons.cancel_rounded;
            }
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 5.h),
              child: Row(
                children: [
                  Icon(itemIcon, color: itemColor, size: 16.sp),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      item.name,
                      style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        color: _Colors.namePrimary,
                      ),
                    ),
                  ),
                  if (item.status.isNotEmpty)
                    _miniChip(
                      item.status.substring(0, 1).toUpperCase() +
                          item.status.substring(1).toLowerCase(),
                      itemColor,
                    ),
                ],
              ),
            );
          }),
          if (area.pictures.isNotEmpty) ...[
            if (area.subItems.isNotEmpty) SizedBox(height: 12.h),
            if (area.subItems.isNotEmpty) Divider(color: _Colors.divider),
            if (area.subItems.isNotEmpty) SizedBox(height: 8.h),
            Text(
              'Attachments for ${area.area}',
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: _Colors.namePrimary,
              ),
            ),
            SizedBox(height: 8.h),
            SizedBox(
              height: 80.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: area.pictures.length,
                itemBuilder: (context, i) {
                  return Container(
                    width: 80.w,
                    margin: EdgeInsets.only(right: 8.w),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.r),
                      image: DecorationImage(
                        image: AssetImage(area.pictures[i]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Mini chip ─────────────────────────────────────────────
  Widget _miniChip(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10.sp,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  // ── Icon per area name ───────────────────────────────────
  IconData _areaIcon(String area) {
    final a = area.toLowerCase();
    if (a.contains('galley')) return Icons.restaurant_rounded;
    if (a.contains('lav')) return Icons.wc_rounded;
    if (a.contains('first class') || a.contains('business'))
      return Icons.airline_seat_recline_extra_rounded;
    if (a.contains('comfort')) return Icons.airline_seat_recline_normal_rounded;
    if (a.contains('cabin') || a.contains('main')) return Icons.weekend_rounded;
    if (a.contains('overhead')) return Icons.inventory_2_outlined;
    if (a.contains('pocket')) return Icons.book_outlined;
    if (a.contains('crew')) return Icons.people_outline_rounded;
    if (a.contains('emergency')) return Icons.health_and_safety_outlined;
    return Icons.event_seat_rounded;
  }

  Widget _detailRow(
    IconData icon,
    String text, {
    bool bold = false,
    bool isGrey = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14.sp, color: _Colors.textGrey),
        SizedBox(width: 4.w),
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 13.sp,
            fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
            color: bold ? _Colors.textDark : _Colors.textGrey,
          ),
        ),
      ],
    );
  }

  // ── Filter Bottom Sheet ──────────────────────────────────
  void _showFilterSheet() async {
    final result = await Get.bottomSheet<Map<String, dynamic>>(
      const NewSearchSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
    if (result != null) {
      // Doc: Pass/Fail multi-checkbox — result['filter'] is now a Set<String>
      // containing any combination of 'pass' and/or 'fail'.
      final rawFilter = result['filter'];
      final Set<String> resultsSet = rawFilter is Set<String>
          ? rawFilter
          : rawFilter is String && rawFilter.isNotEmpty
          ? {rawFilter}
          : {};
      controller.applyFilter(
        name: result['name'] ?? '',
        fromDate: result['fromDate'] ?? '',
        toDate: result['toDate'] ?? '',
        results: resultsSet,
      );
    }
  }
}
