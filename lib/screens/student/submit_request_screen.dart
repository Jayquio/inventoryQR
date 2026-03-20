// lib/screens/student/submit_request_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_application_inventorymanagement/data/api_client.dart';
import 'package:flutter_application_inventorymanagement/models/instrument.dart';
import '../../data/notification_service.dart';
import '../../widgets/notification_icon.dart';
import '../../data/auth_service.dart';
import '../../core/theme.dart';

class SubmitRequestScreen extends StatefulWidget {
  final String? preSelectedInstrument;
  const SubmitRequestScreen({super.key, this.preSelectedInstrument});

  @override
  State<SubmitRequestScreen> createState() => _SubmitRequestScreenState();
}

class _SubmitRequestScreenState extends State<SubmitRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedInstrument;
  String _studentName = '';
  String _course = '';
  DateTime? _neededAt;
  String _purpose = '';
  List<Instrument> _instruments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _selectedInstrument = widget.preSelectedInstrument ?? '';
    _studentName = AuthService.instance.currentUsername;
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await ApiClient.instance.fetchInstruments();
      if (!mounted) return;
      setState(() {
        _instruments = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (_neededAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set when you need the instrument')),
      );
      return;
    }

    try {
      await ApiClient.instance.submitRequest(
        studentName: _studentName,
        instrumentName: _selectedInstrument,
        purpose: _purpose,
        course: _course,
        neededAtIso: _neededAt!.toIso8601String(),
      );
      
      _addRequestNotifications();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request submitted successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  void _addRequestNotifications() {
    final neededStr = _neededAt!.toLocal().toString().split('.').first;
    final extra = ' • Course: $_course • Needed: $neededStr';
    final nowIso = DateTime.now().toIso8601String();

    NotificationService.instance.add(
      NotificationItem(
        id: 'student_${DateTime.now().microsecondsSinceEpoch}',
        title: 'Request Submitted',
        message: 'You requested $_selectedInstrument$extra',
        type: 'success',
        timestamp: nowIso,
        recipient: 'Student',
        course: _course,
        priority: 'low',
      ),
    );
    NotificationService.instance.add(
      NotificationItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: 'New Request Submitted',
        message: '$_studentName requested $_selectedInstrument$extra',
        type: 'request',
        timestamp: nowIso,
        recipient: 'Teacher',
        course: _course,
        priority: 'medium',
      ),
    );
    NotificationService.instance.add(
      NotificationItem(
        id: 'admin_${DateTime.now().microsecondsSinceEpoch}',
        title: 'New Request',
        message: '$_studentName requested $_selectedInstrument$extra',
        type: 'request',
        timestamp: nowIso,
        recipient: 'Admin',
        course: _course,
        priority: 'low',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTeacher = AuthService.instance.currentRole == UserRole.staff;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(isTeacher ? 'Teacher Request' : 'Submit Request'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          const NotificationIcon(recipients: ['Student']),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isTeacher ? 'Teacher Request' : 'Create a New Request',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Provide details and select an instrument',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildFormCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle(isTeacher ? 'Teacher' : 'Student'),
                          const SizedBox(height: 12),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.person, color: AppTheme.primaryColor),
                            title: Text(_studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(isTeacher ? 'From your faculty account' : 'From your account'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildFormCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('Request Details'),
                          const SizedBox(height: 16),
                          if (_loading)
                            const LinearProgressIndicator(),
                          if (!_loading)
                            DropdownButtonFormField<String>(
                            decoration: _inputDecoration('Select Instrument', Icons.inventory),
                            isExpanded: true,
                            initialValue: _selectedInstrument.isNotEmpty &&
                                    _instruments.any((i) => i.name == _selectedInstrument)
                                ? _selectedInstrument
                                : null,
                            items: _instruments.map((instrument) {
                              return DropdownMenuItem<String>(
                                value: instrument.name,
                                child: Text(instrument.name),
                              );
                            }).toList(),
                            validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                            onChanged: (value) => setState(() => _selectedInstrument = value ?? ''),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            decoration: _inputDecoration('Course', Icons.school),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                            onSaved: (v) => _course = v!.trim(),
                          ),
                          const SizedBox(height: 16),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.event, color: AppTheme.primaryColor),
                            title: const Text('Needed Date & Time'),
                            subtitle: Text(
                              _neededAt != null
                                  ? '${_neededAt!.toLocal()}'.split('.').first
                                  : 'Tap to set when you need the instrument',
                              style: const TextStyle(color: Colors.grey),
                            ),
                            onTap: () async {
                              final now = DateTime.now();
                              final date = await showDatePicker(
                                context: context,
                                initialDate: now,
                                firstDate: now,
                                lastDate: DateTime(now.year + 1),
                              );
                              if (date != null && context.mounted) {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                );
                                if (time != null && mounted) {
                                  setState(() => _neededAt = DateTime(date.year, date.month, date.day, time.hour, time.minute));
                                }
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            decoration: _inputDecoration('Purpose', Icons.flag),
                            maxLines: 3,
                            validator: (value) => value!.isEmpty ? 'Required' : null,
                            onSaved: (value) => _purpose = value!,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _submitRequest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.secondaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send),
                            SizedBox(width: 12),
                            Text(
                              'Submit Request',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.primaryColor,
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppTheme.primaryColor),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.secondaryColor, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }
}
