import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Profile data that persists during session
class ProfileData {
  final String name;
  final String email;
  final String phone;
  final String profession;
  final String address;
  final String? profileImagePath;

  ProfileData({
    this.name = '',
    this.email = '',
    this.phone = '',
    this.profession = 'Software Developer',
    this.address = 'Mumbai, Maharashtra, India',
    this.profileImagePath,
  });

  ProfileData copyWith({
    String? name,
    String? email,
    String? phone,
    String? profession,
    String? address,
    String? profileImagePath,
  }) {
    return ProfileData(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profession: profession ?? this.profession,
      address: address ?? this.address,
      profileImagePath: profileImagePath ?? this.profileImagePath,
    );
  }
}

/// Profile state notifier for persistence
class ProfileNotifier extends StateNotifier<ProfileData> {
  ProfileNotifier() : super(ProfileData());

  void updateProfile({
    String? name,
    String? email,
    String? phone,
    String? profession,
    String? address,
    String? profileImagePath,
  }) {
    state = state.copyWith(
      name: name,
      email: email,
      phone: phone,
      profession: profession,
      address: address,
      profileImagePath: profileImagePath,
    );
  }

  void setProfileImage(String path) {
    state = state.copyWith(profileImagePath: path);
  }

  void initFromUser(String name, String email, String phone) {
    if (state.name.isEmpty) {
      state = state.copyWith(name: name, email: email, phone: phone);
    }
  }
}

/// Global profile provider
final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileData>((ref) {
  return ProfileNotifier();
});
