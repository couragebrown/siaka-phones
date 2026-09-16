class UserProfile {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String avatarUrl;
  final String membershipTier;
  final int rewardPoints;
  final String detailAddress;
  final String gpsCode;
  final String region;
  final String country;
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
    this.detailAddress = 'House No. 14, Independence Avenue, Airport Residential Area',
    this.gpsCode = 'GA-014-2041',
    this.region = 'Greater Accra',
    this.country = 'Ghana',
    this.biometricEnabled = true,
    this.pushNotifications = true,
  });

  String get fullFormattedAddress =>
      '$detailAddress, $region • $gpsCode';

  /// Returns the single saved address as a single-element list for backward compatibility
  List<String> get savedAddresses => [fullFormattedAddress];

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    String? membershipTier,
    int? rewardPoints,
    String? detailAddress,
    String? gpsCode,
    String? region,
    String? country,
    bool? biometricEnabled,
    bool? pushNotifications,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      membershipTier: membershipTier ?? this.membershipTier,
      rewardPoints: rewardPoints ?? this.rewardPoints,
      detailAddress: detailAddress ?? this.detailAddress,
      gpsCode: gpsCode ?? this.gpsCode,
      region: region ?? this.region,
      country: country ?? this.country,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      pushNotifications: pushNotifications ?? this.pushNotifications,
    );
  }
}
