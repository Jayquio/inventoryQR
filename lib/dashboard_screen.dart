// lib/dashboard_screen.dart
// Unified dashboard matching the React Dashboard component exactly.
// Adapts links based on user role (admin / staff / student).

import 'package:flutter/material.dart';
import 'data/api_client.dart';
import 'data/auth_service.dart';
import 'data/notification_service.dart';
import 'models/instrument.dart';
import 'core/theme.dart';
import 'core/constants.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Instrument> _instruments = [];
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        ApiClient.instance.fetchInstruments(),
        ApiClient.instance.fetchRequests(),
      ]);
      if (!mounted) return;
      setState(() {
        _instruments = results[0] as List<Instrument>;
        _requests = results[1] as List<Map<String, dynamic>>;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  String get _roleName {
    switch (AuthService.instance.currentRole) {
      case UserRole.admin:
      case UserRole.superadmin:
        return 'admin';
      case UserRole.teacher:
        return 'teacher';
      case UserRole.student:
        return 'student';
    }
  }

  bool get _isAdmin =>
      AuthService.instance.currentRole == UserRole.admin ||
      AuthService.instance.currentRole == UserRole.superadmin;

  @override
  Widget build(BuildContext context) {
    final pendingRequests =
        _requests.where((r) => (r['status'] ?? '') == 'pending').length;
    final availableInstruments =
        _instruments.where((i) => i.available > 0 && i.status.toLowerCase() == 'active').length;
    final unreadNotifs = NotificationService.instance.unreadCount;

    final stats = [
      _StatItem('Total Instruments', _instruments.length, Icons.science,
          AppTheme.primaryColor, AppTheme.primaryColor.withValues(alpha: 0.08), onTap: () {
        if (_isAdmin) {
          Navigator.pushNamed(context, AppRoutes.manageInstruments);
        } else {
          Navigator.pushNamed(context, AppRoutes.viewInstruments,
              arguments: AuthService.instance.currentRole == UserRole.teacher ? 'Teacher' : 'Student');
        }
      }),
      _StatItem('Available', availableInstruments, Icons.inventory_2,
          Colors.green.shade600, Colors.green.shade50, onTap: () {
        if (_isAdmin) {
          Navigator.pushNamed(context, AppRoutes.manageInstruments);
        } else {
          Navigator.pushNamed(context, AppRoutes.viewInstruments,
              arguments: AuthService.instance.currentRole == UserRole.teacher ? 'Teacher' : 'Student');
        }
      }),
      _StatItem('Pending Requests', pendingRequests, Icons.access_time,
          Colors.amber.shade700, Colors.amber.shade50, onTap: () {
        if (_isAdmin) {
          Navigator.pushNamed(context, AppRoutes.manageRequests);
        } else {
          Navigator.pushNamed(context, AppRoutes.trackStatus);
        }
      }),
    ];

    // Role-based navigation links
    final links = _isAdmin
        ? _adminLinks
        : AuthService.instance.currentRole == UserRole.teacher
            ? _teacherLinks
            : _studentLinks;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          // Header
          Container(
            color: AppTheme.primaryColor,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              right: 16,
              bottom: 16,
            ),
            child: Row(
              children: [
                // Logo
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.science, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MedLab Inventory',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${_roleName[0].toUpperCase()}${_roleName.substring(1)} Dashboard',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Role badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_roleName[0].toUpperCase()}${_roleName.substring(1)}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                // Notification Bell
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, AppRoutes.notificationCenter),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(Icons.notifications, color: Colors.white.withValues(alpha: 0.8), size: 20),
                      if (NotificationService.instance.unreadCount > 0)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${NotificationService.instance.unreadCount}',
                              style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Settings
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, AppRoutes.settings,
                      arguments: _isAdmin
                          ? 'Admin'
                          : AuthService.instance.currentRole == UserRole.teacher
                              ? 'Teacher'
                              : 'Student'),
                  child: Icon(Icons.settings,
                      color: Colors.white.withValues(alpha: 0.8), size: 20),
                ),
                const SizedBox(width: 12),
                // Logout
                GestureDetector(
                  onTap: () {
                    NotificationService.instance.clear(persist: true);
                    Navigator.pushNamedAndRemoveUntil(
                        context, '/login', (route) => false);
                  },
                  child: Icon(Icons.logout,
                      color: Colors.white.withValues(alpha: 0.8), size: 20),
                ),
              ],
            ),
          ),

          // Body
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 900),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Stat cards
                              _buildStatsGrid(stats),
                              const SizedBox(height: 24),

                              // Navigation links
                              _buildNavigationGrid(links),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: _isAdmin ? null : FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(
          context,
          AppRoutes.qrScanner,
          arguments: AuthService.instance.currentRole == UserRole.teacher
              ? 'Teacher'
              : 'Student',
        ),
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Scan QR'),
        backgroundColor: AppTheme.secondaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildStatsGrid(List<_StatItem> stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth > 600 ? 4 : 2;
        final width = (constraints.maxWidth - (cols - 1) * 12) / cols;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: stats.map((s) {
            return SizedBox(
              width: width,
              child: Card(
                elevation: 0.5,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  onTap: s.onTap,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: s.bg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(s.icon, color: s.color, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${s.value}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              Text(
                                s.label,
                                style: const TextStyle(
                                    fontSize: 11, color: Color(0xFF6B7280)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildNavigationGrid(List<_NavLink> links) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = R.columns(constraints.maxWidth, xs: 1, sm: 2, md: 3, lg: 3);
        final width = (constraints.maxWidth - (cols - 1) * 12) / cols;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: links.map((link) {
            return SizedBox(
              width: width,
              child: Card(
                elevation: 0.5,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    if (link.route.isNotEmpty) {
                      Navigator.pushNamed(context, link.route,
                          arguments: link.args);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(link.icon,
                              color: AppTheme.primaryColor, size: 22),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                link.label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                link.desc,
                                style: const TextStyle(
                                    fontSize: 12, color: Color(0xFF6B7280)),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward,
                            size: 16, color: Color(0xFF9CA3AF)),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  List<_NavLink> get _adminLinks => [
        _NavLink(AppRoutes.manageInstruments, Icons.science,
            'Manage Instruments', 'Add, edit, remove lab instruments'),
        _NavLink(AppRoutes.manageRequests, Icons.assignment,
            'Manage Requests', 'Approve or reject borrow requests'),
        _NavLink(AppRoutes.userManagement, Icons.people, 'User Management',
            'Manage students and teachers accounts'),
        _NavLink(AppRoutes.transactionLogs, Icons.bar_chart,
            'Transaction Logs', 'View all system transactions'),
        _NavLink(AppRoutes.generateReports, Icons.trending_up,
            'Generate Reports', 'Create inventory and usage reports'),
      ];

  List<_NavLink> get _teacherLinks => [
        _NavLink(AppRoutes.viewInstruments, Icons.science,
            'View Instruments', 'Browse available lab equipment',
            args: 'Teacher'),
        _NavLink(AppRoutes.submitRequest, Icons.assignment,
            'Submit Request', 'Request to borrow instruments'),
        _NavLink(AppRoutes.trackStatus, Icons.access_time, 'Track Status',
            'Check your request status'),
      ];

  List<_NavLink> get _studentLinks => [
        _NavLink(AppRoutes.viewInstruments, Icons.science,
            'View Instruments', 'Browse available lab equipment',
            args: 'Student'),
        _NavLink(AppRoutes.submitRequest, Icons.assignment,
            'Submit Request', 'Request to borrow instruments'),
        _NavLink(AppRoutes.trackStatus, Icons.access_time, 'Track Status',
            'Check your request status'),
      ];
}

class _StatItem {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final Color bg;
  final VoidCallback? onTap;
  const _StatItem(this.label, this.value, this.icon, this.color, this.bg, {this.onTap});
}

class _NavLink {
  final String route;
  final IconData icon;
  final String label;
  final String desc;
  final Object? args;
  const _NavLink(this.route, this.icon, this.label, this.desc, {this.args});
}
