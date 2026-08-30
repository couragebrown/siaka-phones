import 'package:flutter/foundation.dart';
import '../mock_data.dart';
import '../../domain/models/user_profile.dart';

class UserRepository extends ChangeNotifier {
  UserProfile _profile = MockData.profile;

  UserProfile get profile => _profile;

  void updateProfile({String? name, String? phone, String? email}) {
    _profile = UserProfile(
      id: _profile.id,
      name: name ?? _profile.name,
      email: email ?? _profile.email,
      phone: phone ?? _profile.phone,
      avatarUrl: _profile.avatarUrl,
      membershipTier: _profile.membershipTier,
      rewardPoints: _profile.rewardPoints,
      savedAddresses: _profile.savedAddresses,
      biometricEnabled: _profile.biometricEnabled,
      pushNotifications: _profile.pushNotifications,
    );
    notifyListeners();
  }

  void addAddress(String newAddress) {
    final updatedList = List<String>.from(_profile.savedAddresses)..add(newAddress);
    _profile = UserProfile(
      id: _profile.id,
      name: _profile.name,
      email: _profile.email,
      phone: _profile.phone,
      avatarUrl: _profile.avatarUrl,
      membershipTier: _profile.membershipTier,
      rewardPoints: _profile.rewardPoints,
      savedAddresses: updatedList,
      biometricEnabled: _profile.biometricEnabled,
      pushNotifications: _profile.pushNotifications,
    );
    notifyListeners();
  }
}
