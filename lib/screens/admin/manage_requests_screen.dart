// lib/screens/admin/manage_requests_screen.dart

import 'package:flutter/material.dart';
import '../../data/dummy_data.dart';
import '../../models/request.dart';
import '../../widgets/search_bar.dart';
import '../../data/notification_service.dart';
import '../../core/constants.dart';
import '../../data/api_client.dart';
import '../../data/auth_service.dart';

class ManageRequestsScreen extends StatefulWidget {
  const ManageRequestsScreen({super.key});

  @override
  State<ManageRequestsScreen> createState() => _ManageRequestsScreenState();
}

class _ManageRequestsScreenState extends State<ManageRequestsScreen> {
  static const String _instrumentPrefix = 'Instrument: ';
  static const String _exceptionPrefix = 'Exception: ';

  final TextEditingController _searchController = TextEditingController();
  int _page = 0;
  final int _perPage = 10;
  String _statusFilter = 'Pending';

  Future<void> _markReturned(int index) async {
    final req = requests[index];
    if (req.id.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot sync return: request id is missing.')),
        );
      }
      return;
    }
    
    try {
      await ApiClient.instance.updateRequestStatus(
        id: req.id,
        status: 'returned',
        user: AuthService.instance.currentUsername,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst(_exceptionPrefix, ''))),
      );
      return;
    }

    if (!context.mounted) return;
    setState(() {
      requests[index].status = RequestStatus.returned;
      final instrument = instruments.firstWhere(
        (inst) => inst.name == requests[index].instrumentName,
        orElse: () => instruments.first,
      );
      if (instrument.available < instrument.quantity) {
        instrument.available++;
      }
    });
    NotificationService.instance.add(
      NotificationItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: 'Instrument Returned',
        message: '${requests[index].studentName} returned ${requests[index].instrumentName}.',
        type: 'info',
        timestamp: DateTime.now().toIso8601String(),
        recipient: 'Teacher',
        priority: 'low',
      ),
    );
    NotificationService.instance.add(
      NotificationItem(
        id: 'student_${DateTime.now().microsecondsSinceEpoch}',
        title: 'Return Recorded',
        message: 'Return recorded for ${requests[index].instrumentName}.',
        type: 'success',
        timestamp: DateTime.now().toIso8601String(),
        recipient: 'Student',
        priority: 'low',
      ),
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Marked as returned.')),
      );
    }
  }

  void _approveRequest(int index) {
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      requests[index].status = RequestStatus.approved;
      // Update instrument availability
      final instrument = instruments.firstWhere(
        (inst) => inst.name == requests[index].instrumentName,
      );
      if (instrument.available > 0) {
        instrument.available--;
      }
    });
    NotificationService.instance.add(
      NotificationItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: 'Request Approved',
        message: '${requests[index].studentName} approved for ${requests[index].instrumentName}.',
        type: 'success',
        timestamp: DateTime.now().toIso8601String(),
        recipient: 'Teacher',
        priority: 'medium',
      ),
    );
    NotificationService.instance.add(
      NotificationItem(
        id: 'student_${DateTime.now().microsecondsSinceEpoch}',
        title: 'Request Approved',
        message: 'Your request for ${requests[index].instrumentName} has been approved.',
        type: 'success',
        timestamp: DateTime.now().toIso8601String(),
        recipient: 'Student',
        priority: 'medium',
      ),
    );
    if (context.mounted) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Request approved!')),
      );
    }
  }

  void _rejectRequest(int index) {
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      requests[index].status = RequestStatus.rejected;
    });
    NotificationService.instance.add(
      NotificationItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: 'Request Rejected',
        message: '${requests[index].studentName} rejected for ${requests[index].instrumentName}.',
        type: 'error',
        timestamp: DateTime.now().toIso8601String(),
        recipient: 'Teacher',
        priority: 'high',
      ),
    );
    NotificationService.instance.add(
      NotificationItem(
        id: 'student_${DateTime.now().microsecondsSinceEpoch}',
        title: 'Request Rejected',
        message: 'Your request for ${requests[index].instrumentName} has been rejected.',
        type: 'error',
        timestamp: DateTime.now().toIso8601String(),
        recipient: 'Student',
        priority: 'high',
      ),
    );
    if (context.mounted) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Request rejected!')),
      );
    }
  }

  void _deleteRequest(int index) {
    final req = requests[index];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Request'),
        content: Text('Delete request for ${req.instrumentName} by ${req.studentName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiClient.instance.deleteRequest(id: req.id);
                if (context.mounted) {
                  setState(() {
                    requests.removeAt(index);
                  });
                  NotificationService.instance.add(
                    NotificationItem(
                      id: 'student_${DateTime.now().microsecondsSinceEpoch}',
                      title: 'Request Removed',
                      message: 'Your request for ${req.instrumentName} was removed by Admin.',
                      type: 'info',
                      timestamp: DateTime.now().toIso8601String(),
                      recipient: 'Student',
                      priority: 'low',
                    ),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Request deleted.')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString().replaceFirst(_exceptionPrefix, ''))),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredRequests = _getFilteredRequests();
    final totalPages = (filteredRequests.length / _perPage).ceil();
    final pageItems = _getPageItems(filteredRequests);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Requests')),
      body: Column(
        children: [
          _buildFilters(),
          _buildRequestList(filteredRequests, pageItems),
          _buildPagination(totalPages),
        ],
      ),
    );
  }

  List<Request> _getFilteredRequests() {
    final searchTerm = _searchController.text.toLowerCase();
    return requests.where((req) {
      return _filterBySearch(req, searchTerm) && _filterByStatus(req, _statusFilter);
    }).toList();
  }

  bool _filterBySearch(Request req, String term) {
    if (term.isEmpty) return true;
    return req.studentName.toLowerCase().contains(term) ||
        req.instrumentName.toLowerCase().contains(term) ||
        req.purpose.toLowerCase().contains(term) ||
        req.status.name.toLowerCase().contains(term);
  }

  bool _filterByStatus(Request req, String filter) {
    if (filter == 'All') return true;
    final s = req.status;
    return switch (filter) {
      'Pending' => s == RequestStatus.pending,
      'Approved' => s == RequestStatus.approved,
      'Rejected' => s == RequestStatus.rejected,
      'Returned' => s == RequestStatus.returned,
      _ => true,
    };
  }

  List<Request> _getPageItems(List<Request> filteredRequests) {
    final start = (_page * _perPage).clamp(0, filteredRequests.length);
    final end = (start + _perPage).clamp(0, filteredRequests.length);
    return filteredRequests.sublist(start, end);
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          DebouncedSearchBar(
            controller: _searchController,
            hintText: 'Search requests...',
            onChanged: (value) => setState(() {
              _page = 0;
            }),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _statusFilter,
            isExpanded: true,
            items: const [
              DropdownMenuItem(value: 'All', child: Text('All')),
              DropdownMenuItem(value: 'Pending', child: Text('Pending')),
              DropdownMenuItem(value: 'Approved', child: Text('Approved')),
              DropdownMenuItem(value: 'Rejected', child: Text('Rejected')),
              DropdownMenuItem(value: 'Returned', child: Text('Returned')),
            ],
            onChanged: (v) => setState(() {
              _statusFilter = v ?? 'Pending';
              _page = 0;
            }),
            decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Filter by status'),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestList(List<Request> filteredRequests, List<Request> pageItems) {
    return Expanded(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: filteredRequests.isEmpty
            ? const Center(child: Text('No pending requests.'))
            : ListView.builder(
                key: ValueKey(pageItems.length),
                padding: const EdgeInsets.all(16),
                itemCount: pageItems.length,
                itemBuilder: (context, index) => _buildRequestCard(pageItems[index]),
              ),
      ),
    );
  }

  Widget _buildRequestCard(Request request) {
    final originalIndex = requests.indexOf(request);
    return _HoverListCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () => _showRequestDetails(request),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader(request),
            const SizedBox(height: 8),
            _buildCardContent(request),
            const SizedBox(height: 12),
            _buildCardActions(request, originalIndex),
          ],
        ),
      ),
    );
  }

  Widget _buildCardHeader(Request request) {
    final statusColor = _getStatusColor(request.status);
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: Colors.orange.shade100,
          child: const Icon(Icons.assignment, color: Colors.orange),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            request.studentName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            request.status.name[0].toUpperCase() + request.status.name.substring(1),
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return Colors.orange;
      case RequestStatus.approved:
        return Colors.green;
      case RequestStatus.rejected:
        return Colors.red;
      case RequestStatus.returned:
        return Colors.blue;
    }
  }

  Widget _buildCardContent(Request request) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.black),
            children: _highlightSpans(request.instrumentName, _searchController.text.toLowerCase()),
          ),
        ),
        Text("Purpose: ${request.purpose}"),
      ],
    );
  }

  Widget _buildCardActions(Request request, int originalIndex) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (request.status == RequestStatus.pending) ...[
          ElevatedButton(
            onPressed: () => _approveRequest(originalIndex),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve'),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () => _rejectRequest(originalIndex),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ] else if (request.status == RequestStatus.approved) ...[
          ElevatedButton(
            onPressed: () => _markReturned(originalIndex),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Returned'),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () => _deleteRequest(originalIndex),
            child: const Text('Delete'),
          ),
        ] else ...[
          OutlinedButton(
            onPressed: () => _deleteRequest(originalIndex),
            child: const Text('Delete'),
          ),
        ]
      ],
    );
  }

  Widget _buildPagination(int totalPages) {
    final w = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('Page ${_page + 1} of ${totalPages == 0 ? 1 : totalPages}', style: TextStyle(fontSize: R.text(12, w))),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: _page > 0 ? () => setState(() => _page--) : null,
            child: const Text('Prev'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: (_page + 1) < totalPages ? () => setState(() => _page++) : null,
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  void _showRequestDetails(Request request) {
    final idx = requests.indexOf(request);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                request.instrumentName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text('Student: ${request.studentName}', textAlign: TextAlign.center),
              Text('Purpose: ${request.purpose}', textAlign: TextAlign.center),
              if (request.course != null && request.course!.isNotEmpty) Text('Course: ${request.course}', textAlign: TextAlign.center),
              if (request.neededAt != null && request.neededAt!.isNotEmpty) Text('Needed At: ${request.neededAt}', textAlign: TextAlign.center),
              Text('Status: ${request.status.name}', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              _buildDetailsActions(request, idx),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsActions(Request request, int idx) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        const SizedBox(width: 8),
        if (request.status == RequestStatus.pending) ...[
          ElevatedButton(
            onPressed: () {
              _approveRequest(idx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              _rejectRequest(idx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
          const SizedBox(width: 8),
        ] else if (request.status == RequestStatus.approved) ...[
          ElevatedButton(
            onPressed: () {
              _markReturned(idx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Returned'),
          ),
          const SizedBox(width: 8),
        ],
        OutlinedButton(
          onPressed: () {
            Navigator.pop(context);
            _deleteRequest(idx);
          },
          child: const Text('Delete'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TextSpan> _highlightSpans(String text, String term) {
    final List<TextSpan> spans = [const TextSpan(text: _instrumentPrefix)];
    if (term.isEmpty) {
      spans.add(TextSpan(text: text));
      return spans;
    }
    final lowerText = text.toLowerCase();
    int start = 0;
    int idx;
    while ((idx = lowerText.indexOf(term, start)) != -1) {
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx)));
      }
      spans.add(TextSpan(
        text: text.substring(idx, idx + term.length),
        style: const TextStyle(backgroundColor: Color(0xFFFFF59D)),
      ));
      start = idx + term.length;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }
    return spans;
  }
}

class _HoverListCard extends StatefulWidget {
  const _HoverListCard({
    required this.child,
    this.onTap,
    this.margin,
  });
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  @override
  State<_HoverListCard> createState() => _HoverListCardState();
}

class _HoverListCardState extends State<_HoverListCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: widget.margin,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          transform: Matrix4.diagonal3Values(_hover ? 1.01 : 1.0, _hover ? 1.01 : 1.0, 1.0),
          child: Card(
            elevation: _hover ? 8 : 4,
            child: InkWell(
              onTap: widget.onTap,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
