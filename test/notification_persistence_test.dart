import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_application_inventorymanagement/data/notification_service.dart';

void main() {
  test('notifications persist across reloads via SharedPreferences', () async {
    SharedPreferences.setMockInitialValues({});
    final service = NotificationService.instance;
    await service.loadFromStorage();
    expect(service.notifications.length, 0);

    service.add(NotificationItem(
      id: '1',
      title: 'Success',
      message: 'Instrument updated',
      type: 'success',
      timestamp: DateTime.now().toIso8601String(),
      recipient: 'Admin',
    ));

    // Verify persisted
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('notifications');
    expect(raw, isNotNull);
    final list = json.decode(raw!);
    expect(list is List, true);
    expect(list.length, 1);

    // Simulate reload by clearing in-memory and loading again
    await service.loadFromStorage();
    expect(service.notifications.length, 1);
    expect(service.notifications.first.title, 'Success');
  });
}
