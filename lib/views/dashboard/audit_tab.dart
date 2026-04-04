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

class AuditTab extends StatefulWidget {
  const AuditTab({super.key});

  @override
  State<AuditTab> createState() => _AuditTabState();
}

class _AuditTabState extends State<AuditTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'all';
  bool _onlyWithGate = false;
  String _sortOption = 'arrival_asc';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    final next = _searchController.text.trim();
    if (next == _searchQuery) {
      return;
    }
    setState(() => _searchQuery = next);
  }

  String _normalizeSearchValue(String value) {
    return value.trim().toLowerCase();
  }

  bool _hasRealGate(String gate) {
    final normalized = gate.trim().toLowerCase();
    return normalized.isNotEmpty &&
        normalized != '—' &&
        normalized != 'n/a' &&
        normalized != 'unknown';
  }

  bool _matchesSearch(AviationFlight flight, String query) {
    if (query.isEmpty) {
      return true;
    }

    final normalizedQuery = _normalizeSearchValue(query);
    final haystack = <String>[
      flight.flightNumber,
      flight.airlineName,
      flight.shipNumber,
      flight.arrivalGate,
      flight.arrivalTerminal,
      flight.arrivalAirport,
      flight.arrivalIata,
      flight.departureAirport,
      flight.departureIata,
      flight.status,
    ].map(_normalizeSearchValue).join(' ');

    return haystack.contains(normalizedQuery);
  }

  List<AviationFlight> _applyFilters(List<AviationFlight> flights) {
    final filtered = flights.where((flight) {
      if (!_matchesSearch(flight, _searchQuery)) {
        return false;
      }

      if (_statusFilter != 'all' &&
          flight.status.toLowerCase() != _statusFilter.toLowerCase()) {
        return false;
      }

      if (_onlyWithGate && !_hasRealGate(flight.arrivalGate)) {
        return false;
      }

      return true;
    }).toList();

    filtered.sort((a, b) {
      switch (_sortOption) {
        case 'arrival_desc':
          final aTime = a.arrivalTime;
          final bTime = b.arrivalTime;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        case 'airline_asc':
          return a.airlineName.toLowerCase().compareTo(
            b.airlineName.toLowerCase(),
          );
        case 'flight_asc':
          return a.flightNumber.toLowerCase().compareTo(
            b.flightNumber.toLowerCase(),
          );
        case 'arrival_asc':
        default:
          final aTime = a.arrivalTime;
          final bTime = b.arrivalTime;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return aTime.compareTo(bTime);
      }
    });

    return filtered;
  }

  int _activeFilterCount() {
    var count = 0;
    if (_statusFilter != 'all') {
      count++;
    }
    if (_onlyWithGate) {
      count++;
    }
    if (_sortOption != 'arrival_asc') {
      count++;
    }
    return count;
  }

  void _resetFilters() {
    setState(() {
      _statusFilter = 'all';
      _onlyWithGate = false;
      _sortOption = 'arrival_asc';
    });
  }

  Future<void> _showFilterSheet(BuildContext context) async {
    String tempStatus = _statusFilter;
    bool tempOnlyWithGate = _onlyWithGate;
    String tempSort = _sortOption;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Widget buildChoiceChip({
              required String label,
              required bool selected,
              required VoidCallback onTap,
            }) {
              return Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 8),
                child: ChoiceChip(
                  label: Text(label),
                  selected: selected,
                  onSelected: (_) => onTap(),
                  labelStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? Colors.white
                        : const Color(0xFF334155),
                  ),
                  selectedColor: const Color(0xFF0F766E),
                  backgroundColor: const Color(0xFFF8FAFC),
                  side: BorderSide(
                    color: selected
                        ? const Color(0xFF0F766E)
                        : const Color(0xFFE2E8F0),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                ),
              );
            }

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(context).padding.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter Flights',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            tempStatus = 'all';
                            tempOnlyWithGate = false;
                            tempSort = 'arrival_asc';
                          });
                        },
                        child: Text(
                          'Reset',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F766E),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'Status',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF475569),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Wrap(
                    children: [
                      buildChoiceChip(
                        label: 'All',
                        selected: tempStatus == 'all',
                        onTap: () => setModalState(() => tempStatus = 'all'),
                      ),
                      buildChoiceChip(
                        label: 'Active',
                        selected: tempStatus == 'active',
                        onTap: () => setModalState(() => tempStatus = 'active'),
                      ),
                      buildChoiceChip(
                        label: 'Delayed',
                        selected: tempStatus == 'delayed',
                        onTap: () =>
                            setModalState(() => tempStatus = 'delayed'),
                      ),
                      buildChoiceChip(
                        label: 'Cancelled',
                        selected: tempStatus == 'cancelled',
                        onTap: () => setModalState(
                          () => tempStatus = 'cancelled',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Container(
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.place_outlined,
                            color: Color(0xFF15803D),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Only flights with gate assigned',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                'Hide inbound flights that do not have an arrival gate yet.',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: tempOnlyWithGate,
                          onChanged: (value) =>
                              setModalState(() => tempOnlyWithGate = value),
                          activeColor: const Color(0xFF0F766E),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 18.h),
                  Text(
                    'Sort by',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF475569),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Wrap(
                    children: [
                      buildChoiceChip(
                        label: 'Arrival Time',
                        selected: tempSort == 'arrival_asc',
                        onTap: () => setModalState(
                          () => tempSort = 'arrival_asc',
                        ),
                      ),
                      buildChoiceChip(
                        label: 'Latest First',
                        selected: tempSort == 'arrival_desc',
                        onTap: () => setModalState(
                          () => tempSort = 'arrival_desc',
                        ),
                      ),
                      buildChoiceChip(
                        label: 'Airline A-Z',
                        selected: tempSort == 'airline_asc',
                        onTap: () => setModalState(
                          () => tempSort = 'airline_asc',
                        ),
                      ),
                      buildChoiceChip(
                        label: 'Flight Number',
                        selected: tempSort == 'flight_asc',
                        onTap: () => setModalState(
                          () => tempSort = 'flight_asc',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 18.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _statusFilter = tempStatus;
                          _onlyWithGate = tempOnlyWithGate;
                          _sortOption = tempSort;
                        });
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F766E),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Apply Filters',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

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
        SizedBox(height: 16.h),
        _buildSearchAndFilterBar(context, state),
        SizedBox(height: 16.h),
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

  Widget _buildSearchAndFilterBar(BuildContext context, AirportState state) {
    return Obx(() {
      final totalFlights = state.data.length;
      final visibleFlights = _applyFilters(state.data);
      final activeCount = _activeFilterCount();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22.r),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withOpacity(0.04),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(18.r),
                    ),
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search by flight, airline, gate, ship number...',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF94A3B8),
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF64748B),
                        ),
                        suffixIcon: _searchQuery.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () => _searchController.clear(),
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 16.h),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                InkWell(
                  onTap: () => _showFilterSheet(context),
                  borderRadius: BorderRadius.circular(18.r),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 14.h,
                    ),
                    decoration: BoxDecoration(
                      color: activeCount > 0
                          ? const Color(0xFF0F766E)
                          : const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(18.r),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.tune_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        if (activeCount > 0) ...[
                          SizedBox(width: 8.w),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '$activeCount',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInfoPill(
                icon: Icons.visibility_outlined,
                label: '${visibleFlights.length} of $totalFlights visible',
                color: const Color(0xFF2563EB),
                backgroundColor: const Color(0xFFEFF6FF),
              ),
              if (_searchQuery.isNotEmpty)
                _buildInfoPill(
                  icon: Icons.search_rounded,
                  label: 'Searching "$_searchQuery"',
                  color: const Color(0xFF7C3AED),
                  backgroundColor: const Color(0xFFF5F3FF),
                ),
              if (_statusFilter != 'all')
                _buildInfoPill(
                  icon: Icons.info_outline,
                  label: _statusFilter.capitalizeFirst ?? _statusFilter,
                  color: const Color(0xFFB45309),
                  backgroundColor: const Color(0xFFFFFBEB),
                ),
              if (_onlyWithGate)
                _buildInfoPill(
                  icon: Icons.place_outlined,
                  label: 'Gate assigned',
                  color: const Color(0xFF15803D),
                  backgroundColor: const Color(0xFFF0FDF4),
                ),
              if (_activeFilterCount() > 0)
                InkWell(
                  onTap: _resetFilters,
                  borderRadius: BorderRadius.circular(999),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 2,
                    ),
                    child: Text(
                      'Clear filters',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F766E),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildInfoPill({
    required IconData icon,
    required String label,
    required Color color,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: color,
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
      final filteredFlights = _applyFilters(state.data);

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

      if (filteredFlights.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.manage_search_rounded,
                    size: 36,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No matching flights',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16.sp,
                    color: const Color(0xFF334155),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Try a different search term or clear one of the active filters.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.sp,
                    color: const Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),
                TextButton(
                  onPressed: () {
                    _searchController.clear();
                    _resetFilters();
                  },
                  child: Text(
                    'Clear search and filters',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F766E),
                    ),
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
        itemCount: filteredFlights.length,
        itemBuilder: (context, index) {
          final flight = filteredFlights[index];
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
