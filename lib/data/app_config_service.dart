import 'dart:async';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

class AppConfigService extends ChangeNotifier {
  AppConfigService._();
  static final AppConfigService instance = AppConfigService._();

  String _baseUrl = '';
  String get baseUrl => _baseUrl;

  Future<void> loadAndApplyBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString('api_base_url') ?? '';
    if (_baseUrl.isNotEmpty) {
      ApiClient.setBaseUrl(_baseUrl);
    } else {
      final detected = await _detectBaseUrl();
      if (detected != null && detected.isNotEmpty) {
        await setBaseUrl(detected);
      }
    }
  }

  Future<void> setBaseUrl(String url) async {
    final normalized = url.trim().replaceAll(RegExp(r'/+$'), '');
    _baseUrl = normalized;
    ApiClient.setBaseUrl(normalized);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_base_url', normalized);
    notifyListeners();
  }

  Future<bool> detectAndApply() async {
    final detected = await _detectBaseUrl();
    if (detected != null && detected.isNotEmpty) {
      await setBaseUrl(detected);
      return true;
    }
    return false;
  }

  // Fix: extracted into separate method to reduce cognitive complexity
  bool _isPrivateIp(String ip) {
    return ip.startsWith('192.168.') ||
        ip.startsWith('10.') ||
        ip.startsWith('172.16.') ||
        ip.startsWith('172.17.') ||
        ip.startsWith('172.18.') ||
        ip.startsWith('172.19.') ||
        ip.startsWith('172.2') ||
        ip.startsWith('172.3');
  }

<<<<<<< HEAD
    // Candidate list in order of likelihood  
    final List<String> candidates = [
      // Windows/macOS desktop running XAMPP locally
      'http://localhost/inventory_api',
      // Android emulator talking to host
      'http://10.0.2.2/inventory_api',
    ];

    // Add LAN IPs of the current device (useful if server is same machine and phones need LAN URL)
=======
  // Fix: extracted into separate method to reduce cognitive complexity
  Future<List<String>> _getLanCandidates() async {
    final candidates = <String>[];
>>>>>>> d636c45dd1bba92b66c9ecf9f0f29d82aac0dfe8
    try {
      final interfaces = await io.NetworkInterface.list(
        type: io.InternetAddressType.any,
        includeLoopback: false,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (addr.type == io.InternetAddressType.IPv4 && _isPrivateIp(addr.address)) {
            candidates.add('http://${addr.address}/inventory_api');
          }
        }
      }
    } catch (_) {
      // ignore interface errors
    }
    return candidates;
  }

  Future<String?> _detectBaseUrl() async {
    if (kIsWeb) return 'http://localhost/inventory_api';

    final List<String> candidates = [
      'http://localhost/inventory_api',
      'http://10.0.2.2/inventory_api',
      ...await _getLanCandidates(),
    ];

    for (final base in candidates.toSet()) {
      final ok = await _probe('$base/ping.php');
      if (ok) return base;
    }

    return 'http://192.168.1.88/inventory_api';
  }

  Future<bool> _probe(String url) async {
    try {
      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 3));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
