import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import 'api_exception.dart';
import 'cloudinary_upload_service.dart';
import 'session_service.dart';

class AppApiService {
  AppApiService({
    http.Client? client,
    SessionService? sessionService,
    CloudinaryUploadService? cloudinaryUploadService,
  }) : _client = client ?? http.Client(),
       _sessionService = sessionService ?? Get.find<SessionService>(),
       _cloudinaryUploadService =
           cloudinaryUploadService ?? CloudinaryUploadService();

  final http.Client _client;
  final SessionService _sessionService;
  final CloudinaryUploadService _cloudinaryUploadService;
  Completer<bool>? _refreshCompleter;

  static String get baseUrl {
    const configured = String.fromEnvironment('API_BASE_URL');
    if (configured.isNotEmpty) {
      return _normalizeBaseUrl(configured);
    }

    final defaultHost = kReleaseMode
        ? 'https://sensitive-united-contracts-governor.trycloudflare.com/api'
        : !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? 'https://sensitive-united-contracts-governor.trycloudflare.com/api'
        : 'https://sensitive-united-contracts-governor.trycloudflare.com/api';
    return _normalizeBaseUrl(defaultHost);
  }

  static String _normalizeBaseUrl(String value) {
    return value.endsWith('/') ? value : '$value/';
  }

  Uri buildUri(String endpoint, {Map<String, dynamic>? queryParameters}) {
    final baseUri = Uri.parse(baseUrl);
    final uri = baseUri.resolve(endpoint);
    final normalizedQuery = <String, String>{};

    queryParameters?.forEach((key, value) {
      if (value == null) {
        return;
      }
      if (value is Iterable) {
        final joined = value
            .where((entry) => entry != null)
            .map((entry) => entry.toString())
            .where((entry) => entry.trim().isNotEmpty)
            .join(',');
        if (joined.isNotEmpty) {
          normalizedQuery[key] = joined;
        }
        return;
      }

      final stringValue = value.toString().trim();
      if (stringValue.isNotEmpty) {
        normalizedQuery[key] = stringValue;
      }
    });

    return uri.replace(
      queryParameters: normalizedQuery.isEmpty ? null : normalizedQuery,
    );
  }

  String buildFileContentUrl(String fileId) {
    return buildUri('files/$fileId/content').toString();
  }

  Map<String, String> buildImageHeaders() {
    final token = _sessionService.accessToken;
    if (token == null || token.isEmpty) {
      return const <String, String>{};
    }
    return {'Authorization': 'Bearer $token'};
  }

  Future<Map<String, dynamic>> login({
    required String userId,
    required String password,
    required bool rememberMe,
  }) async {
    final data = await _send(
      'POST',
      'auth/login',
      body: {'userId': userId, 'password': password, 'rememberMe': rememberMe},
      authenticated: false,
      retryOnUnauthorized: false,
    );
    return _asMap(data);
  }

  Future<Map<String, dynamic>> refreshSession(String refreshToken) async {
    final data = await _send(
      'POST',
      'auth/refresh',
      body: {'refreshToken': refreshToken},
      authenticated: false,
      retryOnUnauthorized: false,
    );
    return _asMap(data);
  }

  Future<void> logout() async {
    final refreshToken = _sessionService.refreshToken;
    try {
      await _send(
        'POST',
        'auth/logout',
        body: refreshToken == null ? const {} : {'refreshToken': refreshToken},
      );
    } catch (_) {
      // Local session should still be cleared even if the server is unavailable.
    } finally {
      _sessionService.clear();
    }
  }

  Future<Map<String, dynamic>> me() async {
    final data = await _send('GET', 'auth/me');
    return _asMap(data);
  }

  Future<Map<String, dynamic>> getMyProfile() async {
    final data = await _send('GET', 'profile');
    return _asMap(data);
  }

  Future<Map<String, dynamic>> updateMyProfile(
    Map<String, dynamic> payload,
  ) async {
    final data = await _send('PATCH', 'profile', body: payload);
    return _asMap(data);
  }

