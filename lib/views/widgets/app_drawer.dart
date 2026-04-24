import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../healper/route.dart';
import '../../services/app_api_service.dart';
import '../../services/session_service.dart';
import '../../utils/app_colors.dart';
import '../audits/my_audits_screen.dart';

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
                DrawerTile(
                  icon: Icons.history_outlined,
                  title: 'My Audits',
                  onTap: () {
                    Get.back();
                    Get.to(() => const MyAuditsScreen());
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
                const Divider(),
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
