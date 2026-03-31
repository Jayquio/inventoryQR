import 'package:flutter/foundation.dart';

class AuditLogEntry {
  AuditLogEntry({
    required this.timestamp,
    required this.userRole,
    required this.action,
    required this.type,
    required this.details,
  });

  final DateTime timestamp;
  final String userRole;
  final String action; // e.g., GENERATE_QR
  final String type; // e.g., borrow|receive|return
  final String details;
}

class AuditLogService extends ChangeNotifier {
  AuditLogService._();
  static final AuditLogService instance = AuditLogService._();

  final List<AuditLogEntry> _entries = [];

  List<AuditLogEntry> get entries => List.unmodifiable(_entries);

  void addEntry(AuditLogEntry entry) {
    _entries.insert(0, entry);
    notifyListeners();
  }
}
