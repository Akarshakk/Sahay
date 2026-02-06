import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WebSocketService {
  IO.Socket? _socket;
  final String baseUrl = 'https://sahay-backend-production.up.railway.app';
  
  bool get isConnected => _socket?.connected ?? false;

  void connect(String authToken) {
    // Connect to /events namespace
    _socket = IO.io('$baseUrl/events', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'auth': {'token': authToken},
    });

    _socket?.on('connect', (_) {
      print('🔌 WebSocket connected to /events');
    });

    _socket?.on('disconnect', (_) {
      print('❌ WebSocket disconnected. Attempting to reconnect...');
    });

    _socket?.on('error', (error) {
      print('⚠️ WebSocket error: $error');
    });
    
    _socket?.on('reconnect', (_) {
      print('🔄 WebSocket reconnected');
    });
  }

  void joinLocation(double latitude, double longitude) {
    _socket?.emit('subscribeToLocation', {
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  void joinRegion(String region) {
    _socket?.emit('subscribeToRegion', region);
  }

  void onNewPost(Function(dynamic) callback) {
    _socket?.on('newPost', callback);
  }

  void onNewChatMessage(Function(dynamic) callback) {
    _socket?.on('newChatMessage', callback);
  }

  void onMessageReaction(Function(dynamic) callback) {
    _socket?.on('messageReaction', callback);
  }

  void onPostVerified(Function(dynamic) callback) {
    _socket?.on('postVerified', callback);
  }

  void onEmergencyBroadcast(Function(dynamic) callback) {
    _socket?.on('emergencyBroadcast', callback);
  }

  // SOS Events
  void onNewSOS(Function(dynamic) callback) {
    _socket?.on('newSOS', callback);
  }

  void onSOSUpdated(Function(dynamic) callback) {
    _socket?.on('sosUpdated', callback);
  }

  void onSOSResolved(Function(dynamic) callback) {
    _socket?.on('sosResolved', callback);
  }

  void subscribeToSOSAlerts(double latitude, double longitude, {double radiusKm = 5.0}) {
    _socket?.emit('subscribeToSOS', {
      'latitude': latitude,
      'longitude': longitude,
      'radiusKm': radiusKm,
    });
  }

  // Subscribe as responder (volunteer/authority) for SOS alerts
  void subscribeAsResponder(String userId, String role, double latitude, double longitude) {
    _socket?.emit('subscribeAsResponder', {
      'userId': userId,
      'role': role,
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  // Listen for volunteer responding to SOS
  void onVolunteerResponding(Function(dynamic) callback) {
    _socket?.on('volunteerResponding', callback);
  }

  // Listen for authority dispatching resources
  void onAuthorityDispatched(Function(dynamic) callback) {
    _socket?.on('authorityDispatched', callback);
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }
}

final webSocketServiceProvider = Provider<WebSocketService>((ref) => WebSocketService());

