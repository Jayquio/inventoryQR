// lib/screens/admin/transaction_logs_screen.dart
import 'package:flutter/material.dart';
import '../../widgets/search_bar.dart';
import '../../core/constants.dart';

class TransactionLogsScreen extends StatefulWidget {
  const TransactionLogsScreen({super.key});

  @override
  State<TransactionLogsScreen> createState() => _TransactionLogsScreenState();
}

class _TransactionLogsScreenState extends State<TransactionLogsScreen> {
  final List<Map<String, dynamic>> _transactionLogs = [
    {
      'id': '1',
      'timestamp': '2024-01-20 10:30:15',
      'user': 'Admin User',
      'action': 'LOGIN',
      'resource': 'System',
      'details': 'Successful login from Admin Computer',
      'ip': '192.168.1.100'
    },
  ];

  final String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> get _filteredLogs {
    List<Map<String, dynamic>> filtered = _transactionLogs;
    if (_selectedFilter != 'All') {
      filtered = filtered.where((log) => log['action'] == _selectedFilter).toList();
    }
    if (_searchController.text.isNotEmpty) {
      final s = _searchController.text.toLowerCase();
      filtered = filtered.where((log) =>
          log['user'].toLowerCase().contains(s) ||
          log['action'].toLowerCase().contains(s) ||
          log['resource'].toLowerCase().contains(s) ||
          log['details'].toLowerCase().contains(s)).toList();
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Logs'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: DebouncedSearchBar(
              controller: _searchController,
              hintText: 'Search logs...',
              onChanged: (value) => setState(() {}),
            ),
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredLogs.length,
        itemBuilder: (context, index) {
          final log = _filteredLogs[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${log['action']} • ${log['resource']}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: R.text(14, w)),
                  ),
                  const SizedBox(height: 6),
                  Text(log['details']),
                  const SizedBox(height: 6),
                  Text('${log['timestamp']} • ${log['ip']}', style: TextStyle(color: Colors.grey, fontSize: R.text(12, w))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
