import '../mock_data.dart';
import '../../domain/models/store_location.dart';

class LocationRepository {
  Future<List<StoreLocation>> getLocations({String? searchQuery}) async {
    await Future.delayed(const Duration(milliseconds: 100));
    const list = MockData.locations;
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      return list.where((loc) =>
          loc.name.toLowerCase().contains(q) ||
          loc.city.toLowerCase().contains(q) ||
          loc.address.toLowerCase().contains(q)).toList();
    }
    return list;
  }
}
