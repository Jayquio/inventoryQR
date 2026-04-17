// lib/screens/common/settings_screen.dart

import 'package:flutter/material.dart';
import '../../data/api_client.dart';
import '../../data/auth_service.dart';
import '../../data/app_config_service.dart';
import '../../data/theme_service.dart';
import '../../data/notification_service.dart';
import '../../core/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  final String userRole;
  const SettingsScreen({super.key, required this.userRole});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameController = TextEditingController();
  bool _saving = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = AuthService.instance.currentUsername;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    // In a real app you'd call an API to update the name
    await Future.delayed(const Duration(milliseconds: 500));
    AuthService.instance.setUsername(_nameController.text);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _saved = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _saved = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final role = AuthService.instance.currentRole.name;
    final email = AuthService.instance.currentUserEmail;

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
                const Icon(Icons.settings, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'Settings',
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
                  child: Column(
                    children: [
                      // Profile Card
                      Card(
                        elevation: 0.5,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.person,
                                      size: 18, color: Colors.grey.shade600),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Profile',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF374151),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Full Name
                              const Text('Full Name',
                                  style: TextStyle(fontSize: 13)),
                              const SizedBox(height: 4),
                              TextField(
                                controller: _nameController,
                                decoration: _inputDecor('Your name'),
                              ),
                              const SizedBox(height: 12),

                              // Email
                              const Text('Email',
                                  style: TextStyle(fontSize: 13)),
                              const SizedBox(height: 4),
                              TextField(
                                enabled: false,
                                decoration: _inputDecor(
                                    email.isNotEmpty ? email : 'No email'),
                                style:
                                    const TextStyle(color: Color(0xFF9CA3AF)),
                              ),
                              const SizedBox(height: 12),

                              // Role
                              const Text('Role',
                                  style: TextStyle(fontSize: 13)),
                              const SizedBox(height: 4),
                              TextField(
                                enabled: false,
                                decoration: _inputDecor(
                                    '${role[0].toUpperCase()}${role.substring(1)}'),
                                style:
                                    const TextStyle(color: Color(0xFF9CA3AF)),
                              ),
                              const SizedBox(height: 16),

                              // Save button
                              SizedBox(
                                height: 40,
                                child: ElevatedButton.icon(
                                  onPressed: _saving ? null : _save,
                                  icon: _saving
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : _saved
                                          ? const Icon(Icons.check_circle,
                                              size: 16)
                                          : const Icon(Icons.save, size: 16),
                                  label: Text(
                                      _saved ? 'Saved!' : 'Save Changes',
                                      style: const TextStyle(fontSize: 13)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // About Card
                      Card(
                        elevation: 0.5,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'About',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF374151),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildAboutRow('App', 'MedLab Inventory'),
                              const SizedBox(height: 8),
                              _buildAboutRow('Version', '1.0.0'),
                              const SizedBox(height: 8),
                              _buildAboutRow(
                                'Role',
                                '${role[0].toUpperCase()}${role.substring(1)}',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Sign Out
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            NotificationService.instance.clear(persist: true);
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/login',
                              (route) => false,
                            );
                          },
                          icon: Icon(Icons.logout,
                              size: 18, color: Colors.red.shade600),
                          label: Text(
                            'Sign Out',
                            style: TextStyle(color: Colors.red.shade600),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.red.shade200),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
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
        ],
      ),
    );
  }

  Widget _buildAboutRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
        Text(value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
            )),
      ],
    );
  }

  InputDecoration _inputDecor(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
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
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
    );
  }
}
