// lib/screens/admin/notification_center_screen.dart

import 'package:flutter/material.dart';
import '../../data/notification_service.dart';
import '../../widgets/search_bar.dart';
import '../../data/auth_service.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedFilter = 'All';
  bool _showUnreadOnly = false;
  String _recipientFilter = 'All';
  String _courseFilter = 'All';

  @override
  void initState() {
    super.initState();
    final role = AuthService.instance.currentRole;
    switch (role) {
      case UserRole.admin:
        _recipientFilter = 'Admin';
        break;
      case UserRole.staff:
        _recipientFilter = 'Teacher';
        break;
      case UserRole.student:
        _recipientFilter = 'Student';
        break;
    }
  }

  List<NotificationItem> get _filteredNotifications {
    List<NotificationItem> filtered = NotificationService.instance.notifications;

    final role = AuthService.instance.currentRole;
    if (role == UserRole.staff) {
      filtered = filtered.where((notification) => notification.recipient == 'Teacher' || notification.recipient == 'Staff').toList();
    } else if (role == UserRole.student) {
      filtered = filtered.where((notification) => notification.recipient == 'Student').toList();
    }

    // Filter by type
    if (_selectedFilter != 'All') {
      filtered = filtered.where((notification) => notification.type == _selectedFilter).toList();
    }

    // Filter by recipient
    if (_recipientFilter != 'All') {
      if (_recipientFilter == 'Teacher') {
        filtered = filtered.where((n) => n.recipient == 'Teacher' || n.recipient == 'Staff').toList();
      } else {
        filtered = filtered.where((notification) => notification.recipient == _recipientFilter).toList();
      }
    }

    // Filter by course
    if (_courseFilter != 'All') {
      filtered = filtered.where((n) {
        final c = n.course?.trim().isNotEmpty == true ? n.course! : _parseCourse(n.message);
        return c.toLowerCase() == _courseFilter.toLowerCase();
      }).toList();
    }

    // Filter by read status
    if (_showUnreadOnly) {
      filtered = filtered.where((notification) => !notification.read).toList();
    }

    if (_searchController.text.isNotEmpty) {
      final searchTerm = _searchController.text.toLowerCase();
      filtered = filtered.where((notification) {
        return notification.title.toLowerCase().contains(searchTerm) ||
            notification.message.toLowerCase().contains(searchTerm) ||
            notification.recipient.toLowerCase().contains(searchTerm) ||
            notification.priority.toLowerCase().contains(searchTerm);
      }).toList();
    }

    return filtered;
  }

  String _parseCourse(String message) {
    final idx = message.toLowerCase().indexOf('course:');
    if (idx == -1) return '';
    final substr = message.substring(idx + 7).trim();
    final stopIdx = substr.indexOf('•');
    final raw = (stopIdx >= 0 ? substr.substring(0, stopIdx) : substr).trim();
    return raw;
  }

  List<String> _courseOptions() {
    final courses = <String>{};
    for (final n in NotificationService.instance.notifications) {
      final c = n.course?.trim().isNotEmpty == true ? n.course! : _parseCourse(n.message);
      if (c.isNotEmpty) courses.add(c);
    }
    final list = ['All', ...courses.toList()..sort()];
    return list;
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'request':
        return Colors.purple;
      case 'error':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'success':
        return Colors.green;
      case 'info':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final y = dt.year.toString().padLeft(4, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final d = dt.day.toString().padLeft(2, '0');
      return '$y-$m-$d';
    } catch (_) {
      return iso.length >= 10 ? iso.substring(0, 10) : iso;
    }
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso);
      int hour = dt.hour;
      final minute = dt.minute.toString().padLeft(2, '0');
      final suffix = hour >= 12 ? 'PM' : 'AM';
      hour = hour % 12;
      if (hour == 0) hour = 12;
      final hh = hour.toString().padLeft(2, '0');
      return '$hh:$minute $suffix';
    } catch (_) {
      if (iso.contains('T')) {
        final parts = iso.split('T').last.split('.');
        return parts.first;
      }
      return iso;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'request':
        return Icons.assignment;
      case 'error':
        return Icons.error;
      case 'warning':
        return Icons.warning;
      case 'success':
        return Icons.check_circle;
      case 'info':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _markAsRead(String id) {
    NotificationService.instance.markAsRead(id);
    setState(() {});
  }

  void _markAllAsRead() {
    NotificationService.instance.markAllAsRead();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final role = AuthService.instance.currentRole;
    final bool showRecipientFilter = role == UserRole.admin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Center'),
      ),
      body: AnimatedBuilder(
        animation: NotificationService.instance,
        builder: (context, _) {
          final unreadCount = NotificationService.instance.unreadCount;
          return Column(
            children: [
              // Search
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DebouncedSearchBar(
                  controller: _searchController,
                  hintText: 'Search notifications...',
                  onChanged: (value) => setState(() {}),
                ),
              ),
              const SizedBox(height: 12),
              // Filters
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedFilter,
                            isExpanded: true,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: ['All', 'request', 'error', 'warning', 'success', 'info'].map((filter) {
                              return DropdownMenuItem(
                                  value: filter, child: Text(filter.toUpperCase()));
                            }).toList(),
                            onChanged: (value) => setState(() => _selectedFilter = value!),
                          ),
                        ),
                        if (showRecipientFilter) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _recipientFilter,
                              isExpanded: true,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'All', child: Text('ALL')),
                                DropdownMenuItem(value: 'Admin', child: Text('ADMIN')),
                                DropdownMenuItem(value: 'Teacher', child: Text('TEACHER')),
                                DropdownMenuItem(value: 'Student', child: Text('STUDENT')),
                              ],
                              onChanged: (value) => setState(() => _recipientFilter = value!),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ] else
                          const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            key: ValueKey('course_${_courseOptions().length}'),
                            initialValue: _courseFilter,
                            isExpanded: true,
                            items: _courseOptions()
                                .map((c) => DropdownMenuItem(value: c, child: Text(c.toUpperCase())))
                                .toList(),
                            onChanged: (v) => setState(() => _courseFilter = v ?? 'All'),
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        FilterChip(
                          label: const Text('Unread Only'),
                          selected: _showUnreadOnly,
                          onSelected: (selected) => setState(() => _showUnreadOnly = selected),
                        ),
                        if (unreadCount > 0)
                          TextButton.icon(
                            onPressed: _markAllAsRead,
                            icon: const Icon(Icons.done_all),
                            label: const Text('Mark All Read'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Notifications List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredNotifications.length,
                  itemBuilder: (context, index) {
                    final notification = _filteredNotifications[index];
                    final bgColor = notification.read ? Colors.white : Colors.blue.shade50;
                    return InkWell(
                      onTap: () => _markAsRead(notification.id),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: _getTypeColor(notification.type).withValues(alpha: 0.1),
                              child: Icon(
                                _getTypeIcon(notification.type),
                                color: _getTypeColor(notification.type),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          notification.title,
                                          style: TextStyle(
                                            fontWeight: notification.read ? FontWeight.w500 : FontWeight.bold,
                                            fontSize: 14,
                                            color: notification.read ? Colors.black87 : Colors.black,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _formatDate(notification.timestamp),
                                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    notification.message,
                                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        _formatTime(notification.timestamp),
                                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _getPriorityColor(notification.priority).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          notification.priority.toUpperCase(),
                                          style: TextStyle(
                                            color: _getPriorityColor(notification.priority),
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (!notification.read)
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
