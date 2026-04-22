import 'package:flutter/material.dart';
import '../../data/api_client.dart';
import '../../models/instrument.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../widgets/borrower_notification_header_action.dart';

class ViewInstrumentsScreen extends StatefulWidget {
  final String userRole;
  const ViewInstrumentsScreen({super.key, this.userRole = 'Student'});

  @override
  State<ViewInstrumentsScreen> createState() => _ViewInstrumentsScreenState();
}

class _ViewInstrumentsScreenState extends State<ViewInstrumentsScreen>
    with SingleTickerProviderStateMixin {
  // --- Data from API (for borrowing) ---
  List<Instrument> _dbInstruments = [];
  List<Map<String, dynamic>> _allRequests = [];
  bool _loading = true;

  // --- UI State ---
  String _search = '';
  int _selectedTab = 0; // 0=All, 1=Glasswares, 2=Machines, 3=Chemicals
  bool _isGridView = false; // Default to List View (Order/List)

  late TabController _tabController;

  static const _tabs = ['All Items', 'Glasswares', 'Machines', 'Chemicals'];
  static const _tabIcons = [
    Icons.inventory_2_outlined,
    Icons.science_outlined,
    Icons.precision_manufacturing_outlined,
    Icons.biotech_outlined,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedTab = _tabController.index);
      }
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final instruments = await ApiClient.instance.fetchInstruments();
      List<Map<String, dynamic>> requests = [];
      try {
        requests = await ApiClient.instance.fetchRequests();
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _dbInstruments = instruments;
        _allRequests = requests;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  // --- Computed counts from DB ---
  int get _totalItems => _dbInstruments.fold(0, (sum, i) => sum + i.quantity);
  int get _availableItems =>
      _dbInstruments.fold(0, (sum, i) => sum + i.available);
  int get _pendingItems => _allRequests
      .where((r) => (r['status'] ?? '').toString().toLowerCase() == 'pending')
      .length;

  // --- Filtered DB instruments ---
  List<Instrument> get _filteredDbInstruments {
    List<Instrument> baseList;
    switch (_selectedTab) {
      case 1: // Glasswares
        baseList = _dbInstruments.where((i) {
          final cat = i.category.toLowerCase();
          return cat.contains('glassware') ||
              cat.contains('microscopy') ||
              cat.contains('biology') ||
              cat.contains('measuring');
        }).toList();
        break;
      case 2: // Machines
        baseList = _dbInstruments.where((i) {
          final cat = i.category.toLowerCase();
          return cat.contains('machine') ||
              cat.contains('analyzer') ||
              cat.contains('processing') ||
              cat.contains('hematology') ||
              cat.contains('chemistry') ||
              cat.contains('sterilization') ||
              cat.contains('heating');
        }).toList();
        break;
      case 3: // Chemicals
        baseList = _dbInstruments.where((i) {
          final cat = i.category.toLowerCase();
          return cat.contains('chemical') || cat.contains('reagent');
        }).toList();
        break;
      default:
        baseList = _dbInstruments;
    }

    if (_search.isEmpty) return baseList;
    final q = _search.toLowerCase();
    return baseList.where((i) {
      return i.name.toLowerCase().contains(q) ||
          i.category.toLowerCase().contains(q) ||
          (i.serialNumber?.toLowerCase().contains(q) ?? false) ||
          i.location.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FA),
      body: Column(
        children: [
          _buildHeader(context),
          _buildTabBar(),
          _buildToolbar(),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                      strokeWidth: 2,
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    color: AppTheme.primaryColor,
                    child: _buildDbInstrumentsList(),
                  ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  //  HEADER
  // ═══════════════════════════════════════
  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white70,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.inventory_2_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lab Instruments',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: MediaQuery.sizeOf(context).width < 360
                            ? 16
                            : 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Browse, borrow & request instruments',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 11,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (widget.userRole == 'Student' || widget.userRole == 'Teacher')
                const BorrowerNotificationHeaderAction(),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.search,
                  size: 18,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
                hintText: 'Search by name, brand, serial no...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 13,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  //  STATS BAR (Real-time from DB)
  // ═══════════════════════════════════════
  Widget _buildStatsBar() {
    final narrow = MediaQuery.sizeOf(context).width < 430;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        children: [
          _statChip(
            Icons.inventory,
            '$_totalItems',
            'Total',
            const Color(0xFF6366F1),
            narrow ? 0.48 : 0.31,
          ),
          _statChip(
            Icons.check_circle_outline,
            '$_availableItems',
            'Available',
            const Color(0xFF10B981),
            narrow ? 0.48 : 0.31,
          ),
          _statChip(
            Icons.pending_outlined,
            '$_pendingItems',
            'Pending',
            const Color(0xFFF59E0B),
            narrow ? 0.48 : 0.31,
          ),
        ],
      ),
    );
  }

  Widget _statChip(
    IconData icon,
    String value,
    String label,
    Color color,
    double widthFactor,
  ) {
    final screenW = MediaQuery.sizeOf(context).width;
    final chipWidth = (screenW - 32) * widthFactor;
    return SizedBox(
      width: chipWidth.clamp(120.0, 220.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: color.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  //  TAB BAR
  // ═══════════════════════════════════════
  Widget _buildTabBar() {
    final narrow = MediaQuery.sizeOf(context).width < 520;
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppTheme.primaryColor,
        indicatorWeight: 3,
        labelColor: AppTheme.primaryColor,
        unselectedLabelColor: Colors.grey.shade500,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        isScrollable: narrow,
        tabAlignment: narrow ? TabAlignment.start : TabAlignment.fill,
        labelPadding: EdgeInsets.zero,
        tabs: List.generate(4, (i) {
          return Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_tabIcons[i], size: 14),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(_tabs[i], overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ═══════════════════════════════════════
  //  TOOLBAR
  // ═══════════════════════════════════════
  Widget _buildToolbar() {
    final narrow = MediaQuery.sizeOf(context).width < 430;
    final groupLabel = _selectedTab == 0
        ? 'All Items'
        : 'Grouped by ${_tabs[_selectedTab]}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFFF5F5FA),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.category_outlined, size: 14, color: Colors.grey.shade500),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              groupLabel,
              maxLines: narrow ? 2 : 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _viewToggleButton(Icons.view_list_rounded, false),
                Container(width: 1, height: 22, color: Colors.grey.shade300),
                _viewToggleButton(Icons.grid_view_rounded, true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _viewToggleButton(IconData icon, bool isGrid) {
    final active = _isGridView == isGrid;
    return GestureDetector(
      onTap: () => setState(() => _isGridView = isGrid),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? AppTheme.primaryColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.horizontal(
            left: Radius.circular(isGrid ? 0 : 7),
            right: Radius.circular(isGrid ? 7 : 0),
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: active ? AppTheme.primaryColor : Colors.grey.shade400,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  //  DB INSTRUMENTS LIST (TAB 0 - "All Items")
  // ═══════════════════════════════════════
  Widget _buildDbInstrumentsList() {
    final items = _filteredDbInstruments;
    if (items.isEmpty) return _buildEmpty();

    if (_isGridView) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final cols = R.columns(
            constraints.maxWidth,
            xs: 2,
            sm: 2,
            md: 3,
            lg: 4,
          );
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.78,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) => _buildDbGridCard(items[index]),
          );
        },
      );
    }

    return _buildGroupedListView(items);
  }

  Widget _buildGroupedListView(List<Instrument> items) {
    // Group by a secondary field or just use category as the group header
    final Map<String, List<Instrument>> groups = {};
    for (final item in items) {
      final key = item.category.isNotEmpty ? item.category : 'Other';
      groups.putIfAbsent(key, () => []).add(item);
    }

    final sortedEntries = groups.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: sortedEntries.length,
      itemBuilder: (context, index) {
        final entry = sortedEntries[index];
        return _buildGroupSection(entry.key, entry.value);
      },
    );
  }

  Widget _buildGroupSection(String groupName, List<Instrument> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Row(
            children: [
              Text(
                groupName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${items.length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...items.map((i) => _buildDbListRow(i)).toList(),
      ],
    );
  }

  Widget _buildDbGridCard(Instrument inst) {
    final available = inst.available > 0;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getDbCategoryIcon(inst.category),
                    color: AppTheme.primaryColor,
                    size: 18,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: available ? Colors.green : Colors.red.shade400,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              inst.name,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: Color(0xFF1F2937),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (inst.serialNumber != null && inst.serialNumber!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                'S/N: ${inst.serialNumber}',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              '${inst.category} · ${inst.location}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            // Qty badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: available ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${inst.available}/${inst.quantity} avail',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: available
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 30,
                    child: ElevatedButton(
                      onPressed: () => _requestInstrument(inst),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: EdgeInsets.zero,
                        elevation: 0,
                      ),
                      child: const Text(
                        'Request',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDbListRow(Instrument inst) {
    final available = inst.available > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 430;
            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: available ? Colors.green : Colors.red.shade400,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          inst.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _qtyBadge(inst, available),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (inst.category.isNotEmpty) _miniPill(inst.category),
                      if (inst.serialNumber != null &&
                          inst.serialNumber!.isNotEmpty)
                        _miniPill('S/N: ${inst.serialNumber}'),
                      _miniPill(inst.location),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: ElevatedButton(
                      onPressed: () => _requestInstrument(inst),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: EdgeInsets.zero,
                        elevation: 0,
                      ),
                      child: const Text('Request', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              );
            }

            return Row(
              children: [
                // Status dot
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: available ? Colors.green : Colors.red.shade400,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (available ? Colors.green : Colors.red).withValues(
                          alpha: 0.3,
                        ),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inst.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          if (inst.category.isNotEmpty) _miniPill(inst.category),
                          if (inst.category.isNotEmpty) const SizedBox(width: 6),
                          if (inst.serialNumber != null &&
                              inst.serialNumber!.isNotEmpty)
                            _miniPill('S/N: ${inst.serialNumber}'),
                          const Spacer(),
                          Flexible(
                            child: Text(
                              inst.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _qtyBadge(inst, available),
                const SizedBox(width: 10),
                SizedBox(
                  width: 72,
                  height: 28,
                  child: ElevatedButton(
                    onPressed: () => _requestInstrument(inst),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: EdgeInsets.zero,
                      elevation: 0,
                    ),
                    child: const Text(
                      'Request',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _qtyBadge(Instrument inst, bool available) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: available ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            '${inst.available}/${inst.quantity}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: available ? Colors.green.shade700 : Colors.red.shade700,
            ),
          ),
          Text(
            'avail',
            style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  void _requestInstrument(Instrument inst) {
    Navigator.pushNamed(context, '/submit_request', arguments: inst.name);
  }

  // ═══════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'No items found',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _infoPill(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.grey.shade400),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _miniPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  IconData _getDbCategoryIcon(String category) {
    final c = category.toLowerCase();
    if (c.contains('glass') || c.contains('microscop'))
      return Icons.science_outlined;
    if (c.contains('chem') || c.contains('reagent'))
      return Icons.biotech_outlined;
    if (c.contains('heat') || c.contains('steril'))
      return Icons.local_fire_department_outlined;
    return Icons.precision_manufacturing_outlined;
  }
}
