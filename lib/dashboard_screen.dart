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
      final instruments = await ApiClient.instance.fetchInstruments();
      List<Map<String, dynamic>> requests = [];
      try {
        final role = AuthService.instance.currentRole;
        final studentName = (role == UserRole.admin || role == UserRole.superadmin) 
            ? null 
            : AuthService.instance.currentUsername;
        requests = await ApiClient.instance.fetchRequests(studentName: studentName);
      } catch (e) {
        debugPrint('Error fetching requests: $e');
      }
      if (!mounted) return;
      setState(() {
        _instruments = instruments;
        _requests = requests;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error fetching instruments: $e');
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
    final pendingRequests = _requests
        .where((r) => (r['status'] ?? '').toString().toLowerCase() == 'pending')
        .length;
    // Calculate total physical items and available physical units
    final totalItems = _instruments.fold<int>(0, (sum, i) => sum + i.quantity);
    final availableItems = _instruments.fold<int>(0, (sum, i) => sum + i.available);

    final stats = [
      _StatItem(
        'Total Items',
        totalItems,
        Icons.inventory,
        AppTheme.primaryColor,
        AppTheme.primaryColor.withValues(alpha: 0.1),
        onTap: () => Navigator.pushNamed(context, AppRoutes.viewInstruments),
      ),
      _StatItem(
        'Available',
        availableItems,
        Icons.check_circle,
        AppTheme.secondaryColor,
        AppTheme.secondaryColor.withValues(alpha: 0.1),
        onTap: () => Navigator.pushNamed(context, AppRoutes.viewInstruments),
      ),
      _StatItem(
        'Pending',
        pendingRequests,
        Icons.pending_actions,
        Colors.amber.shade700,
        Colors.amber.shade50,
        onTap: () => Navigator.pushNamed(
          context,
          _isAdmin ? AppRoutes.manageRequests : AppRoutes.trackStatus,
        ),
      ),
    ];

    // Role-based navigation links
    final links = _isAdmin
        ? _adminLinks
        : AuthService.instance.currentRole == UserRole.teacher
        ? _teacherLinks
        : _studentLinks;

    final screenW = MediaQuery.sizeOf(context).width;
    final compactHeader = screenW < 400;
    final titleSize = _isAdmin
        ? (compactHeader ? 17.0 : 20.0)
        : (compactHeader ? 16.0 : 19.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          // Header
          Container(
            color: AppTheme.primaryColor,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              left: 12,
              right: 12,
              bottom: 12,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.science,
                    color: Colors.white,
                    size: compactHeader ? 20 : 24,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MedLab Inventory',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: titleSize,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (!compactHeader || _isAdmin)
                        Text(
                          '${_roleName[0].toUpperCase()}${_roleName.substring(1)} Dashboard',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                if (!compactHeader)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_roleName[0].toUpperCase()}${_roleName.substring(1)}',
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                  ),
                if (compactHeader) const SizedBox(width: 4),
                if (!compactHeader) const SizedBox(width: 6),
                AnimatedBuilder(
                  animation: NotificationService.instance,
                  builder: (context, _) {
                    final count = NotificationService.instance.unreadCount;
                    return IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      onPressed: () {
                        NotificationService.instance.fetchFromServer();
                        Navigator.pushNamed(
                          context,
                          AppRoutes.notificationCenter,
                        );
                      },
                      icon: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.notifications_outlined,
                            color: Colors.white.withValues(alpha: 0.9),
                            size: compactHeader ? 22 : 24,
                          ),
                          if (count > 0)
                            Positioned(
                              right: 0,
                              top: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                constraints: const BoxConstraints(minWidth: 16),
                                child: Text(
                                  count > 9 ? '9+' : '$count',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  onPressed: () => Navigator.pushNamed(
                    context,
                    AppRoutes.settings,
                    arguments: _isAdmin
                        ? 'Admin'
                        : AuthService.instance.currentRole == UserRole.teacher
                        ? 'Teacher'
                        : 'Student',
                  ),
                  icon: Icon(
                    Icons.settings_outlined,
                    color: Colors.white.withValues(alpha: 0.9),
                    size: compactHeader ? 22 : 24,
                  ),
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
                      padding: const EdgeInsets.only(
                        left: 16,
                        top: 16,
                        right: 16,
                        bottom: 80, // Add bottom padding to account for the FAB
                      ),
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
      floatingActionButton: _isAdmin
          ? null
          : FloatingActionButton.extended(
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
                  borderRadius: BorderRadius.circular(12),
                ),
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
                                  fontSize: 11,
                                  color: Color(0xFF6B7280),
                                ),
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
        final cols = R.columns(
          constraints.maxWidth,
          xs: 1,
          sm: 2,
          md: 3,
          lg: 3,
        );
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
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    if (link.route.isNotEmpty) {
                      Navigator.pushNamed(
                        context,
                        link.route,
                        arguments: link.args,
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(
                              alpha: 0.08,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            link.icon,
                            color: AppTheme.primaryColor,
                            size: 22,
                          ),
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
                                  fontSize: 12,
                                  color: Color(0xFF6B7280),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: Color(0xFF9CA3AF),
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

  List<_NavLink> get _adminLinks => [
    _NavLink(
      AppRoutes.manageInstruments,
      Icons.science,
      'Manage Instruments',
      'Add, edit, remove lab instruments',
    ),
    _NavLink(
      AppRoutes.manageRequests,
      Icons.assignment,
      'Manage Requests',
      'Approve or reject borrow requests',
    ),
    _NavLink(
      AppRoutes.userManagement,
      Icons.people,
      'User Management',
      'Manage students and teachers accounts',
    ),
    _NavLink(
      AppRoutes.transactionLogs,
      Icons.bar_chart,
      'Transaction Logs',
      'View all system transactions',
    ),
    _NavLink(
      AppRoutes.generateReports,
      Icons.trending_up,
      'Generate Reports',
      'Create inventory and usage reports',
    ),
    _NavLink(
      AppRoutes.userQr,
      Icons.qr_code,
      'User QR Codes',
      'Generate/Download user identification QRs',
    ),
  ];

  List<_NavLink> get _teacherLinks => [
    _NavLink(
      AppRoutes.viewInstruments,
      Icons.science,
      'View Instruments',
      'Browse available lab equipment',
      args: 'Teacher',
    ),
    _NavLink(
      AppRoutes.submitRequest,
      Icons.assignment,
      'Submit Request',
      'Request to borrow instruments',
    ),
    _NavLink(
      AppRoutes.userQr,
      Icons.qr_code,
      'My QR Code',
      'Show your ID for scanning',
    ),
    _NavLink(
      AppRoutes.trackStatus,
      Icons.access_time,
      'Track Status',
      'Check your request status',
    ),
  ];

  List<_NavLink> get _studentLinks => [
    _NavLink(
      AppRoutes.viewInstruments,
      Icons.science,
      'View Instruments',
      'Browse available lab equipment',
      args: 'Student',
    ),
    _NavLink(
      AppRoutes.submitRequest,
      Icons.assignment,
      'Submit Request',
      'Request to borrow instruments',
    ),
    _NavLink(
      AppRoutes.userQr,
      Icons.qr_code,
      'My QR Code',
      'Show your ID for scanning',
    ),
    _NavLink(
      AppRoutes.trackStatus,
      Icons.access_time,
      'Track Status',
      'Check your request status',
    ),
  ];
}

class _StatItem {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final Color bg;
  final VoidCallback? onTap;
  const _StatItem(
    this.label,
    this.value,
    this.icon,
    this.color,
    this.bg, {
    this.onTap,
  });
}

class _NavLink {
  final String route;
  final IconData icon;
  final String label;
  final String desc;
  final Object? args;
  const _NavLink(this.route, this.icon, this.label, this.desc, {this.args});
}
