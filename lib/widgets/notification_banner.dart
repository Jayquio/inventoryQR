import 'package:flutter/material.dart';
import '../data/notification_service.dart';
import '../core/constants.dart';
import '../core/theme.dart';

class NotificationBanner extends StatelessWidget {
  const NotificationBanner({
    super.key,
    this.recipients,
    this.types,
  });

  final List<String>? recipients;
  final List<String>? types;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return AnimatedBuilder(
      animation: NotificationService.instance,
      builder: (context, _) {
        final unread = NotificationService.instance.unreadCount;
        if (unread == 0) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.symmetric(
            vertical: 10,
            horizontal: w < 420 ? 12 : 16,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications, color: AppTheme.primaryColor, size: 24),
                  if (unread > 0)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$unread',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'You have $unread unread notifications',
                  style: TextStyle(
                    fontSize: R.text(14, w),
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/notification_center'),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: Text('View All', style: TextStyle(fontSize: R.text(12, w))),
              ),
              const SizedBox(width: 4),
              if (unread > 0)
                OutlinedButton(
                  onPressed: () => NotificationService.instance.markAllAsRead(),
                  child: Text('Mark Read', style: TextStyle(fontSize: R.text(12, w))),
                ),
            ],
          ),
        );
      },
    );
  }
}
