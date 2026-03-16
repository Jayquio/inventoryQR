// lib/screens/common/qr_scanner_screen.dart

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_application_inventorymanagement/data/api_client.dart';
import 'package:flutter_application_inventorymanagement/models/instrument.dart';
import '../../data/auth_service.dart';
import '../../data/notification_service.dart';

class QrScannerScreen extends StatefulWidget {
  final String userRole;
  const QrScannerScreen({super.key, required this.userRole});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isScanning = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        actions: [
          IconButton(
            icon: Icon(
              cameraController.torchEnabled ? Icons.flash_on : Icons.flash_off,
            ),
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            icon: Icon(
              cameraController.facing == CameraFacing.front
                  ? Icons.camera_front
                  : Icons.camera_rear,
            ),
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: MobileScanner(
        controller: cameraController,
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty && _isScanning) {
            _isScanning = false;
            final String code = barcodes.first.rawValue ?? '';
            _handleScannedCode(code);
          }
        },
      ),
    );
  }

  Future<void> _handleScannedCode(String code) async {
    String? type;
    String? name;
    if (code.startsWith('USR|')) {
      String? userId;
      String? role;
      final parts = code.substring(4).split(';');
      for (final p in parts) {
        final kv = p.split('=');
        if (kv.length == 2) {
          if (kv[0] == 'id') userId = kv[1];
          if (kv[0] == 'role') role = kv[1];
        }
      }
      final isLoginMode = widget.userRole.toLowerCase() == 'login';
      if (isLoginMode) {
        if (userId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid User QR')),
          );
          setState(() => _isScanning = true);
          return;
        }

        try {
          final users = await ApiClient.instance.fetchUsers();
          final userRec = users.firstWhere(
            (u) => (u['username']?.toString() ?? '') == userId,
            orElse: () => {},
          );

          if (userRec.isEmpty) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('User not found in database')),
            );
            setState(() => _isScanning = true);
            return;
          }

          final dbRoleStr = (userRec['role']?.toString() ?? '').toLowerCase();
          UserRole? parsedRole;
          switch (dbRoleStr) {
            case 'admin':
              parsedRole = UserRole.admin;
              break;
            case 'staff':
            case 'teacher':
              parsedRole = UserRole.staff;
              break;
            case 'student':
              parsedRole = UserRole.student;
              break;
          }

          if (parsedRole == null) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invalid user role')),
            );
            setState(() => _isScanning = true);
            return;
          }

          AuthService.instance.setUsername(userId);
          AuthService.instance.setRole(parsedRole);

          NotificationService.instance.add(
            NotificationItem(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              title: 'User Login',
              message: '$userId logged in',
              type: 'login',
              timestamp: DateTime.now().toIso8601String(),
              recipient: 'Admin',
              priority: 'low',
            ),
          );
          
          final route = parsedRole == UserRole.admin
              ? '/admin_dashboard'
              : (parsedRole == UserRole.staff ? '/staff_dashboard' : '/student_dashboard');
          if (!mounted) return;
          Navigator.of(context).pushNamedAndRemoveUntil(route, (r) => false);
          return;
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login error: ${e.toString().replaceFirst('Exception: ', '')}')),
          );
          setState(() => _isScanning = true);
          return;
        }
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('User QR Detected'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ID: ${userId ?? "unknown"}') ,
                Text('Role: ${role ?? "unknown"}') ,
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() => _isScanning = true);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }
    } else if (code.startsWith('QR|')) {
      final parts = code.substring(3).split(';');
      for (final p in parts) {
        final kv = p.split('=');
        if (kv.length == 2) {
          if (kv[0] == 'type') type = kv[1];
          if (kv[0] == 'name') name = kv[1];
        }
      }
    } else if (code.startsWith('INSTR|')) {
      final parts = code.substring(6).split(';');
      for (final p in parts) {
        final kv = p.split('=');
        if (kv.length == 2) {
          if (kv[0] == 'name') name = kv[1];
        }
      }
    } else {
      name = code;
    }
    List<Instrument> inventory = [];
    try {
      inventory = await ApiClient.instance.fetchInstruments();
    } catch (_) {}
    final instrument = inventory.firstWhere(
      (inst) => inst.name == (name ?? ''),
      orElse: () => Instrument(
        name: '',
        category: '',
        quantity: 0,
        available: 0,
        status: '',
        condition: '',
        location: '',
        lastMaintenance: '',
      ),
    );

    if (instrument.name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Instrument not found!')),
      );
      setState(() => _isScanning = true);
      return;
    }

    final role = AuthService.instance.currentRole;
    if (type == null) {
      if (role == UserRole.student || role == UserRole.staff) {
        if (instrument.available <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Instrument not available')),
          );
          setState(() => _isScanning = true);
          return;
        }
        Navigator.pushNamed(context, '/submit_request', arguments: instrument.name)
            .then((_) => setState(() => _isScanning = true));
        return;
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(instrument.name),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Category: ${instrument.category}"),
                Text("Quantity: ${instrument.quantity}"),
                Text("Available: ${instrument.available}"),
                Text("Borrowed: ${instrument.quantity - instrument.available}"),
                Text("Status: ${instrument.status}"),
                Text("Condition: ${instrument.condition}"),
                Text("Location: ${instrument.location}"),
                Text("Last Maintenance: ${instrument.lastMaintenance}"),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              if (instrument.available > 0)
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final updatedAvail = await ApiClient.instance.processTransaction(
                        type: 'receive',
                        instrumentName: instrument.name,
                        processedBy: AuthService.instance.currentUsername,
                      );
                      if (updatedAvail != null) {
                        instrument.available = updatedAvail;
                      }
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Received (borrow processed) via QR')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                      );
                    }
                    setState(() => _isScanning = true);
                  },
                  child: const Text('Receive (Borrow)'),
                ),
              if (instrument.available < instrument.quantity)
                OutlinedButton(
                  onPressed: () async {
                    try {
                      final updatedAvail = await ApiClient.instance.processTransaction(
                        type: 'return',
                        instrumentName: instrument.name,
                        processedBy: AuthService.instance.currentUsername,
                      );
                      if (updatedAvail != null) {
                        instrument.available = updatedAvail;
                      }
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Returned via QR')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                      );
                    }
                    setState(() => _isScanning = true);
                  },
                  child: const Text('Return'),
                ),
            ],
          ),
        ).then((_) => setState(() => _isScanning = true));
        return;
      }
    }
    if (type == 'borrow' && !(role == UserRole.student || role == UserRole.staff)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unauthorized: Only Students/Teachers can use BORROW QR codes')),
      );
      setState(() => _isScanning = true);
      return;
    }
    if ((type == 'receive' || type == 'return') &&
        role != UserRole.admin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unauthorized: Only Admin can use RECEIVE/RETURN QR codes')),
      );
      setState(() => _isScanning = true);
      return;
    }

    if ((role == UserRole.student || role == UserRole.staff) && type == 'borrow') {
      if (instrument.available <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Instrument not available')),
        );
        setState(() => _isScanning = true);
        return;
      }
      Navigator.pushNamed(context, '/submit_request', arguments: instrument.name)
          .then((_) => setState(() => _isScanning = true));
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(instrument.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Category: ${instrument.category}"),
              Text("Quantity: ${instrument.quantity}"),
              Text("Available: ${instrument.available}"),
              Text("Borrowed: ${instrument.quantity - instrument.available}"),
              Text("Status: ${instrument.status}"),
              Text("Condition: ${instrument.condition}"),
              Text("Location: ${instrument.location}"),
              Text("Last Maintenance: ${instrument.lastMaintenance}"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            if (instrument.available > 0 && type == 'receive')
              ElevatedButton(
                onPressed: () async {
                  try {
                    final updatedAvail = await ApiClient.instance.processTransaction(
                      type: 'receive',
                      instrumentName: instrument.name,
                      processedBy: AuthService.instance.currentUsername,
                    );
                    if (updatedAvail != null) {
                      instrument.available = updatedAvail;
                    }
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Received (borrow processed) via QR')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                    );
                  }
                  setState(() => _isScanning = true);
                },
                child: const Text('Receive (Borrow)'),
              ),
            if (instrument.available < instrument.quantity && type == 'return')
              OutlinedButton(
                onPressed: () async {
                  try {
                    final updatedAvail = await ApiClient.instance.processTransaction(
                      type: 'return',
                      instrumentName: instrument.name,
                      processedBy: AuthService.instance.currentUsername,
                    );
                    if (updatedAvail != null) {
                      instrument.available = updatedAvail;
                    }
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Returned via QR')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                    );
                  }
                  setState(() => _isScanning = true);
                },
                child: const Text('Return'),
              ),
          ],
        ),
      ).then((_) => setState(() => _isScanning = true));
    }
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}
