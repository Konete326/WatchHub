import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../utils/audit_logger.dart';

class SecurityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> updateUserPermissions(
      String userId, List<String> permissions) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final oldData = userDoc.data();

    await _firestore.collection('users').doc(userId).update({
      'permissions': permissions,
    });

    await AuditLogger.logUserRoleChanged(
      userId,
      oldData?['email'] ?? 'Unknown',
      'Permissions Update',
      permissions.join(', '),
    );
  }

  Future<void> toggle2FA(String userId, bool enabled) async {
    await _firestore.collection('users').doc(userId).update({
      'twoFactorEnabled': enabled,
    });

    await AuditLogger.logCustomAction(
      'Toggled 2FA for user: $userId to $enabled',
      targetId: userId,
      targetType: 'user',
      metadata: {'enabled': enabled},
    );
  }

  Future<void> updateIpAllowlist(String userId, List<String> ips) async {
    await _firestore.collection('users').doc(userId).update({
      'ipAllowlist': ips,
    });

    await AuditLogger.logCustomAction(
      'Updated IP allowlist for user: $userId',
      targetId: userId,
      targetType: 'user',
      metadata: {'ips': ips},
    );
  }

  Future<bool> checkIpAccess(User user, String currentIp) async {
    if (user.ipAllowlist.isEmpty) return true;
    return user.ipAllowlist.contains(currentIp);
  }

  // Helper to record login IP
  Future<void> recordLogin(String userId, String ip) async {
    await _firestore.collection('users').doc(userId).update({
      'lastLoginIp': ip,
    });
  }
}
