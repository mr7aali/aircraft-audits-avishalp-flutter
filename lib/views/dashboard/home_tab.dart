  import 'package:avislap/services/session_service.dart';
import 'package:avislap/config/app_permission_codes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../../utils/app_colors.dart';

// Navigation Imports
import 'package:avislap/views/forms/Cabin%20Quality%20Audit/CabinQualityAuditList.dart';
import 'package:avislap/views/forms/LAV%20Safety%20Observation/LavSafetyObservationScreen.dart';
import 'package:avislap/views/forms/cabin%20security%20search/CabinSecurityTrainingScreen.dart';
import 'package:avislap/views/forms/hidden_object_audit/hidden_object_audit_screen.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionService>();

    return Container(
      color: const Color(0xFFF8FAFC),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeroSection(
              userName: session.fullName,
              designation: session.activeRoleName,
            ),
            const _DateSection(),
            SizedBox(height: 24.h),
            const QuickAccessSection(),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }
}

class QuickAccessSection extends StatelessWidget {
  final String title;
  final EdgeInsetsGeometry? padding;

  const QuickAccessSection({
    super.key,
    this.title = "Quick Access",
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionService>();
    final showLavSafety = session.hasPermission(
      AppPermissionCodes.lavSafetyObservation,
    );
    final showCabinQuality = session.hasPermission(
      AppPermissionCodes.cabinQualityAudit,
    );
    final showCabinSecurity = session.hasPermission(
      AppPermissionCodes.cabinSecuritySearchTraining,
    );
    final showHiddenObjectAudit = session.hasPermission(
      AppPermissionCodes.hiddenObjectAudit,
    );

    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.dark,
                letterSpacing: -0.5,
              ),
            ),
          ),
          SizedBox(height: 16.h),
          _QuickAccessGrid(
            showLavSafety: showLavSafety,
            showCabinQuality: showCabinQuality,
            showCabinSecurity: showCabinSecurity,
            showHiddenObjectAudit: showHiddenObjectAudit,
          ),
        ],
      ),
    );
  }
}

class _QuickAccessGrid extends StatelessWidget {
  final bool showLavSafety;
  final bool showCabinQuality;
  final bool showCabinSecurity;
  final bool showHiddenObjectAudit;

  const _QuickAccessGrid({
    required this.showLavSafety,
    required this.showCabinQuality,
    required this.showCabinSecurity,
    required this.showHiddenObjectAudit,
  });

  void _showComingSoon(String title) {
    Get.snackbar(
      title,
      'This feature will be available soon.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black.withOpacity(0.8),
      colorText: Colors.white,
      margin: EdgeInsets.all(16.w),
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> items = [
      // ─── FORMS ──────────────────────────────────────────
      if (showLavSafety)
        {
          'title': 'Lav Safety\nObservation',
          'icon': Icons.clean_hands,
          'color': const Color(0xFF0EA5E9),
          'onTap': () => Get.to(() => LavSafetyObservationScreen()),
        },
      if (showCabinQuality)
        {
          'title': 'Cabin Quality\nAudit',
          'icon': Icons.check_circle_outline,
          'color': const Color(0xFF10B981),
          'onTap': () => Get.to(() => CabinQualityAuditListScreen()),
        },
      if (showCabinSecurity)
        {
          'title': 'Cabin Security\nSearch Training',
          'icon': Icons.security,
          'color': const Color(0xFFF59E0B),
          'onTap': () => Get.to(() => CabinSecurityScreen()),
        },
      if (showHiddenObjectAudit)
        {
          'title': 'Hidden Object\nAudit',
          'icon': Icons.search,
          'color': const Color(0xFF8B5CF6),
          'onTap': () => Get.to(() => const HiddenObjectAuditListScreen()),
        },

      // ─── HR & ADMIN ─────────────────────────────────────
      {
        'title': 'Employee\nDetail',
        'icon': Icons.person_outline_rounded,
        'color': const Color(0xFF6366F1),
        'onTap': () => _showComingSoon('Employee Detail'),
      },

      {
        'title': 'Time and Edits',
        'icon': Icons.access_time_rounded,
        'color': const Color(0xFFF43F5E),
        'onTap': () => _showComingSoon('Time Sheet'),
      },

      // ─── OPERATIONS ─────────────────────────────────────
      {
        'title': 'Inventory',
        'icon': Icons.grid_view_outlined,
        'color': const Color(0xFFEAB308),
        'onTap': () => _showComingSoon('Inventory'),
      },
      {
        'title': 'Feedback',
        'icon': Icons.people_alt_outlined,
        'color': const Color(0xFF8B5CF6),
        'onTap': () => _showComingSoon('Feedback'),
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16.w,
          mainAxisSpacing: 16.h,
          childAspectRatio: 1.15,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final Color iColor = item['color'];

          return InkWell(
            onTap: item['onTap'],
            borderRadius: BorderRadius.circular(16.r),
            child: Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: iColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(item['icon'], color: iColor, size: 24.sp),
                  ),
                  const Spacer(),
                  Text(
                    item['title'],
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.dark,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  final String userName;
  final String designation;

  const _HeroSection({required this.userName, required this.designation});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 40.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF0F172A), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36.r),
          bottomRight: Radius.circular(36.r),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                  ),
                ),
                Image.asset(
                  'assets/images/custom_logo.png',
                  height: 52.h,
                  color: Colors.white,
                ),
              ],
            ),
            const SizedBox(height: 36),
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white30, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 36.r,
                    backgroundColor: Colors.white24,
                    backgroundImage: const AssetImage(
                      'assets/images/mursalin.jpg',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Hello, $userName",
                  style: GoogleFonts.dmSans(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                Text(
                  "Welcome Back",
                  style: GoogleFonts.dmSans(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.verified_user,
                        size: 14,
                        color: Colors.blueAccent,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        designation.isEmpty
                            ? "STAFF"
                            : designation.toUpperCase(),
                        style: GoogleFonts.dmSans(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
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

class _DateSection extends StatelessWidget {
  const _DateSection();

  String _formatFullDate() {
    final d = DateTime.now();
    const months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];
    const weekdays = [
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
      "Sunday",
    ];
    return "${weekdays[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}, ${d.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -15),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_today,
                color: Color(0xFF3B82F6),
                size: 18,
              ),
              const SizedBox(width: 12),
              Text(
                _formatFullDate(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
