import 'package:flutter/foundation.dart';

enum UserRole { admin, staff, student, superadmin }

class AuthService extends ChangeNotifier {
  AuthService._();
  static final AuthService instance = AuthService._();

  UserRole _currentRole = UserRole.student;
  String _currentUsername = 'guest';

  UserRole get currentRole => _currentRole;
  String get currentUsername => _currentUsername;

  void setRole(UserRole role) {
    _currentRole = role;
    notifyListeners();
  }

  void setUsername(String username) {
    _currentUsername = username;
    notifyListeners();
  }

  bool isAllowedBorrow() => _currentRole == UserRole.student || _currentRole == UserRole.staff || _currentRole == UserRole.superadmin;
  bool isAllowedReceiveReturn() => _currentRole == UserRole.admin || _currentRole == UserRole.staff || _currentRole == UserRole.superadmin;
}
