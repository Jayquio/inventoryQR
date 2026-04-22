import 'package:flutter/material.dart';
import '../../models/request.dart';
import '../../data/api_client.dart';
import '../../data/auth_service.dart';
import '../../core/datetime_utils.dart';
import '../../core/theme.dart';
import '../../widgets/borrower_notification_header_action.dart';

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

  Map<String, List<Request>> get _groupedRequests {
    final Map<String, List<Request>> groups = {};
    for (final req in _requests) {
      // Use batchId if available, otherwise fallback to grouping by (Purpose + Date)
      // to catch items submitted together before batchId was implemented or if it failed
      String key;
      if (req.batchId != null && req.batchId!.isNotEmpty) {
        key = req.batchId!;
      } else {
        // Fallback key: student + purpose + date
        final p = req.purpose.trim().toLowerCase();
        final d = (req.neededAt ?? '').trim();
        key = 'fallback_${req.studentName}_${p}_${d}';
      }
      groups.putIfAbsent(key, () => []).add(req);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groupedRequests;
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
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white70,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.access_time, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Track My Requests',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const BorrowerNotificationHeaderAction(),
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
                : groups.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.science,
                          size: 40,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "You haven't submitted any requests yet.",
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () =>
                              Navigator.pushNamed(context, '/submit_request'),
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
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: groups.length,
                    itemBuilder: (context, index) {
                      final batchId = groups.keys.elementAt(index);
                      final items = groups[batchId]!;
                      return _buildBatchCard(batchId, items);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _calculateDuration(String? neededAt) {
    final neededDate = DateTimeUtils.tryParseFlexible(neededAt);
    if (neededDate == null) return '';
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    final neededDay = DateTime(
      neededDate.year,
      neededDate.month,
      neededDate.day,
    );
    final difference = neededDay.difference(todayMidnight).inDays;
    if (difference <= 0) return '';
    return '($difference day${difference > 1 ? 's' : ''} until needed)';
  }

  Widget _buildBatchCard(String batchId, List<Request> items) {
    final isRealBatch = !batchId.startsWith('fallback_');
    final isMultiple = items.length > 1;
    final first = items.first;

    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Batch Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isMultiple ? Icons.inventory_2 : Icons.description,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isMultiple ? 'Batch Request' : 'Single Request',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      if (isRealBatch)
                        Text(
                          'ID: $batchId',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                    ],
                  ),
                ),
                if (first.neededAt != null && first.neededAt!.isNotEmpty)
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Needed by: ${DateTimeUtils.formatNeededByForDisplay(first.neededAt)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.end,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _calculateDuration(first.neededAt),
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (first.purpose.isNotEmpty) ...[
                  const Text(
                    'Purpose:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    first.purpose,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (first.course != null && first.course!.isNotEmpty) ...[
                  Text(
                    'Course: ${first.course}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                const Divider(height: 1),
                const SizedBox(height: 12),

                const Text(
                  'Items:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),

                // Item List
                ...items
                    .map(
                      (req) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Icon(
                              _statusIcon(req.status),
                              color: _statusColor(req.status),
                              size: 18,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${req.instrumentName} (x${req.quantity})',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                  if (req.isOverride)
                                    Text(
                                      'Adjusted from ${req.originalQuantity} units',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.orange.shade700,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            _buildStatusBadge(req.status),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(RequestStatus status) {
    final map = {
      RequestStatus.pending: (Colors.amber.shade100, Colors.amber.shade700),
      RequestStatus.approved: (Colors.green.shade100, Colors.green.shade700),
      RequestStatus.rejected: (Colors.red.shade100, Colors.red.shade700),
      RequestStatus.returned: (
        const Color(0xFFF3F4F6),
        const Color(0xFF374151),
      ),
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
