import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_inventorymanagement/models/instrument.dart';

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();
  static String _overrideBaseUrl = '';

  static const Map<String, String> _jsonHeaders = {
    'Content-Type': 'application/json',
  };

  static const Map<String, String> _authHeaders = {};

  static const String _productionApiFallback =
      'https://api.medtechinventorysystem.org';

  static bool _isLocalhostUrl(String u) {
    final lower = u.toLowerCase();
    return lower.contains('localhost') || lower.contains('127.0.0.1');
  }

  /// On web, never keep a localhost base URL (browsers resolve it to the user's PC).
  static void setBaseUrl(String url) {
    var u = url.trim().replaceAll(RegExp(r'/+$'), '');
    if (kIsWeb && _isLocalhostUrl(u)) {
      u = '';
    }
    _overrideBaseUrl = u;
  }

  static String _baseUrl() {
    if (_overrideBaseUrl.isNotEmpty) {
      if (kIsWeb && _isLocalhostUrl(_overrideBaseUrl)) {
        return _productionApiFallback;
      }
      return _overrideBaseUrl;
    }
    return _productionApiFallback;
  }

  dynamic _safeDecode(String body) {
    if (body.isEmpty) return {};
    try {
      return jsonDecode(body);
    } catch (e) {
      // If not JSON, return a helpful error map
      if (body.contains('<br />') || body.contains('<b>')) {
        return {
          'error':
              'Server Error (PHP): ${body.replaceAll(RegExp(r'<[^>]*>'), ' ').trim()}',
        };
      }
      return {
        'error':
            'Invalid server response: ${body.substring(0, body.length > 100 ? 100 : body.length)}',
      };
    }
  }

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final uri = Uri.parse('${_baseUrl()}/auth_login.php');
    final res = await http
        .post(
          uri,
          headers: _jsonHeaders,
          body: jsonEncode({'username': username, 'password': password}),
        )
        .timeout(const Duration(seconds: 15));
    final body = _safeDecode(res.body);
    if (res.statusCode == 200 && body is Map && body['ok'] == true) {
      return body.cast<String, dynamic>();
    }
    final msg = body is Map
        ? (body['error'] ?? 'login_failed')
        : 'login_failed';
    throw Exception(msg.toString());
  }

  Future<Map<String, dynamic>> createUser({
    required String username,
    required String password,
    required String role,
    String? email,
  }) async {
    final uri = Uri.parse('${_baseUrl()}/create_user.php');
    final res = await http
        .post(
          uri,
          headers: _jsonHeaders,
          body: jsonEncode(
            {
              'username': username,
              'password': password,
              'role': role,
              'email': email,
            }..removeWhere((k, v) => v == null),
          ),
        )
        .timeout(const Duration(seconds: 15));
    final body = _safeDecode(res.body);
    if (res.statusCode == 200 && body is Map && body['ok'] == true) {
      return body.cast<String, dynamic>();
    }
    final msg = body is Map
        ? (body['error'] ?? 'create_failed')
        : 'create_failed';
    throw Exception(msg.toString());
  }

  Future<Map<String, dynamic>> updateUser({
    required String username,
    String? password,
    String? role,
  }) async {
    final uri = Uri.parse('${_baseUrl()}/update_user.php');
    final payload = {
      'username': username,
      if (password != null && password.isNotEmpty) 'password': password,
      if (role != null && role.isNotEmpty) 'role': role,
    };
    final res = await http
        .post(uri, headers: _jsonHeaders, body: jsonEncode(payload))
        .timeout(const Duration(seconds: 15));
    final body = _safeDecode(res.body);
    if (res.statusCode == 200 && body is Map && body['ok'] == true) {
      return body.cast<String, dynamic>();
    }
    final msg = body is Map
        ? (body['error'] ?? 'update_failed')
        : 'update_failed';
    throw Exception(msg.toString());
  }

  Future<void> deleteUser({required String username}) async {
    final uri = Uri.parse('${_baseUrl()}/delete_user.php');
    final res = await http
        .post(
          uri,
          headers: _jsonHeaders,
          body: jsonEncode({'username': username}),
        )
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      final body = _safeDecode(res.body);
      final msg = body is Map
          ? (body['error'] ?? 'delete_failed')
          : 'delete_failed';
      throw Exception(msg.toString());
    }
  }

  Future<List<Map<String, dynamic>>> fetchUsers() async {
    final uri = Uri.parse('${_baseUrl()}/users_list.php');
    final res = await http
        .get(uri, headers: _authHeaders)
        .timeout(const Duration(seconds: 15));
    final body = _safeDecode(res.body);
    if (res.statusCode == 200 && body is Map && body['ok'] == true) {
      final data = (body['data'] as List? ?? []);
      return data
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
    }
    final msg = body is Map ? (body['error'] ?? 'load_failed') : 'load_failed';
    throw Exception(msg.toString());
  }

  Future<bool> ping() async {
    final uri = Uri.parse('${_baseUrl()}/ping.php');
    final res = await http
        .get(uri, headers: _authHeaders)
        .timeout(const Duration(seconds: 5));
    if (res.statusCode == 200) {
      final body = _safeDecode(res.body);
      return body is Map && body['ok'] == true;
    }
    return false;
  }

  Future<List<Instrument>> fetchInstruments() async {
    final uri = Uri.parse('${_baseUrl()}/instruments_list.php');
    final res = await http
        .get(uri, headers: _authHeaders)
        .timeout(const Duration(seconds: 15));
    final body = _safeDecode(res.body);
    if (res.statusCode == 200 && body is Map && body['ok'] == true) {
      final data = (body['data'] as List? ?? []);
      return data
          .whereType<Map>()
          .map((e) => Instrument.fromJson(e.cast<String, dynamic>()))
          .toList();
    }
    final msg = body is Map ? (body['error'] ?? 'load_failed') : 'load_failed';
    throw Exception(msg.toString());
  }

  Future<void> createInstrument({required Instrument instrument}) async {
    final uri = Uri.parse('${_baseUrl()}/instruments_create.php');
    final res = await http
        .post(uri, headers: _jsonHeaders, body: jsonEncode(instrument.toJson()))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      final body = _safeDecode(res.body);
      final msg = body is Map
          ? (body['error'] ?? 'create_failed')
          : 'create_failed';
      throw Exception(msg.toString());
    }
  }

  Future<void> updateInstrument({
    required String originalName,
    required Instrument instrument,
  }) async {
    final uri = Uri.parse('${_baseUrl()}/instruments_update.php');
    final payload = {'originalName': originalName, ...instrument.toJson()};
    final res = await http
        .post(uri, headers: _jsonHeaders, body: jsonEncode(payload))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      final body = _safeDecode(res.body);
      final msg = body is Map
          ? (body['error'] ?? 'update_failed')
          : 'update_failed';
      throw Exception(msg.toString());
    }
  }

  Future<void> deleteInstrument({required String name}) async {
    final uri = Uri.parse('${_baseUrl()}/instruments_delete.php');
    final res = await http
        .post(uri, headers: _jsonHeaders, body: jsonEncode({'name': name}))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      final body = _safeDecode(res.body);
      final msg = body is Map
          ? (body['error'] ?? 'delete_failed')
          : 'delete_failed';
      throw Exception(msg.toString());
    }
  }

  Future<void> updateRequestQuantity({
    required String id,
    required int quantity,
    required String user,
    String? reason,
  }) async {
    final uri = Uri.parse('${_baseUrl()}/requests_update_quantity.php');
    final payload = {
      'id': id,
      'quantity': quantity,
      'user': user,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    };
    final res = await http
        .post(uri, headers: _jsonHeaders, body: jsonEncode(payload))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      final body = _safeDecode(res.body);
      final msg = body is Map
          ? (body['error'] ?? 'update_failed')
          : 'update_failed';
      throw Exception(msg.toString());
    }
  }

  Future<List<Map<String, dynamic>>> fetchRequests({
    String? studentName,
  }) async {
    final url = studentName != null && studentName.isNotEmpty
        ? '${_baseUrl()}/requests_list.php?student_name=${Uri.encodeQueryComponent(studentName)}'
        : '${_baseUrl()}/requests_list.php';
    final uri = Uri.parse(url);
    final res = await http
        .get(uri, headers: _authHeaders)
        .timeout(const Duration(seconds: 15));
    final body = _safeDecode(res.body);
    if (res.statusCode == 200 && body is Map && body['ok'] == true) {
      final data = (body['data'] as List? ?? []);
      return data
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
    }
    final msg = body is Map ? (body['error'] ?? 'load_failed') : 'load_failed';
    throw Exception(msg.toString());
  }

  Future<void> updateRequestStatus({
    required String id,
    required String status,
    required String user,
  }) async {
    final uri = Uri.parse('${_baseUrl()}/requests_update_status.php');
    final payload = {'id': id, 'status': status, 'user': user};
    final res = await http
        .post(uri, headers: _jsonHeaders, body: jsonEncode(payload))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      final body = _safeDecode(res.body);
      final msg = body is Map
          ? (body['error'] ?? 'update_failed')
          : 'update_failed';
      throw Exception(msg.toString());
    }
  }

  Future<void> submitRequest({
    required String studentName,
    required String instrumentName,
    required String purpose,
    int quantity = 1,
    String? serialNumber,
    String? course,
    String? neededAtIso,
  }) async {
    final uri = Uri.parse('${_baseUrl()}/request_create.php');
    final payload = {
      'student_name': studentName,
      'instrument_name': instrumentName,
      'quantity': quantity,
      'purpose': purpose,
      if (serialNumber != null && serialNumber.isNotEmpty)
        'serialNumber': serialNumber,
      if (course != null && course.isNotEmpty) 'course': course,
      if (neededAtIso != null && neededAtIso.isNotEmpty)
        'needed_at': neededAtIso,
    };
    final res = await http
        .post(uri, headers: _jsonHeaders, body: jsonEncode(payload))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      final body = _safeDecode(res.body);
      final msg = body is Map
          ? (body['error'] ?? 'request_failed')
          : 'request_failed';
      throw Exception(msg.toString());
    }
  }

  Future<int?> processTransaction({
    required String type,
    required String instrumentName,
    required String processedBy,
    String? requestId,
  }) async {
    final uri = Uri.parse('${_baseUrl()}/transaction_process.php');
    final res = await http
        .post(
          uri,
          headers: _jsonHeaders,
          body: jsonEncode(
            {
              'type': type,
              'instrument_name': instrumentName,
              'processed_by': processedBy,
              'request_id': requestId,
            }..removeWhere((k, v) => v == null),
          ),
        )
        .timeout(const Duration(seconds: 15));
    final body = _safeDecode(res.body);
    if (res.statusCode == 200 && body is Map && body['ok'] == true) {
      final avail = body['available'];
      if (avail is int) return avail;
      return int.tryParse(avail?.toString() ?? '');
    }
    final msg = body is Map ? (body['error'] ?? 'tx_failed') : 'tx_failed';
    throw Exception(msg.toString());
  }

  Future<void> deleteRequest({required String id}) async {
    final uri = Uri.parse('${_baseUrl()}/request_delete.php');
    final res = await http
        .post(uri, headers: _jsonHeaders, body: jsonEncode({'id': id}))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      final body = _safeDecode(res.body);
      final msg = body is Map
          ? (body['error'] ?? 'delete_failed')
          : 'delete_failed';
      throw Exception(msg.toString());
    }
  }

  Future<List<Map<String, dynamic>>> fetchNotifications({
    String recipient = 'All',
    String username = '',
    int limit = 50,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final url =
        '${_baseUrl()}/notifications_list.php?recipient=$recipient&username=${Uri.encodeQueryComponent(username)}&limit=$limit&_=$timestamp';
    final uri = Uri.parse(url);
    final res = await http
        .get(uri, headers: _authHeaders)
        .timeout(const Duration(seconds: 15));
    final body = _safeDecode(res.body);
    if (res.statusCode == 200 && body is Map && body['ok'] == true) {
      final data = (body['data'] as List? ?? []);
      return data
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
    }
    final msg = body is Map ? (body['error'] ?? 'load_failed') : 'load_failed';
    throw Exception(msg.toString());
  }

  Future<void> createNotification({
    required String title,
    required String message,
    required String type,
    String recipient = 'All',
    String priority = 'medium',
  }) async {
    final uri = Uri.parse('${_baseUrl()}/notifications_create.php');
    final payload = {
      'title': title,
      'message': message,
      'type': type,
      'recipient': recipient,
      'priority': priority,
    };
    final res = await http
        .post(uri, headers: _jsonHeaders, body: jsonEncode(payload))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      final body = _safeDecode(res.body);
      final msg = body is Map ? (body['error'] ?? 'failed') : 'failed';
      throw Exception(msg.toString());
    }
  }

  Future<void> markNotificationRead({
    String? id,
    String? username,
    bool all = false,
  }) async {
    final uri = Uri.parse('${_baseUrl()}/notifications_mark_read.php');
    final payload = {'id': id, 'username': username, 'all': all}
      ..removeWhere((k, v) => v == null);
    final res = await http
        .post(uri, headers: _jsonHeaders, body: jsonEncode(payload))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      final body = _safeDecode(res.body);
      final msg = body is Map ? (body['error'] ?? 'failed') : 'failed';
      throw Exception(msg.toString());
    }
  }
}
