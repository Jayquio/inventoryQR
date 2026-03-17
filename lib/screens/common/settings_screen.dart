// lib/screens/common/settings_screen.dart

import 'package:flutter/material.dart';
import '../../data/app_config_service.dart';
import '../../data/api_client.dart';
import '../../data/theme_service.dart';
import '../../data/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/notification_service.dart';
import '../../core/constants.dart';

class SettingsScreen extends StatefulWidget {
  final String userRole;
  const SettingsScreen({super.key, required this.userRole});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _showAdvanced = false;
  void _unlockAdvanced() {
    if (widget.userRole != 'Admin') return;
    if (_showAdvanced) return;
    setState(() => _showAdvanced = true);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Advanced settings unlocked')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onLongPress: _unlockAdvanced,
          child: const Text('Settings'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.userRole == 'Admin' && _showAdvanced) ...[
            Card(
              elevation: 4,
              child: ListTile(
                leading: const Icon(Icons.cloud, color: Colors.blueGrey),
                title: const Text('API Server'),
                subtitle: Text(AppConfigService.instance.baseUrl.isEmpty
                    ? 'Default URL'
                    : AppConfigService.instance.baseUrl),
                trailing: const Icon(Icons.edit),
                onTap: () async {
                  final controller = TextEditingController(
                    text: AppConfigService.instance.baseUrl.isEmpty
                        ? 'http://192.168.1.88/inventory_api'
                        : AppConfigService.instance.baseUrl,
                  );
                  final newUrl = await showDialog<String>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Set API Base URL'),
                      content: TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          hintText: 'http://192.168.1.88/inventory_api',
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, controller.text),
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  );
                  if (newUrl != null && newUrl.trim().isNotEmpty) {
                    await AppConfigService.instance.setBaseUrl(newUrl);
                    ApiClient.setBaseUrl(AppConfigService.instance.baseUrl);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('API set to ${AppConfigService.instance.baseUrl}')),
                      );
                    }
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 4,
              child: ListTile(
                leading: const Icon(Icons.search, color: Colors.green),
                title: const Text('Detect API Server'),
                subtitle: const Text('Auto-detect and prefill LAN URL'),
                onTap: () async {
                  final ok = await AppConfigService.instance.detectAndApply();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(ok
                            ? 'Detected: ${AppConfigService.instance.baseUrl}'
                            : 'No server detected; set URL manually'),
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 4,
              child: ListTile(
                leading: const Icon(Icons.wifi_tethering, color: Colors.teal),
                title: const Text('Test API Connection'),
                subtitle: const Text('Call ping.php and show status'),
                onTap: () async {
                  final ok = await ApiClient.instance.ping();
                  final msg = ok ? 'API reachable' : 'API not reachable';
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(msg)),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Profile Settings
          Card(
            elevation: 4,
            child: ListTile(
              leading: const Icon(Icons.person, color: Colors.blue),
              title: const Text('Profile Settings'),
              subtitle: const Text('Your account information'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () async {
                final uname = AuthService.instance.currentUsername;
                final role = AuthService.instance.currentRole.name;
                await showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Account'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Username: $uname'),
                        Text('Role: ${role[0].toUpperCase()}${role.substring(1)}'),
                      ],
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Notification Settings
          Card(
            elevation: 4,
            child: ListTile(
              leading: const Icon(Icons.notifications, color: Colors.orange),
              title: const Text('Notifications'),
              subtitle: const Text('Configure notification preferences'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                bool enabled = prefs.getBool('notifications_enabled') ?? true;
                bool autoRefresh = prefs.getBool('notifications_auto_refresh') ?? true;
                await showDialog(
                  context: context,
                  builder: (ctx) {
                    return StatefulBuilder(
                      builder: (ctx, setStateDialog) => AlertDialog(
                        title: const Text('Notification Settings'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SwitchListTile(
                              value: enabled,
                              title: const Text('Enable notifications'),
                              onChanged: (v) => setStateDialog(() => enabled = v),
                            ),
                            SwitchListTile(
                              value: autoRefresh,
                              title: const Text('Auto-refresh every 30s'),
                              onChanged: (v) => setStateDialog(() => autoRefresh = v),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                          TextButton(
                            onPressed: () async {
                              await prefs.setBool('notifications_enabled', enabled);
                              await prefs.setBool('notifications_auto_refresh', autoRefresh);
                              if (autoRefresh) {
                                NotificationService.instance.startAutoRefresh();
                              } else {
                                NotificationService.instance.stopAutoRefresh();
                              }
                              if (context.mounted) Navigator.pop(ctx);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notification settings saved')));
                              }
                            },
                            child: const Text('Save'),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Security Settings
          Card(
            elevation: 4,
            child: ListTile(
              leading: const Icon(Icons.security, color: Colors.green),
              title: const Text('Security'),
              subtitle: const Text('Change password and security settings'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () async {
                final newPwController = TextEditingController();
                final confirmPwController = TextEditingController();
                bool submitting = false;
                await showDialog(
                  context: context,
                  builder: (ctx) {
                    return StatefulBuilder(builder: (ctx, setStateDialog) {
                      return AlertDialog(
                        title: const Text('Change Password'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: newPwController,
                              obscureText: true,
                              decoration: const InputDecoration(labelText: 'New Password'),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: confirmPwController,
                              obscureText: true,
                              decoration: const InputDecoration(labelText: 'Confirm Password'),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(onPressed: submitting ? null : () => Navigator.pop(ctx), child: const Text('Cancel')),
                          TextButton(
                            onPressed: submitting
                                ? null
                                : () async {
                                    final p1 = newPwController.text.trim();
                                    final p2 = confirmPwController.text.trim();
                                    if (p1.isEmpty || p2.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter both fields')));
                                      return;
                                    }
                                    if (p1 != p2) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
                                      return;
                                    }
                                    setStateDialog(() => submitting = true);
                                    try {
                                      await ApiClient.instance.updateUser(username: AuthService.instance.currentUsername, password: p1);
                                      if (context.mounted) Navigator.pop(ctx);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated')));
                                      }
                                    } catch (e) {
                                      setStateDialog(() => submitting = false);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
                                      }
                                    }
                                  },
                            child: const Text('Save'),
                          ),
                        ],
                      );
                    });
                  },
                );
              }
            ),
          ),

          const SizedBox(height: 16),

          // Admin-only settings
          if (widget.userRole == 'Admin') ...[
            Card(
              elevation: 4,
              child: ListTile(
                leading: const Icon(Icons.admin_panel_settings, color: Colors.purple),
                title: const Text('System Administration'),
                subtitle: const Text('Advanced system configuration'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    showDragHandle: true,
                    builder: (ctx) => ListView(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.people),
                          title: const Text('User Management'),
                          onTap: () {
                            Navigator.pop(ctx);
                            Navigator.pushNamed(context, '/user_management');
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.inventory),
                          title: const Text('Manage Instruments'),
                          onTap: () {
                            Navigator.pop(ctx);
                            Navigator.pushNamed(context, '/manage_instruments');
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.receipt_long),
                          title: const Text('Transaction Logs'),
                          onTap: () {
                            Navigator.pop(ctx);
                            Navigator.pushNamed(context, '/transaction_logs');
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.notifications_active),
                          title: const Text('Notification Center'),
                          onTap: () {
                            Navigator.pop(ctx);
                            Navigator.pushNamed(context, '/notification_center');
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.bar_chart),
                          title: const Text('Generate Reports'),
                          onTap: () {
                            Navigator.pop(ctx);
                            Navigator.pushNamed(context, '/generate_reports');
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Teacher/Staff-only settings
          if (widget.userRole == 'Teacher' || widget.userRole == 'Staff') ...[
            Card(
              elevation: 4,
              child: ListTile(
                leading: const Icon(Icons.work, color: Colors.teal),
                title: const Text('Work Preferences'),
                subtitle: const Text('Configure work options'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  bool onlyPending = prefs.getBool('staff_show_pending_only') ?? true;
                  await showDialog(
                    context: context,
                    builder: (ctx) => StatefulBuilder(
                      builder: (ctx, setStateDialog) => AlertDialog(
                        title: const Text('Work Preferences'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SwitchListTile(
                              value: onlyPending,
                              title: const Text('Show only pending requests'),
                              onChanged: (v) => setStateDialog(() => onlyPending = v),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                          TextButton(
                            onPressed: () async {
                              await prefs.setBool('staff_show_pending_only', onlyPending);
                              if (context.mounted) Navigator.pop(ctx);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Work preferences saved')));
                              }
                            },
                            child: const Text('Save'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Student-only settings
          if (widget.userRole == 'Student') ...[
            Card(
              elevation: 4,
              child: ListTile(
                leading: const Icon(Icons.school, color: Colors.indigo),
                title: const Text('Student Tools'),
                subtitle: const Text('Shortcuts to student features'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    showDragHandle: true,
                    builder: (ctx) => ListView(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.inventory),
                          title: const Text('View Instruments'),
                          onTap: () {
                            Navigator.pop(ctx);
                            Navigator.pushNamed(context, AppRoutes.viewInstruments, arguments: 'Student');
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.add),
                          title: const Text('Submit Request'),
                          onTap: () {
                            Navigator.pop(ctx);
                            Navigator.pushNamed(context, '/submit_request');
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.track_changes),
                          title: const Text('Track Status'),
                          onTap: () {
                            Navigator.pop(ctx);
                            Navigator.pushNamed(context, '/track_status');
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],

          // General Settings
          Card(
            elevation: 4,
            child: ListTile(
              leading: const Icon(Icons.palette, color: Colors.pink),
              title: const Text('Appearance'),
              subtitle: const Text('Theme and display preferences'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () async {
                ThemeMode picked = ThemeService.instance.mode;
                await showDialog(
                  context: context,
                  builder: (ctx) => StatefulBuilder(
                    builder: (ctx, setStateDialog) => AlertDialog(
                      title: const Text('Theme'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.light_mode),
                            title: const Text('Light'),
                            trailing: picked == ThemeMode.light ? const Icon(Icons.check, color: Colors.green) : null,
                            onTap: () => setStateDialog(() => picked = ThemeMode.light),
                          ),
                          ListTile(
                            leading: const Icon(Icons.dark_mode),
                            title: const Text('Dark'),
                            trailing: picked == ThemeMode.dark ? const Icon(Icons.check, color: Colors.green) : null,
                            onTap: () => setStateDialog(() => picked = ThemeMode.dark),
                          ),
                          ListTile(
                            leading: const Icon(Icons.phone_android),
                            title: const Text('System'),
                            trailing: picked == ThemeMode.system ? const Icon(Icons.check, color: Colors.green) : null,
                            onTap: () => setStateDialog(() => picked = ThemeMode.system),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                        TextButton(
                          onPressed: () async {
                            await ThemeService.instance.setMode(picked);
                            if (context.mounted) Navigator.pop(ctx);
                          },
                          child: const Text('Apply'),
                        ),
                      ],
                    ),
                  ),
                );
              }
            ),
          ),

          const SizedBox(height: 16),

          Card(
            elevation: 4,
            child: ListTile(
              leading: const Icon(Icons.help, color: Colors.blue),
              title: const Text('Help & Support'),
              subtitle: const Text('Get help and contact support'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () async {
                final api = AppConfigService.instance.baseUrl.isEmpty ? 'Default URL' : AppConfigService.instance.baseUrl;
                await showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Help & Support'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('For assistance, contact your system administrator.'),
                        const SizedBox(height: 8),
                        Text('API: $api'),
                      ],
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          Card(
            elevation: 4,
            child: ListTile(
              leading: const Icon(Icons.info, color: Colors.grey),
              title: const Text('About'),
              subtitle: const Text('App version and information'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'MedLab Inventory System',
                  applicationVersion: '1.0.0',
                  applicationLegalese: '© 2024 JMCFI MedLab',
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
