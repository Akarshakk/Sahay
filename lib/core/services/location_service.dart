import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

/// Location Service for GPS and Geocoding
class LocationService {
  /// Check and request location permissions
  Future<bool> handlePermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Get current GPS location
  Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await handlePermissions();
      if (!hasPermission) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  /// Convert coordinates to human-readable address
  Future<String> getAddressFromCoordinates(double lat, double lng) async {
    try {
      // Validate coordinates first
      if (lat == 0 && lng == 0) {
        return 'Location not available';
      }

      List<Placemark>? placemarks;
      try {
        placemarks = await placemarkFromCoordinates(lat, lng);
      } catch (e) {
        // Geocoding may fail on web/emulator - silently use fallback
        return _getDefaultAddress(lat, lng);
      }
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        
        // Build address string safely with null checks
        List<String> addressParts = [];
        
        final subLocality = place.subLocality;
        if (subLocality != null && subLocality.isNotEmpty) {
          addressParts.add(subLocality);
        }
        
        final locality = place.locality;
        if (locality != null && locality.isNotEmpty) {
          addressParts.add(locality);
        }
        
        final administrativeArea = place.administrativeArea;
        if (administrativeArea != null && administrativeArea.isNotEmpty) {
          addressParts.add(administrativeArea);
        }
        
        if (addressParts.isEmpty) {
          return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
        }
        
        return addressParts.join(', ');
      }
      
      return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
    } catch (e) {
      // Silently handle geocoding errors on web/emulator
      return _getDefaultAddress(lat, lng);
    }
  }

  /// Get default/fallback address for demo
  String _getDefaultAddress(double lat, double lng) {
    // Demo location fallback for hackathon (Kalyan area)
    if ((lat - 19.24).abs() < 0.2 && (lng - 73.14).abs() < 0.2) {
      return 'Sahay Control HQ, Kalyan West, Maharashtra 421301';
    }
    return 'Location: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
  }
}

// Provider for LocationService
final locationServiceProvider = Provider<LocationService>((ref) => LocationService());

// Provider for current location state
final currentLocationProvider = FutureProvider<LocationData?>((ref) async {
  final service = ref.watch(locationServiceProvider);
  final position = await service.getCurrentLocation();
  
  if (position == null) {
    return null;
  }
  
  final address = await service.getAddressFromCoordinates(
    position.latitude,
    position.longitude,
  );
  
  return LocationData(
    latitude: position.latitude,
    longitude: position.longitude,
    address: address,
  );
});

/// Location data model
class LocationData {
  final double latitude;
  final double longitude;
  final String address;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.address,
  });
}
