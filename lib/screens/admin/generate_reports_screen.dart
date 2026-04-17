// lib/screens/admin/generate_reports_screen.dart

import 'package:flutter/material.dart';
import '../../data/api_client.dart';
import '../../models/instrument.dart';
import '../../core/theme.dart';

class GenerateReportsScreen extends StatefulWidget {
  const GenerateReportsScreen({super.key});

  @override
  State<GenerateReportsScreen> createState() => _GenerateReportsScreenState();
}

class _GenerateReportsScreenState extends State<GenerateReportsScreen> {
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        body: const Center(
          child: Text(
            'Loading reports...',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    // Category breakdown
    final categoryMap = <String, int>{};
    for (final i in _instruments) {
      final cat = i.category.isNotEmpty ? i.category : 'Other';
      categoryMap[cat] = (categoryMap[cat] ?? 0) + 1;
    }

    // Request status breakdown
    final statusCounts = <String, int>{};
    for (final s in ['pending', 'approved', 'rejected', 'returned']) {
      final count =
          _requests.where((r) => (r['status'] ?? '') == s).length;
      if (count > 0) statusCounts[s] = count;
    }

    // Top borrowed instruments
    final borrowMap = <String, int>{};
    for (final r in _requests) {
      final name = (r['instrumentName'] ?? '') as String;
      if (name.isNotEmpty) {
        borrowMap[name] = (borrowMap[name] ?? 0) + 1;
      }
    }
    final borrowEntries = borrowMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topBorrowed = borrowEntries.take(6).toList();

    final activeCount =
        _instruments.where((i) => i.status.toLowerCase() == 'active').length;

    final stats = [
      _StatItem(
        'Total Instruments',
        _instruments.length,
        Icons.science,
        AppTheme.primaryColor,
        AppTheme.primaryColor.withValues(alpha: 0.08),
      ),
      _StatItem(
        'Total Requests',
        _requests.length,
        Icons.assignment,
        Colors.green.shade600,
        Colors.green.shade50,
      ),
      _StatItem(
        'Maintenance Logs',
        0,
        Icons.build,
        Colors.amber.shade700,
        Colors.amber.shade50,
      ),
      _StatItem(
        'Active Instruments',
        activeCount,
        Icons.trending_up,
        Colors.blue.shade600,
        Colors.blue.shade50,
      ),
    ];

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
                  child: const Icon(Icons.arrow_back, color: Colors.white70, size: 22),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.trending_up, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'Reports & Analytics',
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary stats
                      _buildStatsGrid(stats),
                      const SizedBox(height: 24),

                      // Category + Status breakdowns side by side
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth > 600) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildBreakdownCard(
                                    'Instruments by Category',
                                    categoryMap,
                                    _categoryColors,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildBreakdownCard(
                                    'Requests by Status',
                                    statusCounts,
                                    _statusColors,
                                  ),
                                ),
                              ],
                            );
                          }
                          return Column(
                            children: [
                              _buildBreakdownCard(
                                'Instruments by Category',
                                categoryMap,
                                _categoryColors,
                              ),
                              const SizedBox(height: 16),
                              _buildBreakdownCard(
                                'Requests by Status',
                                statusCounts,
                                _statusColors,
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // Most Requested
                      _buildMostRequestedCard(topBorrowed),
                      const SizedBox(height: 24),

                      // Instrument Availability Table
                      _buildAvailabilityTable(),
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

  Widget _buildStatsGrid(List<_StatItem> stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth > 600 ? 4 : 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: stats.map((s) {
            final width =
                (constraints.maxWidth - (cols - 1) * 12) / cols;
            return SizedBox(
              width: width,
              child: Card(
                elevation: 0.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: s.bg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(s.icon, color: s.color, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.value.toString(),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                          ),
                          Text(
                            s.label,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  static const _categoryColors = [
    Color(0xFF6366F1),
    Color(0xFF22C55E),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
    Color(0xFF06B6D4),
    Color(0xFFEC4899),
  ];

  static const _statusColors = [
    Color(0xFF6366F1),
    Color(0xFF22C55E),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
  ];

  Widget _buildBreakdownCard(
    String title,
    Map<String, int> data,
    List<Color> colors,
  ) {
    if (data.isEmpty) {
      return Card(
        elevation: 0.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 40),
              const Center(
                child: Text('No data', style: TextStyle(color: Colors.grey)),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      );
    }

    final total = data.values.fold<int>(0, (a, b) => a + b);
    final entries = data.entries.toList();

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ...entries.asMap().entries.map((e) {
              final idx = e.key;
              final entry = e.value;
              final pct = total > 0 ? entry.value / total : 0.0;
              final color = colors[idx % colors.length];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${entry.key[0].toUpperCase()}${entry.key.substring(1)}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                        Text(
                          '${entry.value}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation(color),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMostRequestedCard(List<MapEntry<String, int>> data) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Most Requested Instruments',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            if (data.isEmpty)
              const SizedBox(
                height: 120,
                child: Center(
                  child: Text('No data', style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ...data.map((entry) {
                final maxVal = data.first.value;
                final pct = maxVal > 0 ? entry.value / maxVal : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              entry.key,
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${entry.value}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation(
                            Color(0xFF6366F1),
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilityTable() {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Instrument Availability',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF9FAFB)),
              headingTextStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
              dataTextStyle: const TextStyle(
                fontSize: 13,
                color: Color(0xFF374151),
              ),
              columns: const [
                DataColumn(label: Text('Name')),
                DataColumn(label: Text('Category')),
                DataColumn(label: Text('Total')),
                DataColumn(label: Text('Available')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Condition')),
              ],
              rows: _instruments.isEmpty
                  ? [
                      const DataRow(cells: [
                        DataCell(Text('No instruments')),
                        DataCell(Text('')),
                        DataCell(Text('')),
                        DataCell(Text('')),
                        DataCell(Text('')),
                        DataCell(Text('')),
                      ]),
                    ]
                  : _instruments.map((i) {
                      return DataRow(cells: [
                        DataCell(Text(
                          i.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF111827),
                          ),
                        )),
                        DataCell(Text(
                          i.category,
                          style: const TextStyle(color: Color(0xFF6B7280)),
                        )),
                        DataCell(Text(
                          '${i.quantity}',
                          style: const TextStyle(color: Color(0xFF4B5563)),
                        )),
                        DataCell(Text(
                          '${i.available}',
                          style: TextStyle(
                            color: i.available > 0
                                ? Colors.green.shade600
                                : Colors.red.shade500,
                            fontWeight: i.available > 0
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        )),
                        DataCell(_buildStatusChip(i.status)),
                        DataCell(_buildConditionText(i.condition)),
                      ]);
                    }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.isNotEmpty ? '${status[0].toUpperCase()}${status.substring(1)}' : '',
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  Widget _buildConditionText(String cond) {
    return Text(
      cond.isNotEmpty ? '${cond[0].toUpperCase()}${cond.substring(1)}' : '',
      style: const TextStyle(fontSize: 12),
    );
  }
}

class _StatItem {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final Color bg;
  const _StatItem(this.label, this.value, this.icon, this.color, this.bg);
}