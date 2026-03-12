import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();
  static String _overrideBaseUrl = '';

  // Fix: constant to avoid duplicating 'Content-Type' header
  static const Map<String, String> _jsonHeaders = {'Content-Type': 'application/json'};

  static void setBaseUrl(String url) {
    _overrideBaseUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
  }

  static String _baseUrl() {
    if (_overrideBaseUrl.isNotEmpty) return _overrideBaseUrl;
    if (kIsWeb) return 'http://localhost/inventory_api';
    if (defaultTargetPlatform == TargetPlatform.android) {
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
          headers: _jsonHeaders,
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
          headers: _jsonHeaders,
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
          headers: _jsonHeaders,
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
          headers: _jsonHeaders,
          body: jsonEncode({'username': username}),
        )
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};
      final msg = body is Map ? (body['error'] ?? 'delete_failed') : 'delete_failed';
      throw Exception(msg.toString());
    }
  }
}
