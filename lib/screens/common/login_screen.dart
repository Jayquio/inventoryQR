// lib/screens/common/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Add this for kIsWeb
import '../../core/theme.dart';
import '../../data/auth_service.dart';
import '../../data/notification_service.dart';
import '../../data/api_client.dart';
import '../../core/constants.dart';

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
    return const BoxDecoration(
      gradient: AppTheme.primaryGradient,
    );
  }

  Widget _buildLoginCard() {
    return Card(
      elevation: 12,
      color: Colors.white,
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
        Icon(Icons.inventory_2, size: 64, color: AppTheme.primaryColor),
        SizedBox(height: 16),
        Text(
          _userLoginTitle,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: AppTheme.primaryColor,
          ),
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
      onChanged: (v) => setState(() {}), // Refresh to show superadmin settings
      decoration: InputDecoration(
        labelText: 'Username',
        prefixIcon: const Icon(Icons.person_outline, color: AppTheme.primaryColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
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
        prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primaryColor),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: AppTheme.primaryColor,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
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
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
        child: _isLoading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('LOGIN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildQrLoginOption() {
    return Column(
      children: [
        TextButton.icon(
          onPressed: () => Navigator.pushNamed(context, '/qr_scanner', arguments: 'login'),
          icon: const Icon(Icons.qr_code_scanner, color: AppTheme.secondaryColor),
          label: const Text(
            'Login via QR Code',
            style: TextStyle(color: AppTheme.secondaryColor, fontWeight: FontWeight.w600),
          ),
        ),
        // Superadmin API Config Access
        if (_usernameController.text.trim().toLowerCase() == 'superadmin')
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/settings', arguments: 'Admin'),
              icon: const Icon(Icons.settings, color: Colors.orange, size: 16),
              label: const Text(
                'Configure API (Superadmin)',
                style: TextStyle(color: Colors.orange, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final username = _usernameController.text.trim();
      final password = _passwordController.text;

      if (await _handleBypassLogin(username, password)) return;

      final res = await ApiClient.instance.login(username: username, password: password);
      final roleStr = (res['role']?.toString() ?? '').toLowerCase();
      UserRole? role = _parseRole(roleStr);

      if (role == null) {
        _showError('Invalid user role');
        return;
      }

      if (role == UserRole.admin && !kIsWeb) {
        _showError('Admin Dashboard is restricted to Web browsers only.');
        return;
      }

      await _completeLogin(username, role);
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (context.mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _handleBypassLogin(String username, String password) async {
    // 1. Superadmin Offline Bypass
    if (username == 'superadmin' && password == 'superadmin123') {
      await _performBypass(username, UserRole.superadmin, 'Superadmin Bypass Mode Activated (Offline)');
      return true;
    }

    // 2. Local Admin Bypass
    if (username == 'admin' && password == 'admin123') {
      if (!kIsWeb) {
        _showError('Admin access is restricted to Web browsers only.');
        return true;
      }
      await _performBypass(username, UserRole.admin, 'Local Admin Maintenance Mode Activated');
      return true;
    }
    return false;
  }

  Future<void> _performBypass(String username, UserRole role, String message) async {
    AuthService.instance.setUsername(username);
    AuthService.instance.setRole(role);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      Navigator.of(context).pushReplacementNamed(AppRoutes.adminDashboard);
    }
  }

  Future<void> _completeLogin(String username, UserRole role) async {
    AuthService.instance.setUsername(username);
    AuthService.instance.setRole(role);

    NotificationService.instance.add(
      NotificationItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: 'User Login',
        message: '$username logged in',
        type: 'login',
        timestamp: DateTime.now().toIso8601String(),
        recipient: 'Admin',
        priority: 'low',
      ),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Logged in as $username')));
      Navigator.of(context).pushReplacementNamed(_getRoute(role));
    }
  }

  void _showError(String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
    setState(() => _isLoading = false);
  }

  UserRole? _parseRole(String roleStr) {
    if (roleStr == 'admin') return UserRole.admin;
    if (roleStr == 'teacher' || roleStr == 'staff') return UserRole.teacher;
    if (roleStr == 'student') return UserRole.student;
    return null;
  }

  String _getRoute(UserRole role) {
    if (role == UserRole.admin || role == UserRole.superadmin) return AppRoutes.adminDashboard;
    if (role == UserRole.teacher) return AppRoutes.teacherDashboard;
    return AppRoutes.studentDashboard;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
