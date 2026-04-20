import 'package:flutter/material.dart';
import '../../data/api_client.dart';
import '../../models/instrument.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';

class ViewInstrumentsScreen extends StatefulWidget {
  final String userRole;
  const ViewInstrumentsScreen({super.key, this.userRole = 'Student'});

  @override
  State<ViewInstrumentsScreen> createState() => _ViewInstrumentsScreenState();
}

class _ViewInstrumentsScreenState extends State<ViewInstrumentsScreen> {
  List<Instrument> _instruments = [];
  String _search = '';
  String _category = 'all';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiClient.instance.fetchInstruments();
      if (!mounted) return;
      setState(() {
        _instruments = data;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  List<String> get _categories {
    final cats =
        _instruments.map((i) => i.category).where((c) => c.isNotEmpty).toSet();
    return ['all', ...cats];
  }

  List<Instrument> get _filtered {
    return _instruments.where((i) {
      final matchSearch = _search.isEmpty ||
          i.name.toLowerCase().contains(_search.toLowerCase()) ||
          (i.serialNumber?.toLowerCase().contains(_search.toLowerCase()) ??
              false);
      final matchCat =
          _category == 'all' || i.category == _category;
      return matchSearch && matchCat;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          // Header
          Container(
            color: AppTheme.primaryColor,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              right: 16,
              bottom: 16,
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back,
                      color: Colors.white70, size: 22),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.science, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'Lab Instruments',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Body
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    children: [
                      // Search + Category Filter
                      _buildSearchFilter(),
                      const SizedBox(height: 16),

                      // Content
                      Expanded(
                        child: _loading
                            ? const Center(
                                child: Text(
                                  'Loading instruments...',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : filtered.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No instruments found',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  )
                                : LayoutBuilder(
                                    builder: (context, constraints) {
                                      final cols = R.columns(
                                        constraints.maxWidth,
                                        xs: 2,
                                        sm: 2,
                                        md: 3,
                                        lg: 4,
                                      );
                                      return GridView.builder(
                                        gridDelegate:
                                            SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: cols,
                                          crossAxisSpacing: 12,
                                          mainAxisSpacing: 12,
                                          childAspectRatio: 0.58,
                                        ),
                                        itemCount: filtered.length,
                                        itemBuilder: (context, index) {
                                          return _buildInstrumentCard(
                                              filtered[index]);
                                        },
                                      );
                                    },
                                  ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchFilter() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 500) {
          return Row(
            children: [
              Expanded(child: _buildSearchField()),
              const SizedBox(width: 12),
              SizedBox(width: 180, child: _buildCategoryDropdown()),
            ],
          );
        }
        return Column(
          children: [
            _buildSearchField(),
            const SizedBox(height: 12),
            _buildCategoryDropdown(),
          ],
        );
      },
    );
  }

  Widget _buildSearchField() {
    return TextField(
      decoration: InputDecoration(
        prefixIcon:
            const Icon(Icons.search, size: 18, color: Color(0xFF9CA3AF)),
        hintText: 'Search instruments...',
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      style: const TextStyle(fontSize: 14),
      onChanged: (v) => setState(() => _search = v),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _category,
          isExpanded: true,
          style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
          items: _categories
              .map((c) => DropdownMenuItem(
                    value: c,
                    child:
                        Text(c == 'all' ? 'Instruments and Reagent' : c),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _category = v ?? 'all'),
        ),
      ),
    );
  }

  Widget _buildInstrumentCard(Instrument inst) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: icon + status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.science,
                      color: AppTheme.primaryColor, size: 22),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: _buildStatusBadge(inst.status),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Name
            Text(
              inst.name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Color(0xFF111827),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (inst.serialNumber != null &&
                inst.serialNumber!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                'S/N: ${inst.serialNumber}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              '${inst.category} · ${inst.location}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // Available count + condition
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.inventory_2_outlined,
                        size: 16, color: Color(0xFF9CA3AF)),
                    const SizedBox(width: 4),
                    Text(
                      '${inst.available}/${inst.quantity} avail',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF4B5563),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                _buildConditionBadge(inst.condition),
              ],
            ),

            const Spacer(),

            // Request button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/submit_request',
                    arguments: inst.name,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text('Request', style: TextStyle(fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final map = {
      'active': (Colors.green.shade50, Colors.green.shade700),
      'available': (Colors.green.shade50, Colors.green.shade700),
      'inactive': (const Color(0xFFF3F4F6), const Color(0xFF4B5563)),
      'maintenance': (Colors.amber.shade50, Colors.amber.shade700),
    };
    final pair = map[status.toLowerCase()] ??
        (Colors.green.shade50, Colors.green.shade700);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: pair.$1,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.isNotEmpty
            ? '${status[0].toUpperCase()}${status.substring(1).toLowerCase()}'
            : '',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: pair.$2,
        ),
      ),
    );
  }

  Widget _buildConditionBadge(String condition) {
    final map = {
      'good': (Colors.green.shade50, Colors.green.shade700),
      'excellent': (Colors.green.shade50, Colors.green.shade700),
      'fair': (Colors.yellow.shade50, Colors.yellow.shade800),
      'poor': (Colors.red.shade50, Colors.red.shade700),
    };
    final pair = map[condition.toLowerCase()] ??
        (Colors.green.shade50, Colors.green.shade700);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: pair.$1,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        condition.isNotEmpty
            ? '${condition[0].toUpperCase()}${condition.substring(1).toLowerCase()}'
            : '',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: pair.$2,
        ),
      ),
    );
  }
}
