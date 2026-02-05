/// Helper function to safely parse int from dynamic (handles String and int)
int _parseIntSafe(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  if (value is double) return value.toInt();
  return 0;
}

/// Helper function to parse DateTime from various formats (ISO string, Firestore timestamp object)
DateTime? _parseDateTimeSafe(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) {
    return DateTime.tryParse(value);
  }
  // Handle Firestore timestamp object format: {_seconds: int, _nanoseconds: int}
  if (value is Map) {
    final seconds = _parseIntSafe(value['_seconds'] ?? value['seconds']);
    if (seconds != 0) {
      return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    }
  }
  return null;
}

class Task {
  final String id;
  final String title;
  final String description;
  final String region;
  final String areaId;
  final String createdBy;
  final List<String> assignedTo;
  final String priority;
  final String status;
  final int rewardPoints;
  final String? imageUrl;
  final DateTime? deadline;
  final DateTime createdAt;
  final DateTime updatedAt;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.region,
    required this.areaId,
    required this.createdBy,
    required this.assignedTo,
    required this.priority,
    required this.status,
    required this.rewardPoints,
    this.imageUrl,
    this.deadline,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    try {
      return Task(
        id: json['id']?.toString() ?? '',
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        region: json['region'] ?? '',
        areaId: json['areaId'] ?? '',
        createdBy: json['createdBy'] ?? '',
        assignedTo: List<String>.from(json['assignedTo'] ?? []),
        priority: json['priority'] ?? 'medium',
        status: json['status'] ?? 'open',
        rewardPoints: _parseIntSafe(json['rewardPoints']),
        imageUrl: json['imageUrl'],
        deadline: _parseDateTimeSafe(json['deadline']),
        createdAt: _parseDateTimeSafe(json['createdAt']) ?? DateTime.now(),
        updatedAt: _parseDateTimeSafe(json['updatedAt']) ?? DateTime.now(),
      );
    } catch (e) {
      print('Error parsing Task: $e');
      print('Task JSON: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'region': region,
      'areaId': areaId,
      'createdBy': createdBy,
      'assignedTo': assignedTo,
      'priority': priority,
      'status': status,
      'rewardPoints': rewardPoints,
      'imageUrl': imageUrl,
      'deadline': deadline?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class TaskSubmission {
  final String id;
  final String taskId;
  final String volunteerId;
  final String? volunteerName;
  final String submissionImageUrl;
  final String? submissionNotes;
  final String status;
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  TaskSubmission({
    required this.id,
    required this.taskId,
    required this.volunteerId,
    this.volunteerName,
    required this.submissionImageUrl,
    this.submissionNotes,
    required this.status,
    this.verifiedBy,
    this.verifiedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TaskSubmission.fromJson(Map<String, dynamic> json) {
    try {
      return TaskSubmission(
        id: json['id']?.toString() ?? '',
        taskId: json['taskId']?.toString() ?? '',
        volunteerId: json['volunteerId']?.toString() ?? '',
        volunteerName: json['volunteerName']?.toString(),
        submissionImageUrl: json['submissionImageUrl']?.toString() ?? '',
        submissionNotes: json['submissionNotes']?.toString(),
        status: json['status']?.toString() ?? 'submitted',
        verifiedBy: json['verifiedBy']?.toString(),
        verifiedAt: _parseDateTimeSafe(json['verifiedAt']),
        createdAt: _parseDateTimeSafe(json['createdAt']) ?? DateTime.now(),
        updatedAt: _parseDateTimeSafe(json['updatedAt']) ?? DateTime.now(),
      );
    } catch (e) {
      print('Error parsing TaskSubmission: $e');
      print('Submission JSON: $json');
      // Return a safe fallback rather than crashing
      return TaskSubmission(
         id: 'error-${DateTime.now().millisecondsSinceEpoch}',
         taskId: '', 
         volunteerId: '', 
         submissionImageUrl: '', 
         status: 'error', 
         createdAt: DateTime.now(), 
         updatedAt: DateTime.now()
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskId': taskId,
      'volunteerId': volunteerId,
      'volunteerName': volunteerName,
      'submissionImageUrl': submissionImageUrl,
      'submissionNotes': submissionNotes,
      'status': status,
      'verifiedBy': verifiedBy,
      'verifiedAt': verifiedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
