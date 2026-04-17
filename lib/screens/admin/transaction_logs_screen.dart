// lib/screens/admin/transaction_logs_screen.dart

import 'package:flutter/material.dart';
import '../../data/api_client.dart';
import '../../core/theme.dart';

class TransactionLogsScreen extends StatefulWidget {
  const TransactionLogsScreen({super.key});

  @override
  State<TransactionLogsScreen> createState() => _TransactionLogsScreenState();
}

class _TransactionLogsScreenState extends State<TransactionLogsScreen> {
  List<Map<String, dynamic>> _requests = [];
  String _search = '';
  String _filter = 'all';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiClient.instance.fetchRequests();
      if (!mounted) return;
      setState(() {
        _requests = data;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    return _requests.where((r) {
      final status = (r['status'] ?? '').toString().toLowerCase();
      final matchStatus = _filter == 'all' || status == _filter;
      final studentName =
          (r['studentName'] ?? '').toString().toLowerCase();
      final instrumentName =
          (r['instrumentName'] ?? '').toString().toLowerCase();
      final matchSearch = _search.isEmpty ||
          studentName.contains(_search.toLowerCase()) ||
          instrumentName.contains(_search.toLowerCase());
      return matchStatus && matchSearch;
    }).toList();
  }

  int _countStatus(String status) {
    return _requests
        .where((r) => (r['status'] ?? '').toString().toLowerCase() == status)
        .length;
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
                  child: const Icon(Icons.arrow_back, color: Colors.white70, size: 22),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.bar_chart, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'Transaction Logs',
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
            child: _loading
                ? const Center(
                    child: Text(
                      'Loading logs...',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 900),
                        child: Column(
                          children: [
                            // Search + Filter
                            _buildSearchFilter(),
                            const SizedBox(height: 16),

                            // Status summary cards
                            _buildStatusSummary(),
                            const SizedBox(height: 16),

                            // Data table
                            _buildDataTable(filtered),
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
              SizedBox(width: 160, child: _buildFilterDropdown()),
            ],
          );
        }
        return Column(
          children: [
            _buildSearchField(),
            const SizedBox(height: 12),
            _buildFilterDropdown(),
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
        hintText: 'Search...',
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

  Widget _buildFilterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _filter,
          isExpanded: true,
          style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('All')),
            DropdownMenuItem(value: 'pending', child: Text('Pending')),
            DropdownMenuItem(value: 'approved', child: Text('Approved')),
            DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
            DropdownMenuItem(value: 'returned', child: Text('Returned')),
          ],
          onChanged: (v) => setState(() => _filter = v ?? 'all'),
        ),
      ),
    );
  }

  Widget _buildStatusSummary() {
    final items = [
      _SummaryItem('pending', _countStatus('pending'),
          const Color(0xFFFFFBEB), Colors.amber.shade700),
      _SummaryItem('approved', _countStatus('approved'),
          const Color(0xFFF0FDF4), Colors.green.shade700),
      _SummaryItem('rejected', _countStatus('rejected'),
          const Color(0xFFFEF2F2), Colors.red.shade700),
      _SummaryItem('returned', _countStatus('returned'),
          const Color(0xFFF3F4F6), const Color(0xFF4B5563)),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth > 500 ? 4 : 2;
        final width = (constraints.maxWidth - (cols - 1) * 12) / cols;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items.map((item) {
            return Container(
              width: width,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: item.bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    '${item.count}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: item.textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.status[0].toUpperCase()}${item.status.substring(1)}',
                    style: TextStyle(fontSize: 12, color: item.textColor),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildDataTable(List<Map<String, dynamic>> data) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF9FAFB)),
          headingTextStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
          ),
          dataTextStyle: const TextStyle(fontSize: 13),
          columns: const [
            DataColumn(label: Text('Student')),
            DataColumn(label: Text('Instrument')),
            DataColumn(label: Text('Qty')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Course')),
            DataColumn(label: Text('Needed By')),
            DataColumn(label: Text('Action By')),
          ],
          rows: data.isEmpty
              ? [
                  const DataRow(cells: [
                    DataCell(Text('')),
                    DataCell(Text('')),
                    DataCell(Text('')),
                    DataCell(
                      Center(child: Text('No transactions found',
                        style: TextStyle(color: Colors.grey),
                      )),
                    ),
                    DataCell(Text('')),
                    DataCell(Text('')),
                    DataCell(Text('')),
                  ]),
                ]
              : data.map((req) {
                  final status =
                      (req['status'] ?? '').toString().toLowerCase();
                  final actionBy = (req['approvedBy'] ??
                          req['rejectedBy'] ??
                          req['returnedBy'] ??
                          '—')
                      .toString();

                  return DataRow(cells: [
                    DataCell(Text(
                      (req['studentName'] ?? '').toString(),
                      style: const TextStyle(color: Color(0xFF111827)),
                    )),
                    DataCell(Text(
                      (req['instrumentName'] ?? '').toString(),
                      style: const TextStyle(color: Color(0xFF374151)),
                    )),
                    DataCell(Text(
                      (req['quantity'] ?? '').toString(),
                      style: const TextStyle(color: Color(0xFF4B5563)),
                    )),
                    DataCell(_buildStatusBadge(status)),
                    DataCell(Text(
                      (req['course'] ?? '—').toString(),
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                      ),
                    )),
                    DataCell(Text(
                      (req['neededAt'] ?? '—').toString(),
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                      ),
                    )),
                    DataCell(Text(
                      actionBy,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                      ),
                    )),
                  ]);
                }).toList(),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final colors = {
      'pending': (const Color(0xFFFFF7ED), Colors.amber.shade700),
      'approved': (const Color(0xFFDCFCE7), Colors.green.shade700),
      'rejected': (const Color(0xFFFEE2E2), Colors.red.shade700),
      'returned': (const Color(0xFFF3F4F6), const Color(0xFF374151)),
    };
    final pair = colors[status] ??
        (const Color(0xFFF3F4F6), const Color(0xFF374151));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: pair.$1,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.isNotEmpty
            ? '${status[0].toUpperCase()}${status.substring(1)}'
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

class _SummaryItem {
  final String status;
  final int count;
  final Color bg;
  final Color textColor;
  const _SummaryItem(this.status, this.count, this.bg, this.textColor);
}
