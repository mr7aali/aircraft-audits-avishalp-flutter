import 'package:avislap/views/forms/Cabin%20Quality%20Audit/CabinQualityAuditList.dart';
import 'package:avislap/views/forms/LAV%20Safety%20Observation/LavSafetyObservationScreen.dart';
import 'package:avislap/views/forms/cabin%20security%20search/CabinSecurityTrainingScreen.dart';
import 'package:avislap/views/forms/hidden_object_audit/hidden_object_audit_screen.dart';
import 'package:avislap/services/session_service.dart';
import 'package:avislap/widgets/app_drawer_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/app_colors.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionService>();
    final showHiddenObjectAudit = !session.isEmployeeRole;
    const tasksToComplete = 2;
    const completedToday = 0;
    const supervisorName = "John Smith";

    return Scaffold(
      backgroundColor: Colors.white,
      // ✅ Drawer
      drawer: AppDrawerWidget(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ✅ Builder wraps HeroSection so Scaffold.of(ctx) works
            Builder(
              builder: (ctx) => _HeroSection(
                date: DateTime.now(),
                toComplete: tasksToComplete,
                completed: completedToday,
                onMenuTap: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const _SupervisorCard(name: supervisorName),
                  const SizedBox(height: 24),
                  _TasksSection(
                    toComplete: tasksToComplete,
                    showHiddenObjectAudit: showHiddenObjectAudit,
                    onCabinAudit: () =>
                        Get.to(() => CabinQualityAuditListScreen()),
                    onLavSafety: () =>
                        Get.to(() => LavSafetyObservationScreen()),
                    onCabinSecurity: () => Get.to(() => CabinSecurityScreen()),
                    onHiddenObject: () =>
                        Get.to(() => const HiddenObjectAuditListScreen()),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================
// HERO SECTION
// =====================
class _HeroSection extends StatelessWidget {
  final DateTime date;
  final int toComplete;
  final int completed;
  final VoidCallback onMenuTap; // ✅ menu tap callback

  const _HeroSection({
    required this.date,
    required this.toComplete,
    required this.completed,
    required this.onMenuTap,
  });

  String _formatDate(DateTime d) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return "${months[d.month - 1]} ${d.day}";
  }

  @override
  Widget build(BuildContext context) {
    final total = toComplete + completed;
    final progress = total > 0 ? completed / total : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
        ),
      ),
      child: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Top row: menu icon + notification icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: onMenuTap,
                  child: const Icon(Icons.menu, color: Colors.white, size: 26),
                ),
                // const Icon(
                //   Icons.notifications_none_outlined,
                //   color: Colors.white,
                //   size: 26,
                // ),
              ],
            ),
            const SizedBox(height: 16),

            Text(
              "Today",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.9),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDate(date),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text(
                  "$completed",
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                Text(
                  " of $toComplete completed",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF86EFAC),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================
// SUPERVISOR CARD
// =====================
class _SupervisorCard extends StatelessWidget {
  final String name;

  const _SupervisorCard({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.mainAppColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.mainAppColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.mainAppColor.withValues(alpha: 0.2),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : "?",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.mainAppColor,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Your supervisor",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.from_heading,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dark,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.contact_phone_outlined,
            size: 22,
            color: AppColors.mainAppColor.withValues(alpha: 0.6),
          ),
        ],
      ),
    );
  }
}

// =====================
// TASKS SECTION
// =====================
class _TasksSection extends StatelessWidget {
  final int toComplete;
  final bool showHiddenObjectAudit;
  final VoidCallback onCabinAudit;
  final VoidCallback onLavSafety;
  final VoidCallback onCabinSecurity;
  final VoidCallback onHiddenObject;

  const _TasksSection({
    required this.toComplete,
    required this.showHiddenObjectAudit,
    required this.onCabinAudit,
    required this.onLavSafety,
    required this.onCabinSecurity,
    required this.onHiddenObject,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              "Tasks",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
            if (toComplete > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.mainAppColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "$toComplete to do",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mainAppColor,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _PrimaryTaskCard(
          title: "Cabin Quality Audit",
          subtitle: "Inspect cabin areas and submit report",
          icon: Icons.airline_seat_recline_extra,
          onTap: onCabinAudit,
        ),
        const SizedBox(height: 12),
        _SecondaryTaskTile(
          title: "Lav Safety Observation",
          subtitle: "Lavatory safety checklist",
          icon: Icons.wc,
          onTap: onLavSafety,
        ),
        const SizedBox(height: 12),
        _SecondaryTaskTile(
          title: "Cabin Security Search Training",
          subtitle: "Seat map audit and search training",
          icon: Icons.security,
          onTap: onCabinSecurity,
        ),
        if (showHiddenObjectAudit) ...[
          const SizedBox(height: 12),
          _SecondaryTaskTile(
            title: "Hidden Object Audit",
            subtitle: "Hide objects and track live search progress",
            icon: Icons.visibility_outlined,
            onTap: onHiddenObject,
          ),
        ],
      ],
    );
  }
}

// =====================
// PRIMARY TASK CARD
// =====================
class _PrimaryTaskCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _PrimaryTaskCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      shadowColor: Colors.black,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.mainAppColor.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.mainAppColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 28, color: AppColors.mainAppColor),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.from_heading,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.mainAppColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  "Start",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================
// SECONDARY TASK TILE
// =====================
class _SecondaryTaskTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _SecondaryTaskTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.grey.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: AppColors.grey),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.dark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.from_heading,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: AppColors.from_heading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
