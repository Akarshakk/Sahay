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

  // Incidents endpoints
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

  // User endpoints
  Future<Map<String, dynamic>> getMyProfile() async {
    final response = await _dio.get('/users/me');
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
