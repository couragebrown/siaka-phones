class UserProfile {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String avatarUrl;
  final String membershipTier;
  final int rewardPoints;
  final List<String> savedAddresses;
  final bool biometricEnabled;
  final bool pushNotifications;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.avatarUrl,
    this.membershipTier = 'Diamond Elite',
    this.rewardPoints = 4850,
    this.savedAddresses = const [
      '742 Evergreen Terrace, Springfield, OR',
      '10880 Wilshire Blvd #1100, Los Angeles, CA'
    ],
    this.biometricEnabled = true,
    this.pushNotifications = true,
  });
}
