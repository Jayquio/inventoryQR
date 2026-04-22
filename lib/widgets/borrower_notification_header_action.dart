import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../data/notification_service.dart';

/// Bell + badge for student/teacher flows (borrowing screens). Taps open the
/// notification center and refreshes from the server.
class BorrowerNotificationHeaderAction extends StatelessWidget {
  const BorrowerNotificationHeaderAction({
    super.key,
    this.iconColor,
    this.size = 22,
  });

  final Color? iconColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? Colors.white.withValues(alpha: 0.9);
    return AnimatedBuilder(
      animation: NotificationService.instance,
      builder: (context, _) {
        final count = NotificationService.instance.unreadCount;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              NotificationService.instance.fetchFromServer();
              Navigator.pushNamed(context, AppRoutes.notificationCenter);
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Icon(Icons.notifications_outlined, color: color, size: size),
                  if (count > 0)
                    Positioned(
                      right: -2,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        constraints: const BoxConstraints(minWidth: 18),
                        child: Text(
                          count > 9 ? '9+' : '$count',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
