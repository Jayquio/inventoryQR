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
    final originalRequests = List<Map<String, dynamic>>.from(_requests);
    final name = AuthService.instance.currentUsername;

    // 1. Optimistic Update (Immediate UI feedback)
    setState(() {
      _actioning = '$id$status';
      final idx = _requests.indexWhere((r) => r['id'].toString() == id);
      if (idx != -1) {
        _requests[idx] = {..._requests[idx], 'status': status};
      }
    });

    try {
      // 2. Perform API call
      await ApiClient.instance.updateRequestStatus(
        id: id,
        status: status,
        user: name,
      );
      // Backend endpoint already writes borrower notifications for these statuses.
      // 3. Refresh to be sure (quietly)
      await _load();
    } catch (e) {
      // Rollback if failed
      if (mounted) {
        setState(() => _requests = originalRequests);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _actioning = null);
    }
  }

  Future<void> _actionBatch(List<String> ids, String status) async {
    final originalRequests = List<Map<String, dynamic>>.from(_requests);
    final name = AuthService.instance.currentUsername;

    setState(() {
      _actioning = 'batch_$status';
      for (final id in ids) {
        final idx = _requests.indexWhere((r) => r['id'].toString() == id);
        if (idx != -1) {
          _requests[idx] = {..._requests[idx], 'status': status};
        }
      }
    });

    try {
      await ApiClient.instance.updateBatchStatus(
        ids: ids,
        status: status,
        user: name,
      );
      await _load();
    } catch (e) {
      if (mounted) {
        setState(() => _requests = originalRequests);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update batch: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _actioning = null);
    }
  }

  void _showOverrideDialog(Map<String, dynamic> req) {
    final id = (req['id'] ?? '').toString();
    final currentQty = int.tryParse((req['quantity'] ?? '1').toString()) ?? 1;
    final instrumentName = (req['instrumentName'] ?? '').toString();
    final studentName = (req['studentName'] ?? '').toString();
    final qtyController = TextEditingController(text: currentQty.toString());
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.edit, size: 20, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            const Text('Edit Request Quantity', style: TextStyle(fontSize: 17)),
          ],
        ),
        content: SizedBox(
          width: 380,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Instrument: $instrumentName',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Requested by: $studentName',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Current Qty: $currentQty',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // New quantity
                const Text('New Quantity *', style: TextStyle(fontSize: 13)),
                const SizedBox(height: 4),
                TextFormField(
                  controller: qtyController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Enter new quantity',
                    hintStyle: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    final n = int.tryParse(v);
                    if (n == null || n <= 0) return 'Must be > 0';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Reason
                const Text('Reason / Comment', style: TextStyle(fontSize: 13)),
                const SizedBox(height: 4),
                TextFormField(
                  controller: reasonController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Optional: reason for the override...',
                    hintStyle: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.save, size: 16),
            label: const Text('Save Override'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final newQty = int.tryParse(qtyController.text) ?? currentQty;
              final reason = reasonController.text.trim();
              Navigator.pop(dialogContext);
              try {
                await ApiClient.instance.updateRequestQuantity(
                  id: id,
                  quantity: newQty,
                  user: AuthService.instance.currentUsername,
                  reason: reason,
                );
                await _load();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Quantity updated from $currentQty to $newQty',
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error: ${e.toString().replaceFirst("Exception: ", "")}',
                      ),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _confirmDeleteRequest(String id) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Request?'),
        content: const Text(
          'Are you sure you want to delete this request record? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await ApiClient.instance.deleteRequest(id: id);
                await _load();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Request deleted.')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
      final instrumentName = (r['instrumentName'] ?? '')
          .toString()
          .toLowerCase();
      final matchSearch =
          _search.isEmpty ||
          studentName.contains(_search.toLowerCase()) ||
          instrumentName.contains(_search.toLowerCase());
      return matchStatus && matchSearch;
    }).toList();
  }

  Map<String, List<Map<String, dynamic>>> get _groupedFiltered {
    final filtered = _filtered;
    final Map<String, List<Map<String, dynamic>>> groups = {};
    for (final req in filtered) {
      String key;
      final bId = (req['batchId'] ?? req['batch_id'])?.toString();
      if (bId != null && bId.isNotEmpty) {
        key = bId;
      } else {
        // Fallback key: student + purpose + date (same as student view)
        final s = (req['studentName'] ?? '').toString().trim().toLowerCase();
        final p = (req['purpose'] ?? '').toString().trim().toLowerCase();
        final d = (req['neededAt'] ?? '').toString().trim();
        key = 'fallback_${s}_${p}_${d}';
      }
      groups.putIfAbsent(key, () => []).add(req);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupedFiltered;

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

                      // Global Bulk Actions (if multiple pending across all groups)
                      _buildGlobalBulkActions(),

                      // Content
                      Expanded(
                        child: _loading
                            ? const Center(
                                child: Text(
                                  'Loading requests...',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : grouped.isEmpty
                            ? const Center(
                                child: Text(
                                  'No requests found',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : ListView.builder(
                                itemCount: grouped.length,
                                itemBuilder: (context, index) {
                                  final batchId = grouped.keys.elementAt(index);
                                  final items = grouped[batchId]!;
                                  return _buildBatchRequestCard(batchId, items);
                                },
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

  Widget _buildBatchRequestCard(
    String batchId,
    List<Map<String, dynamic>> items,
  ) {
    final isRealBatch = !batchId.startsWith('fallback_');
    final studentName = items.first['studentName'] ?? 'Unknown';
    final first = items.first;

    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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
                  items.length > 1 ? Icons.inventory_2 : Icons.person,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              items.length > 1
                                  ? 'Batch: $studentName'
                                  : studentName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                          if (first['neededAt'] != null)
                            Text(
                              'Needed by: ${first['neededAt']}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                      if (isRealBatch)
                        Text(
                          'Batch ID: $batchId',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      // Batch Actions (Only show if there are multiple pending items)
                      if (items.length > 1 &&
                          items.any(
                            (r) =>
                                r['status'].toString().toLowerCase() ==
                                'pending',
                          ))
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              _buildBatchActionButton(
                                items.map((r) => r['id'].toString()).toList(),
                                'approved',
                                'Approve All',
                                Icons.done_all,
                                Colors.green.shade600,
                              ),
                              const SizedBox(width: 8),
                              _buildBatchActionButton(
                                items.map((r) => r['id'].toString()).toList(),
                                'rejected',
                                'Reject All',
                                Icons.remove_done,
                                Colors.red.shade600,
                              ),
                            ],
                          ),
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
                if ((first['purpose'] ?? '').isNotEmpty) ...[
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
                    first['purpose'],
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                const Divider(height: 1),
                const SizedBox(height: 12),

                const Text(
                  'Items in Request:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),

                ...items.map((req) => _buildItemRow(req)).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchActionButton(
    List<String> ids,
    String status,
    String label,
    IconData icon,
    Color color,
  ) {
    return InkWell(
      onTap: _actioning != null ? null : () => _actionBatch(ids, status),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(Map<String, dynamic> req) {
    final id = req['id'].toString();
    final status = (req['status'] ?? '').toString().toLowerCase();
    final isOverride = req['isOverride'] == 1 || req['isOverride'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${req['instrumentName']} (x${req['quantity']})',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              _buildStatusBadge(status),
            ],
          ),
          if (isOverride) ...[
            const SizedBox(height: 4),
            Text(
              'Qty adjusted from ${req['originalQuantity']} units',
              style: TextStyle(
                fontSize: 11,
                color: Colors.orange.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
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
                const SizedBox(width: 8),
                _buildActionButton(
                  id,
                  'rejected',
                  'Reject',
                  Icons.cancel,
                  Colors.red.shade600,
                  Colors.red.shade600,
                  borderColor: Colors.red.shade300,
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _showOverrideDialog(req),
                  icon: const Icon(Icons.edit, size: 18),
                  color: Colors.orange.shade700,
                  tooltip: 'Override Quantity',
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
              const Spacer(),
              IconButton(
                onPressed: () => _confirmDeleteRequest(id),
                icon: const Icon(Icons.delete_outline, size: 18),
                color: Colors.red.shade600,
                tooltip: 'Delete Record',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalBulkActions() {
    final pendingRequests = _filtered
        .where((r) => r['status'].toString().toLowerCase() == 'pending')
        .toList();

    if (pendingRequests.length < 2) return const SizedBox.shrink();

    final ids = pendingRequests.map((r) => r['id'].toString()).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.bolt, color: Colors.orange.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Bulk Actions (${pendingRequests.length} pending items)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade900,
                fontSize: 13,
              ),
            ),
          ),
          _buildBatchActionButton(
            ids,
            'approved',
            'Approve All',
            Icons.done_all,
            Colors.green.shade600,
          ),
          const SizedBox(width: 8),
          _buildBatchActionButton(
            ids,
            'rejected',
            'Reject All',
            Icons.remove_done,
            Colors.red.shade600,
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
        prefixIcon: const Icon(
          Icons.search,
          size: 18,
          color: Color(0xFF9CA3AF),
        ),
        hintText: 'Search by student or instrument...',
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
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
                        strokeWidth: 2,
                        color: textColor,
                      ),
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
                        strokeWidth: 2,
                        color: textColor,
                      ),
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
    final pair =
        map[status] ?? (const Color(0xFFF3F4F6), const Color(0xFF374151));

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
