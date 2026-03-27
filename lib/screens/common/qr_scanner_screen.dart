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
  static const String _exceptionPrefix = 'Exception: ';
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
    if (code.startsWith('USR|')) {
      await _handleUserCode(code);
    } else {
      await _handleInventoryCode(code);
    }
  }

  Future<void> _handleUserCode(String code) async {
    String? userId;
    String? role;
    final parts = code.substring(4).split(';');
    for (final p in parts) {
      final kv = p.split('=');
      if (kv.length == 2) {
        if (kv[0] == 'id') {
          userId = kv[1];
        }
        if (kv[0] == 'role') {
          role = kv[1];
        }
      }
    }

    final isLoginMode = widget.userRole.toLowerCase() == 'login';
    if (isLoginMode) {
      await _handleUserLogin(userId);
    } else {
      _showUserDetectedDialog(userId, role);
    }
  }

  Future<void> _handleUserLogin(String? userId) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (userId == null) {
      if (context.mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Invalid User QR')),
        );
        setState(() => _isScanning = true);
      }
      return;
    }

    try {
      final users = await ApiClient.instance.fetchUsers();
      final userRec = users.firstWhere(
        (u) => (u['username']?.toString() ?? '') == userId,
        orElse: () => {},
      );

      if (userRec.isEmpty) {
        if (context.mounted) {
          messenger.showSnackBar(
            const SnackBar(content: Text('User not found in database')),
          );
          setState(() => _isScanning = true);
        }
        return;
      }

      final dbRoleStr = (userRec['role']?.toString() ?? '').toLowerCase();
      UserRole? parsedRole = _parseUserRole(dbRoleStr);

      if (parsedRole == null) {
        if (context.mounted) {
          messenger.showSnackBar(
            const SnackBar(content: Text('Invalid user role')),
          );
          setState(() => _isScanning = true);
        }
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

      final route = _getDashboardRoute(parsedRole);
      if (context.mounted) {
        navigator.pushNamedAndRemoveUntil(route, (r) => false);
      }
    } catch (e) {
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Login error: ${e.toString().replaceFirst(_exceptionPrefix, '')}')),
        );
        setState(() => _isScanning = true);
      }
    }
  }

  void _showUserDetectedDialog(String? userId, String? role) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('User QR Detected'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${userId ?? "unknown"}'),
            Text('Role: ${role ?? "unknown"}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (context.mounted) Navigator.pop(context);
              if (mounted) setState(() => _isScanning = true);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleInventoryCode(String code) async {
    final parsed = _parseInventoryCode(code);

    List<Instrument> inventory = [];
    try {
      inventory = await ApiClient.instance.fetchInstruments();
    } catch (_) {}

    final instrument = inventory.firstWhere(
      (inst) => inst.name == (parsed['name'] ?? ''),
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

    if (!context.mounted) return;
    _processInventoryScan(instrument, parsed['type'], parsed['course'], parsed['date']);
  }

  Map<String, dynamic> _parseInventoryCode(String code) {
    if (code.startsWith('QR|')) {
      return _parseQrProtocol(code.substring(3));
    } else if (code.startsWith('INSTR|')) {
      return _parseInstrProtocol(code.substring(6));
    }
    return {'name': code};
  }

  Map<String, dynamic> _parseQrProtocol(String content) {
    final result = <String, dynamic>{};
    final parts = content.split(';');
    for (final p in parts) {
      final kv = p.split('=');
      if (kv.length == 2) {
        final key = kv[0];
        final val = kv[1];
        if (key == 'type') {
          result['type'] = val;
        } else if (key == 'name') {
          result['name'] = val;
        } else if (key == 'course') {
          result['course'] = val;
        } else if (key == 'date') {
          result['date'] = DateTime.tryParse(val);
        }
      }
    }
    return result;
  }

  Map<String, dynamic> _parseInstrProtocol(String content) {
    final result = <String, dynamic>{};
    final parts = content.split(';');
    for (final p in parts) {
      final kv = p.split('=');
      if (kv.length == 2 && kv[0] == 'name') {
        result['name'] = kv[1];
      }
    }
    return result;
  }

  void _processInventoryScan(Instrument instrument, String? type, String? course, DateTime? date) {
    if (instrument.name.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Instrument not found!')),
        );
        setState(() => _isScanning = true);
      }
      return;
    }

    final role = AuthService.instance.currentRole;
    
    // Authorization checks
    if (!_isAuthorized(role, type)) {
      if (context.mounted) {
        String msg = type == 'borrow' 
            ? 'Unauthorized: Only Students/Teachers can use BORROW QR codes'
            : 'Unauthorized: Only Admin can use RECEIVE/RETURN QR codes';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        setState(() => _isScanning = true);
      }
      return;
    }

    // Process logic
    if ((role == UserRole.student || role == UserRole.staff) && (type == null || type == 'borrow')) {
      _handleStudentBorrow(instrument, course, date);
    } else {
      _showInstrumentDetailsDialog(context, instrument, type);
    }
  }

  bool _isAuthorized(UserRole role, String? type) {
    if (type == 'borrow' && !(role == UserRole.student || role == UserRole.staff)) {
      return false;
    }
    if ((type == 'receive' || type == 'return') && role != UserRole.admin) {
      return false;
    }
    return true;
  }

  void _handleStudentBorrow(Instrument instrument, String? course, DateTime? date) {
    if (instrument.available <= 0) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Instrument not available')),
        );
        setState(() => _isScanning = true);
      }
      return;
    }
    if (context.mounted) {
      Navigator.pushNamed(context, '/submit_request', arguments: {
        'instrumentName': instrument.name,
        'course': course,
        'date': date,
      }).then((_) {
        if (context.mounted) setState(() => _isScanning = true);
      });
    }
  }

  void _showInstrumentDetailsDialog(BuildContext context, Instrument instrument, String? type) {
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
            onPressed: () {
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Close'),
          ),
          if (instrument.available > 0 && (type == null || type == 'receive'))
            ElevatedButton(
              onPressed: () => _processTransaction(context, instrument, 'receive'),
              child: const Text('Receive (Borrow)'),
            ),
          if (instrument.available < instrument.quantity && (type == null || type == 'return'))
            OutlinedButton(
              onPressed: () => _processTransaction(context, instrument, 'return'),
              child: const Text('Return'),
            ),
        ],
      ),
    ).then((_) {
      if (mounted) setState(() => _isScanning = true);
    });
  }

  Future<void> _processTransaction(BuildContext context, Instrument instrument, String txType) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final updatedAvail = await ApiClient.instance.processTransaction(
        type: txType,
        instrumentName: instrument.name,
        processedBy: AuthService.instance.currentUsername,
      );
      if (updatedAvail != null) {
        instrument.available = updatedAvail;
      }
      if (context.mounted) {
        navigator.pop();
        messenger.showSnackBar(
          SnackBar(content: Text(txType == 'receive' ? 'Received (borrow processed) via QR' : 'Returned via QR')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst(_exceptionPrefix, ''))),
        );
      }
    }
  }

  UserRole? _parseUserRole(String roleStr) {
    switch (roleStr) {
      case 'admin':
        return UserRole.admin;
      case 'superadmin':
        return UserRole.superadmin;
      case 'staff':
      case 'teacher':
        return UserRole.staff;
      case 'student':
        return UserRole.student;
      default:
        return null;
    }
  }

  String _getDashboardRoute(UserRole role) {
    switch (role) {
      case UserRole.admin:
      case UserRole.superadmin:
        return '/admin_dashboard';
      case UserRole.staff:
        return '/staff_dashboard';
      case UserRole.student:
        return '/student_dashboard';
    }
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}
