// lib/screens/staff/staff_dashboard.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_application_inventorymanagement/data/api_client.dart';
import 'package:flutter_application_inventorymanagement/models/instrument.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/module_search_bar.dart';
import '../../widgets/hover_scale_card.dart';
import '../../models/request.dart';
import '../../core/constants.dart';
import '../../widgets/notification_icon.dart';
import '../../core/theme.dart';
import '../../data/auth_service.dart';

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({super.key});

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> with RouteAware {
  List<Request> _requests = [];
  List<Instrument> _instruments = [];
  bool _loading = true;
  Timer? _poller;

  @override
  void initState() {
    super.initState();
    _load();
    _poller = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    try {
      final rows = await ApiClient.instance.fetchRequests();
      final reqs = rows.map((e) => Request.fromJson(e)).toList();
      final insts = await ApiClient.instance.fetchInstruments();
      if (!mounted) return;
      setState(() {
        _requests = reqs;
        _instruments = insts;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final myName = AuthService.instance.currentUsername;
    final pendingRequests = _requests.where((req) => req.status == RequestStatus.pending).length;
    final approvedRequests = _requests.where((req) => req.status == RequestStatus.approved).length;
    final returnedRequests = _requests.where((req) => req.status == RequestStatus.returned).length;
    final lowStockInstruments = _instruments.where((inst) => inst.available <= 1).length;
    final myRequests = _requests.where((req) => req.studentName == myName).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Teacher Dashboard"),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          const NotificationIcon(recipients: ['Teacher'], types: ['success', 'error']),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _load,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ModuleSearchController.instance.setQuery('');
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      drawer: AppDrawer(userRole: 'Teacher'),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.backgroundLight, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ModuleSearchBar(),
              const SizedBox(height: 12),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: LinearProgressIndicator(),
                ),
              // Welcome Section
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, ${AuthService.instance.currentUsername}!',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Request instruments and track your borrowing status',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Statistics Cards
              Text('Current Status',
                  style: TextStyle(
                    fontSize: R.text(20, w),
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  )),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        context,
                        'Pending',
                        pendingRequests.toString(),
                        Icons.pending_actions,
                        AppTheme.primaryColor,
                        onTap: () => Navigator.pushNamed(context, '/track_status'),
                      ),
                      _buildStatDivider(),
                      _buildStatItem(
                        context,
                        'Active',
                        approvedRequests.toString(),
                        Icons.inventory_2,
                        AppTheme.secondaryColor,
                        onTap: () => Navigator.pushNamed(context, '/track_status'),
                      ),
                      _buildStatDivider(),
                      _buildStatItem(
                        context,
                        'Returns',
                        returnedRequests.toString(),
                        Icons.assignment_return,
                        AppTheme.primaryColor,
                        onTap: () => Navigator.pushNamed(context, '/track_status'),
                      ),
                      _buildStatDivider(),
                      _buildStatItem(
                        context,
                        'Low Stock',
                        lowStockInstruments.toString(),
                        Icons.warning,
                        Colors.red,
                        onTap: () => Navigator.pushNamed(context, '/view_instruments', arguments: 'Teacher'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Daily Tasks
              Text('Daily Tasks',
                  style: TextStyle(
                    fontSize: R.text(20, w),
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  )),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = R.columns(constraints.maxWidth, xs: 3, sm: 3, md: 4, lg: 5);
                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: R.tileAspect(constraints.maxWidth),
                    children: [
                      _buildActionCard(
                        context,
                        title: 'Request',
                        icon: Icons.add_circle,
                        color: AppTheme.secondaryColor,
                        onTap: () => Navigator.pushNamed(context, '/submit_request'),
                      ),
                      _buildActionCard(
                        context,
                        title: 'Track Status',
                        icon: Icons.timeline,
                        color: AppTheme.primaryColor,
                        onTap: () => Navigator.pushNamed(context, '/track_status'),
                      ),
                      _buildActionCard(
                        context,
                        title: 'Scan QR',
                        icon: Icons.qr_code_scanner,
                        color: AppTheme.secondaryColor,
                        onTap: () => Navigator.pushNamed(context, '/qr_scanner', arguments: 'Teacher'),
                      ),
                      _buildActionCard(
                        context,
                        title: 'My QR',
                        icon: Icons.qr_code_2,
                        color: AppTheme.primaryColor,
                        onTap: () => Navigator.pushNamed(context, '/user_qr'),
                      ),
                      _buildActionCard(
                        context,
                        title: 'Monitor',
                        icon: Icons.inventory,
                        color: AppTheme.primaryColor,
                        onTap: () => Navigator.pushNamed(context, '/view_instruments', arguments: 'Teacher'),
                      ),
                      _buildActionCard(
                        context,
                        title: 'Overview',
                        icon: Icons.dashboard,
                        color: AppTheme.primaryColor,
                        onTap: () => _showOverviewDialog(context, myRequests),
                      ),
                    ],
                  );
                },
              ),


              const SizedBox(height: 24),

              // My Borrow History
              Text('My Borrow History',
                  style: TextStyle(
                    fontSize: R.text(20, w),
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  )),

              const SizedBox(height: 12),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: myRequests.isEmpty
                      ? const Text('No borrow history yet.')
                      : Column(
                          children: [
                            ...myRequests.take(5).map((req) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  children: [
                                    Icon(
                                      _getStatusIcon(req.status),
                                      color: _getStatusColor(req.status),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        req.instrumentName,
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    Text(
                                      _getStatusText(req.status),
                                      style: TextStyle(
                                        color: _getStatusColor(req.status),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () => Navigator.pushNamed(context, '/track_status'),
                                icon: const Icon(Icons.open_in_new),
                                label: const Text('View All'),
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // Teacher dashboard simplified (no transaction notifications or urgent admin sections)
              const SizedBox(height: 8),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: AppTheme.primaryColor),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'As a Teacher, you can submit requests, scan equipment labels, and track your status.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOverviewDialog(BuildContext context, List<Request> myRequests) {
    final myPending = myRequests.where((r) => r.status == RequestStatus.pending).length;
    final myActive = myRequests.where((r) => r.status == RequestStatus.approved).length;
    final myReturned = myRequests.where((r) => r.status == RequestStatus.returned).length;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Teacher Overview'),
        content: SingleChildScrollView(
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _overviewStatTile(color: AppTheme.primaryColor, icon: Icons.pending_actions, value: '$myPending', label: 'My Pending'),
              _overviewStatTile(color: AppTheme.secondaryColor, icon: Icons.inventory_2, value: '$myActive', label: 'My Active'),
              _overviewStatTile(color: Colors.blue, icon: Icons.assignment_return, value: '$myReturned', label: 'My Returns'),
              _overviewStatTile(color: Colors.red, icon: Icons.warning, value: '${_instruments.where((i) => i.available <= 1).length}', label: 'Low Stock'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _overviewStatTile({
    required Color color,
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      constraints: const BoxConstraints(minWidth: 160),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
              Text(label, style: const TextStyle(color: Colors.black87)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 30,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: Colors.grey.withValues(alpha: 0.1),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return HoverScaleCard(
      baseElevation: 4,
      hoverElevation: 10,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return Icons.pending;
      case RequestStatus.approved:
        return Icons.check_circle;
      case RequestStatus.rejected:
        return Icons.cancel;
      case RequestStatus.returned:
        return Icons.assignment_return;
    }
  }

  Color _getStatusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return AppTheme.primaryColor;
      case RequestStatus.approved:
        return AppTheme.secondaryColor;
      case RequestStatus.rejected:
        return Colors.red;
      case RequestStatus.returned:
        return AppTheme.primaryColor;
    }
  }

  String _getStatusText(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return 'Pending';
      case RequestStatus.approved:
        return 'Approved';
      case RequestStatus.rejected:
        return 'Rejected';
      case RequestStatus.returned:
        return 'Returned';
    }
  }

}

 