  Future<Map<String, dynamic>> requestForgotPassword(String email) async {
    final data = await _send(
      'POST',
      'auth/forgot-password/request',
      body: {'email': email},
      authenticated: false,
      retryOnUnauthorized: false,
    );
    return _asMap(data);
  }

  Future<void> requestForgotUid(String email) {
    return _send(
      'POST',
      'auth/forgot-uid/request',
      body: {'email': email},
      authenticated: false,
      retryOnUnauthorized: false,
    );
  }

  Future<void> confirmForgotPassword({
    required String token,
    required String newPassword,
  }) {
    return _send(
      'POST',
      'auth/forgot-password/confirm',
      body: {'token': token, 'newPassword': newPassword},
      authenticated: false,
      retryOnUnauthorized: false,
    );
  }

  Future<String> fetchNoEmailAccessMessage() async {
    final response = await _send(
      'GET',
      'auth/no-email-access-message',
      authenticated: false,
      retryOnUnauthorized: false,
    );
    if (response is String) {
      return response;
    }
    if (response is Map && response['message'] is String) {
      return response['message'] as String;
    }
    return 'Please contact your management for assistance.';
  }

  Future<List<Map<String, dynamic>>> getMyStations() async {
    final data = await _send('GET', 'stations/my');
    final stations = _asMap(data)['stations'];
    return _asListOfMaps(stations);
  }

  Future<Map<String, dynamic>?> getActiveStation() async {
    final data = await _send('GET', 'stations/active');
    if (data == null) {
      return null;
    }
    return _asMap(data);
  }

  Future<Map<String, dynamic>> selectStation(String stationId) async {
    final data = await _send(
      'POST',
      'stations/select',
      body: {'stationId': stationId},
    );
    return _asMap(data);
  }

  Future<List<Map<String, dynamic>>> getCleanTypes() async {
    final data = await _send('GET', 'master-data/clean-types');
    return _asListOfMaps(data);
  }

  Future<List<Map<String, dynamic>>> getAircraftTypes() async {
    final data = await _send('GET', 'master-data/aircraft-types');
    return _asListOfMaps(data);
  }

  Future<List<Map<String, dynamic>>> getFleetAircraft() async {
    final data = await _send('GET', 'master-data/fleet-aircraft');
    return _asListOfMaps(data);
  }

  Future<List<Map<String, dynamic>>> getCabinQualityChecklistItems() async {
    final data = await _send(
      'GET',
      'master-data/cabin-quality-checklist-items',
    );
    return _asListOfMaps(data);
  }

  Future<List<Map<String, dynamic>>> getLavSafetyChecklistItems() async {
    final data = await _send('GET', 'master-data/lav-safety-checklist-items');
    return _asListOfMaps(data);
  }

  Future<List<Map<String, dynamic>>> getSecuritySearchAreas() async {
    final data = await _send('GET', 'master-data/security-search-areas');
    return _asListOfMaps(data);
  }

  Future<List<Map<String, dynamic>>> getGates(String stationId) async {
    final data = await _send(
      'GET',
      'master-data/gates',
      queryParameters: {'stationId': stationId},
    );
    return _asListOfMaps(data);
  }

  Future<CloudinarySignedUploadPayload>
  getCloudinarySignedUploadPayload() async {
    final data = await _send('POST', 'upload/signed-url', body: const {});
    final payload = CloudinarySignedUploadPayload.fromMap(_asMap(data));
    if (!payload.isValid) {
      throw const ApiException(
        'Backend returned an invalid Cloudinary signed upload payload.',
      );
    }
    return payload;
  }

