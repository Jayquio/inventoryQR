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

      // 3. Create notification for the borrower
      final req = originalRequests.firstWhere((r) => r['id'].toString() == id);
      final instrumentName = req['instrumentName'] ?? 'instrument';
      final studentUsername = req['studentName']; // This is the username in our DB

      if (status == 'approved') {
        await ApiClient.instance.createNotification(
          title: 'Request Approved',
          message: 'Your request for $instrumentName has been approved.',
          recipient: studentUsername,
          type: 'success',
          priority: 'high',
        );
      } else if (status == 'rejected') {
        await ApiClient.instance.createNotification(
          title: 'Request Rejected',
          message: 'Your request for $instrumentName has been rejected.',
          recipient: studentUsername,
          type: 'error',
          priority: 'high',
        );
      } else if (status == 'returned') {
        await ApiClient.instance.createNotification(
          title: 'Return Confirmed',
          message: 'The return of $instrumentName has been confirmed.',
          recipient: studentUsername,
          type: 'info',
        );
      }

      // 4. Refresh to be sure (quietly)
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
                      Text('Instrument: $instrumentName',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text('Requested by: $studentName',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                      const SizedBox(height: 2),
                      Text('Current Qty: $currentQty',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
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
                    hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                    hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                    SnackBar(content: Text('Quantity updated from $currentQty to $newQty')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString().replaceFirst("Exception: ", "")}')),
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
                                    separatorBuilder: (_, _) =>
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
                // Override info
                if (isOverride) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, size: 13, color: Colors.orange.shade700),
                            const SizedBox(width: 4),
                            Text('Override', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.orange.shade700)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Qty changed from ${req['originalQuantity'] ?? '?'} → ${req['quantity'] ?? '?'}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                        ),
                        if ((req['overrideReason'] ?? '').toString().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              'Reason: ${req['overrideReason']}',
                              style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF6B7280)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
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
                      // Edit Qty / Override button
                      SizedBox(
                        height: 32,
                        child: OutlinedButton.icon(
                          onPressed: () => _showOverrideDialog(req),
                          icon: Icon(Icons.edit, size: 14, color: Colors.orange.shade700),
                          label: Text('Edit Qty', style: TextStyle(fontSize: 12, color: Colors.orange.shade700)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.orange.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
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
                    SizedBox(
                      height: 32,
                      child: OutlinedButton.icon(
                        onPressed: () => _confirmDeleteRequest(id),
                        icon: Icon(Icons.delete, size: 14, color: Colors.red.shade600),
                        label: Text('Delete', style: TextStyle(fontSize: 12, color: Colors.red.shade600)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.red.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
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
