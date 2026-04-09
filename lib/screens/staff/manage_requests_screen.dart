// lib/screens/staff/manage_requests_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_application_inventorymanagement/data/api_client.dart';
import '../../models/request.dart';
import '../../widgets/search_bar.dart';
import '../../data/notification_service.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../data/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/role_guard.dart';

class ManageRequestsScreen extends StatefulWidget {
  const ManageRequestsScreen({super.key});

  @override
  State<ManageRequestsScreen> createState() => _ManageRequestsScreenState();
}

class _ManageRequestsScreenState extends State<ManageRequestsScreen> {
  static const String _exceptionPrefix = 'Exception: ';

  final TextEditingController _searchController = TextEditingController();
  List<Request> _requests = [];
  bool _loading = true;
  bool _initialized = false;

  /// From dashboard "Returns" / Approved stat — show approved (out) items only.
  bool _returnQueueFocus = false;

  @override
  void initState() {
    super.initState();
    _load();
    _loadPrefs();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args == 'Return Queue') {
        setState(() => _returnQueueFocus = true);
      }
      _initialized = true;
    }
  }

  bool _onlyPending = false;

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _onlyPending =
        prefs.getBool('teacher_show_pending_only') ??
        prefs.getBool('staff_show_pending_only') ??
        false;
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _load() async {
    try {
      final rows = await ApiClient.instance.fetchRequests();
      final items = rows.map((e) => Request.fromJson(e)).toList();
      if (!mounted) return;
      setState(() {
        _requests = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      if (!mounted) return;
      final err = e.toString().replaceFirst(_exceptionPrefix, '');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  void _updateRequestStatus(int index, RequestStatus status) {
    final req = _requests[index];
    final newStatusStr = switch (status) {
      RequestStatus.approved => 'approved',
      RequestStatus.rejected => 'rejected',
      RequestStatus.returned => 'returned',
      RequestStatus.pending => 'pending',
    };
    ApiClient.instance
        .updateRequestStatus(
          id: req.id,
          status: newStatusStr,
          user: AuthService.instance.currentUsername,
        )
        .then((_) {
          if (!mounted) return;
          setState(() {
            _requests[index] = Request(
              id: req.id,
              studentName: req.studentName,
              instrumentName: req.instrumentName,
              purpose: req.purpose,
              status: status,
            );
          });
        })
        .catchError((e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceFirst(_exceptionPrefix, '')),
            ),
          );
        });
    NotificationService.instance.add(
      NotificationItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: status == RequestStatus.approved
            ? 'Request Approved'
            : 'Request Rejected',
        message:
            '${req.studentName} ${status == RequestStatus.approved ? 'approved' : 'rejected'} for ${req.instrumentName}.',
        type: status == RequestStatus.approved ? 'success' : 'error',
        timestamp: DateTime.now().toIso8601String(),
        recipient: 'Teacher',
        priority: status == RequestStatus.approved ? 'medium' : 'high',
      ),
    );
    NotificationService.instance.add(
      NotificationItem(
        id: 'student_${DateTime.now().microsecondsSinceEpoch}',
        title: status == RequestStatus.approved
            ? 'Request Approved'
            : 'Request Rejected',
        message:
            'Your request for ${req.instrumentName} has been ${status == RequestStatus.approved ? 'approved' : 'rejected'}.',
        type: status == RequestStatus.approved ? 'success' : 'error',
        timestamp: DateTime.now().toIso8601String(),
        recipient: 'Student',
        priority: status == RequestStatus.approved ? 'medium' : 'high',
      ),
    );
  }

  void _deleteRequest(int index) {
    final req = _requests[index];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Request'),
        content: Text(
          'Delete request for ${req.instrumentName} by ${req.studentName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _loading = true);
              try {
                await ApiClient.instance.deleteRequest(id: req.id);
                if (!mounted) return;
                setState(() {
                  _requests.removeAt(index);
                  _loading = false;
                });
                NotificationService.instance.add(
                  NotificationItem(
                    id: 'student_${DateTime.now().microsecondsSinceEpoch}',
                    title: 'Request Removed',
                    message:
                        'Your request for ${req.instrumentName} was removed by Teacher.',
                    type: 'info',
                    timestamp: DateTime.now().toIso8601String(),
                    recipient: 'Student',
                    priority: 'low',
                  ),
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Request deleted.')),
                );
              } catch (e) {
                if (!mounted) return;
                setState(() => _loading = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      e.toString().replaceFirst(_exceptionPrefix, ''),
                    ),
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _markReturned(Request req) async {
    if (req.instrumentType == 'reagent') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reagents are consumables and cannot be returned.'),
        ),
      );
      return;
    }
    if (req.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot mark return: missing request id.'),
        ),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await ApiClient.instance.updateRequestStatus(
        id: req.id,
        status: 'returned',
        user: AuthService.instance.currentUsername,
      );
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Marked as returned.')));
      NotificationService.instance.add(
        NotificationItem(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          title: 'Instrument returned',
          message: '${req.studentName} returned ${req.instrumentName}.',
          type: 'success',
          timestamp: DateTime.now().toIso8601String(),
          recipient: 'Admin',
          priority: 'low',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst(_exceptionPrefix, '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Color _getStatusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.approved:
        return Colors.green;
      case RequestStatus.rejected:
        return Colors.red;
      case RequestStatus.pending:
        return Colors.orange;
      case RequestStatus.returned:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchTerm = _searchController.text.toLowerCase();
    final filteredRequests = _requests
        .where((req) {
          if (searchTerm.isEmpty) return true;
          return req.studentName.toLowerCase().contains(searchTerm) ||
              req.instrumentName.toLowerCase().contains(searchTerm) ||
              req.purpose.toLowerCase().contains(searchTerm) ||
              req.status.name.toLowerCase().contains(searchTerm);
        })
        .where((req) {
          if (_returnQueueFocus)
            return req.status == RequestStatus.approved &&
                req.instrumentType != 'reagent';
          if (_onlyPending) return req.status == RequestStatus.pending;
          return true;
        })
        .toList();

    return RoleGuard(
      allowed: const {UserRole.superadmin, UserRole.admin},
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _returnQueueFocus ? 'Awaiting return' : 'Manage Requests',
          ),
        ),
        body: Column(
          children: [
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: LinearProgressIndicator(),
              ),
            _buildSearchBar(),
            Expanded(child: _buildRequestList(filteredRequests)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_returnQueueFocus)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: InputChip(
                  label: const Text(
                    'Approved / out — mark returned when items are back',
                  ),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () => setState(() => _returnQueueFocus = false),
                ),
              ),
            ),
          DebouncedSearchBar(
            controller: _searchController,
            hintText: 'Search requests...',
            onChanged: (value) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestList(List<Request> filteredRequests) {
    if (filteredRequests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _returnQueueFocus
                ? 'No instruments awaiting return.'
                : 'No requests match your search.',
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: ListView.builder(
        key: ValueKey(filteredRequests.length),
        padding: const EdgeInsets.all(16),
        itemCount: filteredRequests.length,
        itemBuilder: (context, index) {
          final request = filteredRequests[index];
          final originalIndex = _requests.indexOf(request);
          return _buildRequestCard(request, originalIndex);
        },
      ),
    );
  }

  Widget _buildRequestCard(Request request, int originalIndex) {
    final w = MediaQuery.of(context).size.width;
    return _HoverListCard(
      margin: const EdgeInsets.only(bottom: 16),
      onTap: () => _showRequestDetails(request),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              request.studentName,
              style: TextStyle(
                fontSize: R.text(18, w),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text("Instrument: ${request.instrumentName}"),
            const SizedBox(height: 6),
            Text(
              "Status: ${request.status.name}",
              style: TextStyle(color: _getStatusColor(request.status)),
            ),
            const SizedBox(height: 12),
            _buildActionButtons(request, originalIndex),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(Request request, int originalIndex) {
    if (originalIndex < 0) return const SizedBox.shrink();
    if (request.status == RequestStatus.pending) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 480;
          final approve = ElevatedButton(
            onPressed: () =>
                _updateRequestStatus(originalIndex, RequestStatus.approved),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Approve'),
          );
          final reject = ElevatedButton(
            onPressed: () =>
                _updateRequestStatus(originalIndex, RequestStatus.rejected),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject'),
          );
          final delete = OutlinedButton.icon(
            onPressed: () => _deleteRequest(originalIndex),
            icon: const Icon(Icons.delete_outline, size: 20),
            label: const Text('Delete'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
          );
          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: approve),
                    const SizedBox(width: 8),
                    Expanded(child: reject),
                  ],
                ),
                const SizedBox(height: 8),
                delete,
              ],
            );
          }
          return Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(width: 140, child: approve),
              const SizedBox(width: 8),
              SizedBox(width: 140, child: reject),
              const SizedBox(width: 8),
              SizedBox(width: 120, child: delete),
            ],
          );
        },
      );
    }
    if (request.status == RequestStatus.approved) {
      if (request.instrumentType == 'reagent') {
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Chip(label: Text('Consumable - no return')),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () => _deleteRequest(originalIndex),
              icon: const Icon(Icons.delete_outline, size: 20),
              label: const Text('Delete'),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            ),
          ],
        );
      }
      return LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 360;
          final returned = ElevatedButton.icon(
            onPressed: _loading ? null : () => _markReturned(request),
            icon: const Icon(Icons.assignment_return),
            label: const Text('Returned'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          );
          final delete = OutlinedButton.icon(
            onPressed: () => _deleteRequest(originalIndex),
            icon: const Icon(Icons.delete_outline, size: 20),
            label: const Text('Delete'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
          );
          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [returned, const SizedBox(height: 8), delete],
            );
          }
          return Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(width: 200, child: returned),
              const SizedBox(width: 8),
              SizedBox(width: 120, child: delete),
            ],
          );
        },
      );
    }
    return OutlinedButton.icon(
      onPressed: () => _deleteRequest(originalIndex),
      icon: const Icon(Icons.delete_outline, size: 20),
      label: const Text('Delete'),
      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
    );
  }

  void _showRequestDetails(Request request) {
    final originalIndex = _requests.indexOf(request);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              24 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.instrumentName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Student: ${request.studentName}'),
                Text('Purpose: ${request.purpose}'),
                Text('Status: ${request.status.name}'),
                if (originalIndex >= 0) ...[
                  const SizedBox(height: 16),
                  _buildActionButtons(request, originalIndex),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _HoverListCard extends StatefulWidget {
  const _HoverListCard({required this.child, this.onTap, this.margin});
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  @override
  State<_HoverListCard> createState() => _HoverListCardState();
}

class _HoverListCardState extends State<_HoverListCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: widget.margin,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          transform: Matrix4.diagonal3Values(
            _hover ? 1.01 : 1.0,
            _hover ? 1.01 : 1.0,
            1.0,
          ),
          child: Card(
            elevation: _hover ? 8 : 6,
            child: InkWell(onTap: widget.onTap, child: widget.child),
          ),
        ),
      ),
    );
  }
}