  Future<Map<String, dynamic>> uploadFile(
    File file, {
    required String category,
    ProgressCallback? onSendProgress,
  }) async {
    CloudinaryUploadResult uploadedAsset;
    try {
      final signedPayload = _cloudinaryUploadService.hasUnsignedUploadConfig
          ? null
          : await getCloudinarySignedUploadPayload();
      uploadedAsset = await _cloudinaryUploadService.uploadFile(
        file,
        onProgress: onSendProgress,
        signedPayload: signedPayload,
      );
    } on DioException catch (error) {
      final message = error.response?.data is Map
          ? (error.response?.data['error']?['message']?.toString() ??
                error.message)
          : error.message;
      throw ApiException(
        message?.trim().isNotEmpty == true
            ? message!.trim()
            : 'Unable to upload the file to Cloudinary right now.',
      );
    }

    final data = await _send(
      'POST',
      'files/register',
      body: {
        'cloudinaryUrl': uploadedAsset.secureUrl,
        'category': category,
        'originalFileName': uploadedAsset.originalFileName,
        'mimeType': uploadedAsset.mimeType,
        'sizeBytes': uploadedAsset.bytes,
        if (uploadedAsset.publicId.isNotEmpty)
          'publicId': uploadedAsset.publicId,
        if (uploadedAsset.format.isNotEmpty) 'format': uploadedAsset.format,
        if (uploadedAsset.resourceType.isNotEmpty)
          'resourceType': uploadedAsset.resourceType,
      },
    );
    final registered = _asMap(data);
    if (!registered.containsKey('cloudinaryUrl')) {
      registered['cloudinaryUrl'] = uploadedAsset.secureUrl;
    }
    return registered;
  }

  Future<Map<String, dynamic>> listCabinQualityAudits({
    Map<String, dynamic>? queryParameters,
  }) async {
    final data = await _send(
      'GET',
      'cabin-quality-audits',
      queryParameters: queryParameters,
    );
    return _asMap(data);
  }

  Future<Map<String, dynamic>> getCabinQualityAudit(String id) async {
    final data = await _send('GET', 'cabin-quality-audits/$id');
    return _asMap(data);
  }

  Future<Map<String, dynamic>> createCabinQualityAudit(
    Map<String, dynamic> payload,
  ) async {
    final data = await _send('POST', 'cabin-quality-audits', body: payload);
    return _asMap(data);
  }

  Future<Map<String, dynamic>> listLavSafetyObservations({
    Map<String, dynamic>? queryParameters,
  }) async {
    final data = await _send(
      'GET',
      'lav-safety-observations',
      queryParameters: queryParameters,
    );
    return _asMap(data);
  }

  Future<Map<String, dynamic>> getLavSafetyObservation(String id) async {
    final data = await _send('GET', 'lav-safety-observations/$id');
    return _asMap(data);
  }

  Future<Map<String, dynamic>> createLavSafetyObservation(
    Map<String, dynamic> payload,
  ) async {
    final data = await _send('POST', 'lav-safety-observations', body: payload);
    return _asMap(data);
  }

  Future<Map<String, dynamic>> listCabinSecurityTrainings({
    Map<String, dynamic>? queryParameters,
  }) async {
    final data = await _send(
      'GET',
      'cabin-security-search-trainings',
      queryParameters: queryParameters,
    );
    return _asMap(data);
  }

  Future<Map<String, dynamic>> getCabinSecurityTraining(String id) async {
    final data = await _send('GET', 'cabin-security-search-trainings/$id');
    return _asMap(data);
  }

  Future<Map<String, dynamic>> createCabinSecurityTraining(
    Map<String, dynamic> payload,
  ) async {
    final data = await _send(
      'POST',
      'cabin-security-search-trainings',
      body: payload,
    );
    return _asMap(data);
  }

  Future<Map<String, dynamic>> listHiddenObjectAudits({
    Map<String, dynamic>? queryParameters,
  }) async {
    final data = await _send(
      'GET',
      'hidden-object-audits',
      queryParameters: queryParameters,
    );
    return _asMap(data);
  }

  Future<Map<String, dynamic>> getHiddenObjectAudit(String id) async {
    final data = await _send('GET', 'hidden-object-audits/$id');
    return _asMap(data);
  }

