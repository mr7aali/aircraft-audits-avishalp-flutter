import 'package:get_storage/get_storage.dart';

class SessionService {
  SessionService();

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _rememberMeKey = 'remember_me';
  static const _userKey = 'session_user';
  static const _stationKey = 'active_station';
  static const _passwordRecoveryTokenKey = 'password_recovery_token';
  static const _passwordRecoveryEmailKey = 'password_recovery_email';

  final GetStorage _box = GetStorage();

  Future<SessionService> init() async => this;

  String? get accessToken => _box.read<String>(_accessTokenKey);

  String? get refreshToken => _box.read<String>(_refreshTokenKey);

  bool get rememberMe => _box.read<bool>(_rememberMeKey) ?? false;

  bool get isLoggedIn =>
      (accessToken?.isNotEmpty ?? false) && (refreshToken?.isNotEmpty ?? false);

  Map<String, dynamic>? get user => _readMap(_userKey);

  Map<String, dynamic>? get activeStation => _readMap(_stationKey);
  String? get passwordRecoveryToken =>
      _box.read<String>(_passwordRecoveryTokenKey);
  String? get passwordRecoveryEmail =>
      _box.read<String>(_passwordRecoveryEmailKey);

  String get firstName => (user?['firstName'] as String?)?.trim() ?? '';

  String get fullName {
    final first = (user?['firstName'] as String?)?.trim() ?? '';
    final last = (user?['lastName'] as String?)?.trim() ?? '';
    return [first, last].where((part) => part.isNotEmpty).join(' ');
  }

  String get activeStationId =>
      (activeStation?['stationId'] as String?)?.trim() ?? '';

  String get activeRoleCode =>
      (activeStation?['roleCode'] as String?)?.trim().toUpperCase() ?? '';

  String get activeRoleName =>
      (activeStation?['roleName'] as String?)?.trim().toUpperCase() ?? '';

  bool get isEmployeeRole =>
      activeRoleCode == 'EMPLOYEE' || activeRoleName == 'EMPLOYEE';

  void saveAuth({
    required String accessToken,
    required String refreshToken,
    required bool rememberMe,
  }) {
    _box.write(_accessTokenKey, accessToken);
    _box.write(_refreshTokenKey, refreshToken);
    _box.write(_rememberMeKey, rememberMe);
  }

  void saveUser(Map<String, dynamic>? value) {
    if (value == null) {
      _box.remove(_userKey);
      return;
    }
    _box.write(_userKey, value);
  }

  void saveActiveStation(Map<String, dynamic>? value) {
    if (value == null) {
      _box.remove(_stationKey);
      return;
    }
    _box.write(_stationKey, value);
  }

  void savePasswordRecovery({required String token, required String email}) {
    _box.write(_passwordRecoveryTokenKey, token);
    _box.write(_passwordRecoveryEmailKey, email);
  }

  void clearPasswordRecovery() {
    _box.remove(_passwordRecoveryTokenKey);
    _box.remove(_passwordRecoveryEmailKey);
  }

  void clear() {
    _box.remove(_accessTokenKey);
    _box.remove(_refreshTokenKey);
    _box.remove(_rememberMeKey);
    _box.remove(_userKey);
    _box.remove(_stationKey);
    clearPasswordRecovery();
  }

  Map<String, dynamic>? _readMap(String key) {
    final raw = _box.read(key);
    if (raw is Map) {
      return raw.map((mapKey, value) => MapEntry(mapKey.toString(), value));
    }
    return null;
  }
}
