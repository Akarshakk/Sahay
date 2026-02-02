import 'package:cloud_firestore/cloud_firestore.dart';

/// Audit action types for logging
enum AuditActionType {
  dispatch,         // Authority dispatching to incident
  resourceAdd,      // Adding resources to area
  resourceRemove,   // Removing resources from area
  verify,           // Verifying an incident
  broadcast,        // Broadcasting alert
  login,            // User login
  registration,     // User registration
  sosTriggered,     // SOS button triggered
  incidentCreated,  // New incident reported
}

/// Audit log entry model
class AuditLogEntry {
  final String userId;
  final String userName;
  final String userRole;
  final AuditActionType actionType;
  final String actionDescription;
  final String? areaId;
  final String? areaName;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;

  AuditLogEntry({
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.actionType,
    required this.actionDescription,
    this.areaId,
    this.areaName,
    this.metadata,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'userRole': userRole,
      'actionType': actionType.name,
      'actionDescription': actionDescription,
      'areaId': areaId,
      'areaName': areaName,
      'metadata': metadata,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}

/// Audit Service for logging authority and volunteer actions
class AuditService {
  final FirebaseFirestore _firestore;
  
  AuditService({FirebaseFirestore? firestore}) 
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _auditLogs => _firestore.collection('audit_logs');

  /// Log an action to the audit trail
  Future<void> logAction({
    required String userId,
    required String userName,
    required String userRole,
    required AuditActionType actionType,
    required String actionDescription,
    String? areaId,
    String? areaName,
    Map<String, dynamic>? metadata,
  }) async {
    final entry = AuditLogEntry(
      userId: userId,
      userName: userName,
      userRole: userRole,
      actionType: actionType,
      actionDescription: actionDescription,
      areaId: areaId,
      areaName: areaName,
      metadata: metadata,
    );

    await _auditLogs.add(entry.toFirestore());
  }

  /// Log a dispatch action
  Future<void> logDispatch({
    required String userId,
    required String userName,
    required String incidentId,
    required String incidentTitle,
    String? areaId,
    String? areaName,
  }) async {
    await logAction(
      userId: userId,
      userName: userName,
      userRole: 'authority',
      actionType: AuditActionType.dispatch,
      actionDescription: 'Dispatched to incident: $incidentTitle',
      areaId: areaId,
      areaName: areaName,
      metadata: {'incidentId': incidentId},
    );
  }

  /// Log a resource change
  Future<void> logResourceChange({
    required String userId,
    required String userName,
    required String resourceType,
    required int change,
    required int newCount,
    String? areaId,
    String? areaName,
  }) async {
    final isAdd = change > 0;
    await logAction(
      userId: userId,
      userName: userName,
      userRole: 'authority',
      actionType: isAdd ? AuditActionType.resourceAdd : AuditActionType.resourceRemove,
      actionDescription: '${isAdd ? "Added" : "Removed"} ${change.abs()} $resourceType (now: $newCount)',
      areaId: areaId,
      areaName: areaName,
      metadata: {
        'resourceType': resourceType,
        'change': change,
        'newCount': newCount,
      },
    );
  }

  /// Log an incident verification
  Future<void> logVerification({
    required String userId,
    required String userName,
    required String incidentId,
    required String incidentTitle,
    required bool verified,
    String? areaId,
    String? areaName,
  }) async {
    await logAction(
      userId: userId,
      userName: userName,
      userRole: 'authority',
      actionType: AuditActionType.verify,
      actionDescription: '${verified ? "Verified" : "Rejected"} incident: $incidentTitle',
      areaId: areaId,
      areaName: areaName,
      metadata: {
        'incidentId': incidentId,
        'verified': verified,
      },
    );
  }

  /// Log a broadcast action
  Future<void> logBroadcast({
    required String userId,
    required String userName,
    required String message,
    String? areaId,
    String? areaName,
  }) async {
    await logAction(
      userId: userId,
      userName: userName,
      userRole: 'authority',
      actionType: AuditActionType.broadcast,
      actionDescription: 'Broadcast alert: $message',
      areaId: areaId,
      areaName: areaName,
    );
  }

  /// Log SOS trigger
  Future<void> logSOS({
    required String userId,
    required String userName,
    required double latitude,
    required double longitude,
    String? areaId,
    String? areaName,
  }) async {
    await logAction(
      userId: userId,
      userName: userName,
      userRole: 'citizen',
      actionType: AuditActionType.sosTriggered,
      actionDescription: 'SOS triggered at location ($latitude, $longitude)',
      areaId: areaId,
      areaName: areaName,
      metadata: {
        'latitude': latitude,
        'longitude': longitude,
      },
    );
  }

  /// Get audit logs for a specific area
  Stream<QuerySnapshot> getAuditLogsForArea(String areaId, {int limit = 50}) {
    return _auditLogs
        .where('areaId', isEqualTo: areaId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots();
  }

  /// Get audit logs for a specific user
  Stream<QuerySnapshot> getAuditLogsForUser(String userId, {int limit = 50}) {
    return _auditLogs
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots();
  }

  /// Get all audit logs (admin view)
  Stream<QuerySnapshot> getAllAuditLogs({int limit = 100}) {
    return _auditLogs
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots();
  }
}
