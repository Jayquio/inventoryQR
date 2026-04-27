// lib/screens/common/settings_screen.dart

import 'package:flutter/material.dart';
import '../../data/auth_service.dart';
import '../../data/notification_service.dart';
import '../../data/api_client.dart';
import '../../core/theme.dart';

class SettingsScreen extends StatefulWidget {
  final String userRole;
  const SettingsScreen({super.key, required this.userRole});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _saving = false;
  bool _saved = false;
  bool _changingPassword = false;
  bool _passwordChanged = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _nameController.text = AuthService.instance.currentUsername;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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

  Future<void> _changePassword() async {
    final pass = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    if (pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a new password')),
      );
      return;
    }

    if (pass != confirm) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    setState(() => _changingPassword = true);

    try {
      await ApiClient.instance.updateUser(
        username: AuthService.instance.currentUsername,
        password: pass,
      );

      if (!mounted) return;
      setState(() {
        _changingPassword = false;
        _passwordChanged = true;
        _passwordController.clear();
        _confirmPasswordController.clear();
      });

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _passwordChanged = false);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _changingPassword = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to change password: $e')));
    }
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
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white70,
                    size: 22,
                  ),
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
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.person,
                                    size: 18,
                                    color: Colors.grey.shade600,
                                  ),
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
                              const Text(
                                'Full Name',
                                style: TextStyle(fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              TextField(
                                controller: _nameController,
                                decoration: _inputDecor('Your name'),
                              ),
                              const SizedBox(height: 12),

                              // Email
                              const Text(
                                'Email',
                                style: TextStyle(fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              TextField(
                                enabled: false,
                                decoration: _inputDecor(
                                  email.isNotEmpty ? email : 'No email',
                                ),
                                style: const TextStyle(
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Role
                              const Text(
                                'Role',
                                style: TextStyle(fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              TextField(
                                enabled: false,
                                decoration: _inputDecor(
                                  '${role[0].toUpperCase()}${role.substring(1)}',
                                ),
                                style: const TextStyle(
                                  color: Color(0xFF9CA3AF),
                                ),
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
                                      ? const Icon(Icons.check_circle, size: 16)
                                      : const Icon(Icons.save, size: 16),
                                  label: Text(
                                    _saved ? 'Saved!' : 'Save Changes',
                                    style: const TextStyle(fontSize: 13),
                                  ),
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

                      // Security Card
                      Card(
                        elevation: 0.5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.lock_outline,
                                    size: 18,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Security',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF374151),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // New Password
                              const Text(
                                'New Password',
                                style: TextStyle(fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              TextField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: _inputDecor('Enter new password')
                                    .copyWith(
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          size: 18,
                                        ),
                                        onPressed: () => setState(
                                          () => _obscurePassword =
                                              !_obscurePassword,
                                        ),
                                      ),
                                    ),
                              ),
                              const SizedBox(height: 12),

                              // Confirm Password
                              const Text(
                                'Confirm New Password',
                                style: TextStyle(fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              TextField(
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                decoration: _inputDecor('Confirm new password')
                                    .copyWith(
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscureConfirmPassword
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          size: 18,
                                        ),
                                        onPressed: () => setState(
                                          () => _obscureConfirmPassword =
                                              !_obscureConfirmPassword,
                                        ),
                                      ),
                                    ),
                              ),
                              const SizedBox(height: 16),

                              // Change Password button
                              SizedBox(
                                height: 40,
                                child: ElevatedButton.icon(
                                  onPressed: _changingPassword
                                      ? null
                                      : _changePassword,
                                  icon: _changingPassword
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : _passwordChanged
                                      ? const Icon(Icons.check_circle, size: 16)
                                      : const Icon(Icons.vpn_key, size: 16),
                                  label: Text(
                                    _passwordChanged
                                        ? 'Password Changed!'
                                        : 'Update Password',
                                    style: const TextStyle(fontSize: 13),
                                  ),
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
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                          icon: Icon(
                            Icons.logout,
                            size: 18,
                            color: Colors.red.shade600,
                          ),
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
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecor(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
