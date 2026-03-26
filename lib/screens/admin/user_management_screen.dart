// lib/screens/admin/user_management_screen.dart

import 'package:flutter/material.dart';
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
      if (!context.mounted) return;
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
      if (!context.mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      setState(() => _loading = false);
      messenger.showSnackBar(
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
                context: context,
                username: usernameController.text.trim(),
                password: passwordController.text,
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
    required BuildContext context,
    required String username,
    required String password,
    required String role,
    required Function(bool) setSubmitting,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (username.isEmpty || password.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('Enter username and password')));
      return;
    }
    setSubmitting(true);
    try {
      final res = await ApiClient.instance.createUser(username: username, password: password, role: role);
      if (context.mounted) {
        setState(() {
          _users.add({
            'id': res['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
            'username': res['username']?.toString() ?? username,
            'role': (res['role']?.toString() ?? role).toLowerCase(),
          });
        });
        navigator.pop();
        messenger.showSnackBar(
          const SnackBar(content: Text('User added')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        setSubmitting(false);
        messenger.showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst(_exceptionPrefix, ''))),
        );
      }
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
                context: context,
                index: index,
                user: user,
                newRole: selectedRole.toLowerCase(),
                newPassword: passwordController.text.trim(),
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
    required BuildContext context,
    required int index,
    required Map<String, dynamic> user,
    required String newRole,
    required String newPassword,
    required Function(bool) setSubmitting,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setSubmitting(true);
    try {
      await ApiClient.instance.updateUser(
        username: user['username'],
        role: newRole,
        password: newPassword.isEmpty ? null : newPassword,
      );
      if (context.mounted) {
        setState(() {
          _users[index] = {...user, 'role': newRole};
        });
        navigator.pop();
        messenger.showSnackBar(
          const SnackBar(content: Text('User updated')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        setSubmitting(false);
        messenger.showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst(_exceptionPrefix, ''))),
        );
      }
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
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              try {
                final username = _users[index]['username'];
                await ApiClient.instance.deleteUser(username: username);
                if (context.mounted) {
                  setState(() {
                    _users.removeAt(index);
                  });
                  navigator.pop();
                  messenger.showSnackBar(
                    const SnackBar(content: Text('User deleted')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  messenger.showSnackBar(
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

    return Scaffold(
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
            tooltip: 'Add User',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: DebouncedSearchBar(
              controller: _searchController,
              hintText: 'Search users...',
              onChanged: (value) => setState(() {}),
            ),
          ),
          _buildSummaryCards(),
          Expanded(
            child: _buildUserList(filteredUsers),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _summaryCard(_users.length.toString(), 'Total Users'),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _summaryCard(
              _users
                  .where((u) {
                    final r = (u['role'] as String).toLowerCase();
                    return r == 'teacher' || r == 'staff';
                  })
                  .length
                  .toString(),
              'Teacher Users',
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(String value, String label, {Color? color}) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
            Text(label),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList(List<Map<String, dynamic>> filteredUsers) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredUsers.length,
      itemBuilder: (context, index) {
        final user = filteredUsers[index];
        final originalIndex = _users.indexOf(user);
        return _userCard(user, originalIndex);
      },
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
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isEdit && usernameController != null) ...[
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 8),
          ],
          DropdownButtonFormField<String>(
            value: selectedRole,
            decoration: const InputDecoration(labelText: 'Role'),
            items: const [
              DropdownMenuItem(value: 'Admin', child: Text('Admin')),
              DropdownMenuItem(value: 'Teacher', child: Text('Teacher')),
              DropdownMenuItem(value: 'Student', child: Text('Student')),
            ],
            onChanged: onRoleChanged,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: isEdit ? 'New Password (optional)' : 'Password',
            ),
          ),
        ],
      ),
    );
  }
}
