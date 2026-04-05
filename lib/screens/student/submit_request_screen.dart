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

class _RequestedItem {
  String name;
  int quantity;
  String serialNumber;
  _RequestedItem({
    required this.name,
    required this.quantity,
    required this.serialNumber,
  });
}

class _SubmitRequestScreenState extends State<SubmitRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<_RequestedItem> _requestedItems = [];
  String _studentName = '';
  String? _selectedCourse;
  DateTime? _neededAt;
  String _purpose = '';
  List<Instrument> _instruments = [];
  bool _loading = true;
  String _typeFilter = 'All';

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
    if (widget.preSelectedInstrument != null &&
        widget.preSelectedInstrument!.isNotEmpty) {
      _requestedItems.add(
        _RequestedItem(
          name: widget.preSelectedInstrument!,
          quantity: 1,
          serialNumber: '',
        ),
      );
    } else {
      _requestedItems.add(
        _RequestedItem(name: '', quantity: 1, serialNumber: ''),
      );
    }
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
        const SnackBar(
          content: Text('Please set when you need the instrument'),
        ),
      );
      return;
    }

    final minAllowed = DateTime.now().add(const Duration(days: 3));
    if (_neededAt!.isBefore(minAllowed)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Requests must be filed at least 3 days before use'),
        ),
      );
      return;
    }

    if (_requestedItems.any((item) => item.name.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an instrument for all items'),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      for (final item in _requestedItems) {
        await ApiClient.instance.submitRequest(
          studentName: _studentName,
          instrumentName: item.name,
          quantity: item.quantity,
          purpose: _purpose,
          serialNumber: item.serialNumber,
          course: _selectedCourse ?? '',
          neededAtIso: _neededAt!.toIso8601String(),
        );
      }

      _addRequestNotifications();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Requests submitted successfully!')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  void _addRequestNotifications() {
    final neededStr = _neededAt!.toLocal().toString().split('.').first;
    final extra = ' • Course: $_selectedCourse • Needed: $neededStr';
    final nowIso = DateTime.now().toIso8601String();
    final itemsSummary = _requestedItems
        .map((e) => '${e.name} (x${e.quantity})')
        .join(', ');

    NotificationService.instance.add(
      NotificationItem(
        id: 'student_${DateTime.now().microsecondsSinceEpoch}',
        title: 'Requests Submitted',
        message: 'You requested $itemsSummary$extra',
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
        title: 'New Requests Submitted',
        message: '$_studentName requested $itemsSummary$extra',
        type: 'request',
        timestamp: nowIso,
        recipient: 'Teacher',
        course: _selectedCourse ?? '',
        priority: 'medium',
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
      body: Stack(
        children: [
          SingleChildScrollView(
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
                        _buildRequestedItemsCard(),
                        const SizedBox(height: 20),
                        _buildCommonDetailsCard(),
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
          if (_loading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildRequestedItemsCard() {
    return _buildFormCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionTitle('Requested Instruments'),
              IconButton(
                onPressed: () => setState(
                  () => _requestedItems.add(
                    _RequestedItem(name: '', quantity: 1, serialNumber: ''),
                  ),
                ),
                icon: const Icon(
                  Icons.add_circle,
                  color: AppTheme.primaryColor,
                ),
                tooltip: 'Add another instrument',
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _typeFilter,
            decoration: _inputDecoration('Item Type Filter', Icons.tune),
            items: const [
              DropdownMenuItem(value: 'All', child: Text('All Items')),
              DropdownMenuItem(
                value: 'instrument',
                child: Text('Instruments Only'),
              ),
              DropdownMenuItem(value: 'reagent', child: Text('Reagents Only')),
            ],
            onChanged: (value) => setState(() => _typeFilter = value ?? 'All'),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _requestedItems.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade50,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Item ${index + 1}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        if (_requestedItems.length > 1)
                          IconButton(
                            onPressed: () =>
                                setState(() => _requestedItems.removeAt(index)),
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                              size: 20,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildInstrumentDropdownForItem(index),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: _buildQuantityDropdownForItem(index),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: _buildSerialDropdownForItem(index),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInstrumentDropdownForItem(int index) {
    final item = _requestedItems[index];
    final allOptions = _filteredInstruments();
    // Get unique names to avoid duplicates in the main dropdown
    final uniqueNames = allOptions.map((i) => i.name).toSet().toList();

    return DropdownButtonFormField<String>(
      decoration: _inputDecoration('Select Instrument', Icons.inventory),
      isExpanded: true,
      initialValue: item.name.isNotEmpty && uniqueNames.contains(item.name)
          ? item.name
          : null,
      items: uniqueNames.map((name) {
        final instrument = allOptions.firstWhere((i) => i.name == name);
        return DropdownMenuItem<String>(
          value: name,
          child: Text(
            '[${instrument.type.toUpperCase()}] $name',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14),
          ),
        );
      }).toList(),
      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
      onChanged: (value) => setState(() {
        item.name = value ?? '';
        // Reset serial number when instrument changes
        final serials = _getSerialsForName(item.name);
        item.serialNumber = serials.isNotEmpty ? serials.first : '';
      }),
    );
  }

  Widget _buildQuantityDropdownForItem(int index) {
    final item = _requestedItems[index];
    final selected = _instrumentByName(item.name);
    // If we have a serial number selected, quantity is usually 1,
    // but we can allow more if it's a generic item or reagent.
    final maxQty = selected?.available ?? 10;
    final qtyOptions = List.generate(
      maxQty > 0 ? (maxQty > 20 ? 20 : maxQty) : 1,
      (i) => i + 1,
    );

    return DropdownButtonFormField<int>(
      initialValue: qtyOptions.contains(item.quantity)
          ? item.quantity
          : qtyOptions.first,
      decoration: _inputDecoration('Qty', null),
      items: qtyOptions
          .map((q) => DropdownMenuItem(value: q, child: Text(q.toString())))
          .toList(),
      onChanged: (value) => setState(() => item.quantity = value ?? 1),
    );
  }

  Widget _buildSerialDropdownForItem(int index) {
    final item = _requestedItems[index];
    final serials = _getSerialsForName(item.name);
    final selected = _instrumentByName(item.name);
    final isReagent = selected?.type.toLowerCase() == 'reagent';

    if (isReagent ||
        serials.isEmpty ||
        (serials.length == 1 && serials.first.isEmpty)) {
      return TextFormField(
        enabled: false,
        decoration: _inputDecoration('N/A', null),
        initialValue: 'No Serial',
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      );
    }

    return DropdownButtonFormField<String>(
      key: ValueKey('${item.name}_serials_$index'),
      initialValue: serials.contains(item.serialNumber)
          ? item.serialNumber
          : serials.first,
      decoration: _inputDecoration('Serial No.', null),
      isExpanded: true,
      items: serials.map((sn) {
        return DropdownMenuItem(
          value: sn,
          child: Text(
            sn.isEmpty ? 'Generic' : sn,
            style: const TextStyle(fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (value) => setState(() => item.serialNumber = value ?? ''),
    );
  }

  List<String> _getSerialsForName(String name) {
    if (name.isEmpty) return [];
    return _instruments
        .where((i) => i.name == name)
        .map((i) => i.serialNumber ?? '')
        .toSet()
        .toList();
  }

  Instrument? _instrumentByName(String name) {
    for (final instrument in _instruments) {
      if (instrument.name == name) return instrument;
    }
    return null;
  }

  List<Instrument> _filteredInstruments() {
    if (_typeFilter == 'All') return _instruments;
    return _instruments
        .where((i) => i.type.toLowerCase() == _typeFilter)
        .toList();
  }

  Widget _buildCommonDetailsCard() {
    return _buildFormCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Other Details'),
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

  Widget _buildCourseDropdown() {
    return DropdownButtonFormField<String>(
      decoration: _inputDecoration('Course (CASE)', Icons.school),
      isExpanded: true,
      initialValue: _selectedCourse,
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
      leading: const Icon(Icons.event, color: AppTheme.primaryColor),
      title: const Text('Needed Date & Time'),
      subtitle: Text(
        _neededAt != null
            ? _formatNeededAt(_neededAt!)
            : 'Tap to set when you need the instrument',
        style: const TextStyle(color: Colors.grey),
      ),
      onTap: _pickDateTime,
    );
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    // Enforce 3-day advance policy for all users
    final firstAllowedDate = now.add(const Duration(days: 3));
    
    final date = await showDatePicker(
      context: context,
      initialDate: _neededAt != null && _neededAt!.isAfter(firstAllowedDate) 
          ? _neededAt! 
          : firstAllowedDate,
      firstDate: firstAllowedDate,
      lastDate: DateTime(now.year + 1),
      helpText: 'Select Date (At least 3 days in advance)',
    );
    if (!mounted || date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (!mounted || time == null) return;
    setState(
      () => _neededAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      ),
    );
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

  InputDecoration _inputDecoration(String label, IconData? icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null
          ? Icon(icon, color: AppTheme.primaryColor)
          : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
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
            style: TextStyle(color: Colors.white70, fontSize: 14),
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
            leading: const Icon(Icons.person, color: AppTheme.primaryColor),
            title: Text(
              _studentName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              isTeacher ? 'From your faculty account' : 'From your account',
            ),
          ),
        ],
      ),
    );
  }
}
