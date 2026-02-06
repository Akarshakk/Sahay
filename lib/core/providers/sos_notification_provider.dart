import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';

/// Model for SOS alert data
class SOSAlert {
  final String id;
  final String userId;
  final String userName;
  final String userPhone;
  final String type;
  final String status;
  final double latitude;
  final double longitude;
  final String? address;
  final String? message;
  final List<VolunteerResponse> respondingVolunteers;
  final List<AuthorityDispatch> authorityDispatches;
  final DateTime createdAt;

  SOSAlert({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.type,
    required this.status,
    required this.latitude,
    required this.longitude,
    this.address,
    this.message,
    this.respondingVolunteers = const [],
    this.authorityDispatches = const [],
    required this.createdAt,
  });

  factory SOSAlert.fromJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>?;
    return SOSAlert(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? 'Unknown',
      userPhone: json['userPhone'] ?? '',
      type: json['type'] ?? 'Custom',
      status: json['status'] ?? 'TRIGGERED',
      latitude: location?['latitude']?.toDouble() ?? 0.0,
      longitude: location?['longitude']?.toDouble() ?? 0.0,
      address: json['address'],
      message: json['message'],
      respondingVolunteers: (json['respondingVolunteers'] as List<dynamic>?)
              ?.map((v) => VolunteerResponse.fromJson(v))
              .toList() ??
          [],
      authorityDispatches: (json['authorityDispatches'] as List<dynamic>?)
              ?.map((d) => AuthorityDispatch.fromJson(d))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
    );
  }
}

/// Model for volunteer response
class VolunteerResponse {
  final String odableId;
  final String odableName;
  final DateTime respondedAt;
  final String status;
  final double? distanceKm;

  VolunteerResponse({
    required this.odableId,
    required this.odableName,
    required this.respondedAt,
    required this.status,
    this.distanceKm,
  });

  factory VolunteerResponse.fromJson(Map<String, dynamic> json) {
    return VolunteerResponse(
      odableId: json['odableId'] ?? '',
      odableName: json['odableName'] ?? 'Volunteer',
      respondedAt: json['respondedAt'] != null
          ? DateTime.parse(json['respondedAt'].toString())
          : DateTime.now(),
      status: json['status'] ?? 'ON_THE_WAY',
      distanceKm: json['distanceKm']?.toDouble(),
    );
  }
}

/// Model for authority dispatch
class AuthorityDispatch {
  final String authorityId;
  final String authorityName;
  final String? department;
  final DateTime dispatchedAt;
  final List<DispatchedResource> resources;
  final String status;

  AuthorityDispatch({
    required this.authorityId,
    required this.authorityName,
    this.department,
    required this.dispatchedAt,
    required this.resources,
    required this.status,
  });

  factory AuthorityDispatch.fromJson(Map<String, dynamic> json) {
    return AuthorityDispatch(
      authorityId: json['authorityId'] ?? '',
      authorityName: json['authorityName'] ?? 'Authority',
      department: json['department'],
      dispatchedAt: json['dispatchedAt'] != null
          ? DateTime.parse(json['dispatchedAt'].toString())
          : DateTime.now(),
      resources: (json['resources'] as List<dynamic>?)
              ?.map((r) => DispatchedResource.fromJson(r))
              .toList() ??
          [],
      status: json['status'] ?? 'DISPATCHED',
    );
  }
}

/// Model for dispatched resource
class DispatchedResource {
  final String resourceId;
  final String resourceName;
  final int quantity;
  final String category;

  DispatchedResource({
    required this.resourceId,
    required this.resourceName,
    required this.quantity,
    required this.category,
  });

  factory DispatchedResource.fromJson(Map<String, dynamic> json) {
    return DispatchedResource(
      resourceId: json['resourceId'] ?? '',
      resourceName: json['resourceName'] ?? '',
      quantity: json['quantity'] ?? 0,
      category: json['category'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'resourceId': resourceId,
        'resourceName': resourceName,
        'quantity': quantity,
        'category': category,
      };
}

/// State class for SOS notifications
class SOSNotificationState {
  final SOSAlert? pendingAlert; // Alert waiting to be shown in popup
  final bool showPopup;
  final bool isLoading;
  final String? error;

  SOSNotificationState({
    this.pendingAlert,
    this.showPopup = false,
    this.isLoading = false,
    this.error,
  });

  SOSNotificationState copyWith({
    SOSAlert? pendingAlert,
    bool? showPopup,
    bool? isLoading,
    String? error,
    bool clearPendingAlert = false,
  }) {
    return SOSNotificationState(
      pendingAlert: clearPendingAlert ? null : (pendingAlert ?? this.pendingAlert),
      showPopup: showPopup ?? this.showPopup,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Provider for SOS notifications
class SOSNotificationNotifier extends StateNotifier<SOSNotificationState> {
  final ApiService _apiService;
  final WebSocketService _webSocketService;

  SOSNotificationNotifier(this._apiService, this._webSocketService)
      : super(SOSNotificationState());

  /// Initialize WebSocket listeners
  void initializeListeners() {
    // Listen for new SOS alerts
    _webSocketService.onNewSOS((data) {
      final sosData = data['data'] as Map<String, dynamic>?;
      if (sosData != null) {
        final alert = SOSAlert.fromJson(sosData);
        state = state.copyWith(pendingAlert: alert, showPopup: true);
      }
    });

    // Listen for volunteer responses (for citizen screen)
    _webSocketService.onVolunteerResponding((data) {
      // This will be handled by the SOS active screen
    });

    // Listen for authority dispatches (for citizen screen)
    _webSocketService.onAuthorityDispatched((data) {
      // This will be handled by the SOS active screen
    });
  }

  /// Subscribe as responder for SOS alerts
  void subscribeAsResponder(String userId, String role, double latitude, double longitude) {
    _webSocketService.subscribeAsResponder(userId, role, latitude, longitude);
  }

  /// Respond to SOS as volunteer
  Future<void> volunteerRespond(String sosId, {double? latitude, double? longitude}) async {
    state = state.copyWith(isLoading: true);
    try {
      await _apiService.volunteerRespondToSOS(sosId, latitude: latitude, longitude: longitude);
      state = state.copyWith(isLoading: false, showPopup: false, clearPendingAlert: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Dispatch resources as authority
  Future<void> authorityDispatch(String sosId, List<DispatchedResource> resources) async {
    state = state.copyWith(isLoading: true);
    try {
      final resourceMaps = resources.map((r) => r.toJson()).toList();
      await _apiService.authorityDispatchToSOS(sosId, resources: resourceMaps);
      state = state.copyWith(isLoading: false, showPopup: false, clearPendingAlert: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Dismiss the popup (ignore)
  void dismissPopup() {
    state = state.copyWith(showPopup: false, clearPendingAlert: true);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider instance
final sosNotificationProvider =
    StateNotifierProvider<SOSNotificationNotifier, SOSNotificationState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final webSocketService = ref.watch(webSocketServiceProvider);
  return SOSNotificationNotifier(apiService, webSocketService);
});
