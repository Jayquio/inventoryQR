// lib/screens/common/login_screen.dart

import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../admin/admin_dashboard.dart';
import '../staff/staff_dashboard.dart';
import '../student/student_dashboard.dart';
import '../../data/auth_service.dart';
import '../../widgets/module_search_bar.dart';
import '../../data/notification_service.dart';
import '../../data/api_client.dart';
import '../../data/app_config_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const String _userLoginTitle = 'User Login';
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: _buildBackgroundDecoration(),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: _buildLoginCard(),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildBackgroundDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.blue.shade900, Colors.blue.shade600],
      ),
    );
  }

  Widget _buildLoginCard() {
    return Card(
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildUsernameField(),
              const SizedBox(height: 16),
              _buildPasswordField(),
              const SizedBox(height: 24),
              _buildLoginButton(),
              const SizedBox(height: 16),
              _buildQrLoginOption(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      children: [
        Icon(Icons.inventory_2, size: 64, color: Colors.blue),
        SizedBox(height: 16),
        Text(
          _userLoginTitle,
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        SizedBox(height: 8),
        Text(
          'Inventory Management System',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildUsernameField() {
    return TextFormField(
      controller: _usernameController,
      decoration: InputDecoration(
        labelText: 'Username',
        prefixIcon: const Icon(Icons.person_outline),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: 'Password',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
        ),
        child: _isLoading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('LOGIN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildQrLoginOption() {
    return TextButton.icon(
      onPressed: () => Navigator.pushNamed(context, '/qr_scanner', arguments: 'login'),
      icon: const Icon(Icons.qr_code_scanner),
      label: const Text('Login via QR Code'),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final username = _usernameController.text.trim();
      final password = _passwordController.text;

      final res = await ApiClient.instance.login(username: username, password: password);
      final roleStr = (res['role']?.toString() ?? '').toLowerCase();
      UserRole? role = _parseRole(roleStr);

      if (role != null) {
        AuthService.instance.setUsername(username);
        AuthService.instance.setRole(role);
        _addLoginNotification(username);
        if (mounted) {
          Navigator.pushReplacementNamed(context, _getRoute(role));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid credentials')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  UserRole? _parseRole(String roleStr) {
    if (roleStr == 'admin') return UserRole.admin;
    if (roleStr == 'teacher' || roleStr == 'staff') return UserRole.staff;
    if (roleStr == 'student') return UserRole.student;
    return null;
  }

  String _getRoute(UserRole role) {
    if (role == UserRole.admin) return '/admin_dashboard';
    if (role == UserRole.staff) return '/staff_dashboard';
    return '/student_dashboard';
  }

  void _addLoginNotification(String username) {
    NotificationService.instance.add(
      NotificationItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: _userLoginTitle,
        message: '$username logged in',
        type: 'login',
        timestamp: DateTime.now().toIso8601String(),
        recipient: 'Admin',
        priority: 'low',
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
