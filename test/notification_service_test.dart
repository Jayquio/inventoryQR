import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_inventorymanagement/data/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads notifications from storage', () async {
    final initial = [
      {
        'id': '1',
        'title': 'Success',
        'message': 'Instrument updated',
        'type': 'success',
        'timestamp': DateTime.now().toIso8601String(),
        'recipient': 'Admin',
        'read': false,
        'priority': 'medium',
      },
      {
        'id': '2',
        'title': 'Warning',
        'message': 'Low stock',
        'type': 'warning',
        'timestamp': DateTime.now().toIso8601String(),
        'recipient': 'Admin',
        'read': true,
        'priority': 'high',
      },
    ];
    SharedPreferences.setMockInitialValues({'notifications': json.encode(initial)});
    await NotificationService.instance.loadFromStorage();
    expect(NotificationService.instance.notifications.length, 2);
    expect(NotificationService.instance.unreadCount, 1);
  });

  test('persists notifications to storage', () async {
    SharedPreferences.setMockInitialValues({});
    await NotificationService.instance.clear(persist: true);
    NotificationService.instance.add(NotificationItem(
      id: '3',
      title: 'Info',
      message: 'Sync complete',
      type: 'info',
      timestamp: DateTime.now().toIso8601String(),
      recipient: 'All',
    ));
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('notifications');
    expect(raw != null && raw.isNotEmpty, true);
    final decoded = json.decode(raw!);
    expect(decoded is List, true);
    expect((decoded as List).isNotEmpty, true);
  });

  test('marks notifications as read and persists', () async {
    SharedPreferences.setMockInitialValues({});
    await NotificationService.instance.clear(persist: true);
    final id = '4';
    NotificationService.instance.add(NotificationItem(
      id: id,
      title: 'Error',
      message: 'Failure',
      type: 'error',
      timestamp: DateTime.now().toIso8601String(),
      recipient: 'All',
    ));
    NotificationService.instance.markAsRead(id);
    expect(NotificationService.instance.unreadCount, 0);
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('notifications')!;
    final list = (json.decode(raw) as List).cast<Map<String, dynamic>>();
    final saved = list.firstWhere((e) => e['id'] == id);
    expect(saved['read'], true);
  });
}
