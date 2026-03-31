// lib/screens/admin/transaction_logs_screen.dart

import 'package:flutter/material.dart';
import '../../widgets/search_bar.dart';

class TransactionLogsScreen extends StatefulWidget {
  const TransactionLogsScreen({super.key});

  @override
  State<TransactionLogsScreen> createState() => _TransactionLogsScreenState();
}

class _TransactionLogsScreenState extends State<TransactionLogsScreen> {
  static const String _adminUser = 'Admin User';
  static const String _adminIp = '192.168.1.100';

  final List<Map<String, dynamic>> _transactionLogs = [
    {
      'id': '1',
      'timestamp': '2024-01-20 10:30:15',
      'user': _adminUser,
      'action': 'LOGIN',
      'resource': 'System',
      'details': 'Successful login from Admin Computer',
      'ip': _adminIp
    },
    {
      'id': '2',
      'timestamp': '2024-01-20 10:35:22',
      'user': _adminUser,
      'action': 'CREATE',
      'resource': 'Instrument',
      'details': 'Added new instrument: Microscope Olympus CX23',
      'ip': _adminIp
    },
    {
      'id': '3',
      'timestamp': '2024-01-20 10:40:18',
      'user': 'John Teacher',
      'action': 'APPROVE',
      'resource': 'Request',
      'details': 'Approved request #REQ-001 for Jane Student',
      'ip': '192.168.1.101'
    },
    {
      'id': '4',
      'timestamp': '2024-01-20 10:45:33',
      'user': 'Jane Student',
      'action': 'BORROW',
      'resource': 'Instrument',
      'details': 'Borrowed Centrifuge Machine via QR scan',
      'ip': '192.168.1.102'
    },
    {
      'id': '5',
      'timestamp': '2024-01-20 11:00:45',
      'user': 'Bob Technician',
      'action': 'MAINTENANCE',
      'resource': 'Instrument',
      'details': 'Logged maintenance for Microscope Olympus CX23',
      'ip': '192.168.1.103'
    },
    {
      'id': '6',
      'timestamp': '2024-01-20 11:15:12',
      'user': _adminUser,
      'action': 'DELETE',
      'resource': 'User',
      'details': 'Deleted inactive user account',
      'ip': _adminIp
    },
    {
      'id': '7',
      'timestamp': '2024-01-20 11:30:28',
      'user': 'John Teacher',
      'action': 'RETURN',
      'resource': 'Instrument',
      'details': 'Processed return of Centrifuge Machine',
      'ip': '192.168.1.101'
    },
    {
      'id': '8',
      'timestamp': '2024-01-20 12:00:00',
      'user': _adminUser,
      'action': 'REPORT',
      'resource': 'System',
      'details': 'Generated monthly usage report',
      'ip': _adminIp
    },
  ];

  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> get _filteredLogs {
    List<Map<String, dynamic>> filtered = _transactionLogs;

    // Filter by action type
    if (_selectedFilter != 'All') {
      filtered = filtered.where((log) => log['action'] == _selectedFilter).toList();
    }

    // Filter by search term
    if (_searchController.text.isNotEmpty) {
      final searchTerm = _searchController.text.toLowerCase();
      filtered = filtered.where((log) =>
        log['user'].toLowerCase().contains(searchTerm) ||
        log['action'].toLowerCase().contains(searchTerm) ||
        log['resource'].toLowerCase().contains(searchTerm) ||
        log['details'].toLowerCase().contains(searchTerm)
      ).toList();
    }

    return filtered;
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'LOGIN':
        return Colors.green;
      case 'CREATE':
        return Colors.blue;
      case 'UPDATE':
        return Colors.orange;
      case 'DELETE':
        return Colors.red;
      case 'APPROVE':
        return Colors.purple;
      case 'REJECT':
        return Colors.red;
      case 'BORROW':
        return Colors.teal;
      case 'RETURN':
        return Colors.indigo;
      case 'MAINTENANCE':
        return Colors.brown;
      case 'REPORT':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'LOGIN':
        return Icons.login;
      case 'CREATE':
        return Icons.add;
      case 'UPDATE':
        return Icons.edit;
      case 'DELETE':
        return Icons.delete;
      case 'APPROVE':
        return Icons.check_circle;
      case 'REJECT':
        return Icons.cancel;
      case 'BORROW':
        return Icons.arrow_forward;
      case 'RETURN':
        return Icons.arrow_back;
      case 'MAINTENANCE':
        return Icons.build;
      case 'REPORT':
        return Icons.description;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Logs'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                DebouncedSearchBar(
                  controller: _searchController,
                  hintText: 'Search logs...',
                  onChanged: (value) => setState(() {}),
                ),
                const SizedBox(height: 8),
                // Filter Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedFilter,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    'All',
                    'LOGIN',
                    'CREATE',
                    'UPDATE',
                    'DELETE',
                    'APPROVE',
                    'REJECT',
                    'BORROW',
                    'RETURN',
                    'MAINTENANCE',
                    'REPORT'
                  ].map((filter) {
                    return DropdownMenuItem(value: filter, child: Text(filter));
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedFilter = value!),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Summary Cards
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            _transactionLogs.length.toString(),
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const Text('Total Logs'),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            _filteredLogs.length.toString(),
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
                          ),
                          const Text('Filtered Results'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Logs List
          Expanded(
            child: ListView.builder(
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
                        Row(
                          children: [
                            Icon(
                              _getActionIcon(log['action']),
                              color: _getActionColor(log['action']),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        log['action'],
                                        style: TextStyle(
                                          color: _getActionColor(log['action']),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        log['resource'],
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    log['user'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              log['timestamp'].split(' ')[1], // Show only time
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          log['details'],
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              log['timestamp'],
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            const SizedBox(width: 16),
                            const Icon(Icons.computer, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              'IP: ${log['ip']}',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
