// lib/widgets/app_drawer.dart

import 'package:flutter/material.dart';
import '../core/constants.dart';

class AppDrawer extends StatelessWidget {
  final String userRole;

  const AppDrawer({super.key, required this.userRole});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF4B0082)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MedLab Inventory',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  userRole,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          if (userRole == 'Admin') ...[
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text("Dashboard"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/admin_dashboard');
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text("Manage Instruments"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/manage_instruments');
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text("User Management"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/user_management');
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment),
              title: const Text("Manage Requests"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.manageRequests);
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment_return),
              title: const Text("Confirm returns"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.manageRequests, arguments: 'Return Queue');
              },
            ),
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text("Generate Reports"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/generate_reports');
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text("Transaction Logs"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/transaction_logs');
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text("Notification Center"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/notification_center');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Settings"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.settings, arguments: userRole);
              },
            ),
          ],
          if (userRole == 'Teacher') ...[
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text("Monitor Inventory"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.viewInstruments, arguments: 'Teacher');
              },
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text("Submit Request"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/submit_request');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Settings"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.settings, arguments: userRole);
              },
            ),
          ],
          if (userRole == 'Student') ...[
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text("View Instruments"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.viewInstruments, arguments: 'Student');
              },
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text("Submit Request"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/submit_request');
              },
            ),
            ListTile(
              leading: const Icon(Icons.track_changes),
              title: const Text("Track Status"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.trackStatus);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Settings"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.settings, arguments: userRole);
              },
            ),
          ],
        ],
      ),
    );
  }
}
