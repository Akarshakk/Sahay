import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WebSocketService {
  IO.Socket? _socket;
  final String baseUrl = 'http://localhost:3000';
  
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

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }
}

final webSocketServiceProvider = Provider<WebSocketService>((ref) => WebSocketService());
