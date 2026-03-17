import 'package:avislap/utils/app_colors.dart';
import 'package:avislap/views/forms/cabin%20security%20search/training_filter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../services/api_exception.dart';
import '../../../services/app_api_service.dart';
import 'LAVSafety.dart';

class _Colors {
  static const Color primary = Color(0xFF3D5AFE);
  static const Color background = Color(0xFFF5F6FA);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1A1A2E);
  static const Color textGrey = Color(0xFF9E9E9E);
  static const Color dotColor = Color(0xFF9E9E9E);
  static const Color namePrimary = Color(0xFF3D5AFE);
  static const Color divider = Color(0xFFEEEEEE);
  static const Color newObservationBtn = Color(0xFF3D5AFE);
}

class ObservationItem {
  final String id;
  final String observerName;
  final String observerImage;
  final String date;
  final String time;
  final String gate;
  final String driverName;
  final String locationImage;
  final String locationImage2;

  ObservationItem({
    required this.id,
    required this.observerName,
    required this.observerImage,
    required this.date,
    required this.time,
    required this.gate,
    required this.driverName,
    required this.locationImage,
    required this.locationImage2,
  });
}

class LavSafetyController extends GetxController {
  final AppApiService _api = Get.find<AppApiService>();

  final RxList<ObservationItem> observations = <ObservationItem>[].obs;
  final RxBool isLoading = false.obs;
  final RxString filterName = ''.obs;
  final RxString filterFromDate = ''.obs;
  final RxString filterToDate = ''.obs;

  static const List<String> _avatarPool = [
    'assets/images/nirob.jpg',
    'assets/images/mursalin.jpg',
    'assets/images/Bessie.png',
    'assets/images/Esther.png',
  ];

  @override
  void onInit() {
    super.onInit();
    loadObservations();
  }

