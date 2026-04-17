import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:async';
import '../data/api_client.dart';
import '../data/auth_service.dart';

class NotificationItem {
  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    required this.recipient,
    this.course,
    this.read = false,
    this.priority = 'medium',
    this.isOverride = false,
    this.originalQuantity,
    this.overrideQuantity,
    this.overrideReason,
  });

  final String id;
  final String title;
  final String message;
  final String type;
  final String timestamp;
  final String recipient;
  final String? course;
  bool read;
  final String priority;
  final bool isOverride;
  final int? originalQuantity;
  final int? overrideQuantity;
  final String? overrideReason;
}

class NotificationService extends ChangeNotifier {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final List<NotificationItem> _notifications = [];
  WebSocketChannel? _channel;
  Timer? _autoRefreshTimer;
  bool _isFetching = false;

  List<NotificationItem> get notifications => List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.read).length;

  void add(NotificationItem item) {
    // Avoid duplicates by ID
    if (_notifications.any((n) => n.id == item.id)) return;

    _notifications.insert(0, item);
    // Sort by timestamp descending
    _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    notifyListeners();
    _persist();
  }

  Future<void> fetchFromServer() async {
    if (_isFetching) return;
    _isFetching = true;
    try {
      final role = AuthService.instance.currentRole;
      String recipient = 'All';
      if (role == UserRole.admin || role == UserRole.superadmin) {
        recipient = 'Admin';
      } else if (role == UserRole.teacher) {
        recipient = 'Teacher';
      } else if (role == UserRole.student) {
        recipient = 'Student';
      }

      final list = await ApiClient.instance.fetchNotifications(
        recipient: recipient,
      );

      bool changed = false;
      for (final map in list) {
        final id = map['id'].toString();
        if (!_notifications.any((n) => n.id == id)) {
          _notifications.add(
            NotificationItem(
              id: id,
              title: map['title'] ?? 'Update',
              message: map['message'] ?? '',
              type: map['type'] ?? 'info',
              timestamp: map['timestamp'] ?? DateTime.now().toIso8601String(),
              recipient: map['recipient'] ?? 'All',
              course: map['course'],
              read: map['read'] ?? false,
              priority: map['priority'] ?? 'medium',
            ),
          );
          changed = true;
        }
      }

      if (changed) {
        _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        notifyListeners();
        _persist();
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    } finally {
      _isFetching = false;
    }
  }

  Future<void> clear({bool persist = false}) async {
    _notifications.clear();
    notifyListeners();
    if (persist) {
      await _persist();
    }
  }

  void markAsRead(String id) {
    final idx = _notifications.indexWhere((e) => e.id == id);
    if (idx != -1) {
      _notifications[idx].read = true;
      notifyListeners();
      _persist();
    }
  }

  void markAllAsRead() {
    for (final n in _notifications) {
      n.read = true;
    }
    notifyListeners();
    _persist();
  }

  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('notifications');
    if (jsonStr != null && jsonStr.isNotEmpty) {
      final List<dynamic> raw = json.decode(jsonStr);
      _notifications
        ..clear()
        ..addAll(
          raw.map(
            (e) => NotificationItem(
              id: e['id'].toString(),
              title: e['title'],
              message: e['message'],
              type: e['type'],
              timestamp: e['timestamp'],
              recipient: e['recipient'],
              course: e['course'],
              read: e['read'] ?? false,
              priority: e['priority'] ?? 'medium',
              isOverride: e['isOverride'] ?? false,
              originalQuantity: e['originalQuantity'],
              overrideQuantity: e['overrideQuantity'],
              overrideReason: e['overrideReason'],
            ),
          ),
        );
      _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      notifyListeners();
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = _notifications
        .map(
          (n) => {
            'id': n.id,
            'title': n.title,
            'message': n.message,
            'type': n.type,
            'timestamp': n.timestamp,
            'recipient': n.recipient,
            'course': n.course,
            'read': n.read,
            'priority': n.priority,
            'isOverride': n.isOverride,
            'originalQuantity': n.originalQuantity,
            'overrideQuantity': n.overrideQuantity,
            'overrideReason': n.overrideReason,
          },
        )
        .toList();
    await prefs.setString('notifications', json.encode(raw));
  }

  void connectWebSocket({String? url}) {
    if (url == null || url.isEmpty || url.contains('localhost')) {
      // Don't connect to localhost WebSocket in production
      return;
    }
    try {
      _channel?.sink.close();
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _channel!.stream.listen((event) {
        try {
          final data = json.decode(event);
          if (data is Map<String, dynamic>) {
            add(
              NotificationItem(
                id:
                    data['id']?.toString() ??
                    DateTime.now().microsecondsSinceEpoch.toString(),
                title: data['title'] ?? 'Update',
                message: data['message'] ?? '',
                type: data['type'] ?? 'info',
                timestamp:
                    data['timestamp'] ?? DateTime.now().toIso8601String(),
                recipient: data['recipient'] ?? 'All',
                priority: data['priority'] ?? 'medium',
              ),
            );
          }
        } catch (_) {}
      });
    } catch (_) {}
  }

  void startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    // Poll more frequently for "near real-time" feel (5 seconds)
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      fetchFromServer();
    });
  }

  void stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  List<NotificationItem> getPaginatedNotifications(
    int page, {
    int pageSize = 10,
  }) {
    final start = page * pageSize;
    final end = start + pageSize;
    if (start >= _notifications.length) return const [];
    final safeEnd = end > _notifications.length ? _notifications.length : end;
    return _notifications.sublist(start, safeEnd);
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _autoRefreshTimer?.cancel();
    super.dispose();
  }
}
