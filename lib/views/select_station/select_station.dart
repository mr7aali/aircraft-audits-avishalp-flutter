import 'package:avislap/views/dashboard/dashboard_screen.dart';
import 'package:avislap/widgets/parallax_hero_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/api_exception.dart';
import '../../services/app_api_service.dart';
import '../../services/session_service.dart';

class _C {
  static const Color blue = Color(0xFF3D5AFE);
  static const Color ink = Color(0xFF0E0E10);
  static const Color border = Color(0xFFEAECF2);
  static const Color placeholder = Color(0xFFC8CDD9);
  static const Color muted = Color(0xFF8891A4);
}

class _StationOption {
  const _StationOption({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;
}

class StationSelectionScreen extends StatefulWidget {
  final String userName;

  const StationSelectionScreen({
    super.key,
    this.userName = '',
  });

  @override
  State<StationSelectionScreen> createState() => _StationSelectionScreenState();
}

class _StationSelectionScreenState extends State<StationSelectionScreen> {
  final AppApiService _api = Get.find<AppApiService>();
  final SessionService _session = Get.find<SessionService>();

  String? _selectedStationId;
  String? _selectedStationLabel;
  bool _isLoading = true;
  bool _isSubmitting = false;
  List<_StationOption> _stations = const <_StationOption>[];

  String get _displayName {
    if (widget.userName.trim().isNotEmpty) {
      return widget.userName.trim();
    }
    if (_session.firstName.isNotEmpty) {
      return _session.firstName;
    }
    return 'User';
  }

  @override
  void initState() {
    super.initState();
    _loadStations();
  }

  Future<void> _loadStations() async {
    setState(() => _isLoading = true);

    try {
      final stations = await _api.getMyStations();
      final activeStation = await _api.getActiveStation();

      final mappedStations = stations.map((station) {
        final code = (station['stationCode'] as String?)?.trim() ?? '';
        final name = (station['stationName'] as String?)?.trim() ?? '';
        final label = [code, name]
            .where((part) => part.isNotEmpty)
            .join(' - ');

        return _StationOption(
          id: (station['stationId'] as String?) ?? '',
          label: label.isEmpty ? 'Assigned Station' : label,
        );
      }).where((station) => station.id.isNotEmpty).toList();

      String preselectedId = _session.activeStationId;
      if (preselectedId.isEmpty && activeStation != null) {
        preselectedId = (activeStation['stationId'] as String?) ?? '';
      }

      _StationOption? preselected;
      if (preselectedId.isNotEmpty) {
        for (final station in mappedStations) {
          if (station.id == preselectedId) {
            preselected = station;
            break;
          }
        }
      }

      if (mounted) {
        setState(() {
          _stations = mappedStations;
          _selectedStationId = preselected?.id;
          _selectedStationLabel = preselected?.label;
          _isLoading = false;
        });
      }

      if (mappedStations.length == 1 && mounted) {
        await _continueWithStation(mappedStations.first);
      }
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoading = false);
      Get.snackbar(
        'Stations Unavailable',
        error.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoading = false);
      Get.snackbar(
        'Stations Unavailable',
        'Unable to load the assigned stations right now.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _handleLogout() async {
    await _api.logout();
    if (!mounted) {
      return;
    }
    Get.offAllNamed('/login');
  }

  Future<void> _continueWithStation([_StationOption? station]) async {
    _StationOption? selected = station;
    if (selected == null && _selectedStationId != null) {
      for (final option in _stations) {
        if (option.id == _selectedStationId) {
          selected = option;
          break;
        }
      }
    }

    if (selected == null) {
      Get.snackbar(
        'Station Required',
        'Please select a station first.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (_isSubmitting) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final activeStation = await _api.selectStation(selected.id);
      _session.saveActiveStation(activeStation);

      if (!mounted) {
        return;
      }

      Get.offAll(() => const DashboardScreen());
    } on ApiException catch (error) {
      Get.snackbar(
        'Station Selection Failed',
        error.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (_) {
      Get.snackbar(
        'Station Selection Failed',
        'Unable to continue with the selected station.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showStationPicker() {
    if (_isLoading || _stations.isEmpty) {
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _buildStationSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: Column(
        children: [
          ParallaxHeroWidget(
            bottomPadding: 220,
            trailingAction: GestureDetector(
              onTap: _handleLogout,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.30),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.logout_rounded, color: Colors.white, size: 16.sp),
                    SizedBox(width: 6.w),
                    Text(
                      'Logout',
                      style: GoogleFonts.dmSans(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            child: Text(
              'Welcome, $_displayName!',
              style: GoogleFonts.dmSans(
                fontSize: 30.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.8,
                height: 1.15,
              ),
            ),
          ),
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
                  Text(
                    'Select your station to begin',
                    style: GoogleFonts.dmSans(
                      fontSize: 13.sp,
                      color: Colors.grey.shade500,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 14.h),
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
                              _isLoading
                                  ? 'Loading your stations...'
                                  : _selectedStationLabel ??
                                      (_stations.isEmpty
                                          ? 'No assigned stations'
                                          : 'Select your station'),
                              style: GoogleFonts.dmSans(
                                fontSize: 14.sp,
                                color: _selectedStationLabel != null
                                    ? _C.ink
                                    : _C.placeholder,
                              ),
                            ),
                          ),
                          _isLoading
                              ? SizedBox(
                                  width: 18.w,
                                  height: 18.w,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  Icons.search,
                                  color: _C.muted,
                                  size: 20.sp,
                                ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  GestureDetector(
                    onTap: (_isLoading || _stations.isEmpty || _isSubmitting)
                        ? null
                        : () => _continueWithStation(),
                    child: Container(
                      height: 54.h,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: (_isLoading || _stations.isEmpty)
                            ? _C.blue.withValues(alpha: 0.45)
                            : _C.blue,
                        borderRadius: BorderRadius.circular(30.r),
                      ),
                      alignment: Alignment.center,
                      child: _isSubmitting
                          ? SizedBox(
                              width: 22.w,
                              height: 22.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2.4,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
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
          Container(
            width: 40.w,
            height: 4.h,
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
          ..._stations.map(
            (station) => GestureDetector(
              onTap: () {
                setState(() {
                  _selectedStationId = station.id;
                  _selectedStationLabel = station.label;
                });
                Get.back();
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  vertical: 14.h,
                  horizontal: 16.w,
                ),
                margin: EdgeInsets.only(bottom: 8.h),
                decoration: BoxDecoration(
                  color: _selectedStationId == station.id
                      ? _C.blue.withValues(alpha: 0.08)
                      : const Color(0xFFF7F8FC),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: _selectedStationId == station.id
                        ? _C.blue.withValues(alpha: 0.4)
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  station.label,
                  style: GoogleFonts.dmSans(
                    fontSize: 14.sp,
                    color: _selectedStationId == station.id ? _C.blue : _C.ink,
                    fontWeight: _selectedStationId == station.id
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeIndicator() {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Center(
        child: Container(
          width: 134.w,
          height: 5.h,
          decoration: BoxDecoration(
            color: _C.ink.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(3.r),
          ),
        ),
      ),
    );
  }
}
