import 'package:flutter/material.dart';
import '../../data/qr_code_service.dart';
import '../../data/auth_service.dart';
import '../../data/api_client.dart';

class UserQrScreen extends StatefulWidget {
  const UserQrScreen({super.key});

  @override
  State<UserQrScreen> createState() => _UserQrScreenState();
}

class _UserQrScreenState extends State<UserQrScreen> {
  String? _generatedPayload;
  List<Map<String, dynamic>> _users = [];
  bool _loadingUsers = false;
  String _roleFilter = 'All';
  String? _selectedUsername;

  @override
  void initState() {
    super.initState();
    if (AuthService.instance.currentRole == UserRole.admin) {
      _loadingUsers = true;
      ApiClient.instance.fetchUsers().then((data) {
        if (!mounted) return;
        setState(() {
          _users = data;
          _loadingUsers = false;
        });
      }).catchError((_) {
        if (!mounted) return;
        setState(() => _loadingUsers = false);
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final username = AuthService.instance.currentUsername;
    final roleEnum = AuthService.instance.currentRole;
    final roleLabel = roleEnum == UserRole.staff ? 'Teacher' : roleEnum.name[0].toUpperCase() + roleEnum.name.substring(1);
    final myPayload = QrCodeService.instance.buildUserPayload();
    final isAdmin = roleEnum == UserRole.admin;
    return Scaffold(
      appBar: AppBar(title: const Text('My QR')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Text('User: $username', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Role: $roleLabel', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            Center(child: QrCodeService.instance.buildQrWidget(myPayload, size: 220)),
            const SizedBox(height: 8),
            const Text('Show this QR to identify your account', textAlign: TextAlign.center),
            if (isAdmin) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              const Text('Generate User QR (Admin)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _roleFilter,
                items: const [
                  DropdownMenuItem(value: 'All', child: Text('All Roles')),
                  DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'Teacher', child: Text('Teacher')),
                  DropdownMenuItem(value: 'Student', child: Text('Student')),
                ],
                onChanged: (v) => setState(() {
                  _roleFilter = v ?? 'All';
                  _selectedUsername = null;
                }),
                decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Filter by role'),
              ),
              const SizedBox(height: 8),
              if (_loadingUsers)
                const LinearProgressIndicator()
              else
                DropdownButtonFormField<String>(
                  value: _selectedUsername,
                  isExpanded: true,
                  items: _users
                      .where((u) {
                        final r = (u['role']?.toString() ?? '').toLowerCase();
                        final label = _roleFilter.toLowerCase();
                        if (label == 'all') return true;
                        if (label == 'teacher') return r == 'teacher' || r == 'staff';
                        return r == label;
                      })
                      .map((u) => DropdownMenuItem<String>(
                            value: u['username']?.toString() ?? '',
                            child: Text(u['username']?.toString() ?? ''),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedUsername = v),
                  decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Select User'),
                ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  final uname = _selectedUsername;
                  if (uname == null || uname.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a user first')));
                    return;
                  }
                  final rec = _users.firstWhere(
                    (u) => (u['username']?.toString() ?? '') == uname,
                    orElse: () => {},
                  );
                  final r = (rec['role']?.toString() ?? '').toLowerCase();
                  final userRole = r == 'admin'
                      ? UserRole.admin
                      : (r == 'teacher' || r == 'staff')
                          ? UserRole.staff
                          : UserRole.student;
                  final p = QrCodeService.instance.buildUserPayloadFor(id: uname, role: userRole);
                  setState(() => _generatedPayload = p);
                },
                icon: const Icon(Icons.badge),
                label: const Text('Generate User QR'),
              ),
              if (_generatedPayload != null) ...[
                const SizedBox(height: 12),
                Center(child: QrCodeService.instance.buildQrWidget(_generatedPayload!, size: 220)),
                const SizedBox(height: 8),
                SelectableText(_generatedPayload!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ],
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              color: Colors.blue.withValues(alpha: 0.06),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Payload contains username and role only. Admin may generate QR for others for sign-in.',
                  style: TextStyle(color: Colors.blue),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
