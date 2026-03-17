import 'LAVSafety.dart';
import 'package:avislap/utils/app_colors.dart';
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
  static const Color newObservationBtn = Color(0xFF3D5AFE);
}

// =====================
// MODEL
// =====================
class ObservationItem {
  final String id;
  final String observerName;
  final String observerImage;
  final String date;
  final String time;
  final String gate;
  final String driverName;
  final String locationImage;
  final String locationImage2;

  ObservationItem({
    required this.id,
    required this.observerName,
    required this.observerImage,
    required this.date,
    required this.time,
    required this.gate,
    required this.driverName,
    required this.locationImage,
    required this.locationImage2,
  });
}

// =====================
// CONTROLLER
// =====================
class LavSafetyController extends GetxController {
  final RxList<ObservationItem> observations = <ObservationItem>[].obs;

  @override
  void onInit() {
    super.onInit();
    observations.assignAll([
      ObservationItem(
        id: '1',
        observerName: 'Jane Cooper',
        observerImage: 'assets/images/nirob.jpg',
        date: 'Dec 15, 2024',
        time: '2:30 PM',
        gate: 'Gate A-12',
        driverName: 'Adam West',
        locationImage: 'assets/images/indor.png',
        locationImage2: 'assets/images/window.png',
      ),
      ObservationItem(
        id: '2',
        observerName: 'Kristin Watson',
        observerImage: 'assets/images/mursalin.jpg',
        date: 'Dec 15, 2024',
        time: '2:30 PM',
        gate: 'Gate A-12',
        driverName: 'Michael Keaton',
        locationImage: 'assets/images/indor.png',
        locationImage2: 'assets/images/window.png',
      ),
      ObservationItem(
        id: '3',
        observerName: 'Theresa Webb',
        observerImage: 'assets/images/nirob.jpg',
        date: 'Dec 15, 2024',
        time: '2:30 PM',
        gate: 'Gate A-12',
        driverName: 'Ben Affleck',
        locationImage: 'assets/images/indor.png',
        locationImage2: 'assets/images/window.png',
      ),
      ObservationItem(
        id: '4',
        observerName: 'Guy Hawkins',
        observerImage: 'assets/images/nirob.jpg',
        date: 'Dec 15, 2024',
        time: '2:30 PM',
        gate: 'Gate A-12',
        driverName: 'Christian Bale',
        locationImage: 'assets/images/indor.png',
        locationImage2: 'assets/images/window.png',
      ),
    ]);
  }
}

// =====================
// SCREEN
// =====================
class LavSafetyObservationScreen extends StatefulWidget {
  const LavSafetyObservationScreen({super.key});

  @override
  State<LavSafetyObservationScreen> createState() =>
      _LavSafetyObservationScreenState();
}

class _LavSafetyObservationScreenState
    extends State<LavSafetyObservationScreen> {
  late final LavSafetyController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(LavSafetyController());
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
                    _buildObservationList(),
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
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'LAV Safety Observation',
              style: GoogleFonts.poppins(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: _Colors.primary,
              ),
            ),
          ),
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
              'Past Observations',
              style: GoogleFonts.poppins(
                fontSize: 17.sp,
                fontWeight: FontWeight.w700,
                color: _Colors.textDark,
              ),
            ),
          ],
        ),

        // New Observation button
        GestureDetector(
          onTap: () {
            Get.to(() => LAVSafetyScreen());
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: _Colors.newObservationBtn,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              'New Observation',
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

  // ── Observation List ─────────────────────────────────────
  Widget _buildObservationList() {
    return Obx(() {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: controller.observations.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: _Colors.divider, indent: 0),
        itemBuilder: (context, index) {
          return _buildObservationCard(controller.observations[index]);
        },
      );
    });
  }

  // ── Observation Card ─────────────────────────────────────
  Widget _buildObservationCard(ObservationItem item) {
    return GestureDetector(
      onTap: () {
        // Get.to(() => LAVSafetyScreen());
      },
      child: Container(
        color: _Colors.cardBg,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Observer Avatar with blue border + green dot
            Stack(
              children: [
                Container(
                  padding: EdgeInsets.all(3.r), // ✅ blue border gap
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Color(0xFF3D5AFE), // ✅ blue border
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
                // ✅ Green dot — bottom right
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    width: 13.w,
                    height: 13.h,
                    decoration: BoxDecoration(
                      color: Color(0xFF1DB954), // ✅ green
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
                  SizedBox(height: 5.h),
                  Text(
                    item.observerName,
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: _Colors.namePrimary,
                    ),
                  ),
                  SizedBox(height: 10.h),

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
                        padding: EdgeInsets.symmetric(horizontal: 5.w),
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
                  SizedBox(height: 10.h),

                  // Gate
                  Text(
                    item.gate,
                    style: GoogleFonts.poppins(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: _Colors.textDark,
                    ),
                  ),
                  SizedBox(height: 10.h),

                  // Driver name
                  Text(
                    'Driver: ${item.driverName}',
                    style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      color: _Colors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 10.w),

            // ✅ Replace single image with stacked two images
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: Image.asset(
                    item.locationImage,
                    width: 64.w,
                    height: 60.h,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 64.w,
                      height: 60.h,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        Icons.image_outlined,
                        color: Colors.grey.shade400,
                        size: 24.sp,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 6.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: Image.asset(
                    item.locationImage2,
                    width: 64.w,
                    height: 60.h,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 64.w,
                      height: 60.h,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        Icons.image_outlined,
                        color: Colors.grey.shade400,
                        size: 24.sp,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
