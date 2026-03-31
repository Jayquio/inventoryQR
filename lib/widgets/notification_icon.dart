import 'package:flutter/material.dart';
import '../data/notification_service.dart';

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
        final filtered = NotificationService.instance.notifications.where((n) {
          final byRecipient = recipients == null || recipients!.contains(n.recipient);
          final byType = types == null || types!.contains(n.type);
          return !n.read && byRecipient && byType;
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
