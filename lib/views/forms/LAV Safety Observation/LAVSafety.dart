import 'dart:io';

import 'package:avislap/utils/app_colors.dart';
import 'package:avislap/utils/app_icons.dart';
import 'package:avislap/utils/app_text.dart';
import 'package:avislap/widgets/app_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:signature/signature.dart';

import '../../../services/api_exception.dart';
import '../../../services/app_api_service.dart';
import '../../../services/session_service.dart';
import 'LavSafetyObservationScreen.dart';

class LAVSafetyScreen extends StatefulWidget {
  @override
  State<LAVSafetyScreen> createState() => _LAVSafetyScreenState();
}

class _LAVSafetyScreenState extends State<LAVSafetyScreen> {
  static const Map<String, String> _questionLabelsByKey = {
    'chocks': 'Used Chocks',
    'safety_stop': 'Safety Stop',
    'guide_cone': 'Used Guide Cone',
    'mask': 'Face Mask',
    'gloves': 'Gloves',
    'shoes': 'Shoes',
    'dump': 'Dump',
    'flush': 'Flush',
    'fill': 'Fill',
    'walkaround': '360 Walk Around',
    'chock_removal': 'Chock Removal Process',
  };

  final AppApiService _api = Get.find<AppApiService>();
  final SessionService _session = Get.find<SessionService>();
  bool _isLoading = true;
  bool _isSubmitting = false;
  List<Map<String, dynamic>> _gates = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _checklistItems = <Map<String, dynamic>>[];
  List<String> _gateOptions = const ['Please Select One'];
  // ── step: 0 = Job Details, 1 = Checklist, 2 = Notes/Submit
  int _step = 0;

  // ── Step 0 fields
  final _supervisorCtrl = TextEditingController();
  final _driverCtrl = TextEditingController();
  final _shipCtrl = TextEditingController();
  String _selectedGate = 'Please Select One';

  // ── Step 1 — checklist
  final Map<String, String?> _selectedValues = {};
  final Map<String, List<File>> _uploadedImages = {};
  final ImagePicker _picker = ImagePicker();

  // ── Step 2 — notes + pictures
  final _otherFindingsCtrl = TextEditingController();
  final _additionalCtrl = TextEditingController();
  final List<File> _step2Images = [];

  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  static const double _cardRadius = 16;
  static const double _inputRadius = 12;

  // ─────────────────────────────────────────────
  static String _formatCurrentDate() {
    final now = DateTime.now();
    return '${now.month.toString().padLeft(2, '0')}/'
        '${now.day.toString().padLeft(2, '0')}/${now.year}';
  }

