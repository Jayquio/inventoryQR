// lib/screens/admin/manage_requests_screen.dart

import 'package:flutter/material.dart';
import '../../widgets/role_guard.dart';
import '../../models/request.dart';
import '../../widgets/search_bar.dart';
import '../../data/api_client.dart';
import '../../data/auth_service.dart';
import '../../core/theme.dart';

class ManageRequestsScreen extends StatefulWidget {
  const ManageRequestsScreen({super.key});

  @override
  State<ManageRequestsScreen> createState() => _ManageRequestsScreenState();
}

class _ManageRequestsScreenState extends State<ManageRequestsScreen>
    with SingleTickerProviderStateMixin {
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

      if (!mounted) return;

      setState(() {
        _requests = reqRows.map((e) => Request.fromJson(e)).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
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
    if (req.instrumentType == 'reagent') {
      _showMessage(
        const SnackBar(
          content: Text('Reagents are consumables and cannot be returned.'),
        ),
      );
      return;
    }
    if (req.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot sync return: request id is missing.'),
        ),
      );
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

      if (!mounted) return;
      _closeCurrentRouteIfPossible();
      _showMessage(const SnackBar(content: Text('Item marked as returned.')));
    } catch (e) {
      if (!mounted) return;
      _showMessage(
        SnackBar(
          content: Text(
            'Error: ${e.toString().replaceFirst(_exceptionPrefix, '')}',
          ),
        ),
      );
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
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Request approved!')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Request rejected.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showOverrideQuantityDialog(Request req) {
    final controller = TextEditingController(text: req.quantity.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: EdgeInsets.zero,
        title: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: const Row(
            children: [
              Icon(Icons.edit_note, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                'Override Quantity',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ],
          ),
        ),
        content: Container(
          width: 400, // Fixed width for better web presentation
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 18,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Student: ${req.studentName}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.inventory_2_outlined,
                          size: 18,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Instrument: ${req.instrumentName}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Adjustment',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  labelText: 'New Allocated Quantity',
                  prefixIcon: const Icon(Icons.add_task),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  helperText:
                      'Allocating a lower amount frees up units for other students.',
                  helperStyle: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final newQty = int.tryParse(controller.text);
              if (newQty == null || newQty <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid quantity.'),
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              try {
                await ApiClient.instance.updateRequestQuantity(
                  id: req.id,
                  quantity: newQty,
                  user: AuthService.instance.currentUsername,
                );
                await _loadData();
                if (!mounted) return;
                _showMessage(
                  const SnackBar(
                    content: Text('Quantity overridden successfully.'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                _showMessage(
                  SnackBar(
                    content: Text(
                      'Error: ${e.toString().replaceFirst(_exceptionPrefix, '')}',
                    ),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            icon: const Icon(Icons.check),
            label: const Text('Save Changes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
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
        content: Text(
          'Are you sure you want to delete this request for ${req.instrumentName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiClient.instance.deleteRequest(id: req.id);
                await _loadData();
                if (!mounted) return;
                _closeCurrentRouteIfPossible();
                _showMessage(const SnackBar(content: Text('Request deleted.')));
              } catch (e) {
                if (!mounted) return;
                _showMessage(
                  SnackBar(
                    content: Text(
                      'Error deleting: ${e.toString().replaceFirst(_exceptionPrefix, '')}',
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
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
      final matchesSearch =
          req.studentName.toLowerCase().contains(searchTerm) ||
          req.instrumentName.toLowerCase().contains(searchTerm);
      if (filterStatus == null) return matchesSearch;
      final matchesStatus = req.status == filterStatus;
      if (filterStatus == RequestStatus.approved) {
        return matchesSearch &&
            matchesStatus &&
            req.instrumentType != 'reagent';
      }
      return matchesSearch && matchesStatus;
    }).toList();

    if (filtered.isEmpty) {
      String emptyMessage;
      if (filterStatus == RequestStatus.pending) {
        emptyMessage = 'No pending requests.';
      } else if (filterStatus == RequestStatus.approved) {
        emptyMessage = 'No instruments to be returned.';
      } else {
        emptyMessage = 'No requests found.';
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(emptyMessage, style: const TextStyle(color: Colors.grey)),
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
                Text(
                  request.instrumentName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Student: ${request.studentName}',
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  'Purpose: ${request.purpose}',
                  style: const TextStyle(color: Colors.grey),
                ),
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
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    request.status.name.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Instrument: ${request.instrumentName}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  'Qty: ${request.quantity}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            Text(
              'Purpose: ${request.purpose}',
              style: const TextStyle(color: Colors.grey),
            ),
            if (request.course != null)
              Text(
                'Course: ${request.course}',
                style: const TextStyle(color: Colors.grey),
              ),
            const SizedBox(height: 16),
            _buildActions(request),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(Request request) {
    if (request.status == RequestStatus.pending) {
      return _buildPendingActions(request);
    }
    if (request.status == RequestStatus.approved) {
      return _buildApprovedActions(request);
    }
    return _buildDeleteOnlyAction(request);
  }

  Widget _buildPendingActions(Request request) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow =
            constraints.maxWidth < 600; // Increased to accommodate new button
        final approve = ElevatedButton(
          onPressed: () => _approveRequest(request),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: const Text('Approve'),
        );
        final reject = ElevatedButton(
          onPressed: () => _rejectRequest(request),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Reject'),
        );
        final override = Tooltip(
          message: 'Update the quantity for this request before approving.',
          child: ElevatedButton.icon(
            onPressed: () => _showOverrideQuantityDialog(request),
            icon: const Icon(Icons.edit_note, size: 20),
            label: const Text(
              'Override Qty',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              foregroundColor: AppTheme.primaryColor,
              elevation: 0,
              side: const BorderSide(color: AppTheme.primaryColor, width: 2),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
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
              Row(
                children: [
                  Expanded(child: approve),
                  const SizedBox(width: 8),
                  Expanded(child: reject),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: override),
                  const SizedBox(width: 8),
                  Expanded(child: delete),
                ],
              ),
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
            SizedBox(width: 180, child: override),
            const SizedBox(width: 8),
            SizedBox(width: 130, child: delete),
          ],
        );
      },
    );
  }

  Widget _buildApprovedActions(Request request) {
    if (request.instrumentType == 'reagent') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Chip(label: Text('Consumable - no return')),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () => _confirmDelete(request),
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

  Widget _buildDeleteOnlyAction(Request request) {
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

  void _closeCurrentRouteIfPossible() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  void _showMessage(SnackBar snackBar) {
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Color _getStatusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return Colors.orange;
      case RequestStatus.approved:
        return Colors.green;
      case RequestStatus.rejected:
        return Colors.red;
      case RequestStatus.returned:
        return Colors.blue;
    }
  }
}
