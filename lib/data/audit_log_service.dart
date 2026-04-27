import 'package:flutter/foundation.dart';
import 'api_client.dart';
import 'auth_service.dart';

class AuditLogEntry {
  AuditLogEntry({
    required this.timestamp,
    required this.username,
    required this.userRole,
    required this.action,
    required this.type,
    required this.details,
  });

  final DateTime timestamp;
  final String username;
  final String userRole;
  final String action; // e.g., GENERATE_QR
  final String type; // e.g., borrow|receive|return
  final String details;

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    return AuditLogEntry(
      timestamp: DateTime.parse(json['timestamp']),
      username: json['username'] ?? 'unknown',
      userRole: json['user_role'] ?? 'unknown',
      action: json['action'] ?? '',
      type: json['type'] ?? '',
      details: json['details'] ?? '',
    );
  }
}

class AuditLogService extends ChangeNotifier {
  AuditLogService._();
  static final AuditLogService instance = AuditLogService._();

  final List<AuditLogEntry> _entries = [];
  bool _isFetching = false;

  List<AuditLogEntry> get entries => List.unmodifiable(_entries);

  Future<void> fetchFromServer() async {
    if (_isFetching) return;
    _isFetching = true;
    try {
      final list = await ApiClient.instance.fetchAuditLogs();
      _entries.clear();
      _entries.addAll(list.map((e) => AuditLogEntry.fromJson(e)));
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching audit logs: $e');
    } finally {
      _isFetching = false;
    }
  }

  void addEntry(AuditLogEntry entry) {
    _entries.insert(0, entry);
    notifyListeners();

    // Persist to server
    ApiClient.instance
        .createAuditLog(
          username: entry.username,
          userRole: entry.userRole,
          action: entry.action,
          type: entry.type,
          details: entry.details,
        )
        .catchError((e) {
          debugPrint('Failed to persist audit log: $e');
        });
  }
}
