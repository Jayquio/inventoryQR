// lib/screens/student/submit_request_screen.dart

import 'package:flutter/material.dart';
import '../../data/api_client.dart';
import '../../models/instrument.dart';
import '../../data/auth_service.dart';
import '../../data/notification_service.dart';
import '../../core/theme.dart';

class SubmitRequestScreen extends StatefulWidget {
  final String? preSelectedInstrument;
  final String? preSelectedCourse;
  final DateTime? preSelectedDate;
  const SubmitRequestScreen({
    super.key,
    this.preSelectedInstrument,
    this.preSelectedCourse,
    this.preSelectedDate,
  });

  @override
  State<SubmitRequestScreen> createState() => _SubmitRequestScreenState();
}

class _SubmitRequestScreenState extends State<SubmitRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  List<Instrument> _instruments = [];
  bool _loading = true;
  bool _submitting = false;
  bool _success = false;

  String? _selectedInstrument;
  int _quantity = 1;
  String _purpose = '';
  String _course = '';
  String _neededAt = '';

  @override
  void initState() {
    super.initState();
    _selectedInstrument = widget.preSelectedInstrument;
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await ApiClient.instance.fetchInstruments();
      if (!mounted) return;
      setState(() {
        _instruments =
            items.where((i) => i.status.toLowerCase() == 'active' || i.status.toLowerCase() == 'available').toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (_selectedInstrument == null || _selectedInstrument!.isEmpty) return;
    if (_purpose.isEmpty) return;

    setState(() => _submitting = true);

    try {
      await ApiClient.instance.submitRequest(
        studentName: AuthService.instance.currentUsername,
        instrumentName: _selectedInstrument!,
        quantity: _quantity,
        purpose: _purpose,
        course: _course,
        neededAtIso: _neededAt.isNotEmpty ? _neededAt : null,
      );

      // Add notification
      final nowIso = DateTime.now().toIso8601String();
      NotificationService.instance.add(
        NotificationItem(
          id: 'student_${DateTime.now().microsecondsSinceEpoch}',
          title: 'Request Submitted',
          message:
              'You requested $_selectedInstrument (x$_quantity)',
          type: 'success',
          timestamp: nowIso,
          recipient: 'Student',
          course: _course,
          priority: 'low',
        ),
      );

      if (!mounted) return;
      setState(() {
        _submitting = false;
        _success = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Success state
    if (_success) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check_circle,
                          color: Colors.green.shade600, size: 32),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Request Submitted!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your request has been submitted and is pending review.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                Navigator.pushNamed(context, '/track_status'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Track Status'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _success = false;
                                _selectedInstrument = null;
                                _quantity = 1;
                                _purpose = '';
                                _course = '';
                                _neededAt = '';
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('New Request'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Form state
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
                  'Submit Borrow Request',
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Card(
                    elevation: 0.5,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Request Details',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF374151),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Instrument dropdown
                            const Text('Instrument *',
                                style: TextStyle(fontSize: 13)),
                            const SizedBox(height: 4),
                            _buildInstrumentDropdown(),
                            const SizedBox(height: 16),

                            // Quantity
                            const Text('Quantity *',
                                style: TextStyle(fontSize: 13)),
                            const SizedBox(height: 4),
                            TextFormField(
                              initialValue: '1',
                              keyboardType: TextInputType.number,
                              decoration: _inputDecor(''),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Required';
                                final n = int.tryParse(v);
                                if (n == null || n <= 0) return '> 0';
                                return null;
                              },
                              onSaved: (v) =>
                                  _quantity = int.tryParse(v ?? '1') ?? 1,
                            ),
                            const SizedBox(height: 16),

                            // Purpose
                            const Text('Purpose *',
                                style: TextStyle(fontSize: 13)),
                            const SizedBox(height: 4),
                            TextFormField(
                              maxLines: 3,
                              decoration: _inputDecor(
                                  'Describe why you need this instrument...'),
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Required' : null,
                              onSaved: (v) => _purpose = v ?? '',
                            ),
                            const SizedBox(height: 16),

                            // Course + Needed By
                            LayoutBuilder(
                              builder: (context, constraints) {
                                if (constraints.maxWidth > 400) {
                                  return Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text('Course / Subject',
                                                style: TextStyle(
                                                    fontSize: 13)),
                                            const SizedBox(height: 4),
                                            TextFormField(
                                              decoration:
                                                  _inputDecor('e.g. Biology 101'),
                                              onSaved: (v) =>
                                                  _course = v ?? '',
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text('Needed By',
                                                style: TextStyle(
                                                    fontSize: 13)),
                                            const SizedBox(height: 4),
                                            GestureDetector(
                                              onTap: _pickDate,
                                              child: AbsorbPointer(
                                                child: TextFormField(
                                                  decoration: _inputDecor(
                                                      _neededAt.isEmpty
                                                          ? 'Select date'
                                                          : _neededAt),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text('Course / Subject',
                                        style: TextStyle(fontSize: 13)),
                                    const SizedBox(height: 4),
                                    TextFormField(
                                      decoration:
                                          _inputDecor('e.g. Biology 101'),
                                      onSaved: (v) => _course = v ?? '',
                                    ),
                                    const SizedBox(height: 16),
                                    const Text('Needed By',
                                        style: TextStyle(fontSize: 13)),
                                    const SizedBox(height: 4),
                                    GestureDetector(
                                      onTap: _pickDate,
                                      child: AbsorbPointer(
                                        child: TextFormField(
                                          decoration: _inputDecor(
                                              _neededAt.isEmpty
                                                  ? 'Select date'
                                                  : _neededAt),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 24),

                            // Submit
                            SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: ElevatedButton(
                                onPressed: (_submitting ||
                                        _selectedInstrument == null ||
                                        _selectedInstrument!.isEmpty)
                                    ? null
                                    : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor:
                                      AppTheme.primaryColor.withValues(alpha: 0.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: _submitting
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Submit Request',
                                        style: TextStyle(fontSize: 15)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstrumentDropdown() {
    if (_loading) {
      return const LinearProgressIndicator();
    }
    return DropdownButtonFormField<String>(
      value: _selectedInstrument != null &&
              _instruments.any((i) => i.name == _selectedInstrument)
          ? _selectedInstrument
          : null,
      decoration: _inputDecor('Select instrument'),
      isExpanded: true,
      items: _instruments.map((i) {
        return DropdownMenuItem(
          value: i.name,
          enabled: i.available > 0,
          child: Text(
            '${i.name} ${i.available == 0 ? "(unavailable)" : "(${i.available} available)"}',
            style: TextStyle(
              fontSize: 14,
              color: i.available == 0 ? Colors.grey : null,
            ),
          ),
        );
      }).toList(),
      onChanged: (v) => setState(() => _selectedInstrument = v),
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final firstAllowedDate = now.add(const Duration(days: 3));
    final date = await showDatePicker(
      context: context,
      initialDate: firstAllowedDate,
      firstDate: firstAllowedDate,
      lastDate: DateTime(now.year + 1),
    );
    if (date != null && mounted) {
      setState(() {
        _neededAt =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      });
    }
  }

  InputDecoration _inputDecor(String hint) {
    return InputDecoration(
      hintText: hint,
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
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
      ),
    );
  }
}
