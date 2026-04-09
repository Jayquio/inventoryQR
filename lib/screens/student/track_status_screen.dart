// lib/screens/student/track_status_screen.dart

import 'package:flutter/material.dart';
import '../../models/request.dart';
import '../../data/api_client.dart';

import '../../data/auth_service.dart';

class TrackStatusScreen extends StatefulWidget {
  const TrackStatusScreen({super.key});

  @override
  State<TrackStatusScreen> createState() => _TrackStatusScreenState();
}

class _TrackStatusScreenState extends State<TrackStatusScreen> {
  List<Request> _filteredRequests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _searchRequests();
  }

  Future<void> _searchRequests() async {
    final name = AuthService.instance.currentUsername;
    if (name.isNotEmpty) {
      if (!mounted) return;
      setState(() => _loading = true);
      try {
        final rows = await ApiClient.instance.fetchRequests(studentName: name);
        if (!mounted) return;
        setState(() {
          _filteredRequests = rows.map((e) => Request.fromJson(e)).toList();
          _loading = false;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _filteredRequests = [];
          _loading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Color _getStatusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.approved:
        return Colors.green;
      case RequestStatus.rejected:
        return Colors.red;
      case RequestStatus.pending:
        return Colors.orange;
      case RequestStatus.returned:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Track Request Status')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _searchRequests,
                  child: _filteredRequests.isEmpty
                      ? const Center(child: Text('No requests found.'))
                      : ListView.builder(
                          itemCount: _filteredRequests.length,
                          itemBuilder: (context, index) {
                            final request = _filteredRequests[index];
                            return Card(
                              elevation: 4,
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Instrument: ${request.instrumentName}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Status: ${request.status.name}',
                                      style: TextStyle(
                                        color: _getStatusColor(request.status),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (request.isOverride) ...[
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Row(
                                              children: [
                                                Icon(Icons.info_outline, size: 16, color: Colors.orange),
                                                SizedBox(width: 6),
                                                Text(
                                                  'Override Update',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.orange,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              'Quantity adjusted from ${request.originalQuantity} to ${request.quantity} units.',
                                              style: const TextStyle(fontSize: 13),
                                            ),
                                            if (request.overrideReason != null && request.overrideReason!.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                'Reason: ${request.overrideReason}',
                                                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
