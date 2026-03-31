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
  late String _selectedInstrument;
  String _studentName = '';
  String? _selectedCourse;
  DateTime? _neededAt;
  String _purpose = '';
  List<Instrument> _instruments = [];
  bool _loading = true;

  final List<String> _caseCourses = [
    'BS Pharmacy',
    'BS Biology',
    'BS Radiologic Technology',
    'BS Medical Technology/Medical Laboratory Science',
    'BS Nursing',
  ];

  @override
  void initState() {
    super.initState();
    _selectedInstrument = widget.preSelectedInstrument ?? '';
    _selectedCourse = widget.preSelectedCourse;
    _neededAt = widget.preSelectedDate;
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

  String _formatNeededAt(DateTime dt) {
    final months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final local = dt.toLocal();
    var hour = local.hour;
    final minute = local.minute.toString().padLeft(2, '0');
    final suffix = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    final hh = hour.toString().padLeft(2, '0');
    return '${months[local.month - 1]} ${local.day}, ${local.year} • $hh:$minute $suffix';
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
        course: _selectedCourse ?? '',
        neededAtIso: _neededAt!.toIso8601String(),
      );
      
      _addRequestNotifications();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request submitted successfully!')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  void _addRequestNotifications() {
    final neededStr = _neededAt!.toLocal().toString().split('.').first;
    final extra = ' • Course: $_selectedCourse • Needed: $neededStr';
    final nowIso = DateTime.now().toIso8601String();

    NotificationService.instance.add(
      NotificationItem(
        id: 'student_${DateTime.now().microsecondsSinceEpoch}',
        title: 'Request Submitted',
        message: 'You requested $_selectedInstrument$extra',
        type: 'success',
        timestamp: nowIso,
        recipient: 'Student',
        course: _selectedCourse ?? '',
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
        course: _selectedCourse ?? '',
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
        course: _selectedCourse ?? '',
        priority: 'low',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTeacher = AuthService.instance.currentRole == UserRole.teacher;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(isTeacher ? 'Teacher Request' : 'Submit Request'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: const [
          NotificationIcon(recipients: ['Student']),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(isTeacher),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildUserCard(isTeacher),
                    const SizedBox(height: 20),
                    _buildDetailsCard(),
                    const SizedBox(height: 32),
                    _buildSubmitButton(),
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
      style: const TextStyle(
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
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }

  Widget _buildHeader(bool isTeacher) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.only(
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
    );
  }

  Widget _buildUserCard(bool isTeacher) {
    return _buildFormCard(
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
    );
  }

  Widget _buildDetailsCard() {
    return _buildFormCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Request Details'),
          const SizedBox(height: 16),
          if (_loading) const LinearProgressIndicator(),
          if (!_loading) _buildInstrumentDropdown(),
          const SizedBox(height: 16),
          _buildCourseDropdown(),
          const SizedBox(height: 16),
          _buildDateTimePicker(),
          const SizedBox(height: 16),
          _buildPurposeField(),
        ],
      ),
    );
  }

  Widget _buildInstrumentDropdown() {
    return DropdownButtonFormField<String>(
      decoration: _inputDecoration('Select Instrument', Icons.inventory),
      isExpanded: true,
      initialValue: _selectedInstrument.isNotEmpty && _instruments.any((i) => i.name == _selectedInstrument)
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
    );
  }

  Widget _buildCourseDropdown() {
    return DropdownButtonFormField<String>(
      decoration: _inputDecoration('Course (CASE)', Icons.school),
      isExpanded: true,
      value: _selectedCourse,
      items: _caseCourses.map((course) {
        return DropdownMenuItem<String>(
          value: course,
          child: Text(course, style: const TextStyle(fontSize: 13)),
        );
      }).toList(),
      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
      onChanged: (value) => setState(() => _selectedCourse = value),
    );
  }

  Widget _buildDateTimePicker() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.event, color: AppTheme.primaryColor),
      title: const Text('Needed Date & Time'),
      subtitle: Text(
        _neededAt != null ? _formatNeededAt(_neededAt!) : 'Tap to set when you need the instrument',
        style: const TextStyle(color: Colors.grey),
      ),
      onTap: _pickDateTime,
    );
  }

  Future<void> _pickDateTime() async {
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
      if (time != null && context.mounted) {
        setState(() => _neededAt = DateTime(date.year, date.month, date.day, time.hour, time.minute));
      }
    }
  }

  Widget _buildPurposeField() {
    return TextFormField(
      decoration: _inputDecoration('Purpose', Icons.flag),
      maxLines: 3,
      validator: (value) => value!.isEmpty ? 'Required' : null,
      onSaved: (value) => _purpose = value!,
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _submitRequest,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.secondaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
    );
  }
}
