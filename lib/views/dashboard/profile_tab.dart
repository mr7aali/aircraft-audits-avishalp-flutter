import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    const name = "Employee";
    const supervisorName = "John Smith";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 24),
          CircleAvatar(
            radius: 48,
            backgroundColor: AppColors.mainAppColor.withOpacity(0.2),
            child: AppText(
              name.isNotEmpty ? name[0].toUpperCase() : "?",
              color: AppColors.mainAppColor,
              fontWeight: FontWeight.bold,
              fontSize: 36,
            ),
          ),
          const SizedBox(height: 16),
          AppText(name, fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.dark),
          const SizedBox(height: 4),
          AppText("Supervisor: $supervisorName", fontSize: 14, color: AppColors.from_heading),
          const SizedBox(height: 32),
          _SettingsTile(icon: Icons.notifications_outlined, title: "Notifications", onTap: () {}),
          _SettingsTile(icon: Icons.info_outline, title: "About", onTap: () {}),
          _SettingsTile(icon: Icons.logout, title: "Log out", onTap: () {}),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.mainAppColor, size: 22),
      title: AppText(title, fontSize: 16, color: AppColors.dark),
      trailing: Icon(Icons.chevron_right, color: AppColors.from_heading),
      onTap: onTap,
    );
  }
}
