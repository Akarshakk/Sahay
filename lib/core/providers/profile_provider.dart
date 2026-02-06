import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Profile data that persists during session and across app restarts
class ProfileData {
  final String name;
  final String email;
  final String phone;
  final String profession;
  final String address;
  final String state;
  final String district;
  final String city;
  final String? profileImagePath;

  ProfileData({
    this.name = '',
    this.email = '',
    this.phone = '',
    this.profession = '',
    this.address = '',
    this.state = '',
    this.district = '',
    this.city = '',
    this.profileImagePath,
  });

  ProfileData copyWith({
    String? name,
    String? email,
    String? phone,
    String? profession,
    String? address,
    String? state,
    String? district,
    String? city,
    String? profileImagePath,
  }) {
    return ProfileData(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profession: profession ?? this.profession,
      address: address ?? this.address,
      state: state ?? this.state,
      district: district ?? this.district,
      city: city ?? this.city,
      profileImagePath: profileImagePath ?? this.profileImagePath,
    );
  }
}

/// Profile state notifier with persistence (web-safe)
class ProfileNotifier extends StateNotifier<ProfileData> {
  ProfileNotifier() : super(ProfileData()) {
    // Defer loading to avoid blocking startup
    Future.microtask(() => _loadFromPrefs());
  }

  Future<void> _loadFromPrefs() async {
    // Skip SharedPreferences on web (causes errors)
    if (kIsWeb) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString('profile_name') ?? '';
      final email = prefs.getString('profile_email') ?? '';
      final phone = prefs.getString('profile_phone') ?? '';
      final profession = prefs.getString('profile_profession') ?? '';
      final address = prefs.getString('profile_address') ?? '';
      final stateVal = prefs.getString('profile_state') ?? '';
      final district = prefs.getString('profile_district') ?? '';
      final city = prefs.getString('profile_city') ?? '';
      final imagePath = prefs.getString('profile_image');

      state = ProfileData(
        name: name,
        email: email,
        phone: phone,
        profession: profession,
        address: address,
        state: stateVal,
        district: district,
        city: city,
        profileImagePath: imagePath,
      );
    } catch (e) {
      // Silently ignore on web/any errors
    }
  }

  Future<void> _saveToPrefs() async {
    // Skip SharedPreferences on web
    if (kIsWeb) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_name', state.name);
      await prefs.setString('profile_email', state.email);
      await prefs.setString('profile_phone', state.phone);
      await prefs.setString('profile_profession', state.profession);
      await prefs.setString('profile_address', state.address);
      await prefs.setString('profile_state', state.state);
      await prefs.setString('profile_district', state.district);
      await prefs.setString('profile_city', state.city);
      if (state.profileImagePath != null) {
        await prefs.setString('profile_image', state.profileImagePath!);
      }
    } catch (e) {
      // Silently ignore
    }
  }

  Future<void> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? profession,
    String? address,
    String? stateVal,
    String? district,
    String? city,
    String? profileImagePath,
  }) async {
    state = state.copyWith(
      name: name,
      email: email,
      phone: phone,
      profession: profession,
      address: address,
      state: stateVal,
      district: district,
      city: city,
      profileImagePath: profileImagePath,
    );
    await _saveToPrefs();
  }

  Future<void> setProfileImage(String path) async {
    state = state.copyWith(profileImagePath: path);
    await _saveToPrefs();
  }

  void initFromUser(String name, String email, String phone) {
    if (state.name.isEmpty) {
      state = state.copyWith(name: name, email: email, phone: phone);
      _saveToPrefs();
    }
  }
}

/// Global profile provider
final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileData>((ref) {
  return ProfileNotifier();
});
