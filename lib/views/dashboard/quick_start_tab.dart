import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../utils/app_colors.dart';
import '../forms/survey_hub/survey_hub_screen.dart';
import 'home_tab.dart';

class QuickStartTab extends StatelessWidget {
  const QuickStartTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 8.h),
                child: Text(
                  'Quick Start',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.dark,
                    letterSpacing: -0.6,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Text(
                  'Open the tools and shortcuts you use most.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.from_heading,
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: _FormsCreationLaunchCard(
                  onTap: () => Get.to(() => const SurveyHubScreen()),
                ),
              ),
              SizedBox(height: 24.h),
              const QuickAccessSection(title: 'Quick Start'),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormsCreationLaunchCard extends StatelessWidget {
  final VoidCallback onTap;

  const _FormsCreationLaunchCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24.r),
      child: Ink(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: <Color>[Color(0xFF0F172A), Color(0xFF2563EB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: const Color(0xFF2563EB).withValues(alpha: 0.22),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999.r),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(
                'Forms & Surveys',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            SizedBox(height: 14.h),
            Text(
              'Open the new survey answer flow',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22.sp,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.2,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Use this shortcut to browse published forms and submit your answers from mobile.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.82),
                height: 1.45,
              ),
            ),
            SizedBox(height: 18.h),
            Row(
              children: <Widget>[
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Icon(
                    Icons.assignment_turned_in_outlined,
                    color: Colors.white,
                    size: 24.sp,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Text(
                    'Go Now',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.mainAppColor,
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
