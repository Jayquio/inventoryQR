// lib/screens/staff/manage_requests_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_application_inventorymanagement/data/api_client.dart';
import '../../models/request.dart';
import '../../widgets/search_bar.dart';
import '../../data/notification_service.dart';
import '../../core/constants.dart';
import '../../data/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  @override
  void initState() {
    super.initState();
    _load();
    _loadPrefs();
  }

  bool _onlyPending = false;

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _onlyPending = prefs.getBool('staff_show_pending_only') ?? false;
    if (mounted) setState(() {});
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst(_exceptionPrefix, ''))),
      );
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
        .updateRequestStatus(id: req.id, status: newStatusStr, user: AuthService.instance.currentUsername)
        .then((_) {
      setState(() {
        _requests[index] = Request(
          id: req.id,
          studentName: req.studentName,
          instrumentName: req.instrumentName,
          purpose: req.purpose,
          status: status,
        );
      });
    }).catchError((e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst(_exceptionPrefix, ''))),
        );
      }
    });
    NotificationService.instance.add(
      NotificationItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: status == RequestStatus.approved ? 'Request Approved' : 'Request Rejected',
        message: '${req.studentName} ${status == RequestStatus.approved ? 'approved' : 'rejected'} for ${req.instrumentName}.',
        type: status == RequestStatus.approved ? 'success' : 'error',
        timestamp: DateTime.now().toIso8601String(),
        recipient: 'Teacher',
        priority: status == RequestStatus.approved ? 'medium' : 'high',
      ),
    );
    NotificationService.instance.add(
      NotificationItem(
        id: 'student_${DateTime.now().microsecondsSinceEpoch}',
        title: status == RequestStatus.approved ? 'Request Approved' : 'Request Rejected',
        message: 'Your request for ${req.instrumentName} has been ${status == RequestStatus.approved ? 'approved' : 'rejected'}.',
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
        content: Text('Delete request for ${req.instrumentName} by ${req.studentName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _loading = true);
              try {
                await ApiClient.instance.deleteRequest(id: req.id);
                setState(() {
                  _requests.removeAt(index);
                  _loading = false;
                });
                NotificationService.instance.add(
                  NotificationItem(
                    id: 'student_${DateTime.now().microsecondsSinceEpoch}',
                    title: 'Request Removed',
                    message: 'Your request for ${req.instrumentName} was removed by Teacher.',
                    type: 'info',
                    timestamp: DateTime.now().toIso8601String(),
                    recipient: 'Student',
                    priority: 'low',
                  ),
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Request deleted.')),
                  );
                }
              } catch (e) {
                setState(() => _loading = false);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString().replaceFirst(_exceptionPrefix, ''))),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
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
    final filteredRequests = _requests.where((req) {
      if (searchTerm.isEmpty) return true;
      return req.studentName.toLowerCase().contains(searchTerm) ||
          req.instrumentName.toLowerCase().contains(searchTerm) ||
          req.purpose.toLowerCase().contains(searchTerm) ||
          req.status.name.toLowerCase().contains(searchTerm);
    }).where((req) => _onlyPending ? req.status == RequestStatus.pending : true).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Manage Requests")),
      body: Column(
        children: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: LinearProgressIndicator(),
            ),
          _buildSearchBar(),
          Expanded(
            child: _buildRequestList(filteredRequests),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: DebouncedSearchBar(
        controller: _searchController,
        hintText: 'Search requests...',
        onChanged: (value) => setState(() {}),
      ),
    );
  }

  Widget _buildRequestList(List<Request> filteredRequests) {
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
              style: TextStyle(fontSize: R.text(18, w), fontWeight: FontWeight.bold),
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
    if (request.status == RequestStatus.pending) {
      return Row(
        children: [
          ElevatedButton(
            onPressed: () => _updateRequestStatus(originalIndex, RequestStatus.approved),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("Approve"),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () => _updateRequestStatus(originalIndex, RequestStatus.rejected),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Reject"),
          ),
        ],
      );
    }
    return OutlinedButton(
      onPressed: () => _deleteRequest(originalIndex),
      child: const Text("Delete"),
    );
  }

  void _showRequestDetails(Request request) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              request.instrumentName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Student: ${request.studentName}'),
            Text('Purpose: ${request.purpose}'),
            Text('Status: ${request.status.name}'),
          ],
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
  const _HoverListCard({
    required this.child,
    this.onTap,
    this.margin,
  });
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
          transform: Matrix4.diagonal3Values(_hover ? 1.01 : 1.0, _hover ? 1.01 : 1.0, 1.0),
          child: Card(
            elevation: _hover ? 8 : 6,
            child: InkWell(
              onTap: widget.onTap,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
