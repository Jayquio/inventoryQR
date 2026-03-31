// lib/screens/admin/generate_reports_screen.dart

import 'package:flutter/material.dart';
import '../../data/dummy_data.dart';
import '../../models/request.dart';

class GenerateReportsScreen extends StatelessWidget {
  const GenerateReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final totalInstruments = instruments.length;
    final availableInstruments = instruments.where((inst) => inst.available > 0).length;
    final totalRequests = requests.length;
    final approvedRequests = requests.where((req) => req.status == RequestStatus.approved).length;
    final pendingRequests = requests.where((req) => req.status == RequestStatus.pending).length;
    final rejectedRequests = requests.where((req) => req.status == RequestStatus.rejected).length;
    final returnedRequests = requests.where((req) => req.status == RequestStatus.returned).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Generate Reports')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Inventory Report',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Instruments: $totalInstruments'),
                    Text('Available Instruments: $availableInstruments'),
                    Text('Unavailable Instruments: ${totalInstruments - availableInstruments}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Requests Report',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Requests: $totalRequests'),
                    Text('Approved Requests: $approvedRequests'),
                    Text('Pending Requests: $pendingRequests'),
                    Text('Rejected Requests: $rejectedRequests'),
                    Text('Returned Requests: $returnedRequests'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Maintenance Report',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Maintenance Logs: ${maintenanceRecords.length}'),
                    if (maintenanceRecords.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text('Recent Maintenance Activities:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...maintenanceRecords.take(5).map((log) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text('${log.date}: ${log.instrumentName} - ${log.notes} (by ${log.technician})'),
                      )),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}