  Future<void> loadObservations() async {
    isLoading.value = true;
    try {
      final result = await _api.listLavSafetyObservations(
        queryParameters: {
          'auditorName': filterName.value,
          'fromDate': _toApiDate(filterFromDate.value),
          'toDate': _toApiDate(filterToDate.value, endOfDay: true),
        },
      );

      final items = (result['items'] as List<dynamic>? ?? const [])
          .map((entry) => entry is Map<String, dynamic> ? entry : <String, dynamic>{})
          .toList();

      observations.assignAll(
        List<ObservationItem>.generate(items.length, (index) {
          final item = items[index];
          final observedAtRaw = item['observedAt'] as String? ?? '';
          final observedAt = DateTime.tryParse(observedAtRaw)?.toLocal();
          final date = observedAt != null
              ? DateFormat('MMM d, y').format(observedAt)
              : '--';
          final time = observedAt != null
              ? DateFormat('h:mm a').format(observedAt)
              : '--';

          return ObservationItem(
            id: item['id'] as String? ?? '',
            observerName: item['auditorName'] as String? ?? 'Unknown Auditor',
            observerImage: _avatarPool[index % _avatarPool.length],
            date: date,
            time: time,
            gate: item['gateCode'] as String? ?? 'Unknown Gate',
            driverName: item['driverName'] as String? ?? 'Unknown Driver',
            locationImage: 'assets/images/indor.png',
            locationImage2: 'assets/images/window.png',
          );
        }),
      );
    } on ApiException catch (error) {
      observations.clear();
      Get.snackbar(
        'Load Failed',
        error.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (_) {
      observations.clear();
      Get.snackbar(
        'Load Failed',
        'Unable to load LAV safety observations right now.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> applyFilter({
    required String name,
    required String fromDate,
    required String toDate,
  }) async {
    filterName.value = name;
    filterFromDate.value = fromDate;
    filterToDate.value = toDate;
    await loadObservations();
  }

  String? _toApiDate(String value, {bool endOfDay = false}) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final parts = trimmed.split('/');
    if (parts.length != 3) {
      return null;
    }

    final month = int.tryParse(parts[0]);
    final day = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (month == null || day == null || year == null) {
      return null;
    }

    final date = DateTime(
      year,
      month,
      day,
      endOfDay ? 23 : 0,
      endOfDay ? 59 : 0,
      endOfDay ? 59 : 0,
    );

    return date.toIso8601String();
  }
}

class LavSafetyObservationScreen extends StatefulWidget {
  const LavSafetyObservationScreen({super.key});

  @override
  State<LavSafetyObservationScreen> createState() =>
      _LavSafetyObservationScreenState();
}

class _LavSafetyObservationScreenState
    extends State<LavSafetyObservationScreen> {
  late final LavSafetyController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(LavSafetyController());
  }

  Future<void> _showFilterSheet() async {
    final result = await Get.bottomSheet<Map<String, dynamic>>(
      const NewSearchSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );

    if (result == null) {
      return;
    }

    await controller.applyFilter(
      name: result['name'] as String? ?? '',
      fromDate: result['fromDate'] as String? ?? '',
      toDate: result['toDate'] as String? ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Colors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(),
                    SizedBox(height: 12.h),
                    _buildObservationList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Icon(Icons.arrow_back, color: _Colors.primary, size: 22.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'LAV Safety Observation',
              style: GoogleFonts.poppins(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: _Colors.primary,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.tune_rounded,
              color: AppColors.mainAppColor,
              size: 24.sp,
            ),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 4.w,
              height: 22.h,
              decoration: BoxDecoration(
                color: _Colors.primary,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(width: 10.w),
            Text(
              'Past Observations',
              style: GoogleFonts.poppins(
                fontSize: 17.sp,
                fontWeight: FontWeight.w700,
                color: _Colors.textDark,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () => Get.to(() => LAVSafetyScreen()),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: _Colors.newObservationBtn,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              'New Observation',
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildObservationList() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(child: CircularProgressIndicator()),
        );
      }

      if (controller.observations.isEmpty) {
        return Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 40.h),
            child: Text(
              'No observations found',
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                color: AppColors.textGrey,
              ),
            ),
          ),
        );
      }

      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: controller.observations.length,
        separatorBuilder: (_, _) =>
            Divider(height: 1, color: _Colors.divider, indent: 0),
        itemBuilder: (context, index) {
          return _buildObservationCard(controller.observations[index]);
        },
      );
    });
  }

  Widget _buildObservationCard(ObservationItem item) {
    return Container(
      color: _Colors.cardBg,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                padding: EdgeInsets.all(3.r),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF3D5AFE),
                    width: 2.5.w,
                  ),
                ),
                child: CircleAvatar(
                  radius: 26.r,
                  backgroundImage: AssetImage(item.observerImage),
                  backgroundColor: Colors.grey.shade200,
                  onBackgroundImageError: (_, _) {},
                ),
              ),
              Positioned(
                right: 2,
                bottom: 2,
                child: Container(
                  width: 13.w,
                  height: 13.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1DB954),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 5.h),
                Text(
                  item.observerName,
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: _Colors.namePrimary,
                  ),
                ),
                SizedBox(height: 10.h),
                Row(
                  children: [
                    Text(
                      item.date,
                      style: GoogleFonts.poppins(
                        fontSize: 11.sp,
                        color: _Colors.textGrey,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 5.w),
                      child: Container(
                        width: 4.w,
                        height: 4.h,
                        decoration: const BoxDecoration(
                          color: _Colors.dotColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Text(
                      item.time,
                      style: GoogleFonts.poppins(
                        fontSize: 11.sp,
                        color: _Colors.textGrey,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                Text(
                  item.gate,
                  style: GoogleFonts.poppins(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: _Colors.textDark,
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  'Driver: ${item.driverName}',
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    color: _Colors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: Image.asset(
                  item.locationImage,
                  width: 64.w,
                  height: 60.h,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 64.w,
                    height: 60.h,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      Icons.image_outlined,
                      color: Colors.grey.shade400,
                      size: 24.sp,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 6.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: Image.asset(
                  item.locationImage2,
                  width: 64.w,
                  height: 60.h,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 64.w,
                    height: 60.h,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      Icons.image_outlined,
                      color: Colors.grey.shade400,
                      size: 24.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
