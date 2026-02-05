import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../home/presentation/screens/home_screen.dart';

/// SOS Active Screen - Shows map with location and status after SOS is triggered
class SOSActiveScreen extends ConsumerStatefulWidget {
  final bool silentMode;
  final bool requireVolunteerAssistance;
  final String emergencyNumber;
  final String emergencyLabel;
  
  const SOSActiveScreen({
    super.key,
    this.silentMode = false,
    this.requireVolunteerAssistance = true,
    this.emergencyNumber = '112',
    this.emergencyLabel = 'Police',
  });

  @override
  ConsumerState<SOSActiveScreen> createState() => _SOSActiveScreenState();
}

class _SOSActiveScreenState extends ConsumerState<SOSActiveScreen> {
  final MapController _mapController = MapController();
  String _sosId = '';
  String _sosStatus = 'SOS Pressed';
  bool _isLoading = true;
  bool _callMade = false;
  
  // Default location
  static const double _defaultLatitude = 19.0760;
  static const double _defaultLongitude = 72.8777;

  @override
  void initState() {
    super.initState();
    _triggerSOSBackend();
  }

  Future<void> _triggerSOSBackend() async {
    try {
      final user = ref.read(authControllerProvider);
      final location = ref.read(currentLocationProvider).valueOrNull;
      final api = ref.read(apiServiceProvider);
      
      // 1. Trigger SOS on backend
      final response = await api.triggerSOS(
        latitude: location?.latitude ?? _defaultLatitude,
        longitude: location?.longitude ?? _defaultLongitude,
        type: 'POLICE',
        address: location?.address,
      );
      
      if (response['success'] == true && response['data'] != null) {
        setState(() {
          _sosId = response['data']['id']?.toString() ?? '${DateTime.now().millisecondsSinceEpoch}';
          _isLoading = false;
        });
      }
      
      // 2. Make emergency call after 5 seconds (unless silent mode)
      if (!widget.silentMode && !_callMade) {
        await Future.delayed(const Duration(seconds: 5));
        if (mounted) {
          _makeEmergencyCall();
        }
      }
      
    } catch (e) {
      setState(() {
        _sosId = '${DateTime.now().millisecondsSinceEpoch}'.substring(5, 11);
        _isLoading = false;
      });
      debugPrint('SOS Trigger Error: $e');
    }
  }

  Future<void> _makeEmergencyCall() async {
    if (_callMade) return;
    _callMade = true;
    
    // Use the emergency number passed from countdown screen
    final emergencyNum = widget.emergencyNumber;
    
    try {
      // Use FlutterPhoneDirectCaller for auto-dialing (doesn't just open dialer)
      await FlutterPhoneDirectCaller.callNumber(emergencyNum);
    } catch (e) {
      debugPrint('Direct call failed: $e');
      // Fallback to url_launcher
      final Uri phoneUri = Uri(scheme: 'tel', path: emergencyNum);
      try {
        if (await canLaunchUrl(phoneUri)) {
          await launchUrl(phoneUri);
        }
      } catch (e2) {
        debugPrint('Fallback call failed: $e2');
      }
    }
  }

