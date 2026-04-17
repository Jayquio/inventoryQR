// lib/screens/admin/manage_requests_screen.dart

import 'package:flutter/material.dart';
import '../../data/api_client.dart';
import '../../data/auth_service.dart';
import '../../core/theme.dart';

class ManageRequestsScreen extends StatefulWidget {
  const ManageRequestsScreen({super.key});

  @override
  State<ManageRequestsScreen> createState() => _ManageRequestsScreenState();
}

class _ManageRequestsScreenState extends State<ManageRequestsScreen> {
  List<Map<String, dynamic>> _requests = [];
  String _search = '';
  String _filter = 'all';
  bool _loading = true;
  String? _actioning;

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

  Future<void> _action(String id, String status) async {
    setState(() => _actioning = '$id$status');
    final name = AuthService.instance.currentUsername;
    try {
      await ApiClient.instance.updateRequestStatus(
        id: id,
        status: status,
        user: name,
      );
      await _load();
    } catch (_) {}
    if (mounted) setState(() => _actioning = null);
  }

  void _confirmDeleteRequest(String id) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Request?'),
        content: const Text('Are you sure you want to delete this request record? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await ApiClient.instance.deleteRequest(id: id);
                await _load();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request deleted.')));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> get _filtered {
    return _requests.where((r) {
      final status = (r['status'] ?? '').toString().toLowerCase();
      final matchStatus = _filter == 'all' || status == _filter;
      final studentName = (r['studentName'] ?? '').toString().toLowerCase();
      final instrumentName =
          (r['instrumentName'] ?? '').toString().toLowerCase();
      final matchSearch = _search.isEmpty ||
          studentName.contains(_search.toLowerCase()) ||
          instrumentName.contains(_search.toLowerCase());
      return matchStatus && matchSearch;
    }).toList();
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
                  child: const Icon(Icons.arrow_back,
                      color: Colors.white70, size: 22),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.assignment, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'Manage Requests',
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
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    children: [
                      // Search + Filter
                      _buildSearchFilter(),
                      const SizedBox(height: 16),

                      // Content
                      Expanded(
                        child: _loading
                            ? const Center(
                                child: Text('Loading requests...',
                                    style: TextStyle(color: Colors.grey)),
                              )
                            : filtered.isEmpty
                                ? const Center(
                                    child: Text('No requests found',
                                        style: TextStyle(color: Colors.grey)),
                                  )
                                : ListView.separated(
                                    itemCount: filtered.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 12),
                                    itemBuilder: (context, index) =>
                                        _buildRequestCard(filtered[index]),
                                  ),
                      ),
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
        hintText: 'Search by student or instrument...',
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
            DropdownMenuItem(value: 'all', child: Text('All Status')),
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

  Widget _buildRequestCard(Map<String, dynamic> req) {
    final id = (req['id'] ?? '').toString();
    final status = (req['status'] ?? '').toString().toLowerCase();
    final isOverride = req['isOverride'] == 1 || req['isOverride'] == true;

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top: Name + Status + Override
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      (req['instrumentName'] ?? '').toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Color(0xFF111827),
                      ),
                    ),
                    _buildStatusBadge(status),
                    if (isOverride)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Override',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.purple.shade700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${req['studentName'] ?? ''} · Qty: ${req['quantity'] ?? 1}',
                  style:
                      const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                ),
                if ((req['purpose'] ?? '').toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Purpose: ${req['purpose']}',
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF9CA3AF)),
                    ),
                  ),
                if ((req['course'] ?? '').toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Course: ${req['course']}',
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF9CA3AF)),
                    ),
                  ),
                if ((req['neededAt'] ?? '').toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Needed by: ${req['neededAt']}',
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF9CA3AF)),
                    ),
                  ),
                if ((req['approvedBy'] ?? '').toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Approved by: ${req['approvedBy']}',
                      style: TextStyle(
                          fontSize: 11, color: Colors.green.shade600),
                    ),
                  ),
                if ((req['rejectedBy'] ?? '').toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Rejected by: ${req['rejectedBy']}',
                      style:
                          TextStyle(fontSize: 11, color: Colors.red.shade500),
                    ),
                  ),

                const SizedBox(height: 12),

                // Action buttons
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (status == 'pending') ...[
                      _buildActionButton(
                        id,
                        'approved',
                        'Approve',
                        Icons.check_circle,
                        Colors.green.shade600,
                        Colors.white,
                        filled: true,
                      ),
                      _buildActionButton(
                        id,
                        'rejected',
                        'Reject',
                        Icons.cancel,
                        Colors.red.shade600,
                        Colors.red.shade600,
                        borderColor: Colors.red.shade300,
                      ),
                    ],
                    if (status == 'approved')
                      _buildActionButton(
                        id,
                        'returned',
                        'Mark Returned',
                        Icons.replay,
                        Colors.blue.shade600,
                        Colors.blue.shade600,
                        borderColor: Colors.blue.shade300,
                      ),
                    OutlinedButton.icon(
                      onPressed: () => _confirmDeleteRequest(id),
                      icon: Icon(Icons.delete, size: 14, color: Colors.red.shade600),
                      label: Text('Delete', style: TextStyle(fontSize: 12, color: Colors.red.shade600)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: const Size(0, 32),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String id,
    String newStatus,
    String label,
    IconData icon,
    Color color,
    Color textColor, {
    bool filled = false,
    Color? borderColor,
  }) {
    final isProcessing = _actioning == '$id$newStatus';
    return SizedBox(
      height: 32,
      child: filled
          ? ElevatedButton.icon(
              onPressed: isProcessing ? null : () => _action(id, newStatus),
              icon: isProcessing
                  ? SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: textColor),
                    )
                  : Icon(icon, size: 14),
              label: Text(label, style: const TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: textColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            )
          : OutlinedButton.icon(
              onPressed: isProcessing ? null : () => _action(id, newStatus),
              icon: isProcessing
                  ? SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: textColor),
                    )
                  : Icon(icon, size: 14),
              label: Text(label, style: const TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                foregroundColor: textColor,
                side: BorderSide(color: borderColor ?? Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final map = {
      'pending': (Colors.amber.shade100, Colors.amber.shade700),
      'approved': (Colors.green.shade100, Colors.green.shade700),
      'rejected': (Colors.red.shade100, Colors.red.shade700),
      'returned': (const Color(0xFFF3F4F6), const Color(0xFF374151)),
    };
    final pair = map[status] ??
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
