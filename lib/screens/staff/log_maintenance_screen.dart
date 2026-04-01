// lib/screens/staff/log_maintenance_screen.dart

import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../widgets/role_guard.dart';
import '../../data/auth_service.dart';
import '../../data/dummy_data.dart';
import '../../models/maintenance.dart';

class LogMaintenanceScreen extends StatefulWidget {
  final String? preSelectedInstrument;

  const LogMaintenanceScreen({super.key, this.preSelectedInstrument});

  @override
  State<LogMaintenanceScreen> createState() => _LogMaintenanceScreenState();
}

class _LogMaintenanceScreenState extends State<LogMaintenanceScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedInstrument = '';
  String _notes = '';
  String _technician = '';
  String _type = '';
  String _status = 'Completed';

  @override
  void initState() {
    super.initState();
    if (widget.preSelectedInstrument != null && widget.preSelectedInstrument!.isNotEmpty) {
      _selectedInstrument = widget.preSelectedInstrument!;
    }
  }

  void _logMaintenance() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final newMaintenance = Maintenance(
        instrumentName: _selectedInstrument,
        technician: _technician,
        date: DateTime.now().toString().split(' ')[0], // YYYY-MM-DD format
        type: _type,
        notes: _notes,
        status: _status,
      );
      setState(() {
        maintenanceRecords.add(newMaintenance);
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maintenance logged successfully!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Log Maintenance'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RoleGuard(
        allowed: const {UserRole.admin, UserRole.superadmin},
        unauthorizedMessage: 'Only Admin/Superadmin can access maintenance',
        child: SingleChildScrollView(
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
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Register Maintenance Record',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Keep our laboratory instruments in top condition',
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
                          _buildSectionTitle('Instrument Details'),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            decoration: _inputDecoration('Select Instrument', Icons.inventory),
                            isExpanded: true,
                            initialValue: widget.preSelectedInstrument != null && widget.preSelectedInstrument!.isNotEmpty
                                ? widget.preSelectedInstrument
                                : null,
                            items: instruments.map((instrument) {
                              return DropdownMenuItem<String>(
                                value: instrument.name,
                                child: Text(instrument.name),
                              );
                            }).toList(),
                            validator: (value) => value == null ? 'Required' : null,
                            onChanged: (value) => setState(() => _selectedInstrument = value!),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            decoration: _inputDecoration('Maintenance Type', Icons.build),
                            validator: (value) => value!.isEmpty ? 'Required' : null,
                            onSaved: (value) => _type = value!,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildFormCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('Maintenance Info'),
                          const SizedBox(height: 16),
                          TextFormField(
                            decoration: _inputDecoration('Technician Name', Icons.person),
                            validator: (value) => value!.isEmpty ? 'Required' : null,
                            onSaved: (value) => _technician = value!,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            decoration: _inputDecoration('Current Status', Icons.info_outline),
                            initialValue: _status,
                            items: ['Completed', 'Pending', 'In Progress'].map((status) {
                              return DropdownMenuItem<String>(
                                value: status,
                                child: Text(status),
                              );
                            }).toList(),
                            onChanged: (value) => setState(() => _status = value!),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            decoration: _inputDecoration('Detailed Notes', Icons.note_add),
                            maxLines: 4,
                            validator: (value) => value!.isEmpty ? 'Required' : null,
                            onSaved: (value) => _notes = value!,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _logMaintenance,
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
                            Icon(Icons.save),
                            SizedBox(width: 12),
                            Text(
                              'Save Record',
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
        ),),
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
