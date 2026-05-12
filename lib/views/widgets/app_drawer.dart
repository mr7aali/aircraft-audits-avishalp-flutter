import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../healper/route.dart';
import '../../services/app_api_service.dart';
import '../../services/session_service.dart';
import '../../utils/app_colors.dart';
import '../audits/draft_audits_screen.dart';
import '../audits/my_audits_screen.dart';
import '../dashboard/audit_operations_tab.dart';
import '../../config/app_permission_codes.dart';
import '../forms/survey_hub/admin_submitted_forms_screen.dart';
import '../forms/survey_hub/my_submitted_forms_screen.dart';
import '../forms/Cabin%20Quality%20Audit/CabinQualityAuditList.dart';
import '../forms/LAV%20Safety%20Observation/LavSafetyObservationScreen.dart';
import '../forms/cabin%20security%20search/CabinSecurityTrainingScreen.dart';
import '../forms/hidden_object_audit/hidden_object_audit_screen.dart';

class AppDrawer extends StatefulWidget {
  final VoidCallback? onDashboardTap;
  final VoidCallback? onProfileTap;

  const AppDrawer({super.key, this.onDashboardTap, this.onProfileTap});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final AppApiService _api = Get.find<AppApiService>();
  bool _isLoggingOut = false;

  Future<void> _logout() async {
    if (_isLoggingOut) {
      return;
    }

    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Log out'),
            content: const Text('Do you want to end your current session?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Log out'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed || !mounted) {
      return;
    }

    setState(() => _isLoggingOut = true);

    await _api.logout();

    if (!mounted) {
      return;
    }

    Get.offAllNamed(RouteHelper.login);
  }

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionService>();
    final canViewAdminSubmissions = session.hasPermission(
      AppPermissionCodes.adminDashboardSubmissions,
    );
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
    final hasAuditWorkflowAccess =
        showLavSafety ||
        showCabinQuality ||
        showCabinSecurity ||
        showHiddenObjectAudit;

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[Color(0xFF0F172A), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            currentAccountPicture: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white30, width: 2),
              ),
              child: const CircleAvatar(
                backgroundColor: Colors.white24,
                backgroundImage: AssetImage('assets/images/mursalin.jpg'),
              ),
            ),
            accountName: Text(
              session.fullName.isEmpty ? "User" : session.fullName,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            accountEmail: Text(
              session.activeRoleName.isEmpty
                  ? "STAFF"
                  : session.activeRoleName.toUpperCase(),
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w500,
                color: Colors.white70,
                fontSize: 12.sp,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _DrawerSectionHeader(title: 'Workspace'),
                DrawerTile(
                  icon: Icons.dashboard_outlined,
                  title: 'Dashboard',
                  onTap: () {
                    Get.back();
                    widget.onDashboardTap?.call();
                  },
                ),
                DrawerTile(
                  icon: Icons.person_outline_rounded,
                  title: 'My Profile',
                  onTap: () {
                    Get.back();
                    widget.onProfileTap?.call();
                  },
                ),
                if (hasAuditWorkflowAccess) ...[
                  const SizedBox(height: 8),
                  _DrawerSectionHeader(
                    title: 'Audit Workflows',
                    subtitle: 'Start the right audit flow for your shift.',
                  ),
                  if (showLavSafety)
                    DrawerTile(
                      icon: Icons.clean_hands,
                      title: 'Lav Safety Observation',
                      iconColor: const Color(0xFF0EA5E9),
                      onTap: () {
                        Get.back();
                        Get.to(() => LavSafetyObservationScreen());
                      },
                    ),
                  if (showCabinQuality)
                    DrawerTile(
                      icon: Icons.check_circle_outline,
                      title: 'Cabin Quality Audit',
                      iconColor: const Color(0xFF10B981),
                      onTap: () {
                        Get.back();
                        Get.to(() => CabinQualityAuditListScreen());
                      },
                    ),
                  if (showCabinSecurity)
                    DrawerTile(
                      icon: Icons.security,
                      title: 'Cabin Security Search Training',
                      iconColor: const Color(0xFFF59E0B),
                      onTap: () {
                        Get.back();
                        Get.to(() => CabinSecurityScreen());
                      },
                    ),
                  if (showHiddenObjectAudit)
                    DrawerTile(
                      icon: Icons.search,
                      title: 'Hidden Object Audit',
                      iconColor: const Color(0xFF8B5CF6),
                      onTap: () {
                        Get.back();
                        Get.to(() => const HiddenObjectAuditListScreen());
                      },
                    ),
                ],
                const SizedBox(height: 8),
                _DrawerSectionHeader(title: 'My Activity'),
                DrawerTile(
                  icon: Icons.history_outlined,
                  title: 'My Audits',
                  onTap: () {
                    Get.back();
                    Get.to(() => const MyAuditsScreen());
                  },
                ),
                DrawerTile(
                  icon: Icons.drafts_outlined,
                  title: 'Draft Audits',
                  onTap: () {
                    Get.back();
                    Get.to(() => const DraftAuditsScreen());
                  },
                ),
                DrawerTile(
                  icon: Icons.assignment_turned_in_outlined,
                  title: 'My Submitted Forms',
                  onTap: () {
                    Get.back();
                    Get.to(() => const MySubmittedFormsScreen());
                  },
                ),
                DrawerTile(
                  icon: Icons.manage_search_outlined,
                  title: 'All Submitted Audits',
                  onTap: () {
                    Get.back();
                    Get.to(() => const AuditOperationsTab());
                  },
                ),
                if (canViewAdminSubmissions)
                  DrawerTile(
                    icon: Icons.topic_outlined,
                    title: 'All Submitted Forms',
                    onTap: () {
                      Get.back();
                      Get.to(() => const AdminSubmittedFormsScreen());
                    },
                  ),
                DrawerTile(
                  icon: Icons.assignment_outlined,
                  title: 'Pending Tasks',
                  onTap: () {
                    Get.back();
                    Get.snackbar(
                      'Coming Soon',
                      'Pending tasks will be available soon.',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.black87,
                      colorText: Colors.white,
                    );
                  },
                ),
                const SizedBox(height: 8),
                _DrawerSectionHeader(title: 'App'),
                DrawerTile(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  onTap: () {
                    Get.back();
                    Get.snackbar(
                      'Coming Soon',
                      'Settings will be available soon.',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.black87,
                      colorText: Colors.white,
                    );
                  },
                ),
                DrawerTile(
                  icon: Icons.help_outline_rounded,
                  title: 'Help & Support',
                  onTap: () {
                    Get.back();
                    Get.snackbar(
                      'Coming Soon',
                      'Help & support will be available soon.',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.black87,
                      colorText: Colors.white,
                    );
                  },
                ),
              ],
            ),
          ),
          const Divider(),
          DrawerTile(
            icon: Icons.logout_rounded,
            title: _isLoggingOut ? 'Logging out...' : 'Logout',
            textColor: Colors.redAccent,
            iconColor: Colors.redAccent,
            trailing: _isLoggingOut
                ? SizedBox(
                    width: 18.w,
                    height: 18.w,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            onTap: _logout,
          ),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }
}

class _DrawerSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _DrawerSectionHeader({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF64748B),
              letterSpacing: 0.8,
            ),
          ),
          if (subtitle != null) ...[
            SizedBox(height: 4.h),
            Text(
              subtitle!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF94A3B8),
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class DrawerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? textColor;
  final Color? iconColor;
  final Widget? trailing;

  const DrawerTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.textColor,
    this.iconColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? const Color(0xFF475569)),
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: textColor ?? AppColors.dark,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
