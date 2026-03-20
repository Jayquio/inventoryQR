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
    showDialog(
      context: context,
      builder: (context) {
        final usernameController = TextEditingController();
        final passwordController = TextEditingController();
        String selectedRole = 'Student';
        bool submitting = false;

        return StatefulBuilder(
          builder: (context, setStateDialog) => AlertDialog(
            title: const Text('Create New User'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: usernameController,
                    decoration: const InputDecoration(labelText: 'Username'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(labelText: 'Role'),
                    items: const [
                      DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                      DropdownMenuItem(value: 'Teacher', child: Text('Teacher')),
                      DropdownMenuItem(value: 'Student', child: Text('Student')),
                    ],
                    onChanged: (v) => setStateDialog(() => selectedRole = v ?? 'Student'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: submitting ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: submitting
                    ? null
                    : () async {
                        final u = usernameController.text.trim();
                        final p = passwordController.text;
                        if (u.isEmpty || p.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Enter username and password')),
                          );
                          return;
                        }
                        setStateDialog(() => submitting = true);
                        try {
                          final role = selectedRole.toLowerCase();
                          final res = await ApiClient.instance.createUser(username: u, password: p, role: role);
                          setState(() {
                            _users.add({
                              'id': res['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
                              'username': res['username']?.toString() ?? u,
                              'role': (res['role']?.toString() ?? role).toLowerCase(),
                            });
                          });
                          if (context.mounted) Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('User created in database')),
                          );
                        } catch (e) {
                          setStateDialog(() => submitting = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString().replaceFirst(_exceptionPrefix, ''))),
                          );
                        }
                      },
                child: const Text('Create'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _editUser(int index) {
    final user = _users[index];
    showDialog(
      context: context,
      builder: (context) {
        String selectedRole = _formatRole(user['role']);
        final passwordController = TextEditingController();
        bool submitting = false;

        return StatefulBuilder(
          builder: (context, setStateDialog) => AlertDialog(
            title: Text('Edit ${user['username']}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(labelText: 'Role'),
                    items: const [
                      DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                      DropdownMenuItem(value: 'Teacher', child: Text('Teacher')),
                      DropdownMenuItem(value: 'Student', child: Text('Student')),
                    ],
                    onChanged: (v) => setStateDialog(() => selectedRole = v ?? selectedRole),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'New Password (optional)'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: submitting ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: submitting
                    ? null
                    : () async {
                        setStateDialog(() => submitting = true);
                        try {
                          final username = user['username'];
                          final pw = passwordController.text.trim();
                          await ApiClient.instance.updateUser(
                            username: username,
                            role: selectedRole.toLowerCase(),
                            password: pw.isEmpty ? null : pw,
                          );
                          setState(() {
                            _users[index] = {
                              ...user,
                              'role': selectedRole.toLowerCase(),
                            };
                          });
                          if (context.mounted) Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('User updated in database')),
                          );
                        } catch (e) {
                          setStateDialog(() => submitting = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString().replaceFirst(_exceptionPrefix, ''))),
                          );
                        }
                      },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
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
                setState(() {
                  _users.removeAt(index);
                });
                if (context.mounted) Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User deleted from database')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString().replaceFirst(_exceptionPrefix, ''))),
                );
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
