import 'package:flutter/foundation.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../domain/models/user_profile.dart';

class ProfileViewModel extends ChangeNotifier {
  final UserRepository _userRepository;

  ProfileViewModel({required UserRepository userRepository})
      : _userRepository = userRepository {
    _userRepository.addListener(_onUserChanged);
  }

  @override
  void dispose() {
    _userRepository.removeListener(_onUserChanged);
    super.dispose();
  }

  void _onUserChanged() {
    notifyListeners();
  }

  UserProfile get profile => _userRepository.profile;
  UserRepository get userRepository => _userRepository;

  void updateProfile({String? name, String? phone, String? email}) {
    _userRepository.updateProfile(name: name, phone: phone, email: email);
  }

  void updateAddress({
    required String detailAddress,
    required String gpsCode,
    String? region,
    String? country,
  }) {
    _userRepository.updateAddress(
      detailAddress: detailAddress,
      gpsCode: gpsCode,
      region: region,
      country: country,
    );
  }

  void addAddress(String address) {
    _userRepository.addAddress(address);
  }
}
