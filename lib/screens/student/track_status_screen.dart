// lib/screens/student/track_status_screen.dart

import 'package:flutter/material.dart';
import '../../models/request.dart';
import '../../widgets/search_bar.dart';
import '../../data/api_client.dart';

class TrackStatusScreen extends StatefulWidget {
  const TrackStatusScreen({super.key});

  @override
  State<TrackStatusScreen> createState() => _TrackStatusScreenState();
}

class _TrackStatusScreenState extends State<TrackStatusScreen> {
  final _nameController = TextEditingController();

  List<Request> _filteredRequests = [];
  bool _loading = false;

  Future<void> _searchRequests() async {
    final name = _nameController.text.trim();
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } else {
      if (mounted) {
        setState(() {
          _filteredRequests = [];
        });
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
            DebouncedSearchBar(
              controller: _nameController,
              hintText: 'Enter your name to search requests',
              onChanged: (value) => _searchRequests(),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else
              Expanded(
                child: _filteredRequests.isEmpty
                    ? const Center(child: Text('Enter your name to view your requests'))
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
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Status: ${request.status.name}',
                                    style: TextStyle(
                                      color: _getStatusColor(request.status),
                                      fontWeight: FontWeight.bold,
                                    ),
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
      ),
    );
  }
}
