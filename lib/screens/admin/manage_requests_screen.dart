// lib/screens/admin/manage_requests_screen.dart

import 'package:flutter/material.dart';
import '../../widgets/role_guard.dart';
import '../../models/request.dart';
import '../../widgets/search_bar.dart';
import '../../data/notification_service.dart';
import '../../data/api_client.dart';
import '../../data/auth_service.dart';
import '../../core/theme.dart';

class ManageRequestsScreen extends StatefulWidget {
  const ManageRequestsScreen({super.key});

  @override
  State<ManageRequestsScreen> createState() => _ManageRequestsScreenState();
}

class _ManageRequestsScreenState extends State<ManageRequestsScreen> with SingleTickerProviderStateMixin {
  static const String _exceptionPrefix = 'Exception: ';

  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  List<Request> _requests = [];
  bool _loading = true;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final reqRows = await ApiClient.instance.fetchRequests();
      
      if (!context.mounted) return;
      
      setState(() {
        _requests = reqRows.map((e) => Request.fromJson(e)).toList();
        _loading = false;
      });
    } catch (e) {
      if (!context.mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: ${e.toString()}')),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args == 'Return Queue') {
        _tabController.index = 1; // Go to "To Return" tab
      }
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _markReturned(Request req) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    
    if (req.id.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('Cannot sync return: request id is missing.')));
      return;
    }
    
    try {
      // Stock + transaction are applied in requests_update_status.php (returned).
      await ApiClient.instance.updateRequestStatus(
        id: req.id,
        status: 'returned',
        user: AuthService.instance.currentUsername,
      );
      
      // Refresh both requests and instruments to ensure stock is correct
      await _loadData();

      // If called from the bottom sheet details, close it
      if (navigator.canPop()) {
        navigator.pop();
      }

      NotificationService.instance.add(
        NotificationItem(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          title: 'Instrument Returned',
          message: '${req.studentName} returned ${req.instrumentName}.',
          type: 'info',
          timestamp: DateTime.now().toIso8601String(),
          recipient: 'Teacher',
          priority: 'low',
        ),
      );

      messenger.showSnackBar(const SnackBar(content: Text('Successfully marked as returned.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: ${e.toString().replaceFirst(_exceptionPrefix, '')}')));
    }
  }

  Future<void> _approveRequest(Request req) async {
    try {
      await ApiClient.instance.updateRequestStatus(
        id: req.id,
        status: 'approved',
        user: AuthService.instance.currentUsername,
      );
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request approved!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _rejectRequest(Request req) async {
    try {
      await ApiClient.instance.updateRequestStatus(
        id: req.id,
        status: 'rejected',
        user: AuthService.instance.currentUsername,
      );
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request rejected.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _confirmDelete(Request req) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Confirm Delete'),
          ],
        ),
        content: Text('Are you sure you want to delete this request for ${req.instrumentName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiClient.instance.deleteRequest(id: req.id);
                await _loadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request deleted.')));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting: $e')));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowed: const {UserRole.admin, UserRole.superadmin},
      webOnly: true,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Requests'),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(text: 'Pending', icon: Icon(Icons.hourglass_empty)),
              Tab(text: 'To Return', icon: Icon(Icons.keyboard_return)),
              Tab(text: 'All Logs', icon: Icon(Icons.history)),
            ],
          ),
        ),
        body: _loading 
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: DebouncedSearchBar(
                    controller: _searchController,
                    hintText: 'Search by student or instrument...',
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTabContent(RequestStatus.pending),
                      _buildTabContent(RequestStatus.approved),
                      _buildTabContent(null), // All logs
                    ],
                  ),
                ),
              ],
            ),
      ),
    );
  }

  Widget _buildTabContent(RequestStatus? filterStatus) {
    final searchTerm = _searchController.text.toLowerCase();
    final filtered = _requests.where((req) {
      final matchesSearch = req.studentName.toLowerCase().contains(searchTerm) || 
                           req.instrumentName.toLowerCase().contains(searchTerm);
      if (filterStatus == null) return matchesSearch;
      return matchesSearch && req.status == filterStatus;
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              filterStatus == RequestStatus.pending 
                ? 'No pending requests.' 
                : filterStatus == RequestStatus.approved 
                  ? 'No instruments to be returned.' 
                  : 'No requests found.',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final req = filtered[index];
        return InkWell(
          onTap: () => _showRequestDetails(req),
          child: _buildRequestCard(req),
        );
      },
    );
  }

  void _showRequestDetails(Request request) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(request.instrumentName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Student: ${request.studentName}', style: const TextStyle(fontSize: 16)),
                Text('Purpose: ${request.purpose}', style: const TextStyle(color: Colors.grey)),
                const Divider(height: 32),
                _buildActions(request),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestCard(Request request) {
    final statusColor = _getStatusColor(request.status);
    
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    request.studentName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    request.status.name.toUpperCase(),
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text('Instrument: ${request.instrumentName}', style: const TextStyle(fontWeight: FontWeight.w600)),
            Text('Purpose: ${request.purpose}', style: const TextStyle(color: Colors.grey)),
            if (request.course != null) Text('Course: ${request.course}', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            _buildActions(request),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(Request request) {
    if (request.status == RequestStatus.pending) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 480;
          final approve = ElevatedButton(
            onPressed: () => _approveRequest(request),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('Approve'),
          );
          final reject = ElevatedButton(
            onPressed: () => _rejectRequest(request),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Reject'),
          );
          final delete = OutlinedButton.icon(
            onPressed: () => _confirmDelete(request),
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
    } else if (request.status == RequestStatus.approved) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 360;
          final returned = ElevatedButton.icon(
            onPressed: () => _markReturned(request),
            icon: const Icon(Icons.assignment_return),
            label: const Text('Returned'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          );
          final delete = OutlinedButton.icon(
            onPressed: () => _confirmDelete(request),
            icon: const Icon(Icons.delete_outline, size: 20),
            label: const Text('Delete'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
          );
          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                returned,
                const SizedBox(height: 8),
                delete,
              ],
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
    } else {
      return Align(
        alignment: Alignment.centerRight,
        child: OutlinedButton.icon(
          onPressed: () => _confirmDelete(request),
          icon: const Icon(Icons.delete_outline, size: 18),
          label: const Text('Delete'),
          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
        ),
      );
    }
  }

  Color _getStatusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending: return Colors.orange;
      case RequestStatus.approved: return Colors.green;
      case RequestStatus.rejected: return Colors.red;
      case RequestStatus.returned: return Colors.blue;
    }
  }
}
