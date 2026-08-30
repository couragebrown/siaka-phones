class StoreLocation {
  final String id;
  final String name;
  final String address;
  final String city;
  final String phone;
  final String openHours;
  final double distanceKm;
  final bool hasRepairCenter;
  final bool isOpenNow;

  const StoreLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.phone,
    required this.openHours,
    required this.distanceKm,
    this.hasRepairCenter = true,
    this.isOpenNow = true,
  });
}
