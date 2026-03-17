import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import '../widgets/search_bar.dart';
import '../core/constants.dart';
 
class ModuleSearchItem {
  ModuleSearchItem({required this.title, required this.description, required this.route, required this.icon});
  final String title;
  final String description;
  final String route;
  final IconData icon;
}
 
class ModuleSearchController extends ChangeNotifier {
  ModuleSearchController._();
  static final ModuleSearchController instance = ModuleSearchController._();
  final TextEditingController controller = TextEditingController();
  String get query => controller.text;
  void setQuery(String q) {
    controller.text = q;
    controller.selection = TextSelection.collapsed(offset: q.length);
    notifyListeners();
  }
}
 
class ModuleSearchBar extends StatefulWidget {
  const ModuleSearchBar({super.key});
  @override
  State<ModuleSearchBar> createState() => _ModuleSearchBarState();
}
 
class _ModuleSearchBarState extends State<ModuleSearchBar> {
  final FocusNode _focusNode = FocusNode();
  final LayerLink _link = LayerLink();
  final ValueNotifier<int> _highlight = ValueNotifier<int>(-1);
  late final List<ModuleSearchItem> _modules;
  OverlayEntry? _overlay;
  List<ModuleSearchItem> _filtered = [];
  Timer? _autoCloseTimer;
 
  @override
  void initState() {
    super.initState();
    _modules = [
      ModuleSearchItem(title: 'Manage Instruments', description: 'Add, update, and view lab instruments', route: '/manage_instruments', icon: Icons.inventory),
      ModuleSearchItem(title: 'Review Requests', description: 'Approve or reject instrument requests', route: '/manage_requests', icon: Icons.assignment),
      ModuleSearchItem(title: 'Scan QR Code', description: 'Scan QR for quick actions', route: '/qr_scanner', icon: Icons.qr_code_scanner),
      ModuleSearchItem(title: 'Generate QR Code', description: 'Create borrow/receive/return QR (role-based)', route: '/qr_generator', icon: Icons.qr_code_2),
      ModuleSearchItem(title: 'My User QR', description: 'Show your user identity QR', route: '/user_qr', icon: Icons.badge),
      ModuleSearchItem(title: 'Generate Reports', description: 'Create inventory and usage reports', route: '/generate_reports', icon: Icons.report),
      ModuleSearchItem(title: 'Transaction Logs', description: 'View system activity logs', route: '/transaction_logs', icon: Icons.history),
      ModuleSearchItem(title: 'Notification Center', description: 'View all notifications', route: '/notification_center', icon: Icons.notifications),
      ModuleSearchItem(title: 'Settings', description: 'Configure preferences', route: '/settings', icon: Icons.settings),
      ModuleSearchItem(title: 'View Instruments', description: 'Browse available instruments', route: AppRoutes.viewInstruments, icon: Icons.inventory_2),
      ModuleSearchItem(title: 'Log Maintenance', description: 'Record maintenance activities', route: '/log_maintenance', icon: Icons.build),
      ModuleSearchItem(title: 'Handle Returns', description: 'Process item returns', route: '/handle_returns', icon: Icons.assignment_return),
      ModuleSearchItem(title: 'Submit Request', description: 'Request an instrument', route: '/submit_request', icon: Icons.add_circle),
      ModuleSearchItem(title: 'Track Status', description: 'Track your requests', route: '/track_status', icon: Icons.track_changes),
      ModuleSearchItem(title: 'Dashboard', description: 'Go to home dashboard', route: '/', icon: Icons.dashboard),
    ];
    _filtered = _modules;
    ModuleSearchController.instance.addListener(_onQueryChanged);
    ModuleSearchController.instance.controller.addListener(_onQueryChanged);
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _overlay?.remove();
        _overlay = null;
        _autoCloseTimer?.cancel();
      }
    });
  }
 
  @override
  void dispose() {
    _overlay?.remove();
    ModuleSearchController.instance.removeListener(_onQueryChanged);
    ModuleSearchController.instance.controller.removeListener(_onQueryChanged);
    _focusNode.dispose();
    _highlight.dispose();
    _autoCloseTimer?.cancel();
    super.dispose();
  }
 
  void _onQueryChanged() {
    final q = ModuleSearchController.instance.query.toLowerCase();
    setState(() {
      _filtered = _modules.where((m) => ('${m.title} ${m.description}').toLowerCase().contains(q)).toList();
    });
    if (q.isEmpty) {
      _overlay?.remove();
      _overlay = null;
      _autoCloseTimer?.cancel();
    } else {
      _updateOverlay();
      _scheduleAutoClose();
    }
  }
 
  void _updateOverlay() {
    _overlay?.remove();
    if (!mounted) return;
    _overlay = OverlayEntry(
      builder: (context) {
        return Positioned.fill(
          child: Stack(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  _overlay?.remove();
                  _overlay = null;
                  _autoCloseTimer?.cancel();
                },
              ),
              CompositedTransformFollower(
                link: _link,
                showWhenUnlinked: false,
                offset: const Offset(0, 52),
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(12),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 300,
                      minWidth: 280,
                      maxWidth: 420,
                    ),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        return ValueListenableBuilder<int>(
                          valueListenable: _highlight,
                          builder: (_, h, __) {
                            final selected = index == h;
                            final m = _filtered[index];
                            return InkWell(
                              onTap: () => _navigate(m),
                              child: Container(
                                color: selected ? Colors.blue.withValues(alpha: 0.08) : null,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                child: Row(
                                  children: [
                                    Icon(m.icon, color: Colors.blue),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(m.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                                          Text(m.description, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
    Overlay.of(context, rootOverlay: true).insert(_overlay!);
    _scheduleAutoClose();
  }
 
  void _navigate(ModuleSearchItem m) {
    FocusScope.of(context).unfocus();
    _overlay?.remove();
    _overlay = null;
    _autoCloseTimer?.cancel();
    Navigator.pushNamed(context, m.route);
  }
 
  void _onKeyEvent(KeyEvent e) {
    if (e is! KeyDownEvent) return;
    if (_filtered.isEmpty) return;
    if (e.logicalKey == LogicalKeyboardKey.arrowDown) {
      final next = (_highlight.value + 1).clamp(0, _filtered.length - 1);
      _highlight.value = next;
    } else if (e.logicalKey == LogicalKeyboardKey.arrowUp) {
      final prev = (_highlight.value - 1).clamp(0, _filtered.length - 1);
      _highlight.value = prev;
    } else if (e.logicalKey == LogicalKeyboardKey.enter) {
      final i = _highlight.value == -1 ? 0 : _highlight.value;
      _navigate(_filtered[i]);
    } else if (e.logicalKey == LogicalKeyboardKey.escape) {
      ModuleSearchController.instance.setQuery('');
    }
    _scheduleAutoClose();
  }
 
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Global module search',
      textField: true,
      child: CompositedTransformTarget(
        link: _link,
        child: KeyboardListener(
          focusNode: _focusNode,
          onKeyEvent: _onKeyEvent,
          child: DebouncedSearchBar(
            controller: ModuleSearchController.instance.controller,
            hintText: 'Search modules...',
            onChanged: (value) {},
          ),
        ),
      ),
    );
  }

  void _scheduleAutoClose() {
    _autoCloseTimer?.cancel();
    _autoCloseTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      if (_overlay != null) {
        _overlay!.remove();
        _overlay = null;
      }
    });
  }
}
