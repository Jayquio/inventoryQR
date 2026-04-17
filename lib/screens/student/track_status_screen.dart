// lib/screens/student/track_status_screen.dart

import 'package:flutter/material.dart';
import '../../models/request.dart';
import '../../data/api_client.dart';
import '../../data/auth_service.dart';
import '../../core/theme.dart';

class TrackStatusScreen extends StatefulWidget {
  const TrackStatusScreen({super.key});

  @override
  State<TrackStatusScreen> createState() => _TrackStatusScreenState();
}

class _TrackStatusScreenState extends State<TrackStatusScreen> {
  List<Request> _requests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final name = AuthService.instance.currentUsername;
    if (name.isEmpty) return;
    try {
      final rows = await ApiClient.instance.fetchRequests(studentName: name);
      if (!mounted) return;
      setState(() {
        _requests = rows.map((e) => Request.fromJson(e)).toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  IconData _statusIcon(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return Icons.access_time;
      case RequestStatus.approved:
        return Icons.check_circle;
      case RequestStatus.rejected:
        return Icons.cancel;
      case RequestStatus.returned:
        return Icons.replay;
    }
  }

  Color _statusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return Colors.amber.shade500;
      case RequestStatus.approved:
        return Colors.green.shade500;
      case RequestStatus.rejected:
        return Colors.red.shade500;
      case RequestStatus.returned:
        return Colors.grey.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
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
                const Icon(Icons.access_time, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'Track My Requests',
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
                      'Loading your requests...',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : _requests.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.science,
                                size: 40, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            const Text(
                              "You haven't submitted any requests yet.",
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => Navigator.pushNamed(
                                  context, '/submit_request'),
                              child: Text(
                                'Submit a request',
                                style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontSize: 14,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _requests.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final req = _requests[index];
                          return _buildRequestCard(req);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(Request req) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Icon(
                _statusIcon(req.status),
                color: _statusColor(req.status),
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          req.instrumentName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusBadge(req.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Qty: ${req.quantity}',
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF6B7280)),
                  ),
                  if (req.purpose.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        req.purpose,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF9CA3AF)),
                      ),
                    ),
                  if (req.course != null && req.course!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Course: ${req.course}',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF9CA3AF)),
                      ),
                    ),
                  if (req.neededAt != null && req.neededAt!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Needed by: ${req.neededAt}',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF9CA3AF)),
                      ),
                    ),
                  if (req.approvedBy != null && req.approvedBy!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Approved by ${req.approvedBy}',
                        style: TextStyle(
                            fontSize: 11, color: Colors.green.shade600),
                      ),
                    ),
                  if (req.rejectedBy != null && req.rejectedBy!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Rejected by ${req.rejectedBy}',
                        style: TextStyle(
                            fontSize: 11, color: Colors.red.shade500),
                      ),
                    ),
                  if (req.returnedBy != null && req.returnedBy!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Returned — processed by ${req.returnedBy}',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF6B7280)),
                      ),
                    ),
                  // Override info
                  if (req.isOverride) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.info_outline,
                                  size: 14, color: Colors.orange),
                              const SizedBox(width: 6),
                              const Text(
                                'Override Update',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Quantity adjusted from ${req.originalQuantity} to ${req.quantity} units.',
                            style: const TextStyle(fontSize: 12),
                          ),
                          if (req.overrideReason != null &&
                              req.overrideReason!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                'Reason: ${req.overrideReason}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(RequestStatus status) {
    final map = {
      RequestStatus.pending: (Colors.amber.shade100, Colors.amber.shade700),
      RequestStatus.approved: (Colors.green.shade100, Colors.green.shade700),
      RequestStatus.rejected: (Colors.red.shade100, Colors.red.shade700),
      RequestStatus.returned:
          (const Color(0xFFF3F4F6), const Color(0xFF374151)),
    };
    final pair = map[status]!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: pair.$1,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.name[0].toUpperCase() + status.name.substring(1),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: pair.$2,
        ),
      ),
    );
  }
}
