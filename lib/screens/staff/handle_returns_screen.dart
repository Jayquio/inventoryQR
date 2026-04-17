// lib/screens/staff/handle_returns_screen.dart

import 'package:flutter/material.dart';
import '../../data/api_client.dart';
import '../../data/auth_service.dart';
import '../../core/theme.dart';

class HandleReturnsScreen extends StatefulWidget {
  const HandleReturnsScreen({super.key});

  @override
  State<HandleReturnsScreen> createState() => _HandleReturnsScreenState();
}

class _HandleReturnsScreenState extends State<HandleReturnsScreen> {
  List<Map<String, dynamic>> _requests = [];
  String _search = '';
  bool _loading = true;
  String? _processing;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final all = await ApiClient.instance.fetchRequests();
      if (!mounted) return;
      setState(() {
        _requests = all
            .where((r) =>
                (r['status'] ?? '').toString().toLowerCase() == 'approved')
            .toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _handleReturn(Map<String, dynamic> req) async {
    final id = (req['id'] ?? '').toString();
    setState(() => _processing = id);
    final staff = AuthService.instance.currentUsername;
    try {
      await ApiClient.instance.updateRequestStatus(
        id: id,
        status: 'returned',
        user: staff,
      );
      await _load();
    } catch (_) {}
    if (mounted) setState(() => _processing = null);
  }

  List<Map<String, dynamic>> get _filtered {
    if (_search.isEmpty) return _requests;
    final s = _search.toLowerCase();
    return _requests.where((r) {
      final student = (r['studentName'] ?? '').toString().toLowerCase();
      final instrument =
          (r['instrumentName'] ?? '').toString().toLowerCase();
      return student.contains(s) || instrument.contains(s);
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
                const Icon(Icons.replay, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'Handle Returns',
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
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Column(
                    children: [
                      // Search
                      TextField(
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search,
                              size: 18, color: Color(0xFF9CA3AF)),
                          hintText: 'Search by student or instrument...',
                          hintStyle: const TextStyle(
                              color: Color(0xFF9CA3AF), fontSize: 14),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        style: const TextStyle(fontSize: 14),
                        onChanged: (v) => setState(() => _search = v),
                      ),
                      const SizedBox(height: 16),

                      // Content
                      Expanded(
                        child: _loading
                            ? const Center(
                                child: Text(
                                  'Loading approved requests...',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : filtered.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.replay,
                                            size: 40,
                                            color: Colors.grey.shade300),
                                        const SizedBox(height: 12),
                                        const Text(
                                          'No approved requests pending return',
                                          style: TextStyle(
                                              color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: filtered.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 12),
                                    itemBuilder: (context, index) {
                                      final req = filtered[index];
                                      final id =
                                          (req['id'] ?? '').toString();
                                      return Card(
                                        elevation: 0.5,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.all(20),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .start,
                                                  children: [
                                                    Text(
                                                      (req['instrumentName'] ??
                                                              '')
                                                          .toString(),
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight
                                                                .w600,
                                                        fontSize: 15,
                                                        color: Color(
                                                            0xFF111827),
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                        height: 4),
                                                    Text(
                                                      '${req['studentName'] ?? ''} · Qty: ${req['quantity'] ?? 1}',
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        color: Color(
                                                            0xFF6B7280),
                                                      ),
                                                    ),
                                                    if ((req['course'] ??
                                                                '')
                                                            .toString()
                                                            .isNotEmpty)
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(
                                                                top: 2),
                                                        child: Text(
                                                          'Course: ${req['course']}',
                                                          style: const TextStyle(
                                                            fontSize: 11,
                                                            color: Color(
                                                                0xFF9CA3AF),
                                                          ),
                                                        ),
                                                      ),
                                                    if ((req['approvedBy'] ??
                                                                '')
                                                            .toString()
                                                            .isNotEmpty)
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(
                                                                top: 2),
                                                        child: Text(
                                                          'Approved by: ${req['approvedBy']}',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            color: Colors
                                                                .green
                                                                .shade600,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              SizedBox(
                                                height: 36,
                                                child: ElevatedButton.icon(
                                                  onPressed:
                                                      _processing == id
                                                          ? null
                                                          : () =>
                                                              _handleReturn(
                                                                  req),
                                                  icon: _processing == id
                                                      ? const SizedBox(
                                                          width: 14,
                                                          height: 14,
                                                          child:
                                                              CircularProgressIndicator(
                                                            strokeWidth:
                                                                2,
                                                            color: Colors
                                                                .white,
                                                          ),
                                                        )
                                                      : const Icon(
                                                          Icons.replay,
                                                          size: 14),
                                                  label: const Text(
                                                    'Process Return',
                                                    style: TextStyle(
                                                        fontSize: 12),
                                                  ),
                                                  style: ElevatedButton
                                                      .styleFrom(
                                                    backgroundColor:
                                                        Colors.blue
                                                            .shade600,
                                                    foregroundColor:
                                                        Colors.white,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius
                                                              .circular(
                                                                  8),
                                                    ),
                                                  ),
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}
