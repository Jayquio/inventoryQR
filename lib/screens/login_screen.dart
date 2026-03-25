import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'admin/admin_dashboard.dart';
import 'staff/staff_dashboard.dart';
import 'student/student_dashboard.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  void _login(BuildContext context, String user) {
    if (user == 'admin') {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const AdminDashboard()));
    } else if (user == 'staff') {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const StaffDashboard()));
    } else {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const StudentDashboard()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: Center(
          child: Card(
            elevation: 12,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.biotech, size: 64, color: Color(0xFF667EEA)),
                  const SizedBox(height: 16),
                  const Text(
                    "MedLab Inventory",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Medical Laboratory Instruments\nJose Maria College",
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: () => _login(context, 'admin'),
                    child: const Text("Login as Admin"),
                  ),
                  ElevatedButton(
                    onPressed: () => _login(context, 'staff'),
                    child: const Text("Login as Teacher"),
                  ),
                  ElevatedButton(
                    onPressed: () => _login(context, 'student'),
                    child: const Text("Login as Student"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
