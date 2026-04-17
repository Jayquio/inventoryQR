// lib/screens/admin/user_management_screen.dart

import 'package:flutter/material.dart';
import '../../widgets/role_guard.dart';
import '../../data/auth_service.dart';
import '../../widgets/search_bar.dart';
import '../../data/api_client.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  static const String _exceptionPrefix = 'Exception: ';

  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final data = await ApiClient.instance.fetchUsers();
      if (!mounted) return;
      setState(() {
        _users = data
            .map((e) => {
                  'id': e['id']?.toString() ?? '',
                  'username': e['username']?.toString() ?? '',
                  'role': (e['role']?.toString() ?? '').toLowerCase(),
                })
            .toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst(_exceptionPrefix, ''))),
      );
    }
  }

  void _addUser() {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    String selectedRole = 'Student';

    showDialog(
      context: context,
      builder: (context) {
        bool submitting = false;
        return StatefulBuilder(
          builder: (context, setStateDialog) => AlertDialog(
            title: const Text('Create New User'),
            content: _UserFormContent(
              usernameController: usernameController,
              passwordController: passwordController,
              selectedRole: selectedRole,
              onRoleChanged: (v) => setStateDialog(() => selectedRole = v!),
              isEdit: false,
            ),
            actions: _buildFormActions(
              context: context,
              submitting: submitting,
              onCancel: () => Navigator.pop(context),
              onSubmit: () => _submitAddUser(
                dialogContext: context,
                username: usernameController.text.trim(),
                password: passwordController.text.trim(),
                role: selectedRole.toLowerCase(),
                setSubmitting: (v) => setStateDialog(() => submitting = v),
              ),
              submitLabel: 'Create',
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitAddUser({
    required BuildContext dialogContext,
    required String username,
    required String password,
    required String role,
    required Function(bool) setSubmitting,
  }) async {
    if (username.isEmpty || password.isEmpty) {
      if (dialogContext.mounted) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(content: Text('All fields are required')));
      }
      return;
    }

    setSubmitting(true);
    try {
      await ApiClient.instance.createUser(username: username, password: password, role: role);
      if (dialogContext.mounted) {
        Navigator.of(dialogContext).pop();
        ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(content: Text('User created')));
        _loadUsers();
      }
    } catch (e) {
      if (dialogContext.mounted) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst(_exceptionPrefix, ''))),
        );
      }
    } finally {
      setSubmitting(false);
    }
  }

  void _editUser(int index) {
    final user = _users[index];
    final passwordController = TextEditingController();
    String selectedRole = _formatRole(user['role']);

    showDialog(
      context: context,
      builder: (context) {
        bool submitting = false;
        return StatefulBuilder(
          builder: (context, setStateDialog) => AlertDialog(
            title: Text('Edit ${user['username']}'),
            content: _UserFormContent(
              passwordController: passwordController,
              selectedRole: selectedRole,
              onRoleChanged: (v) => setStateDialog(() => selectedRole = v!),
              isEdit: true,
            ),
            actions: _buildFormActions(
              context: context,
              submitting: submitting,
              onCancel: () => Navigator.pop(context),
              onSubmit: () => _submitEditUser(
                dialogContext: context,
                username: user['username'],
                role: selectedRole.toLowerCase(),
                password: passwordController.text.trim().isEmpty ? null : passwordController.text.trim(),
                setSubmitting: (v) => setStateDialog(() => submitting = v),
              ),
              submitLabel: 'Save',
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitEditUser({
    required BuildContext dialogContext,
    required String username,
    String? password,
    required String role,
    required Function(bool) setSubmitting,
  }) async {
    if (username.isEmpty) {
      if (dialogContext.mounted) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(content: Text('Username is required')));
      }
      return;
    }

    setSubmitting(true);
    try {
      await ApiClient.instance.updateUser(username: username, password: password, role: role);
      if (dialogContext.mounted) {
        Navigator.of(dialogContext).pop();
        ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(content: Text('User updated')));
        _loadUsers();
      }
    } catch (e) {
      if (dialogContext.mounted) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst(_exceptionPrefix, ''))),
        );
      }
    } finally {
      setSubmitting(false);
    }
  }

  List<Widget> _buildFormActions({
    required BuildContext context,
    required bool submitting,
    required VoidCallback onCancel,
    required VoidCallback onSubmit,
    required String submitLabel,
  }) {
    return [
      TextButton(
        onPressed: submitting ? null : onCancel,
        child: const Text('Cancel'),
      ),
      TextButton(
        onPressed: submitting ? null : onSubmit,
        child: Text(submitLabel),
      ),
    ];
  }

  void _deleteUser(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: const Text('Are you sure you want to delete this user?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final username = _users[index]['username'];
                await ApiClient.instance.deleteUser(username: username);
                if (context.mounted) {
                  setState(() {
                    _users.removeAt(index);
                  });
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User deleted')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString().replaceFirst(_exceptionPrefix, ''))),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (_formatRole(role)) {
      case 'Superadmin':
        return Colors.purple;
      case 'Admin':
        return Colors.red;
      case 'Teacher':
        return Colors.blue;
      case 'Student':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatRole(String role) {
    final r = role.toLowerCase();
    if (r == 'superadmin') return 'Superadmin';
    if (r == 'admin') return 'Admin';
    if (r == 'teacher' || r == 'staff') return 'Teacher';
    if (r == 'student') return 'Student';
    return role;
  }

  @override
  Widget build(BuildContext context) {
    final searchTerm = _searchController.text.toLowerCase();
    final filteredUsers = _users.where((user) {
      if (searchTerm.isEmpty) return true;
      return (user['username'] as String).toLowerCase().contains(searchTerm) ||
          (user['role'] as String).toLowerCase().contains(searchTerm);
    }).toList();

    return RoleGuard(
      allowed: const {UserRole.admin, UserRole.superadmin},
      webOnly: true,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('User Management'),
          actions: [
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
              ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addUser,
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: DebouncedSearchBar(
                controller: _searchController,
                hintText: 'Search users...',
                onChanged: (value) => setState(() {}),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        return _userCard(filteredUsers[index], _users.indexOf(filteredUsers[index]));
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _userCard(Map<String, dynamic> user, int originalIndex) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['username'],
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getRoleColor(user['role']).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _formatRole(user['role']),
                      style: TextStyle(
                        color: _getRoleColor(user['role']),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editUser(originalIndex),
                  tooltip: 'Edit User',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteUser(originalIndex),
                  tooltip: 'Delete User',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _UserFormContent extends StatelessWidget {
  final TextEditingController? usernameController;
  final TextEditingController passwordController;
  final String selectedRole;
  final ValueChanged<String?> onRoleChanged;
  final bool isEdit;

  const _UserFormContent({
    this.usernameController,
    required this.passwordController,
    required this.selectedRole,
    required this.onRoleChanged,
    required this.isEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isEdit)
          TextField(
            controller: usernameController,
            decoration: const InputDecoration(labelText: 'Username'),
          ),
        TextField(
          controller: passwordController,
          decoration: InputDecoration(
            labelText: isEdit ? 'New Password (optional)' : 'Password',
          ),
          obscureText: true,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: selectedRole,
          decoration: const InputDecoration(labelText: 'Role'),
          items: ['Student', 'Teacher', 'Admin'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
          onChanged: onRoleChanged,
        ),
      ],
    );
  }
}