  Future<Map<String, dynamic>> createHiddenObjectAudit(
    Map<String, dynamic> payload,
  ) async {
    final data = await _send('POST', 'hidden-object-audits', body: payload);
    return _asMap(data);
  }

  Future<Map<String, dynamic>> confirmHiddenObjectLocation({
    required String auditId,
    required String locationId,
    required Map<String, dynamic> payload,
  }) async {
    final data = await _send(
      'POST',
      'hidden-object-audits/$auditId/locations/$locationId/confirm',
      body: payload,
    );
    return _asMap(data);
  }

  Future<Map<String, dynamic>> activateHiddenObjectAudit(String auditId) async {
    final data = await _send(
      'POST',
      'hidden-object-audits/$auditId/activate',
      body: const {},
    );
    return _asMap(data);
  }

  Future<Map<String, dynamic>> markHiddenObjectFound({
    required String auditId,
    required String locationId,
  }) async {
    final data = await _send(
      'POST',
      'hidden-object-audits/$auditId/locations/$locationId/found',
      body: const {},
    );
    return _asMap(data);
  }

  Future<Map<String, dynamic>> closeHiddenObjectAudit(String auditId) async {
    final data = await _send(
      'POST',
      'hidden-object-audits/$auditId/close',
      body: const {},
    );
    return _asMap(data);
  }

  Future<List<Map<String, dynamic>>> searchEmployees(String query) async {
    final data = await _send(
      'GET',
      'employees/search',
      queryParameters: {'q': query},
    );
    return _asListOfMaps(data);
  }

  Future<List<Map<String, dynamic>>> listChatUsers({String? query}) async {
    final data = await _send(
      'GET',
      'employees/chat-users',
      queryParameters: {'q': query},
    );
    return _asListOfMaps(data);
  }

  Future<List<Map<String, dynamic>>> listConversations({
    String? tab,
    String? query,
  }) async {
    final data = await _send(
      'GET',
      'chat/conversations',
      queryParameters: {'tab': tab, 'q': query},
    );
    return _asListOfMaps(data);
  }

  Future<Map<String, dynamic>> createDirectConversation(String userId) async {
    final data = await _send(
      'POST',
      'chat/conversations/direct',
      body: {'userId': userId},
    );
    return _asMap(data);
  }

  Future<Map<String, dynamic>> getConversation(String id) async {
    final data = await _send('GET', 'chat/conversations/$id');
    return _asMap(data);
  }

  Future<Map<String, dynamic>> getConversationMessages(
    String id, {
    String? cursor,
    int? limit,
  }) async {
    final data = await _send(
      'GET',
      'chat/conversations/$id/messages',
      queryParameters: {'cursor': cursor, 'limit': limit},
    );
    return _asMap(data);
  }

  Future<Map<String, dynamic>> sendTextMessage(
    String conversationId,
    String text,
  ) async {
    final trimmed = text.trim();
    final preview = trimmed.length <= 100
        ? trimmed
        : '${trimmed.substring(0, 100)}...';
    final data = await _send(
      'POST',
      'chat/conversations/$conversationId/messages',
      body: {
        'messageType': 'TEXT',
        'encryptedPayload': trimmed,
        'previewText': preview,
      },
    );
    return _asMap(data);
  }

  Future<void> markMessageDelivered(String messageId) {
    return _send('POST', 'chat/messages/$messageId/delivered', body: const {});
  }

  Future<void> markMessageRead(String messageId) {
    return _send('POST', 'chat/messages/$messageId/read', body: const {});
  }

