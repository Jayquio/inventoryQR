import 'dart:async';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import 'api_client.dart';

class AppConfigService extends ChangeNotifier {
  AppConfigService._();
  static final AppConfigService instance = AppConfigService._();

  // Shared API base URL constants (avoid duplicated literals)
  static const String _localApiBase = 'http://localhost/inventory_api';
  static const String _androidEmulatorApiBase = 'http://10.0.2.2/inventory_api';

  String _baseUrl = '';
  String get baseUrl => _baseUrl;

  Future<void> loadAndApplyBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString('api_base_url') ?? '';
    if (_baseUrl.isNotEmpty) {
      final ok = await _probe('$_baseUrl/ping.php');
      if (ok) {
        ApiClient.setBaseUrl(_baseUrl);
        return;
      }
    }

    final detected = await _detectBaseUrl();
    if (detected != null && detected.isNotEmpty) {
      await setBaseUrl(detected);
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
  
  // Collect LAN IP-based API candidates (server on same machine/LAN)
  Future<List<String>> _getLanCandidates() async {
    final candidates = <String>[];
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
    // On Flutter Web, `dart:io` network interface probing isn't reliable.
    // Instead, try a small set of likely API URLs (local Docker default included)
    // and pick the first one that answers `/ping.php`.
    if (kIsWeb) {
      final List<String> candidates = [
        // Docker Compose default (api:AppNetwork.apiPort -> container:80)
        'http://localhost:${AppNetwork.apiPort}',
        // Some local setups may still expose the API under `/inventory_api`
        'http://localhost:${AppNetwork.apiPort}/inventory_api',
        // Older/local assumption kept for backward compatibility
        _localApiBase,
        // If running inside the Docker network (e.g., server-to-server)
        'http://api',
        'http://api:80',
      ];

      for (final base in candidates.toSet()) {
        final ok = await _probe('$base/ping.php');
        if (ok) return base;
      }

      // Fallback to Docker port (most likely for your current setup)
      return 'http://localhost:${AppNetwork.apiPort}';
    }

    final List<String> candidates = [
      _localApiBase,
      _androidEmulatorApiBase,
      ...await _getLanCandidates(),
    ];

    for (final base in candidates.toSet()) {
      final ok = await _probe('$base/ping.php');
      if (ok) return base;
    }

    return 'http://192.168.1.164:8081';
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
