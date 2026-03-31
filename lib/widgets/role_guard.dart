import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../data/auth_service.dart';

class RoleGuard extends StatelessWidget {
  const RoleGuard({
    super.key,
    required this.allowed,
    required this.child,
    this.unauthorizedMessage,
    this.webOnly = false,
  });

  final Set<UserRole> allowed;
  final Widget child;
  final String? unauthorizedMessage;
  final bool webOnly;

  @override
  Widget build(BuildContext context) {
    final role = AuthService.instance.currentRole;
    final isAllowed = allowed.contains(role);

    if (isAllowed) {
      if (webOnly && !kIsWeb) {
        return _buildUnauthorized(
          context,
          'This section is restricted to Web access only.',
        );
      }
      return child;
    }

    return _buildUnauthorized(context, unauthorizedMessage ?? 'Unauthorized for your role');
  }

  Widget _buildUnauthorized(BuildContext context, String message) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.red.withValues(alpha: 0.08),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Icon(Icons.lock, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
