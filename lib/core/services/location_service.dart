import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:http/http.dart' as http;
import 'dart:convert';

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

      // Handle Web Platform specifically using OpenStreetMap
      if (kIsWeb) {
        try {
          return await _getAddressFromOSM(lat, lng);
        } catch (e) {
          print('Web Geocoding failed: $e');
          return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
        }
      }

      List<Placemark>? placemarks;
      try {
        placemarks = await placemarkFromCoordinates(lat, lng);
      } catch (e) {
        // Geocoding may fail on web/emulator - silently use fallback
        return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
      }

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;

        // Build address string safely with null checks
        List<String> addressParts = [];

        // Add specific details for "Exact Location"
        if (place.name != null &&
            place.name!.isNotEmpty &&
            place.name != place.street) {
          addressParts.add(place.name!);
        }

        if (place.street != null && place.street!.isNotEmpty) {
          addressParts.add(place.street!);
        }

        final subLocality = place.subLocality;
        if (subLocality != null && subLocality.isNotEmpty) {
          addressParts.add(subLocality);
        }

        final locality = place.locality;
        if (locality != null && locality.isNotEmpty) {
          addressParts.add(locality);
        }

        final subAdminArea = place.subAdministrativeArea;
        if (subAdminArea != null && subAdminArea.isNotEmpty) {
          addressParts.add(subAdminArea);
        }

        final administrativeArea = place.administrativeArea;
        if (administrativeArea != null && administrativeArea.isNotEmpty) {
          addressParts.add(administrativeArea);
        }

        final postalCode = place.postalCode;
        if (postalCode != null && postalCode.isNotEmpty) {
          addressParts.add(postalCode);
        }

        if (addressParts.isEmpty) {
          return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
        }

        return addressParts.join(', ');
      }

      return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
    } catch (e) {
      // Silently handle geocoding errors on web/emulator
      print("GEOCODING ERROR: $e");
      return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
    }
  }

  /// Get address using OpenStreetMap Nominatim API (Fallback for Web)
  Future<String> _getAddressFromOSM(double lat, double lng) async {
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1');

    final response = await http.get(url, headers: {
      'User-Agent': 'SahayApp/1.0 (hackathon-demo)', // Required by OSM
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      // Prefer formatted display_name or construct manually
      // OSM "display_name" is usually very good and detailed
      if (data['display_name'] != null) {
        return data['display_name'];
      }

      // Fallback manual construction from 'address' object
      final address = data['address'];
      if (address != null) {
        List<String> parts = [];
        if (address['road'] != null) parts.add(address['road']);
        if (address['suburb'] != null) parts.add(address['suburb']);
        if (address['city'] != null) parts.add(address['city']);
        if (address['state'] != null) parts.add(address['state']);

        if (parts.isNotEmpty) return parts.join(', ');
      }
    }

    return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
  }
}

// Provider for LocationService
final locationServiceProvider =
    Provider<LocationService>((ref) => LocationService());

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