  Future<dynamic> _send(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    bool authenticated = true,
    bool retryOnUnauthorized = true,
  }) async {
    final uri = buildUri(endpoint, queryParameters: queryParameters);
    final headers = <String, String>{'Accept': 'application/json'};

    if (authenticated) {
      final accessToken = _sessionService.accessToken;
      if (accessToken?.isNotEmpty ?? false) {
        headers['Authorization'] = 'Bearer $accessToken';
      }
    }

    http.Response response;
    try {
      switch (method.toUpperCase()) {
        case 'GET':
          response = await _client.get(uri, headers: headers);
          break;
        case 'POST':
          headers['Content-Type'] = 'application/json';
          response = await _client.post(
            uri,
            headers: headers,
            body: jsonEncode(body ?? const {}),
          );
          break;
        case 'PATCH':
          headers['Content-Type'] = 'application/json';
          response = await _client.patch(
            uri,
            headers: headers,
            body: jsonEncode(body ?? const {}),
          );
          break;
        default:
          throw ApiException('Unsupported request method: $method');
      }
    } on SocketException {
      final baseUri = Uri.tryParse(baseUrl);
      final reachableHost = baseUri == null
          ? baseUrl
          : '${baseUri.scheme}://${baseUri.host}${baseUri.hasPort ? ':${baseUri.port}' : ''}';
      final androidHint =
          !kIsWeb && defaultTargetPlatform == TargetPlatform.android
          ? ' For Android APKs, confirm the installed release was built with the correct API_BASE_URL and that the phone can open $reachableHost.'
          : '';
      throw ApiException(
        'Unable to reach the backend at $reachableHost. Check the API base URL and server status.$androidHint',
      );
    } on HttpException {
      throw const ApiException(
        'Unable to complete the request because the server connection failed.',
      );
    }

    if (response.statusCode == 401 &&
        authenticated &&
        retryOnUnauthorized &&
        await _refreshAccessToken()) {
      return _send(
        method,
        endpoint,
        body: body,
        queryParameters: queryParameters,
        authenticated: authenticated,
        retryOnUnauthorized: false,
      );
    }

    final parsed = _decodeResponse(response.body);
    return _unwrapResponse(response.statusCode, parsed);
  }

  dynamic _decodeResponse(String body) {
    if (body.trim().isEmpty) {
      return null;
    }
    try {
      return jsonDecode(body);
    } catch (_) {
      return body;
    }
  }

  dynamic _unwrapResponse(int statusCode, dynamic parsed) {
    if (statusCode >= 200 && statusCode < 300) {
      if (parsed is Map<String, dynamic> && parsed.containsKey('success')) {
        if (parsed['success'] == false) {
          throw ApiException(
            (parsed['message'] as String?) ?? 'Request failed',
            statusCode: statusCode,
            code: parsed['code'] as String?,
            details: parsed['details'],
          );
        }
        return parsed['data'];
      }
      return parsed;
    }

    if (parsed is Map<String, dynamic>) {
      throw ApiException(
        (parsed['message'] as String?) ?? 'Request failed',
        statusCode: statusCode,
        code: parsed['code'] as String?,
        details: parsed['details'],
      );
    }

    throw ApiException(
      'Request failed with status $statusCode',
      statusCode: statusCode,
    );
  }

  Future<bool> _refreshAccessToken() async {
    final refreshToken = _sessionService.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      _expireSession();
      return false;
    }

    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    final completer = Completer<bool>();
    _refreshCompleter = completer;

    () async {
      try {
        final refreshed = await refreshSession(refreshToken);
        _sessionService.saveAuth(
          accessToken: (refreshed['accessToken'] as String?) ?? '',
          refreshToken: (refreshed['refreshToken'] as String?) ?? '',
          rememberMe: _sessionService.rememberMe,
        );
        completer.complete(true);
      } catch (_) {
        _expireSession();
        completer.complete(false);
      } finally {
        _refreshCompleter = null;
      }
    }();

    return completer.future;
  }

  void _expireSession() {
    _sessionService.clear();

    if (Get.currentRoute == '/login') {
      return;
    }

    Future.microtask(() {
      if (Get.key.currentState != null && Get.currentRoute != '/login') {
        Get.offAllNamed('/login');
      }
    });
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, entry) => MapEntry(key.toString(), entry));
    }
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _asListOfMaps(dynamic value) {
    if (value is! List) {
      return const <Map<String, dynamic>>[];
    }
    return value.map(_asMap).toList();
  }
}
