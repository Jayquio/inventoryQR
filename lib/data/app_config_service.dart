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

  Future<String?> _detectBaseUrl() async {
    // Skip on web; rely on defaults
    if (kIsWeb) return 'http://localhost/inventory_api';

    // Candidate list in order of likelihood  
    final List<String> candidates = [
      // Windows/macOS desktop running XAMPP locally
      'http://localhost/inventory_api',
      // Android emulator talking to host
      'http://10.0.2.2/inventory_api',
    ];

    // Add LAN IPs of the current device (useful if server is same machine and phones need LAN URL)
    try {
      final interfaces = await io.NetworkInterface.list(
        type: io.InternetAddressType.any,
        includeLoopback: false,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (addr.type == io.InternetAddressType.IPv4) {
            final ip = addr.address;
            // Add common private ranges only
            if (ip.startsWith('192.168.') ||
                ip.startsWith('10.') ||
                ip.startsWith('172.16.') ||
                ip.startsWith('172.17.') ||
                ip.startsWith('172.18.') ||
                ip.startsWith('172.19.') ||
                ip.startsWith('172.2') // covers 172.20-29
                ||
                ip.startsWith('172.3') // covers 172.30-31
                ) {
              candidates.add('http://$ip/inventory_api');
            }
          }
        }
      }
    } catch (_) {
      // ignore interface errors
    }

    // Try each candidate using ping.php (fast) with a short timeout
    for (final base in candidates.toSet()) {
      final ok = await _probe('$base/ping.php');
      if (ok) return base;
    }
    // As a last resort, provide a common LAN placeholder to guide users
    return 'http://192.168.1.88/inventory_api';
  }

  Future<bool> _probe(String url) async {
    try {
      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) return true;
    } catch (_) {
      // ignore
    }
    return false;
  }
}