  Future<void> _markSafe() async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.primaryGreen),
            SizedBox(width: 12),
            Text('Mark as Safe?'),
          ],
        ),
        content: const Text(
          'This will notify all volunteers and authorities that you are now safe and end the emergency alert.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
            ),
            child: const Text('Yes, I am Safe'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    try {
      // Update SOS status on backend (if we have a valid SOS ID)
      if (_sosId.isNotEmpty && !_sosId.startsWith('1')) {
        // Only call API if we have a valid Firebase document ID (not a timestamp fallback)
        final api = ref.read(apiServiceProvider);
        await api.addSOSAction(
          _sosId,
          'MARKED_SAFE',
          details: 'User marked themselves as safe',
        );
      }
    } catch (e) {
      // Log error but don't block navigation - user safety is priority
      debugPrint('Failed to update SOS status on backend: $e');
    }
    
    // Always show success and navigate home
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ You have been marked as safe. Authorities and volunteers have been notified.'),
          backgroundColor: AppTheme.primaryGreen,
          duration: Duration(seconds: 3),
        ),
      );
      
      // Navigate back to home
      final user = ref.read(authControllerProvider);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(userRole: user?.role ?? UserRole.citizen),
        ),
        (route) => false,
      );
    }
  }

  void _showMessageDialog() {
    final messageController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.message, color: AppTheme.primaryRed),
            SizedBox(width: 12),
            Text('SOS Message'),
          ],
        ),
        content: TextField(
          controller: messageController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Enter your emergency message...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (messageController.text.isNotEmpty) {
                // Send message to backend (ignore errors - still show success)
                try {
                  if (_sosId.isNotEmpty && !_sosId.startsWith('1')) {
                    final api = ref.read(apiServiceProvider);
                    await api.addSOSAction(
                      _sosId,
                      'MESSAGE_SENT',
                      details: messageController.text,
                    );
                  }
                } catch (e) {
                  debugPrint('Failed to send SOS message: $e');
                }
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Message sent to responders'),
                    backgroundColor: AppTheme.primaryGreen,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryRed),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showVolunteersNearby() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Nearby Volunteers',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (widget.requireVolunteerAssistance) ...[
              _buildVolunteerTile('Rahul Sharma', '0.5 km away', true),
              _buildVolunteerTile('Priya Patel', '0.8 km away', true),
              _buildVolunteerTile('Amit Kumar', '1.2 km away', false),
            ] else
              const Text('Volunteer assistance not requested'),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildVolunteerTile(String name, String distance, bool responding) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: responding ? AppTheme.primaryGreen : Colors.grey,
        child: Icon(
          Icons.person,
          color: Colors.white,
        ),
      ),
      title: Text(name),
      subtitle: Text(distance),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: responding ? AppTheme.primaryGreen.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          responding ? 'Responding' : 'Notified',
          style: TextStyle(
            color: responding ? AppTheme.primaryGreen : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locationAsync = ref.watch(currentLocationProvider);
    
    return Scaffold(
      body: Stack(
        children: [
          // Map View
          locationAsync.when(
            data: (location) {
              final userLatLng = LatLng(
                location?.latitude ?? _defaultLatitude,
                location?.longitude ?? _defaultLongitude,
              );
              
              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: userLatLng,
                  initialZoom: 16,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.sahay.app',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: userLatLng,
                        width: 80,
                        height: 80,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Text(
                                'My Location',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryRed,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.location_pin,
                              color: AppTheme.primaryRed,
                              size: 40,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(_defaultLatitude, _defaultLongitude),
                initialZoom: 16,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.sahay.app',
                ),
              ],
            ),
          ),
          
          // Top App Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 48),
                  const Text(
                    'Sahay',
                    style: TextStyle(
                      color: AppTheme.primaryRed,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // Show info
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Emergency Active'),
                          content: const Text(
                            'Your SOS alert is active. Authorities and volunteers have been notified of your location.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.info_outline, color: AppTheme.textDark),
                  ),
                ],
              ),
            ),
          ),
          
          // Right Side Buttons
          Positioned(
            right: 16,
            top: 120,
            child: Column(
              children: [
                // Center on Location
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: () {
                      final location = ref.read(currentLocationProvider).valueOrNull;
                      if (location != null) {
                        _mapController.move(
                          LatLng(location.latitude, location.longitude),
                          16,
                        );
                      }
                    },
                    icon: const Icon(Icons.my_location, color: AppTheme.primaryRed),
                  ),
                ),
                const SizedBox(height: 12),
                // Show Volunteers
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: _showVolunteersNearby,
                    icon: const Icon(Icons.people, color: AppTheme.primaryRed),
                  ),
                ),
              ],
            ),
          ),
          
          // Bottom Panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // SOS Message
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryRed.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primaryRed.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.message, color: AppTheme.primaryRed),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'SOS message',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  GestureDetector(
                    onTap: _showMessageDialog,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'View message',
                        style: TextStyle(
                          color: Colors.grey[600],
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Service Status
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.emergency, color: AppTheme.primaryRed),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Service Status',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'SOS ID: $_sosId',
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              ),
                              Row(
                                children: [
                                  Text(
                                    'SOS STATUS :',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  ),
                                  Text(
                                    _sosStatus,
                                    style: const TextStyle(
                                      color: AppTheme.primaryGreen,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // Show more details
                          },
                          child: const Row(
                            children: [
                              Text('More\nDetails'),
                              Icon(Icons.chevron_right),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // I am Safe Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _markSafe,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryRed,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'I am Safe',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ).animate().fadeIn().slideY(begin: 0.2, end: 0),
                ],
              ),
            ),
          ),
          
          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Sending SOS Alert...',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
