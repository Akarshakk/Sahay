import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WebSocketService {
  IO.Socket? _socket;
  final String baseUrl = 'http://localhost:3000';
  
  bool get isConnected => _socket?.connected ?? false;

  void connect(String authToken) {
    _socket = IO.io(baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'auth': {'token': authToken},
    });

    _socket?.on('connect', (_) {
      print('🔌 WebSocket connected');
    });

    _socket?.on('disconnect', (_) {
      print('❌ WebSocket disconnected');
    });

    _socket?.on('error', (error) {
      print('⚠️ WebSocket error: $error');
    });
  }

  void joinLocation(double latitude, double longitude) {
    _socket?.emit('joinLocation', {
      'latitude': latitude,
      'longitude': longitude,
    });
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

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }
}

final webSocketServiceProvider = Provider<WebSocketService>((ref) => WebSocketService());
