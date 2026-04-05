import 'package:flutter/foundation.dart';

enum UserRole { admin, teacher, student, superadmin }

class AuthService extends ChangeNotifier {
  AuthService._();
  static final AuthService instance = AuthService._();

  UserRole _currentRole = UserRole.student;
  String _currentUsername = 'guest';
  String _currentUserEmail = '';

  UserRole get currentRole => _currentRole;
  String get currentUsername => _currentUsername;
  String get currentUserEmail => _currentUserEmail;

  void setRole(UserRole role) {
    _currentRole = role;
    notifyListeners();
  }

  void setUsername(String username) {
    _currentUsername = username;
    notifyListeners();
  }

  void setEmail(String email) {
    _currentUserEmail = email;
    notifyListeners();
  }

  bool isAllowedBorrow() => _currentRole == UserRole.student || _currentRole == UserRole.teacher || _currentRole == UserRole.superadmin;
  bool isAllowedReceiveReturn() => _currentRole == UserRole.admin || _currentRole == UserRole.superadmin;
}
