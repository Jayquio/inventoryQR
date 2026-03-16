import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_inventorymanagement/models/instrument.dart';

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  static String _overrideBaseUrl = '';

  static void setBaseUrl(String url) {
    // Trim and remove trailing slashes for consistent URL joining
    _overrideBaseUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
  }

  static String _baseUrl() {
    if (_overrideBaseUrl.isNotEmpty) return _overrideBaseUrl;
    if (kIsWeb) return 'http://localhost/inventory_api';
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Android emulator -> host machine
      return 'http://10.0.2.2/inventory_api';
    }
    return 'http://localhost/inventory_api';
  }

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final uri = Uri.parse('${_baseUrl()}/auth_login.php');
    final res = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'username': username, 'password': password}),
        )
        .timeout(const Duration(seconds: 15));

    final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};
    if (res.statusCode == 200 && body is Map && body['ok'] == true) {
      return body.cast<String, dynamic>();
    }
    final msg = body is Map ? (body['error'] ?? 'login_failed') : 'login_failed';
    throw Exception(msg.toString());
  }

  Future<Map<String, dynamic>> createUser({
    required String username,
    required String password,
    required String role,
  }) async {
    final uri = Uri.parse('${_baseUrl()}/create_user.php');
    final res = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'username': username, 'password': password, 'role': role}),
        )
        .timeout(const Duration(seconds: 15));
    final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};
    if (res.statusCode == 200 && body is Map && body['ok'] == true) {
      return body.cast<String, dynamic>();
    }
    final msg = body is Map ? (body['error'] ?? 'create_failed') : 'create_failed';
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
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 15));
    final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};
    if (res.statusCode == 200 && body is Map && body['ok'] == true) {
      return body.cast<String, dynamic>();
    }
    final msg = body is Map ? (body['error'] ?? 'update_failed') : 'update_failed';
    throw Exception(msg.toString());
  }

  Future<void> deleteUser({required String username}) async {
    final uri = Uri.parse('${_baseUrl()}/delete_user.php');
    final res = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'username': username}),
        )
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};
      final msg = body is Map ? (body['error'] ?? 'delete_failed') : 'delete_failed';
      throw Exception(msg.toString());
    }
  }

  Future<List<Map<String, dynamic>>> fetchUsers() async {
    final uri = Uri.parse('${_baseUrl()}/users_list.php');
    final res = await http.get(uri).timeout(const Duration(seconds: 15));
    final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};
    if (res.statusCode == 200 && body is Map && body['ok'] == true) {
      final data = (body['data'] as List? ?? []);
      return data.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    }
    final msg = body is Map ? (body['error'] ?? 'load_failed') : 'load_failed';
    throw Exception(msg.toString());
  }

  Future<bool> ping() async {
    final uri = Uri.parse('${_baseUrl()}/ping.php');
    final res = await http.get(uri).timeout(const Duration(seconds: 5));
    if (res.statusCode == 200) {
      final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};
      return body is Map && body['ok'] == true;
    }
    return false;
  }

  Future<List<Instrument>> fetchInstruments() async {
    final uri = Uri.parse('${_baseUrl()}/instruments_list.php');
    final res = await http.get(uri).timeout(const Duration(seconds: 15));
    final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};
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
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(instrument.toJson()),
        )
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};
      final msg = body is Map ? (body['error'] ?? 'create_failed') : 'create_failed';
      throw Exception(msg.toString());
    }
  }

  Future<void> updateInstrument({required String originalName, required Instrument instrument}) async {
    final uri = Uri.parse('${_baseUrl()}/instruments_update.php');
    final payload = {'originalName': originalName, ...instrument.toJson()};
    final res = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};
      final msg = body is Map ? (body['error'] ?? 'update_failed') : 'update_failed';
      throw Exception(msg.toString());
    }
  }

  Future<List<Map<String, dynamic>>> fetchRequests() async {
    final uri = Uri.parse('${_baseUrl()}/requests_list.php');
    final res = await http.get(uri).timeout(const Duration(seconds: 15));
    final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};
    if (res.statusCode == 200 && body is Map && body['ok'] == true) {
      final data = (body['data'] as List? ?? []);
      return data.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    }
    final msg = body is Map ? (body['error'] ?? 'load_failed') : 'load_failed';
    throw Exception(msg.toString());
  }

  Future<void> updateRequestStatus({required String id, required String status, required String user}) async {
    final uri = Uri.parse('${_baseUrl()}/requests_update_status.php');
    final payload = {
      'id': id,
      'status': status,
      'user': user,
    };
    final res = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};
      final msg = body is Map ? (body['error'] ?? 'update_failed') : 'update_failed';
      throw Exception(msg.toString());
    }
  }

  Future<void> submitRequest({
    required String studentName,
    required String instrumentName,
    required String purpose,
    String? course,
    String? neededAtIso,
  }) async {
    final uri = Uri.parse('${_baseUrl()}/request_create.php');
    final payload = {
      'student_name': studentName,
      'instrument_name': instrumentName,
      'purpose': purpose,
      if (course != null && course.isNotEmpty) 'course': course,
      if (neededAtIso != null && neededAtIso.isNotEmpty) 'needed_at': neededAtIso,
    };
    final res = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};
      final msg = body is Map ? (body['error'] ?? 'request_failed') : 'request_failed';
      throw Exception(msg.toString());
    }
  }

  Future<int?> processTransaction({required String type, required String instrumentName, required String processedBy}) async {
    final uri = Uri.parse('${_baseUrl()}/transaction_process.php');
    final res = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'type': type, 'instrument_name': instrumentName, 'processed_by': processedBy}),
        )
        .timeout(const Duration(seconds: 15));
    final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};
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
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'id': id}),
        )
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};
      final msg = body is Map ? (body['error'] ?? 'delete_failed') : 'delete_failed';
      throw Exception(msg.toString());
    }
  }
}
