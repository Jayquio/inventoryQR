// lib/screens/staff/handle_returns_screen.dart

import 'package:flutter/material.dart';
import '../../data/dummy_data.dart';
import '../../models/request.dart';

class HandleReturnsScreen extends StatefulWidget {
  const HandleReturnsScreen({super.key});

  @override
  State<HandleReturnsScreen> createState() => _HandleReturnsScreenState();
}

class _HandleReturnsScreenState extends State<HandleReturnsScreen> {
  final TextEditingController _searchController = TextEditingController();

  void _markAsReturned(int index) {
    setState(() {
      requests[index].status = RequestStatus.returned;
      // Update instrument availability
      final instrument = instruments.firstWhere(
        (inst) => inst.name == requests[index].instrumentName,
      );
      if (instrument.available < instrument.quantity) {
        instrument.available++;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Instrument marked as returned!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchTerm = _searchController.text.toLowerCase();
    final approvedRequests = requests
        .where((req) => req.status == RequestStatus.approved)
        .where((req) {
          if (searchTerm.isEmpty) return true;
          return req.studentName.toLowerCase().contains(searchTerm) ||
              req.instrumentName.toLowerCase().contains(searchTerm) ||
              req.purpose.toLowerCase().contains(searchTerm);
        })
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Handle Returns')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search returns...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),
          Expanded(
            child: approvedRequests.isEmpty
                ? const Center(child: Text('No approved requests to return.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: approvedRequests.length,
                    itemBuilder: (context, index) {
                      final request = approvedRequests[index];
                      final originalIndex = requests.indexOf(request);
                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => _showReturnDetails(request),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  request.studentName,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text("Instrument: ${request.instrumentName}"),
                                Text("Status: ${request.status.name}", style: const TextStyle(color: Colors.green)),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: () => _markAsReturned(originalIndex),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                  child: const Text('Mark as Returned'),
                                ),
                              ],
                            ),
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

  void _showReturnDetails(Request request) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              request.instrumentName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Student: ${request.studentName}'),
            Text('Purpose: ${request.purpose}'),
            Text('Status: ${request.status.name}'),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
