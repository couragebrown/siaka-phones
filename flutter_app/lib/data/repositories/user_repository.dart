import 'package:flutter/foundation.dart';
import '../mock_data.dart';
import '../../domain/models/user_profile.dart';

class UserRepository extends ChangeNotifier {
  UserProfile _profile = MockData.profile;

  UserProfile get profile => _profile;

  void updateProfile({String? name, String? phone, String? email}) {
    _profile = _profile.copyWith(
      name: name,
      email: email,
      phone: phone,
    );
    notifyListeners();
  }

  void updateAddress({
    required String detailAddress,
    required String gpsCode,
    String? region,
    String? country,
  }) {
    _profile = _profile.copyWith(
      detailAddress: detailAddress,
      gpsCode: gpsCode,
      region: region,
      country: country,
    );
    notifyListeners();
  }

  void addAddress(String newAddress) {
    // Single saved address: replaces current address
    _profile = _profile.copyWith(detailAddress: newAddress);
    notifyListeners();
  }
}
