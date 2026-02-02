import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api/v1';

  final Dio _dio;
  String? _authToken;

  ApiService()
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
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

  void setAuthToken(String token) {
    _authToken = token;
    _dio.options.headers['Authorization'] = 'Bearer $token';
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
    final response = await _dio.patch('/incidents/$incidentId', data: {
      'status': status,
    });
    return response.data;
  }

  // SOS endpoints
  Future<Map<String, dynamic>> triggerSOS({
    required double latitude,
    required double longitude,
    required String type,
    String? address,
    int? batteryLevel,
  }) async {
    final response = await _dio.post('/sos/trigger', data: {
      'latitude': latitude,
      'longitude': longitude,
      'type': type,
      if (address != null) 'address': address,
      if (batteryLevel != null) 'batteryLevel': batteryLevel,
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
}

// Provider
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
