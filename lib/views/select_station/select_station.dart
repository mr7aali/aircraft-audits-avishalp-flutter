import 'package:avislap/views/dashboard/dashboard_screen.dart';
import 'package:avislap/widgets/parallax_hero_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class _C {
  static const Color blue = Color(0xFF3D5AFE);
  static const Color ink = Color(0xFF0E0E10);
  static const Color border = Color(0xFFEAECF2);
  static const Color placeholder = Color(0xFFC8CDD9);
  static const Color muted = Color(0xFF8891A4);
}

class StationSelectionScreen extends StatefulWidget {
  final String userName;

  const StationSelectionScreen({
    super.key,
    this.userName = 'Sarah',
  });

  @override
  State<StationSelectionScreen> createState() => _StationSelectionScreenState();
}

class _StationSelectionScreenState extends State<StationSelectionScreen> {

  String? _selectedStation;
  bool _isDropdownOpen = false;

  // Sample stations list
  final List<String> _stations = [
    'Station A - Terminal 1',
    'Station B - Terminal 2',
    'Station C - Terminal 3',
    'Station D - Gate 10',
    'Station E - Gate 20',
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _showStationPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _buildStationSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: Column(
        children: [
          // ── Blue Hero ──────────────────────────────────
          ParallaxHeroWidget(
            bottomPadding: 220,
            trailingAction: GestureDetector(
              onTap: () => Get.offAllNamed('/login'),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.30), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.logout_rounded, color: Colors.white, size: 16.sp),
                    SizedBox(width: 6.w),
                    Text('Logout',
                      style: GoogleFonts.dmSans(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      )),
                  ],
                ),
              ),
            ),
            child: Text(
              'Welcome, ${widget.userName}!',
              style: GoogleFonts.dmSans(
                fontSize: 30.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.8,
                height: 1.15,
              ),
            ),
          ),

          // ── White Card ────────────────────────────────
          Transform.translate(
            offset: const Offset(0, -90),
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 16.w),
              padding: EdgeInsets.fromLTRB(20.w, 22.h, 20.w, 30.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Subtitle
                  Text(
                    'Select your station to begin',
                    style: GoogleFonts.dmSans(
                      fontSize: 13.sp,
                      color: Colors.grey.shade500,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 14.h),

                  // Station selector field
                  GestureDetector(
                    onTap: _showStationPicker,
                    child: Container(
                      height: 52.h,
                      padding: EdgeInsets.symmetric(horizontal: 18.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30.r),
                        border: Border.all(color: _C.border, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _selectedStation ?? 'Select your station',
                              style: GoogleFonts.dmSans(
                                fontSize: 14.sp,
                                color: _selectedStation != null
                                    ? _C.ink
                                    : _C.placeholder,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.search,
                            color: _C.muted,
                            size: 20.sp,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Continue button
                  GestureDetector(
                    onTap: () {
                      if (_selectedStation == null) {
                        // Get.snackbar(
                        //   '', 'Please select a station first',
                        //   snackPosition: SnackPosition.BOTTOM,
                        //   backgroundColor: _C.blue,
                        //   colorText: Colors.white,
                        //   margin: const EdgeInsets.all(16),
                        //   borderRadius: 12,
                        // );
                        context;
                      }
                      // Navigate to dashboard or next screen
                      Get.to(() => DashboardScreen());
                    },
                    child: Container(
                      height: 54.h,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _C.blue,
                        borderRadius: BorderRadius.circular(30.r),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'CONTINUE',
                        style: GoogleFonts.dmSans(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),
          _buildHomeIndicator(),
        ],
      ),
    );
  }



  // ── Station Bottom Sheet ──────────────────────────────────
  Widget _buildStationSheet() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40.w, height: 4.h,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 16.h),

          Text(
            'Select Station',
            style: GoogleFonts.dmSans(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: _C.ink,
            ),
          ),
          SizedBox(height: 12.h),

          // Station list
          ...(_stations.map((station) => GestureDetector(
            onTap: () {
              setState(() => _selectedStation = station);
              Get.back();
            },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
              margin: EdgeInsets.only(bottom: 8.h),
              decoration: BoxDecoration(
                color: _selectedStation == station
                    ? _C.blue.withValues(alpha: 0.08)
                    : const Color(0xFFF7F8FC),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: _selectedStation == station
                      ? _C.blue.withValues(alpha: 0.4)
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Text(
                station,
                style: GoogleFonts.dmSans(
                  fontSize: 14.sp,
                  color: _selectedStation == station ? _C.blue : _C.ink,
                  fontWeight: _selectedStation == station
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            ),
          ))),
        ],
      ),
    );
  }



  Widget _buildHomeIndicator() {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Center(
        child: Container(
          width: 134.w, height: 5.h,
          decoration: BoxDecoration(
            color: _C.ink.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(3.r),
          ),
        ),
      ),
    );
  }
}