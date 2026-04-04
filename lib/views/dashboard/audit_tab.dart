import 'dart:ui';
import 'package:avislap/views/forms/Cabin%20Quality%20Audit/CabinAudit.dart';
import 'package:avislap/views/forms/LAV%20Safety%20Observation/LAVSafety.dart';
import 'package:avislap/views/forms/cabin%20security%20search/cabin_secuirity.dart';
import 'package:avislap/views/forms/hidden_object_audit/hidden_object_audit_screen.dart';
import 'package:avislap/config/app_permission_codes.dart';
import 'package:avislap/services/session_service.dart';
import 'package:avislap/widgets/flight_card.dart';
import 'package:avislap/controllers/aviation_controller.dart';
import 'package:avislap/models/aviationstack_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../../utils/app_colors.dart';

class AuditTab extends StatelessWidget {
  const AuditTab({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionService>();
    final aviation = Get.put(AviationController());
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: aviation.fetchFlights,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 24.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Text(
                    "Flight Audits",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.dark,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                _buildRefreshHeader(aviation),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      // Dynamically use the active station code from session
                      _buildAirportSection(
                        session.activeStationCode.isEmpty
                            ? "JFK"
                            : session.activeStationCode,
                        aviation.activeAirport,
                        showLavSafety,
                        showCabinQuality,
                        showCabinSecurity,
                        showHiddenObjectAudit,
                        context,
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRefreshHeader(AviationController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.update, size: 14, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Obx(
                () => Text(
                  "Last updated: ${controller.timeAgo(controller.activeAirport.lastUpdated.value)}",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.sp,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          Obx(() {
            final totalSeconds = controller.secondsUntilRefresh.value;
            final minutes = totalSeconds ~/ 60;
            final seconds = totalSeconds % 60;
            final timeStr =
                "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "Refreshing in $timeStr",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.sp,
                  color: const Color(0xFF1E293B),
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAirportSection(
    String iata,
    AirportState state,
    bool showLavSafety,
    bool showCabinQuality,
    bool showCabinSecurity,
    bool showHiddenObject,
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.flight_land,
                  color: Color(0xFF64748B),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  "Flights arriving at $iata",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.dark,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            Obx(() {
              if (state.status.value == 'success') {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "${state.data.length} flights",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF3B82F6),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
        Obx(() {
          if (state.status.value == 'error' && state.data.isEmpty) {
            return _buildErrorPlaceholder(state.error.value ?? "Unknown error");
          }
          return const SizedBox.shrink();
        }),
        const SizedBox(height: 16),
        _buildListContent(
          state,
          showLavSafety,
          showCabinQuality,
          showCabinSecurity,
          showHiddenObject,
          context,
        ),
      ],
    );
  }

  Widget _buildErrorPlaceholder(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Sync failed for this airport. $error",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.sp,
                color: Colors.red[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListContent(
    AirportState state,
    bool showLavSafety,
    bool showCabinQuality,
    bool showCabinSecurity,
    bool showHiddenObject,
    BuildContext context,
  ) {
    return Obx(() {
      if (state.status.value == 'loading' && state.data.isEmpty) {
        return Column(
          children: List.generate(2, (index) => const _SkeletonCard()),
        );
      }

      if (state.data.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                Icon(Icons.flight_outlined, size: 48, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text(
                  "No flights found",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15.sp,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "API returned no data for this airport.",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.sp,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: state.data.length,
        itemBuilder: (context, index) {
          final flight = state.data[index];
          return FlightCard(
            flight: flight,
            onStartAudit: () => _showAuditTypeDialog(
              context,
              showLavSafety,
              showCabinQuality,
              showCabinSecurity,
              showHiddenObject,
              flight,
            ),
          );
        },
      );
    });
  }

  void _showAuditTypeDialog(
    BuildContext context,
    bool showLavSafety,
    bool showCabinQuality,
    bool showCabinSecurity,
    bool showHiddenObject,
    AviationFlight flight,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Select Audit Type",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Flight ${flight.flightNumber} • ${flight.airlineName}",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            if (showLavSafety) ...[
              _AuditOptionTile(
                title: "Lav Safety Observation",
                subtitle: "Safety check for lavatory maintenance",
                icon: Icons.clean_hands,
                color: const Color(0xFF0EA5E9),
                onTap: () {
                  Get.back();
                  Get.to(
                    () => LAVSafetyScreen(
                      initialShipNumber: flight.shipNumber,
                      initialGateNumber: flight.arrivalGate,
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
            if (showCabinQuality) ...[
              _AuditOptionTile(
                title: "Cabin Quality Audit",
                subtitle: "General cabin quality and cleanliness",
                icon: Icons.check_circle_outline,
                color: const Color(0xFF10B981),
                onTap: () {
                  Get.back();
                  Get.to(
                    () => CabinAuditScreen(
                      initialShipNumber: flight.shipNumber,
                      initialGateNumber: flight.arrivalGate,
                      initialFlightNumber: flight.flightNumber,
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
            if (showCabinSecurity) ...[
              _AuditOptionTile(
                title: "Cabin Security Search Training",
                subtitle: "Form-based security search training",
                icon: Icons.security,
                color: const Color(0xFFF59E0B),
                onTap: () {
                  Get.back();
                  Get.to(
                    () => CabinQualityAuditScreenN(
                      initialShipNumber: flight.shipNumber,
                      initialGateNumber: flight.arrivalGate,
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
            if (showHiddenObject) ...[
              _AuditOptionTile(
                title: "Hidden Object Audit",
                subtitle: "Conduct blind security search test",
                icon: Icons.search,
                color: const Color(0xFF8B5CF6),
                onTap: () {
                  Get.back();
                  Get.to(() => const HiddenObjectAuditWorkflowScreen());
                },
              ),
              const SizedBox(height: 12),
            ],
            if (!showLavSafety &&
                !showCabinQuality &&
                !showCabinSecurity &&
                !showHiddenObject)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  "No audit workflows are assigned to your current role for this station.",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }
}

class _AuditOptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AuditOptionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: 180.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.r),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 120.w,
                      height: 20,
                      color: Colors.grey[300],
                    ),
                    Container(
                      width: 60.w,
                      height: 25,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: Container(height: 40, color: Colors.grey[300]),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Container(height: 40, color: Colors.grey[300]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
