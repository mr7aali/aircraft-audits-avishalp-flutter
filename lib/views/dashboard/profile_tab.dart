import 'package:avislap/healper/route.dart';
import 'package:avislap/services/api_exception.dart';
import 'package:avislap/services/app_api_service.dart';
import 'package:avislap/services/session_service.dart';
import 'package:avislap/utils/app_colors.dart';
import 'package:avislap/utils/app_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final AppApiService _api = Get.find<AppApiService>();
  final SessionService _session = Get.find<SessionService>();
  final TextEditingController _firstNameCtrl = TextEditingController();
  final TextEditingController _lastNameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isLoggingOut = false;
  Map<String, dynamic> _profile = const <String, dynamic>{};

  void _handleDraftChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _firstNameCtrl.addListener(_handleDraftChanged);
    _lastNameCtrl.addListener(_handleDraftChanged);
    _emailCtrl.addListener(_handleDraftChanged);
    _phoneCtrl.addListener(_handleDraftChanged);
    _hydrateFromSession();
    _loadProfile();
  }

  @override
  void dispose() {
    _firstNameCtrl.removeListener(_handleDraftChanged);
    _lastNameCtrl.removeListener(_handleDraftChanged);
    _emailCtrl.removeListener(_handleDraftChanged);
    _phoneCtrl.removeListener(_handleDraftChanged);
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile({bool showLoader = true}) async {
    if (showLoader && mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final profile = await _api.getMyProfile();
      _applyProfile(profile, persistToSession: true);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      Get.snackbar(
        'Profile Unavailable',
        error.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      Get.snackbar(
        'Profile Unavailable',
        'Unable to load your profile right now.',
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

  Future<void> _saveProfile() async {
    final firstName = _firstNameCtrl.text.trim();
    final lastName = _lastNameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    if (firstName.isEmpty || lastName.isEmpty || email.isEmpty) {
      Get.snackbar(
        'Missing Information',
        'First name, last name, and email are required.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (_isSaving) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updated = await _api.updateMyProfile({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phone': phone,
      });
      _applyProfile(updated, persistToSession: true);

      if (!mounted) {
        return;
      }
      Get.snackbar(
        'Profile Updated',
        'Your profile changes have been saved.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.green,
        colorText: Colors.white,
      );
    } on ApiException catch (error) {
      Get.snackbar(
        'Save Failed',
        error.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (_) {
      Get.snackbar(
        'Save Failed',
        'Unable to save profile changes right now.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

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

    if (!confirmed) {
      return;
    }

    setState(() => _isLoggingOut = true);

    await _api.logout();

    if (!mounted) {
      return;
    }

    Get.offAllNamed(RouteHelper.login);
  }

  void _hydrateFromSession() {
    final user = _session.user;
    if (user == null) {
      return;
    }
    _applyProfile(user, persistToSession: false);
  }

  void _applyProfile(
    Map<String, dynamic> profile, {
    required bool persistToSession,
  }) {
    _profile = Map<String, dynamic>.from(profile);
    _firstNameCtrl.text = (_profile['firstName'] as String?)?.trim() ?? '';
    _lastNameCtrl.text = (_profile['lastName'] as String?)?.trim() ?? '';
    _emailCtrl.text = (_profile['email'] as String?)?.trim() ?? '';
    _phoneCtrl.text = (_profile['phone'] as String?)?.trim() ?? '';

    if (persistToSession) {
      final merged = {
        ...?_session.user,
        ..._profile,
      };
      _session.saveUser(merged);
    }

    if (mounted) {
      setState(() {});
    }
  }

  String get _fullName {
    final parts = [
      _firstNameCtrl.text.trim(),
      _lastNameCtrl.text.trim(),
    ].where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) {
      return 'Employee';
    }
    return parts.join(' ');
  }

  String get _initials {
    final parts = _fullName.split(' ').where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  String? get _profileImageFileId =>
      (_profile['profileImageFileId'] as String?)?.trim();

  String get _memberSinceLabel {
    final raw = _profile['createdAt']?.toString();
    if (raw == null || raw.isEmpty) {
      return 'Not available';
    }

    final parsed = DateTime.tryParse(raw)?.toLocal();
    if (parsed == null) {
      return 'Not available';
    }

    return DateFormat('dd MMM yyyy').format(parsed);
  }

  String get _lastSeenLabel {
    final raw = _profile['lastSeenAt']?.toString();
    if (raw == null || raw.isEmpty) {
      return 'Unavailable';
    }

    final parsed = DateTime.tryParse(raw)?.toLocal();
    if (parsed == null) {
      return 'Unavailable';
    }

    return DateFormat('dd MMM yyyy, hh:mm a').format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: RefreshIndicator(
        color: AppColors.mainAppColor,
        onRefresh: () => _loadProfile(showLoader: false),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              _buildHeroCard(),
              const SizedBox(height: 18),
              _buildQuickStats(),
              const SizedBox(height: 18),
              _buildDetailsCard(),
              const SizedBox(height: 18),
              _buildActionsCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          'Profile',
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.dark,
        ),
        const SizedBox(height: 6),
        AppText(
          'Keep your personal details up to date.',
          fontSize: 14,
          color: AppColors.from_heading,
        ),
      ],
    );
  }

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1D4ED8), Color(0xFF2563EB), Color(0xFF60A5FA)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.mainAppColor.withValues(alpha: 0.20),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildAvatar(size: 72),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _fullName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      (_profile['uid'] as String?)?.trim().isNotEmpty ?? false
                          ? 'User ID: ${_profile['uid']}'
                          : 'Account profile',
                      style: GoogleFonts.dmSans(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        (_profile['status'] as String?)?.trim().isNotEmpty ??
                                false
                            ? (_profile['status'] as String).replaceAll('_', ' ')
                            : 'ACTIVE',
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.email_outlined,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _emailCtrl.text.trim().isNotEmpty
                        ? _emailCtrl.text.trim()
                        : 'No email available',
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _InfoChip(
            title: 'Member Since',
            value: _memberSinceLabel,
            icon: Icons.calendar_today_outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _InfoChip(
            title: 'Last Active',
            value: _lastSeenLabel,
            icon: Icons.schedule_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Details',
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Update your core account information here.',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: AppColors.from_heading,
            ),
          ),
          const SizedBox(height: 18),
          _buildField(
            label: 'First Name',
            controller: _firstNameCtrl,
            icon: Icons.person_outline,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),
          _buildField(
            label: 'Last Name',
            controller: _lastNameCtrl,
            icon: Icons.badge_outlined,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),
          _buildField(
            label: 'Email',
            controller: _emailCtrl,
            icon: Icons.alternate_email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),
          _buildField(
            label: 'Phone',
            controller: _phoneCtrl,
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSaving ? null : _saveProfile,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.mainAppColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Save Changes',
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _ActionTile(
            icon: Icons.refresh_rounded,
            title: 'Refresh Profile',
            subtitle: 'Fetch the latest profile details from the server.',
            onTap: () => _loadProfile(showLoader: false),
          ),
          _ActionTile(
            icon: Icons.logout_rounded,
            title: 'Log Out',
            subtitle: 'Securely sign out from this device.',
            isDestructive: true,
            trailing: _isLoggingOut
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            onTap: _isLoggingOut ? null : _logout,
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.mainAppColor,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.from_heading),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            hintText: 'Enter $label',
            hintStyle: GoogleFonts.dmSans(
              color: AppColors.from_heading.withValues(alpha: 0.75),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(
                color: AppColors.border.withValues(alpha: 0.65),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(
                color: AppColors.mainAppColor,
                width: 1.4,
              ),
            ),
          ),
          style: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.dark,
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar({required double size}) {
    final fileId = _profileImageFileId;
    final hasImage = fileId != null && fileId.isNotEmpty;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? Image.network(
              _api.buildFileContentUrl(fileId),
              headers: _api.buildImageHeaders(),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _buildAvatarFallback(),
            )
          : _buildAvatarFallback(),
    );
  }

  Widget _buildAvatarFallback() {
    return Center(
      child: Text(
        _initials,
        style: GoogleFonts.dmSans(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.mainAppColor, size: 18),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.from_heading,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool isDestructive;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.red : AppColors.mainAppColor;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.dmSans(
          fontWeight: FontWeight.w700,
          color: isDestructive ? AppColors.red : AppColors.dark,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.dmSans(
          fontSize: 12.5,
          color: AppColors.from_heading,
        ),
      ),
      trailing:
          trailing ??
          Icon(Icons.chevron_right_rounded, color: AppColors.from_heading),
      onTap: onTap,
    );
  }
}
