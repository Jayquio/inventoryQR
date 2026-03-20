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

    filtered = _filterByRole(filtered);
    filtered = _filterByType(filtered);
    filtered = _filterByRecipient(filtered);
    filtered = _filterByCourse(filtered);
    filtered = _filterByReadStatus(filtered);
    filtered = _filterBySearch(filtered);

    return filtered;
  }

  List<NotificationItem> _filterByRole(List<NotificationItem> items) {
    final role = AuthService.instance.currentRole;
    if (role == UserRole.staff) {
      return items.where((n) => n.recipient == 'Teacher' || n.recipient == 'Staff').toList();
    } else if (role == UserRole.student) {
      return items.where((n) => n.recipient == 'Student').toList();
    }
    return items;
  }

  List<NotificationItem> _filterByType(List<NotificationItem> items) {
    if (_selectedFilter == 'All') return items;
    return items.where((n) => n.type == _selectedFilter).toList();
  }

  List<NotificationItem> _filterByRecipient(List<NotificationItem> items) {
    if (_recipientFilter == 'All') return items;
    if (_recipientFilter == 'Teacher') {
      return items.where((n) => n.recipient == 'Teacher' || n.recipient == 'Staff').toList();
    }
    return items.where((n) => n.recipient == _recipientFilter).toList();
  }

  List<NotificationItem> _filterByCourse(List<NotificationItem> items) {
    if (_courseFilter == 'All') return items;
    return items.where((n) {
      final c = n.course?.trim().isNotEmpty == true ? n.course! : _parseCourse(n.message);
      return c.toLowerCase() == _courseFilter.toLowerCase();
    }).toList();
  }

  List<NotificationItem> _filterByReadStatus(List<NotificationItem> items) {
    if (!_showUnreadOnly) return items;
    return items.where((n) => !n.read).toList();
  }

  List<NotificationItem> _filterBySearch(List<NotificationItem> items) {
    if (_searchController.text.isEmpty) return items;
    final searchTerm = _searchController.text.toLowerCase();
    return items.where((n) {
      return n.title.toLowerCase().contains(searchTerm) ||
          n.message.toLowerCase().contains(searchTerm) ||
          n.recipient.toLowerCase().contains(searchTerm) ||
          n.priority.toLowerCase().contains(searchTerm);
    }).toList();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Center'),
      ),
      body: AnimatedBuilder(
        animation: NotificationService.instance,
        builder: (context, _) {
          return Column(
            children: [
              _buildSearchSection(),
              const SizedBox(height: 12),
              _buildFilterSection(),
              const SizedBox(height: 16),
              Expanded(
                child: _buildNotificationList(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DebouncedSearchBar(
        controller: _searchController,
        hintText: 'Search notifications...',
        onChanged: (value) => setState(() {}),
      ),
    );
  }

  Widget _buildFilterSection() {
    final role = AuthService.instance.currentRole;
    final bool showRecipientFilter = role == UserRole.admin;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  value: _selectedFilter,
                  items: ['All', 'request', 'error', 'warning', 'success', 'info'],
                  onChanged: (value) => setState(() => _selectedFilter = value!),
                ),
              ),
              if (showRecipientFilter) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDropdown(
                    value: _recipientFilter,
                    items: ['All', 'Admin', 'Teacher', 'Student'],
                    onChanged: (value) => setState(() => _recipientFilter = value!),
                  ),
                ),
              ],
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown(
                  value: _courseFilter,
                  items: _courseOptions(),
                  onChanged: (v) => setState(() => _courseFilter = v ?? 'All'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildChipRow(),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: items.map((filter) {
        return DropdownMenuItem(value: filter, child: Text(filter.toUpperCase()));
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildChipRow() {
    final unreadCount = NotificationService.instance.unreadCount;
    return Wrap(
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
    );
  }

  Widget _buildNotificationList() {
    final notifications = _filteredNotifications;
    if (notifications.isEmpty) {
      return const Center(child: Text('No notifications found.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        return _buildNotificationItem(notifications[index]);
      },
    );
  }

  Widget _buildNotificationItem(NotificationItem notification) {
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
            _buildLeadingIcon(notification),
            const SizedBox(width: 10),
            Expanded(child: _buildNotificationBody(notification)),
            if (!notification.read) _buildUnreadIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildLeadingIcon(NotificationItem n) {
    final color = _getTypeColor(n.type);
    return CircleAvatar(
      radius: 18,
      backgroundColor: color.withValues(alpha: 0.1),
      child: Icon(_getTypeIcon(n.type), color: color),
    );
  }

  Widget _buildNotificationBody(NotificationItem n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                n.title,
                style: TextStyle(
                  fontWeight: n.read ? FontWeight.w500 : FontWeight.bold,
                  fontSize: 14,
                  color: n.read ? Colors.black87 : Colors.black,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatDate(n.timestamp),
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          n.message,
          style: const TextStyle(fontSize: 13, color: Colors.black87),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        _buildBottomInfo(n),
      ],
    );
  }

  Widget _buildBottomInfo(NotificationItem n) {
    return Row(
      children: [
        Text(
          _formatTime(n.timestamp),
          style: const TextStyle(color: Colors.grey, fontSize: 11),
        ),
        const SizedBox(width: 8),
        _buildPriorityBadge(n.priority),
      ],
    );
  }

  Widget _buildPriorityBadge(String priority) {
    final color = _getPriorityColor(priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        priority.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildUnreadIndicator() {
    return Container(
      width: 10,
      height: 10,
      decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
