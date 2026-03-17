import 'package:avislap/utils/app_colors.dart';
import 'package:avislap/views/forms/Cabin%20Quality%20Audit/CabinAudit.dart';
import 'package:avislap/views/forms/cabin%20security%20search/training_filter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'CabinQualityAuditScreen.dart';

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
  static const Color newAuditBtn = Color(0xFF3D5AFE);
}

// =====================
// MODEL
// =====================
class CabinAuditItem {
  final String id;
  final String observerName;
  final String observerImage;
  final String date;
  final String time;
  final String gate;

  /// Real clean types:
  /// Charter | Diversion | DCS Turn | MSGT Turn |
  /// RAD – Remain All Day | RON – Remain Over Night | Security Search
  final String type;

  final String locationImage;
  final String locationImage2;
  final String? bottomAvatarImage;

  CabinAuditItem({
    required this.id,
    required this.observerName,
    required this.observerImage,
    required this.date,
    required this.time,
    required this.gate,
    required this.type,
    required this.locationImage,
    required this.locationImage2,
    this.bottomAvatarImage,
  });
}

// =====================
// CONTROLLER
// =====================
class CabinQualityAuditListController extends GetxController {
  final RxList<CabinAuditItem> audits = <CabinAuditItem>[].obs;

  @override
  void onInit() {
    super.onInit();
    audits.assignAll([
      CabinAuditItem(
        id: '1',
        observerName: 'Jane Cooper',
        observerImage: 'assets/images/nirob.jpg',
        date: 'Dec 15, 2024',
        time: '2:30 PM',
        gate: 'Gate A-12',
        type: 'Charter',
        locationImage: 'assets/images/indor.png',
        locationImage2: 'assets/images/window.png',
      ),
      CabinAuditItem(
        id: '2',
        observerName: 'Kristin Watson',
        observerImage: 'assets/images/mursalin.jpg',
        date: 'Dec 15, 2024',
        time: '2:30 PM',
        gate: 'Gate A-12',
        type: 'MSGT Turn',
        locationImage: 'assets/images/indor.png',
        locationImage2: 'assets/images/window.png',
      ),
      CabinAuditItem(
        id: '3',
        observerName: 'Theresa Webb',
        observerImage: 'assets/images/nirob.jpg',
        date: 'Dec 15, 2024',
        time: '2:30 PM',
        gate: 'Gate A-12',
        type: 'Diversion',
        locationImage: 'assets/images/indor.png',
        locationImage2: 'assets/images/window.png',
      ),
      CabinAuditItem(
        id: '4',
        observerName: 'Guy Hawkins',
        observerImage: 'assets/images/nirob.jpg',
        date: 'Dec 15, 2024',
        time: '2:30 PM',
        gate: 'Gate A-12',
        type: 'RON – Remain Over Night',
        locationImage: 'assets/images/indor.png',
        locationImage2: 'assets/images/window.png',
        bottomAvatarImage: 'assets/images/mursalin.jpg',
      ),
    ]);
  }
}

// =====================
// SCREEN
// =====================
class CabinQualityAuditListScreen extends StatefulWidget {
  const CabinQualityAuditListScreen({super.key});

  @override
  State<CabinQualityAuditListScreen> createState() =>
      _CabinQualityAuditListScreenState();
}

class _CabinQualityAuditListScreenState
    extends State<CabinQualityAuditListScreen> {
  late final CabinQualityAuditListController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(CabinQualityAuditListController());
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
                    _buildAuditList(),
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
              'Cabin Quality Audit',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: _Colors.primary,
              ),
            ),
          ),
          // Three dot menu
          IconButton(
            icon: Icon(
              Icons.tune_rounded,
              color: AppColors.mainAppColor,
              size: 24.sp,
            ),
            onPressed: () => Get.bottomSheet(
              const NewSearchSheet(),
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }

  // ── Section Header ───────────────────────────────────────
  Widget _buildSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
            Text(
              'Past Audits',
              style: GoogleFonts.poppins(
                fontSize: 17.sp,
                fontWeight: FontWeight.w700,
                color: _Colors.textDark,
              ),
            ),
          ],
        ),

        // New Audit button
        GestureDetector(
          onTap: () {
            Get.to(() => CabinAuditScreen());
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: _Colors.newAuditBtn,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              'New Audit',
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Audit List ───────────────────────────────────────────
  Widget _buildAuditList() {
    return Obx(
      () => ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: controller.audits.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: _Colors.divider),
        itemBuilder: (context, index) {
          return _buildAuditCard(controller.audits[index]);
        },
      ),
    );
  }

  // ── Audit Card ───────────────────────────────────────────
  Widget _buildAuditCard(CabinAuditItem item) {
    return InkWell(
      onTap: () {
        Get.to(() => const CabinQualityAuditScreen());
      },
      child: Container(
        color: _Colors.cardBg,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar with blue border + green dot
            Stack(
              children: [
                Container(
                  padding: EdgeInsets.all(3.r),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _Colors.primary, width: 2.5.w),
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
                      color: const Color(0xFF1DB954),
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

                  // Name
                  Text(
                    item.observerName,
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: _Colors.namePrimary,
                    ),
                  ),
                  SizedBox(height: 5.h),

                  // Date • Time
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
                          width: 4.w,
                          height: 4.h,
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
                  SizedBox(height: 6.h),

                  // Gate
                  Text(
                    item.gate,
                    style: GoogleFonts.poppins(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: _Colors.textDark,
                    ),
                  ),
                  SizedBox(height: 4.h),

                  // Type
                  Text(
                    item.type,
                    style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      color: _Colors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 10.w),

            // Right: two stacked images + optional bottom avatar
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildLocationImage(item.locationImage),
                SizedBox(height: 6.h),
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    _buildLocationImage(item.locationImage2),
                    if (item.bottomAvatarImage != null)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: CircleAvatar(
                          radius: 12.r,
                          backgroundImage: AssetImage(item.bottomAvatarImage!),
                          backgroundColor: Colors.grey.shade200,
                          onBackgroundImageError: (_, __) {},
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Location Image ───────────────────────────────────────
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
}
