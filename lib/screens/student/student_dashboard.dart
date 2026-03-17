// lib/screens/student/student_dashboard.dart

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_application_inventorymanagement/data/api_client.dart';
import 'package:flutter_application_inventorymanagement/models/instrument.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/module_search_bar.dart';
import '../../widgets/hover_scale_card.dart';
import '../../models/request.dart';
import '../../core/constants.dart';
import '../../widgets/notification_icon.dart';
import '../../data/auth_service.dart';
import '../../core/theme.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
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
      final items = rows.map((e) => Request.fromJson(e)).toList();
      final insts = await ApiClient.instance.fetchInstruments();
      if (!mounted) return;
      setState(() {
        _requests = items;
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
    final current = AuthService.instance.currentUsername.toLowerCase();
    final myRequests = _requests.where((req) => req.studentName.toLowerCase() == current).toList();
    final pendingRequests = myRequests.where((req) => req.status == RequestStatus.pending).length;
    final approvedRequests = myRequests.where((req) => req.status == RequestStatus.approved).length;
    final availableInstruments = _instruments.where((inst) => inst.available > 0).length;
    

    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Dashboard"),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          const NotificationIcon(recipients: ['Student'], types: ['success', 'error']),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
            tooltip: 'Refresh',
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
      drawer: AppDrawer(userRole: 'Student'),
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
                  padding: EdgeInsets.symmetric(horizontal: 8),
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
                        'Access laboratory instruments for your research',
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

              Text('Overview',
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
                        Icons.pending,
                        AppTheme.primaryColor,
                        onTap: () => Navigator.pushNamed(context, '/track_status'),
                      ),
                      _buildStatDivider(),
                      _buildStatItem(
                        context,
                        'Approved',
                        approvedRequests.toString(),
                        Icons.check_circle,
                        AppTheme.secondaryColor,
                        onTap: () => Navigator.pushNamed(context, '/track_status'),
                      ),
                      _buildStatDivider(),
                      _buildStatItem(
                        context,
                        'Total',
                        myRequests.length.toString(),
                        Icons.assignment,
                        AppTheme.primaryColor,
                        onTap: () => Navigator.pushNamed(context, '/track_status'),
                      ),
                      _buildStatDivider(),
                      _buildStatItem(
                        context,
                        'Available',
                        availableInstruments.toString(),
                        Icons.inventory,
                        AppTheme.secondaryColor,
                        onTap: () => Navigator.pushNamed(context, AppRoutes.viewInstruments, arguments: 'Student'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Quick Actions
              Text('Quick Actions',
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
                        title: 'Scan QR',
                        icon: Icons.qr_code_scanner,
                      color: AppTheme.secondaryColor,
                        onTap: () => Navigator.pushNamed(context, '/qr_scanner', arguments: 'Student'),
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
                        title: 'Instruments',
                        icon: Icons.inventory,
                      color: AppTheme.primaryColor,
                        onTap: () => Navigator.pushNamed(context, AppRoutes.viewInstruments),
                      ),
                      _buildActionCard(
                        context,
                        title: 'Track',
                        icon: Icons.track_changes,
                      color: AppTheme.primaryColor,
                        onTap: () => Navigator.pushNamed(context, '/track_status'),
                      ),
                      _buildActionCard(
                        context,
                        title: 'Notifications',
                        icon: Icons.notifications,
                      color: AppTheme.secondaryColor,
                        onTap: () => Navigator.pushNamed(context, '/notification_center'),
                      ),
                      _buildActionCard(
                        context,
                        title: 'Overview',
                        icon: Icons.dashboard,
                        color: AppTheme.primaryColor,
                        onTap: () => _showOverviewDialog(context, myRequests.length, pendingRequests, approvedRequests, availableInstruments),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              // Recent Requests
              if (myRequests.isNotEmpty) ...[
                const Text(
                  'Recent Requests',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 16),

                ...myRequests.take(3).map((request) => Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          _getStatusIcon(request.status),
                          color: _getStatusColor(request.status),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                request.instrumentName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Status: ${_getStatusText(request.status)}',
                                style: TextStyle(
                                  color: _getStatusColor(request.status),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
              ],

              const SizedBox(height: 24),

              // Important Notices
              const Text(
                'Important Notices',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 16),

              Card(
                elevation: 4,
                color: AppTheme.wisteria.withValues(alpha: 0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.announcement, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          const Text(
                            'Lab Usage Guidelines',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• Return instruments promptly after use\n• Handle equipment with care\n• Report any damage immediately\n• Follow safety protocols at all times',
                        style: TextStyle(fontSize: 14),
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

  void _showOverviewDialog(BuildContext context, int total, int pending, int approved, int available) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Student Overview'),
        content: SingleChildScrollView(
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _overviewStatTile(color: AppTheme.primaryColor, icon: Icons.pending, value: '$pending', label: 'My Pending'),
              _overviewStatTile(color: AppTheme.secondaryColor, icon: Icons.check_circle, value: '$approved', label: 'My Approved'),
              _overviewStatTile(color: Colors.blue, icon: Icons.assignment, value: '$total', label: 'My Total'),
              _overviewStatTile(color: AppTheme.secondaryColor, icon: Icons.inventory, value: '$available', label: 'Available'),
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
        width: 100,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
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
      height: 40,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.grey.withValues(alpha: 0.2),
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
        return Colors.orange;
      case RequestStatus.approved:
        return Colors.green;
      case RequestStatus.rejected:
        return Colors.red;
      case RequestStatus.returned:
        return Colors.blue;
    }
  }

  String _getStatusText(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return 'Pending Approval';
      case RequestStatus.approved:
        return 'Approved';
      case RequestStatus.rejected:
        return 'Rejected';
      case RequestStatus.returned:
        return 'Returned';
    }
  }

}

 
