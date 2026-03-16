import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'auth_service.dart';
import 'audit_log_service.dart';

enum QrType { borrow, receive, returnItem }

class QrPermissionException implements Exception {
  QrPermissionException(this.message);
  final String message;
  @override
  String toString() => message;
}

class QrCodeService {
  QrCodeService._();
  static final QrCodeService instance = QrCodeService._();

  String buildPayload({required QrType type, required String instrumentName}) {
    final role = AuthService.instance.currentRole;
    switch (type) {
      case QrType.borrow:
        if (!AuthService.instance.isAllowedBorrow()) {
          throw QrPermissionException('Only Students/Teachers can generate BORROW QR codes');
        }
        break;
      case QrType.receive:
      case QrType.returnItem:
        if (AuthService.instance.currentRole != UserRole.admin) {
          throw QrPermissionException('Only Admin can generate RECEIVE/RETURN QR codes');
        }
        break;
    }
    final typeStr = switch (type) {
      QrType.borrow => 'borrow',
      QrType.receive => 'receive',
      QrType.returnItem => 'return',
    };
    final payload = 'QR|type=$typeStr;name=$instrumentName';
    AuditLogService.instance.addEntry(
      AuditLogEntry(
        timestamp: DateTime.now(),
        userRole: role.name,
        action: 'GENERATE_QR',
        type: typeStr,
        details: 'Instrument="$instrumentName"',
      ),
    );
    return payload;
  }

  String buildPayloadForPrint({required QrType type, required String instrumentName}) {
    final typeStr = switch (type) {
      QrType.borrow => 'borrow',
      QrType.receive => 'receive',
      QrType.returnItem => 'return',
    };
    final payload = 'QR|type=$typeStr;name=$instrumentName';
    final role = AuthService.instance.currentRole;
    AuditLogService.instance.addEntry(
      AuditLogEntry(
        timestamp: DateTime.now(),
        userRole: role.name,
        action: 'GENERATE_QR_PRINT',
        type: typeStr,
        details: 'Instrument="$instrumentName"',
      ),
    );
    return payload;
  }

  String buildInstrumentLabelPayload({required String instrumentName}) {
    final payload = 'INSTR|name=$instrumentName';
    final role = AuthService.instance.currentRole;
    AuditLogService.instance.addEntry(
      AuditLogEntry(
        timestamp: DateTime.now(),
        userRole: role.name,
        action: 'GENERATE_INSTR_LABEL',
        type: 'label',
        details: 'Instrument="$instrumentName"',
      ),
    );
    return payload;
  }

  String buildUserPayload() {
    final role = AuthService.instance.currentRole;
    final username = AuthService.instance.currentUsername;
    final roleStr = role == UserRole.staff ? 'teacher' : role.name;
    final payload = 'USR|id=$username;role=$roleStr';
    AuditLogService.instance.addEntry(
      AuditLogEntry(
        timestamp: DateTime.now(),
        userRole: role.name,
        action: 'GENERATE_USER_QR',
        type: 'user',
        details: 'User="$username"',
      ),
    );
    return payload;
  }

  String buildUserPayloadFor({required String id, required UserRole role}) {
    final roleStr = role == UserRole.staff ? 'teacher' : role.name;
    final payload = 'USR|id=$id;role=$roleStr';
    final currentRole = AuthService.instance.currentRole;
    AuditLogService.instance.addEntry(
      AuditLogEntry(
        timestamp: DateTime.now(),
        userRole: currentRole.name,
        action: 'GENERATE_USER_QR_FOR',
        type: 'user',
        details: 'Target="$id" as $roleStr',
      ),
    );
    return payload;
  }

  Widget buildQrWidget(String payload, {double size = 180}) {
    return QrImageView(
      data: payload,
      version: QrVersions.auto,
      size: size,
      backgroundColor: Colors.white,
    );
  }
}
