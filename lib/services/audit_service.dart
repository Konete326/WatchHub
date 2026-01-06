import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/audit_log.dart';

class AuditService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Log an audit event
  Future<void> logAction({
    required AuditAction action,
    required String actionDescription,
    String? targetId,
    String? targetType,
    Map<String, dynamic>? oldValues,
    Map<String, dynamic>? newValues,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Get admin details
      final adminDoc = await _firestore.collection('users').doc(user.uid).get();
      final adminData = adminDoc.data();

      final auditLog = AuditLog(
        id: '', // Will be set by Firestore
        adminId: user.uid,
        adminEmail: user.email ?? 'Unknown',
        adminName: adminData?['name'] ?? 'Unknown Admin',
        action: action,
        actionDescription: actionDescription,
        targetId: targetId,
        targetType: targetType,
        oldValues: oldValues,
        newValues: newValues,
        timestamp: DateTime.now(),
        ipAddress: null, // Can be implemented if needed
        metadata: metadata,
      );

      await _firestore.collection('audit_logs').add(auditLog.toMap());
    } catch (e) {
      // Silent fail - don't break the app if audit logging fails
      print('Error logging audit action: $e');
    }
  }

  // Get all audit logs with pagination
  Future<List<AuditLog>> getAuditLogs({
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore
          .collection('audit_logs')
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => AuditLog.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error fetching audit logs: $e');
      return [];
    }
  }

  // Get audit logs for a specific admin
  Future<List<AuditLog>> getAuditLogsByAdmin(String adminId,
      {int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection('audit_logs')
          .where('adminId', isEqualTo: adminId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => AuditLog.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error fetching audit logs by admin: $e');
      return [];
    }
  }

  // Get audit logs for a specific target (e.g., a product or order)
  Future<List<AuditLog>> getAuditLogsByTarget(
    String targetId, {
    String? targetType,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore
          .collection('audit_logs')
          .where('targetId', isEqualTo: targetId);

      if (targetType != null) {
        query = query.where('targetType', isEqualTo: targetType);
      }

      final snapshot =
          await query.orderBy('timestamp', descending: true).limit(limit).get();

      return snapshot.docs.map((doc) => AuditLog.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error fetching audit logs by target: $e');
      return [];
    }
  }

  // Get audit logs by action type
  Future<List<AuditLog>> getAuditLogsByAction(
    AuditAction action, {
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('audit_logs')
          .where('action', isEqualTo: action.toString().split('.').last)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => AuditLog.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error fetching audit logs by action: $e');
      return [];
    }
  }

  // Get audit logs within a date range
  Future<List<AuditLog>> getAuditLogsByDateRange(
    DateTime startDate,
    DateTime endDate, {
    int limit = 100,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('audit_logs')
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => AuditLog.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error fetching audit logs by date range: $e');
      return [];
    }
  }

  // Stream audit logs in real-time
  Stream<List<AuditLog>> streamAuditLogs({int limit = 50}) {
    return _firestore
        .collection('audit_logs')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => AuditLog.fromFirestore(doc)).toList());
  }

  // Delete old audit logs (for cleanup)
  Future<void> deleteOldLogs(DateTime beforeDate) async {
    try {
      final snapshot = await _firestore
          .collection('audit_logs')
          .where('timestamp', isLessThan: Timestamp.fromDate(beforeDate))
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print('Error deleting old audit logs: $e');
    }
  }

  // Get audit statistics
  Future<Map<String, dynamic>> getAuditStatistics() async {
    try {
      final logs = await getAuditLogs(limit: 1000);

      final Map<String, int> actionCounts = {};
      final Map<String, int> adminCounts = {};

      for (var log in logs) {
        // Count by action
        final actionKey = log.action.toString().split('.').last;
        actionCounts[actionKey] = (actionCounts[actionKey] ?? 0) + 1;

        // Count by admin
        adminCounts[log.adminEmail] = (adminCounts[log.adminEmail] ?? 0) + 1;
      }

      return {
        'totalLogs': logs.length,
        'actionCounts': actionCounts,
        'adminCounts': adminCounts,
        'mostActiveAdmin':
            adminCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key,
        'mostCommonAction': actionCounts.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key,
      };
    } catch (e) {
      print('Error getting audit statistics: $e');
      return {};
    }
  }
}
