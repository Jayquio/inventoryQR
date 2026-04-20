import 'package:flutter/material.dart';
import '../data/notification_service.dart';
import '../data/auth_service.dart';

class NotificationIcon extends StatelessWidget {
  const NotificationIcon({
    super.key,
    this.recipients,
    this.types,
  });

  final List<String>? recipients;
  final List<String>? types;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: NotificationService.instance,
      builder: (context, _) {
        final role = AuthService.instance.currentRole;
        final username = AuthService.instance.currentUsername;

        final filtered = NotificationService.instance.notifications.where((n) {
          // 1. Recipient filtering (User-aware)
          bool allowed = false;
          if (n.recipient == 'All') {
            allowed = true;
          } else if (n.recipient == username) {
            allowed = true;
          } else if (role == UserRole.admin || role == UserRole.superadmin) {
            if (n.recipient == 'Admin') allowed = true;
          } else if (role == UserRole.teacher) {
            if (n.recipient == 'Teacher' || n.recipient == 'Staff') {
              allowed = true;
            }
          } else if (role == UserRole.student) {
            if (n.recipient == 'Student') allowed = true;
          }

          // 2. Additional manual filters if provided
          final byRecipient = recipients == null || recipients!.contains(n.recipient);
          final byType = types == null || types!.contains(n.type);

          return !n.read && allowed && byRecipient && byType;
        }).toList();

        final count = filtered.length;
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications),
              tooltip: 'Notifications',
              onPressed: () => Navigator.pushNamed(context, '/notification_center'),
            ),
            if (count > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
