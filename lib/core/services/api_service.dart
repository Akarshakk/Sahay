import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_model.dart';

class ApiService {
  // Use localhost for web, PC's IP for mobile
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api/v1';
    } else {
      // Your PC's IP address - change this if your network changes
      return 'http://10.1.19.96:3000/api/v1';
    }
  }

  final Dio _dio;
  String? _authToken;

  ApiService()
      : _dio = Dio(BaseOptions(
          baseUrl: kIsWeb ? 'http://localhost:3000/api/v1' : 'http://10.1.19.96:3000/api/v1',
          connectTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        )) {
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }

  String? get authToken => _authToken;

  void setAuthToken(String token) {
    _authToken = token;
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearAuthToken() {
    _authToken = null;
    _dio.options.headers.remove('Authorization');
  }

  // Auth endpoints
  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    final response = await _dio.post('/auth/register', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> login(Map<String, dynamic> data) async {
    final response = await _dio.post('/auth/login', data: data);
    if (response.data['success'] == true &&
        response.data['data']?['token'] != null) {
      setAuthToken(response.data['data']['token']);
    }
    return response.data;
  }

  Future<void> sendEmailOtp(String email) async {
    await _dio.post('/auth/send-otp', data: {'email': email});
  }

  Future<void> verifyEmailOtp(String email, String otp) async {
    await _dio.post('/auth/verify-otp', data: {'email': email, 'otp': otp});
  }

  // Feed endpoints
  Future<Map<String, dynamic>> createPost(Map<String, dynamic> data) async {
    final response = await _dio.post('/feed/create', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> getNearbyFeed({
    required double latitude,
    required double longitude,
    int? radius,
    int? page,
    int? limit,
    String? category,
  }) async {
    final response = await _dio.get('/feed', queryParameters: {
      'latitude': latitude,
      'longitude': longitude,
      if (radius != null) 'radius': radius,
      if (page != null) 'page': page,
      if (limit != null) 'limit': limit,
      if (category != null) 'category': category,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> verifyPost(String postId) async {
    final response = await _dio.post('/feed/$postId/verify');
    return response.data;
  }

  Future<Map<String, dynamic>> getTrendingPosts({
    required double latitude,
    required double longitude,
    int? limit,
  }) async {
    final response = await _dio.get('/feed/trending', queryParameters: {
      'latitude': latitude,
      'longitude': longitude,
      if (limit != null) 'limit': limit,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> addComment(String postId, String content) async {
    final response = await _dio.post('/feed/$postId/comment', data: {
      'content': content,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getComments(String postId) async {
    final response = await _dio.get('/feed/$postId/comments');
    return response.data;
  }

  Future<Map<String, dynamic>> toggleLike(String postId) async {
    final response = await _dio.post('/feed/$postId/like');
    return response.data;
  }

  // Chat endpoints
  Future<Map<String, dynamic>> sendChatMessage({
    required String postId,
    required String message,
    String? replyToMessageId,
  }) async {
    final response = await _dio.post('/chat/$postId/messages', data: {
      'message': message,
      if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getChatMessages(String postId,
      {int? limit}) async {
    final response = await _dio.get('/chat/$postId/messages', queryParameters: {
      if (limit != null) 'limit': limit,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> reactToMessage(String messageId) async {
    final response = await _dio.post('/chat/messages/$messageId/react');
    return response.data;
  }

  Future<Map<String, dynamic>> getNearbyIncidents({
    required double latitude,
    required double longitude,
    int? radius,
  }) async {
    final response = await _dio.get('/incidents/nearby', queryParameters: {
      'latitude': latitude,
      'longitude': longitude,
      if (radius != null) 'radius': radius,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> createIncident(Map<String, dynamic> data) async {
    final response = await _dio.post('/incidents', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> getIncidents({int? page, int? limit, String? status}) async {
    final response = await _dio.get('/incidents', queryParameters: {
      if (page != null) 'page': page,
      if (limit != null) 'limit': limit,
      if (status != null) 'status': status,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> verifyIncident(String incidentId) async {
    final response = await _dio.patch('/incidents/$incidentId', data: {
      'incrementVerification': true,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> updateIncidentStatus(String incidentId, String status) async {
    final response = await _dio.put('/incidents/$incidentId', data: {
      'status': status,
    });
    return response.data;
  }

  // Broadcast endpoints
  Future<Map<String, dynamic>> sendBroadcast(Map<String, dynamic> data) async {
    final response = await _dio.post('/broadcasts', data: data);
    return response.data;
  }

  Future<List<dynamic>> getBroadcasts(String region) async {
    final response = await _dio.get('/broadcasts', queryParameters: {'region': region});
    // Backend returns generic array or object depending on implementation. 
    // BroadcastsController.findAll returns `this.broadcastsService.findAll(region)`.
    // Assuming it returns a list of broadcasts.
    if (response.data is List) {
      return response.data;
    } else if (response.data is Map && response.data['data'] is List) {
        return response.data['data'];
    }
    return [];
  }

  // SOS endpoints
  Future<Map<String, dynamic>> triggerSOS({
    required double latitude,
    required double longitude,
    required String type,
    String? address,
    String? message,
    int? batteryLevel,
  }) async {
    final response = await _dio.post('/sos/trigger', data: {
      'latitude': latitude,
      'longitude': longitude,
      'type': type,
      if (address != null) 'address': address,
      if (message != null) 'message': message,
      if (batteryLevel != null) 'batteryLevel': batteryLevel,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> updateSOSMessage(
    String sosId,
    String message,
  ) async {
    final response = await _dio.patch('/sos/$sosId', data: {
      'message': message,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> addSOSAction(
    String sosId,
    String action, {
    String? details,
  }) async {
    final response = await _dio.post('/sos/$sosId/action', data: {
      'action': action,
      if (details != null) 'details': details,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getSOSHistory() async {
    final response = await _dio.get('/sos/history');
    return response.data;
  }

  Future<Map<String, dynamic>> getActiveSOSAlerts() async {
    final response = await _dio.get('/sos/active');
    return response.data;
  }

  Future<Map<String, dynamic>> getNearbySOSAlerts({
    required double latitude,
    required double longitude,
    double radius = 5.0,
  }) async {
    final response = await _dio.get('/sos/nearby', queryParameters: {
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
    });
    return response.data;
  }

  // Get SOS by ID
  Future<Map<String, dynamic>> getSOSById(String sosId) async {
    final response = await _dio.get('/sos/$sosId');
    return response.data;
  }

  // Get all responders for an SOS
  Future<Map<String, dynamic>> getSOSResponders(String sosId) async {
    final response = await _dio.get('/sos/$sosId/responders');
    return response.data;
  }

  // Get nearby volunteers and authorities
  Future<Map<String, dynamic>> getNearbyResponders({
    required double latitude,
    required double longitude,
    double radius = 10.0,
  }) async {
    final response = await _dio.get('/sos/responders/nearby', queryParameters: {
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
    });
    return response.data;
  }

  // Volunteer responds to SOS (clicks Help)
  Future<Map<String, dynamic>> volunteerRespondToSOS(
    String sosId, {
    double? latitude,
    double? longitude,
  }) async {
    final response = await _dio.post('/sos/$sosId/volunteer-respond', data: {
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    });
    return response.data;
  }

  // Authority dispatches resources to SOS
  Future<Map<String, dynamic>> authorityDispatchToSOS(
    String sosId, {
    required List<Map<String, dynamic>> resources,
  }) async {
    final response = await _dio.post('/sos/$sosId/authority-dispatch', data: {
      'resources': resources,
    });
    return response.data;
  }

  // User endpoints
  Future<Map<String, dynamic>> getMyProfile() async {
    final response = await _dio.get('/users/me');
    return response.data;
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final response = await _dio.put('/users/me', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> updateLocation({
    required double latitude,
    required double longitude,
  }) async {
    final response = await _dio.put('/users/me/location', data: {
      'latitude': latitude,
      'longitude': longitude,
    });
    return response.data;
  }

  // Upload endpoints
  Future<String> uploadFile(String filePath, {String folder = 'documents', List<int>? fileBytes, String? fileName}) async {
    final String name = fileName ?? filePath.split('/').last;
    
    MultipartFile file;
    if (fileBytes != null) {
      file = MultipartFile.fromBytes(fileBytes, filename: name);
    } else {
      file = await MultipartFile.fromFile(filePath, filename: name);
    }

    final formData = FormData.fromMap({
      "file": file,
    });

    final response = await _dio.post(
      '/upload',
      data: formData,
      queryParameters: {'folder': folder},
    );
    // Returns { url: "...", filename: "...", ... }
    return response.data['url'] as String;
  }

  // Task endpoints
  Future<Task> createTask({
    required String title,
    required String description,
    required String region,
    required String areaId,
    required int rewardPoints,
    String priority = 'medium',
    String? imageUrl,
    List<String>? assignedTo,
    DateTime? deadline,
  }) async {
    final response = await _dio.post('/tasks', data: {
      'title': title,
      'description': description,
      'region': region,
      'areaId': areaId,
      'rewardPoints': rewardPoints,
      'priority': priority,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (assignedTo != null && assignedTo.isNotEmpty) 'assignedTo': assignedTo,
      if (deadline != null) 'deadline': deadline.toIso8601String(),
    });
    return Task.fromJson(response.data['data'] ?? response.data);
  }

  Future<List<Task>> getMyTasks() async {
    final response = await _dio.get('/tasks/my');
    // Handle both formats: direct array [] or wrapped {data: []}
    final rawData = response.data;
    final List<dynamic> data = rawData is List 
        ? rawData 
        : (rawData['data'] ?? []);
    return data.map((item) => Task.fromJson(item)).toList();
  }

  Future<List<Task>> getTasksByRegion(String region) async {
    try {
      final response = await _dio.get('/tasks/region/$region');
      final rawData = response.data;
      List<dynamic> data = [];
      
      if (rawData is List) {
        data = rawData;
      } else if (rawData is Map && rawData.containsKey('data')) {
        data = rawData['data'] is List ? rawData['data'] : [];
      }
      
      return data.map((item) => Task.fromJson(item)).toList();
    } catch (e) {
      print('ERROR in getTasksByRegion: $e');
      return [];
    }
  }

  Future<List<Task>> getAssignedTasks() async {
    try {
      final response = await _dio.get('/tasks/assigned');
      final rawData = response.data;
      List<dynamic> data = [];
      
      if (rawData is List) {
        data = rawData;
      } else if (rawData is Map && rawData.containsKey('data')) {
        data = rawData['data'] is List ? rawData['data'] : [];
      }
      
      return data.map((item) => Task.fromJson(item)).toList();
    } catch (e) {
      print('ERROR in getAssignedTasks: $e');
      return [];
    }
  }

  Future<Task> getTask(String taskId) async {
    final response = await _dio.get('/tasks/$taskId');
    return Task.fromJson(response.data['data'] ?? response.data);
  }

  Future<Task> updateTask(
    String taskId, {
    String? title,
    String? description,
    String? priority,
    int? rewardPoints,
    List<String>? assignedTo,
    String? status,
  }) async {
    final Map<String, dynamic> body = {};
    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    if (priority != null) body['priority'] = priority;
    if (rewardPoints != null) body['rewardPoints'] = rewardPoints;
    if (assignedTo != null) body['assignedTo'] = assignedTo;
    if (status != null) body['status'] = status;

    final response = await _dio.put('/tasks/$taskId', data: body);
    return Task.fromJson(response.data['data'] ?? response.data);
  }

  Future<void> deleteTask(String taskId) async {
    await _dio.delete('/tasks/$taskId');
  }

  Future<TaskSubmission> submitTask({
    required String taskId,
    required String submissionImageUrl,
    String? submissionNotes,
  }) async {
    print('DEBUG submitTask Headers: ${_dio.options.headers}');
    print('DEBUG submitTask Auth Token: $_authToken');
    
    final response = await _dio.post('/tasks/$taskId/submit', data: {
      'taskId': taskId,
      'submissionImageUrl': submissionImageUrl,
      if (submissionNotes != null) 'submissionNotes': submissionNotes,
    });
    return TaskSubmission.fromJson(response.data['data'] ?? response.data);
  }

  Future<List<TaskSubmission>> getTaskSubmissions(String taskId) async {
    try {
      final response = await _dio.get('/tasks/$taskId/submissions');
      final rawData = response.data;
      List<dynamic> data = [];
      
      if (rawData is List) {
        data = rawData;
      } else if (rawData is Map && rawData.containsKey('data')) {
        data = rawData['data'] is List ? rawData['data'] : [];
      }
      
      return data.map((item) => TaskSubmission.fromJson(item)).toList();
    } catch (e) {
      print('ERROR in getTaskSubmissions: $e');
      return [];
    }
  }

  Future<List<TaskSubmission>> getMySubmissions() async {
    try {
      final response = await _dio.get('/tasks/my/submissions');
      print('DEBUG getMySubmissions RESPONSE: ${response.data}'); // LOG COMPLETE JSON
      
      final rawData = response.data;
      List<dynamic> data = [];
      
      if (rawData is List) {
        data = rawData;
      } else if (rawData is Map && rawData.containsKey('data')) {
        // Only access ['data'] if it is a Map
        data = rawData['data'] is List ? rawData['data'] : [];
      } else {
        print('WARN getMySubmissions: Unexpected response format: $rawData');
        return [];
      }
      
      return data.map((item) {
        // print('DEBUG processing submission item: $item');
        return TaskSubmission.fromJson(item);
      }).toList();
    } catch (e) {
      print('ERROR in getMySubmissions: $e');
      // Return empty list on error to prevent UI crash
      return [];
    }
  }

  Future<TaskSubmission> verifySubmission({
    required String submissionId,
    required String status,
    String? notes,
  }) async {
    final response = await _dio.post('/tasks/submissions/$submissionId/verify', data: {
      'submissionId': submissionId,
      'status': status,
      if (notes != null) 'notes': notes,
    });
    return TaskSubmission.fromJson(response.data['data'] ?? response.data);
  }
}

// Provider
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