  Future<void> _pickImagesFor(String key) async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _uploadedImages[key] = [
          ...(_uploadedImages[key] ?? []),
          ...images.map((img) => File(img.path)),
        ];
      });
    }
  }

  Future<void> _pickStep2Images() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _step2Images.addAll(images.map((img) => File(img.path)));
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _supervisorCtrl.text = _session.fullName;
    _loadFormData();
  }

  @override
  void dispose() {
    _supervisorCtrl.dispose();
    _driverCtrl.dispose();
    _shipCtrl.dispose();
    _otherFindingsCtrl.dispose();
    _additionalCtrl.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _loadFormData() async {
    setState(() => _isLoading = true);
    try {
      final stationId = _session.activeStationId;
      final results = await Future.wait([
        _api.getLavSafetyChecklistItems(),
        if (stationId.isNotEmpty) _api.getGates(stationId) else Future.value([]),
      ]);

      _checklistItems = List<Map<String, dynamic>>.from(results[0]);
      _gates = List<Map<String, dynamic>>.from(results[1]);
      _gateOptions = [
        'Please Select One',
        ..._gates.map((gate) => (gate['gateCode'] as String?) ?? 'Unknown Gate'),
      ];
    } catch (error) {
      final message = error is ApiException
          ? error.message
          : 'Unable to load the LAV checklist right now.';
      Get.snackbar(
        'Load Failed',
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _normalizeLabel(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }

  Map<String, dynamic>? _findChecklistItem(String label) {
    final normalizedTarget = _normalizeLabel(label);
    for (final item in _checklistItems) {
      final itemLabel = (item['label'] as String?) ?? '';
      if (_normalizeLabel(itemLabel) == normalizedTarget) {
        return item;
      }
    }
    return null;
  }

  Map<String, dynamic>? _selectedGateRecord() {
    if (_selectedGate == 'Please Select One') {
      return null;
    }
    for (final gate in _gates) {
      if ((gate['gateCode'] as String?) == _selectedGate) {
        return gate;
      }
    }
    return null;
  }

  bool _validateStep0() {
    if (_driverCtrl.text.trim().isEmpty || _shipCtrl.text.trim().isEmpty) {
      Get.snackbar(
        'Incomplete',
        'Please complete the driver and ship details before continuing.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    if (_selectedGateRecord() == null) {
      Get.snackbar(
        'Incomplete',
        'Please select a gate before continuing.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    return true;
  }

  bool _validateStep1() {
    for (final key in _questionLabelsByKey.keys) {
      if ((_selectedValues[key] ?? '').isEmpty) {
        Get.snackbar(
          'Incomplete',
          'Please mark Pass or Fail for every checklist item.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
    }
    return true;
  }

  Future<List<String>> _uploadFiles(List<File> files, String category) async {
    final fileIds = <String>[];
    for (final file in files) {
      final uploaded = await _api.uploadFile(file, category: category);
      final fileId = uploaded['id'] as String?;
      if (fileId != null && fileId.isNotEmpty) {
        fileIds.add(fileId);
      }
    }
    return fileIds;
  }

  Future<String> _uploadSignature() async {
    final bytes = await _signatureController.toPngBytes();
    if (bytes == null || bytes.isEmpty) {
      throw const ApiException('A signature is required before submission.');
    }

    final tempDir = await getTemporaryDirectory();
    final file = File(
      '${tempDir.path}/lav-signature-${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(bytes, flush: true);

    final uploaded = await _api.uploadFile(file, category: 'SIGNATURE');
    final fileId = uploaded['id'] as String?;
    if (fileId == null || fileId.isEmpty) {
      throw const ApiException('Unable to upload the signature.');
    }

    return fileId;
  }

  String _buildAdditionalNotes() {
    final supervisor = _supervisorCtrl.text.trim();
    final notes = _additionalCtrl.text.trim();
    if (supervisor.isEmpty) {
      return notes;
    }
    if (notes.isEmpty) {
      return 'Supervisor/Lead: $supervisor';
    }
    return 'Supervisor/Lead: $supervisor\n$notes';
  }

  Future<void> _submitReport() async {
    if (_isSubmitting) {
      return;
    }
    if (!_validateStep1()) {
      return;
    }
    if (_selectedGateRecord() == null) {
      Get.snackbar(
        'Incomplete',
        'Please return to the first step and select a gate.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final gate = _selectedGateRecord();
      final signatureFileId = await _uploadSignature();
      final generalPictureFileIds = await _uploadFiles(_step2Images, 'IMAGE');

      final responses = <Map<String, dynamic>>[];
      for (final entry in _questionLabelsByKey.entries) {
        final checklistItem = _findChecklistItem(entry.value);
        if (checklistItem == null) {
          throw ApiException('Missing checklist mapping for "${entry.value}".');
        }

        final selectedValue = (_selectedValues[entry.key] ?? '').toUpperCase();
        if (selectedValue.isEmpty) {
          throw ApiException('Every checklist item must be marked.');
        }

        final imageFileIds = await _uploadFiles(
          _uploadedImages[entry.key] ?? const <File>[],
          'IMAGE',
        );

        responses.add({
          'checklistItemId': checklistItem['id'],
          'response': selectedValue == 'PASS' ? 'PASS' : 'FAIL',
          'imageFileIds': imageFileIds,
        });
      }

      await _api.createLavSafetyObservation({
        'driverName': _driverCtrl.text.trim(),
        'shipNumber': _shipCtrl.text.trim(),
        'gateId': gate?['id'],
        'responses': responses,
        'signatureFileId': signatureFileId,
        'otherFindings': _otherFindingsCtrl.text.trim(),
        'additionalNotes': _buildAdditionalNotes(),
        'generalPictureFileIds': generalPictureFileIds,
      });

      if (!mounted) {
        return;
      }

      Get.snackbar(
        "Success",
        "LAV Safety Report Sent Successfully",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      Get.off(() => const LavSafetyObservationScreen());
    } on ApiException catch (error) {
      Get.snackbar(
        'Submission Failed',
        error.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (_) {
      Get.snackbar(
        'Submission Failed',
        'Unable to submit the LAV safety report right now.',
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

  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.mainAppColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () =>
              _step > 0 ? setState(() => _step--) : Navigator.pop(context),
        ),
        title: AppText(
          "LAV Safety Observation",
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: Colors.white),
            onPressed: () => _showInstructions(context),
          ),
        ],
      ),
      body: SafeArea(
        top: true,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _step == 0
            ? _buildStep0()
            : _step == 1
            ? _buildStep1()
            : _buildStep2(),
      ),
    );
  }

  // ══════════════════════════════════════════════
  // STEP 0 — Job Details
  // ══════════════════════════════════════════════
  Widget _buildStep0() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: _buildSectionCard(
              children: [
                _buildRequiredLabel("Date and Time"),
                _buildReadOnlyDateField(),
                _buildRequiredLabel("Supervisor/Lead"),
                _buildTextField(
                  "Enter supervisor or lead name",
                  controller: _supervisorCtrl,
                ),
                _buildRequiredLabel("Driver"),
                _buildTextField("Enter Driver's Name", controller: _driverCtrl),
                _buildRequiredLabel("Ship"),
                _buildTextField("Enter Ship Number", controller: _shipCtrl),
                _buildRequiredLabel("Gate"),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: AppDropdown(
                    hint: "Please Select One",
                    items: _gateOptions,
                    value: _selectedGate,
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() => _selectedGate = value);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildNextButton(() {
          if (_validateStep0()) {
            setState(() => _step = 1);
          }
        }),
      ],
    );
  }

  // ══════════════════════════════════════════════
  // STEP 1 — Inspection Checklist
  // ══════════════════════════════════════════════
  Widget _buildStep1() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // "Inspection Checklist" heading
                AppText(
                  "Inspection Checklist",
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.mainAppColor,
                ),
                const SizedBox(height: 20),

                _buildSectionCard(
                  children: [
                    _buildAuditRow(
                      "Used Chocks",
                      "chocks",
                      showImageUpload: true,
                    ),
                    _buildAuditRow(
                      "Safety Stop",
                      "safety_stop",
                      subtitle:
                          "Checking if breaks are functional before approaching to aircraft",
                      showImageUpload: true,
                    ),
                    _buildAuditRow(
                      "Used Guide Cone",
                      "guide_cone",
                      subtitle:
                          "Placing guide code near panel before reversing LAV truck near aircraft",
                      showImageUpload: true,
                    ),
                    _buildAuditRow(
                      "Face Mask",
                      "mask",
                      subtitle: "Was Face Mask used while servicing aircraft?",
                      showImageUpload: true,
                    ),
                    _buildAuditRow(
                      "Gloves",
                      "gloves",
                      subtitle: "Was agent using gloves to service?",
                      showImageUpload: true,
                    ),
                    _buildAuditRow(
                      "Shoes",
                      "shoes",
                      subtitle: "Was agent wearing proper shoes and clothing?",
                      showImageUpload: true,
                    ),
                    _buildAuditRow(
                      "Dump",
                      "dump",
                      subtitle: "Was the aircraft Dumped?",
                      showImageUpload: true,
                    ),
                    _buildAuditRow(
                      "Flush",
                      "flush",
                      subtitle:
                          "Was the aircraft Flushed with required amount of blue juice?",
                      showImageUpload: true,
                    ),
                    _buildAuditRow(
                      "Fill",
                      "fill",
                      subtitle:
                          "Was the Aircraft filled with the required amount of Blue Juice?",
                      showImageUpload: true,
                    ),
                    _buildAuditRow(
                      "360 Walk Around",
                      "walkaround",
                      subtitle:
                          "LAV Driver Walks around LAV Truck to make sure the truck is clear to move...",
                      showImageUpload: true,
                    ),
                    _buildAuditRow(
                      "Chock Removal Process",
                      "chock_removal",
                      subtitle:
                          "LAV Driver Takes out forward check and drives up 10 feet before coming back...",
                      isLast: true,
                      showImageUpload: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        _buildNextButton(() {
          if (_validateStep1()) {
            setState(() => _step = 2);
          }
        }),
      ],
    );
  }

  // ══════════════════════════════════════════════
  // STEP 2 — Other Findings + Notes + Pictures
  // ══════════════════════════════════════════════
  Widget _buildStep2() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: _buildSectionCard(
              children: [
                _buildNoteField(
                  "Other Findings",
                  "Enter any additional findings or notes...",
                  controller: _otherFindingsCtrl,
                ),
                _buildNoteField(
                  "Additional Notes",
                  "Enter any additional findings or notes...",
                  controller: _additionalCtrl,
                ),
                const SizedBox(height: 4),
                AppText(
                  "Pictures",
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainAppColor,
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickStep2Images,
                  child: _buildUploadBox(),
                ),
                if (_step2Images.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _step2Images.map((file) {
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              file,
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 3,
                            right: 3,
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _step2Images.remove(file)),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 16),
                // Beautiful Signature Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.draw_rounded,
                                color: AppColors.mainAppColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Digital Signature',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const Text(
                                ' *',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => _signatureController.clear(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Clear',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            border: Border.all(
                              color: AppColors.mainAppColor.withOpacity(0.3),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Center(
                                  child: Text(
                                    'Sign Here',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.withOpacity(0.3),
                                    ),
                                  ),
                                ),
                              ),
                              Signature(
                                controller: _signatureController,
                                height: 140,
                                backgroundColor: Colors.transparent,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Submit button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.mainAppColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_inputRadius),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      "Send Report",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // SHARED WIDGETS
  // ─────────────────────────────────────────────

  Widget _buildAuditRow(
    String title,
    String key, {
    String? subtitle,
    bool showImageUpload = false,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRequiredLabel(title),
          if (subtitle != null) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppText(subtitle, fontSize: 13, color: AppColors.grey),
            ),
          ] else
            const SizedBox(height: 8),

          // Pass / Fail — 2 buttons (N/A removed)
          Row(
            children: [
              _auditChip(key, "Pass", AppIcons.correct, AppColors.green),
              const SizedBox(width: 8),
              _auditChip(key, "Fail", AppIcons.cancel, AppColors.red),
            ],
          ),

          if (showImageUpload) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _pickImagesFor(key),
              child: _buildUploadBox(),
            ),
            // thumbnails
            if ((_uploadedImages[key] ?? []).isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (_uploadedImages[key] ?? []).map((file) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          file,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () => setState(
                            () => _uploadedImages[key]!.remove(file),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // Pass / Fail chip (with svg icon)
  Widget _auditChip(String key, String value, String svgIcon, Color color) {
    bool isSelected = _selectedValues[key] == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedValues[key] = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.12)
                : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(_inputRadius),
            border: Border.all(
              color: isSelected ? color : AppColors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                svgIcon,
                width: 16,
                height: 16,
                colorFilter: ColorFilter.mode(
                  isSelected ? color : AppColors.grey,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 5),
              AppText(
                value,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? color : AppColors.from_heading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequiredLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText(
            text,
            fontWeight: FontWeight.w600,
            color: AppColors.mainAppColor,
            fontSize: 14,
          ),
          const Text(
            " *",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.red,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyDateField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      margin: const EdgeInsets.only(bottom: 16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _formatCurrentDate(),
              style: TextStyle(color: AppColors.dark, fontSize: 15),
            ),
          ),
          Icon(Icons.calendar_month_outlined, color: AppColors.grey, size: 20),
        ],
      ),
    );
  }

  Widget _buildSectionCard({String? title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null && title.isNotEmpty) ...[
            AppText(
              title,
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.dark,
            ),
            const SizedBox(height: 16),
          ],
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(String hint, {TextEditingController? controller}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: AppColors.from_heading.withValues(alpha: 0.8),
          ),
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: AppColors.mainAppColor, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildNoteField(
    String label,
    String hint, {
    TextEditingController? controller,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            label,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.mainAppColor,
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: AppColors.from_heading.withValues(alpha: 0.8),
              ),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(_inputRadius),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(_inputRadius),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(_inputRadius),
                borderSide: BorderSide(
                  color: AppColors.mainAppColor,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadBox() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_upload_outlined, color: AppColors.grey, size: 20),
          const SizedBox(width: 8),
          Text(
            "Upload an image",
            style: TextStyle(color: AppColors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton(VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.mainAppColor,
            borderRadius: BorderRadius.circular(30),
          ),
          alignment: Alignment.center,
          child: const Text(
            'NEXT',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  void _showInstructions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: AppColors.mainAppColor,
              size: 26,
            ),
            const SizedBox(width: 10),
            Text(
              "Instructions",
              style: TextStyle(
                color: AppColors.mainAppColor,
                fontWeight: FontWeight.w500,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Conduct the LAV Audit as you observe the Drivers, don\'t wait till the end of the shift to submit.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.dark,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Please submit this with as much detail as possible 2 Observations per Shift',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.dark,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Take pictures of the Driver following the proper procedures.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.mainAppColor,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "OK",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.mainAppColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
