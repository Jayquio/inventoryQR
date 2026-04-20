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

  // --- Borrow list ---
  final List<Map<String, dynamic>> _borrowList = [];
  List<String> _submitResults = [];

  // Controllers so we can clear them after adding to borrow list
  final _quantityController = TextEditingController(text: '1');
  final _purposeController = TextEditingController();
  final _courseController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedInstrument = widget.preSelectedInstrument;
    _load();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _purposeController.dispose();
    _courseController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final items = await ApiClient.instance.fetchInstruments();
      if (!mounted) return;
      setState(() {
        _instruments = items.where((i) {
          final s = i.status.toLowerCase();
          final isPre = i.name == widget.preSelectedInstrument;
          return s == 'active' || s == 'available' || isPre;
        }).toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _addToBorrowList() {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (_selectedInstrument == null || _selectedInstrument!.isEmpty) return;
    if (_purpose.isEmpty) return;

    setState(() {
      _borrowList.add({
        'instrumentName': _selectedInstrument!,
        'quantity': _quantity,
        'purpose': _purpose,
        'course': _course,
        'neededAt': _neededAt,
      });
      // Reset form fields for next item
      _selectedInstrument = null;
      _quantity = 1;
      _purpose = '';
      _neededAt = '';
      // Keep course as it's likely the same
      _quantityController.text = '1';
      _purposeController.clear();
    });
    // Reset form validation state
    _formKey.currentState!.reset();
    _quantityController.text = '1';
  }

  void _removeFromBorrowList(int index) {
    setState(() => _borrowList.removeAt(index));
  }

  Future<void> _submitAll() async {
    if (_borrowList.isEmpty) return;

    setState(() => _submitting = true);

    final results = <String>[];
    int successCount = 0;

    for (final item in _borrowList) {
      try {
        await ApiClient.instance.submitRequest(
          studentName: AuthService.instance.currentUsername,
          instrumentName: item['instrumentName'],
          quantity: item['quantity'],
          purpose: item['purpose'],
          course: item['course'] ?? '',
          neededAtIso: (item['neededAt'] ?? '').toString().isNotEmpty
              ? item['neededAt']
              : null,
        );
        results.add('✓ ${item['instrumentName']} (x${item['quantity']})');
        successCount++;
      } catch (e) {
        results.add(
          '✗ ${item['instrumentName']} — ${e.toString().replaceFirst('Exception: ', '')}',
        );
      }
    }

    // Add notification
    if (successCount > 0) {
      final nowIso = DateTime.now().toIso8601String();
      NotificationService.instance.add(
        NotificationItem(
          id: 'student_${DateTime.now().microsecondsSinceEpoch}',
          title: 'Requests Submitted',
          message:
              'You submitted $successCount borrow request${successCount > 1 ? 's' : ''}',
          type: 'success',
          timestamp: nowIso,
          recipient: 'Student',
          course: _course,
          priority: 'low',
        ),
      );
    }

    if (!mounted) return;
    setState(() {
      _submitting = false;
      _success = true;
      _submitResults = results;
    });
  }

  // Legacy single submit (for when user submits directly without using the list)
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
          message: 'You requested $_selectedInstrument (x$_quantity)',
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
        _submitResults = ['✓ $_selectedInstrument (x$_quantity)'];
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
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 440),
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
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.green.shade600,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _submitResults.length > 1
                          ? 'Requests Submitted!'
                          : 'Request Submitted!',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _submitResults.length > 1
                          ? '${_submitResults.where((r) => r.startsWith('✓')).length} of ${_submitResults.length} requests submitted successfully.'
                          : 'Your request has been submitted and is pending review.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 12),
                    // Show results summary
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxHeight: 160),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _submitResults
                              .map(
                                (r) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    r,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: r.startsWith('✓')
                                          ? Colors.green.shade700
                                          : Colors.red.shade700,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
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
                                _borrowList.clear();
                                _submitResults.clear();
                                _quantityController.text = '1';
                                _purposeController.clear();
                                _courseController.clear();
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
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
                  'Submit Request',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_borrowList.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_borrowList.length} item${_borrowList.length > 1 ? 's' : ''}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
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
                  child: Column(
                    children: [
                      // --- Borrow List Summary ---
                      if (_borrowList.isNotEmpty) ...[
                        _buildBorrowListCard(),
                        const SizedBox(height: 16),
                      ],

                      // --- Request Form ---
                      Card(
                        elevation: 0.5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'Request Details',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF374151),
                                      ),
                                    ),
                                    if (_borrowList.isNotEmpty) ...[
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor
                                              .withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          'Adding item #${_borrowList.length + 1}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.primaryColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 20),

                                // Instrument dropdown
                                const Text(
                                  'Instrument *',
                                  style: TextStyle(fontSize: 13),
                                ),
                                const SizedBox(height: 4),
                                _buildInstrumentDropdown(),
                                const SizedBox(height: 16),

                                // Quantity
                                const Text(
                                  'Quantity *',
                                  style: TextStyle(fontSize: 13),
                                ),
                                const SizedBox(height: 4),
                                TextFormField(
                                  controller: _quantityController,
                                  keyboardType: TextInputType.number,
                                  decoration: _inputDecor(''),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Required';
                                    }
                                    final n = int.tryParse(v);
                                    if (n == null || n <= 0) return '> 0';
                                    if (_selectedInstrument != null &&
                                        _selectedInstrument!.isNotEmpty) {
                                      try {
                                        final inst = _instruments.firstWhere(
                                          (i) => i.name == _selectedInstrument,
                                        );
                                        if (n > inst.available) {
                                          return 'Max available: ${inst.available}';
                                        }
                                      } catch (_) {}
                                    }
                                    return null;
                                  },
                                  onSaved: (v) =>
                                      _quantity = int.tryParse(v ?? '1') ?? 1,
                                ),
                                const SizedBox(height: 16),

                                // Purpose
                                const Text(
                                  'Purpose *',
                                  style: TextStyle(fontSize: 13),
                                ),
                                const SizedBox(height: 4),
                                TextFormField(
                                  controller: _purposeController,
                                  maxLines: 3,
                                  decoration: _inputDecor(
                                    'Describe why you need this instrument...',
                                  ),
                                  validator: (v) => v == null || v.isEmpty
                                      ? 'Required'
                                      : null,
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
                                                const Text(
                                                  'Course',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                TextFormField(
                                                  controller: _courseController,
                                                  decoration: _inputDecor(''),
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
                                                const Text(
                                                  'Needed By',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                GestureDetector(
                                                  onTap: _pickDate,
                                                  child: AbsorbPointer(
                                                    child: TextFormField(
                                                      decoration: _inputDecor(
                                                        _neededAt.isEmpty
                                                            ? 'Select date'
                                                            : _neededAt,
                                                      ),
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
                                        const Text(
                                          'Course',
                                          style: TextStyle(fontSize: 13),
                                        ),
                                        const SizedBox(height: 4),
                                        TextFormField(
                                          controller: _courseController,
                                          decoration: _inputDecor(''),
                                          onSaved: (v) => _course = v ?? '',
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'Needed By',
                                          style: TextStyle(fontSize: 13),
                                        ),
                                        const SizedBox(height: 4),
                                        GestureDetector(
                                          onTap: _pickDate,
                                          child: AbsorbPointer(
                                            child: TextFormField(
                                              decoration: _inputDecor(
                                                _neededAt.isEmpty
                                                    ? 'Select date'
                                                    : _neededAt,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 24),

                                // Buttons: Add More + Submit (if only 1 item)
                                Row(
                                  children: [
                                    // Add More button
                                    Expanded(
                                      child: SizedBox(
                                        height: 48,
                                        child: OutlinedButton.icon(
                                          onPressed:
                                              (_selectedInstrument == null ||
                                                  _selectedInstrument!.isEmpty)
                                              ? null
                                              : _addToBorrowList,
                                          icon: const Icon(
                                            Icons.add_shopping_cart,
                                            size: 18,
                                          ),
                                          label: const Text(
                                            'Add More',
                                            style: TextStyle(fontSize: 14),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor:
                                                AppTheme.primaryColor,
                                            side: BorderSide(
                                              color: AppTheme.primaryColor
                                                  .withValues(alpha: 0.5),
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Show direct submit only when borrow list is empty
                                    if (_borrowList.isEmpty) ...[
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: SizedBox(
                                          height: 48,
                                          child: ElevatedButton(
                                            onPressed:
                                                (_submitting ||
                                                    _selectedInstrument ==
                                                        null ||
                                                    _selectedInstrument!
                                                        .isEmpty)
                                                ? null
                                                : _submit,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppTheme.primaryColor,
                                              foregroundColor: Colors.white,
                                              disabledBackgroundColor: AppTheme
                                                  .primaryColor
                                                  .withValues(alpha: 0.5),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: _submitting
                                                ? const SizedBox(
                                                    width: 18,
                                                    height: 18,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: Colors.white,
                                                        ),
                                                  )
                                                : const Text(
                                                    'Submit Request',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // --- Proceed (Submit All) button pinned at bottom ---
          if (_borrowList.isNotEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _submitting ? null : _submitAll,
                        icon: _submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send, size: 18),
                        label: Text(
                          _submitting
                              ? 'Submitting...'
                              : 'Submit ${_borrowList.length} Request${_borrowList.length > 1 ? 's' : ''}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.green.shade600
                              .withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
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

  // --- Borrow List Card ---
  Widget _buildBorrowListCard() {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.list_alt, size: 18, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Borrow List',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_borrowList.length} item${_borrowList.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...List.generate(_borrowList.length, (index) {
              final item = _borrowList[index];
              return Container(
                margin: EdgeInsets.only(
                  bottom: index < _borrowList.length - 1 ? 8 : 0,
                ),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['instrumentName'],
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Qty: ${item['quantity']} · ${item['purpose']}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _removeFromBorrowList(index),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.red.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildInstrumentDropdown() {
    if (_loading) {
      return const LinearProgressIndicator();
    }
    return DropdownButtonFormField<String>(
      initialValue:
          _selectedInstrument != null &&
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
