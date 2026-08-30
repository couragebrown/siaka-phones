import 'package:flutter/foundation.dart';
import '../../../data/repositories/location_repository.dart';
import '../../../domain/models/store_location.dart';

class LocationsViewModel extends ChangeNotifier {
  final LocationRepository _locationRepository;

  LocationsViewModel({required LocationRepository locationRepository})
      : _locationRepository = locationRepository;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<StoreLocation> _locations = [];
  List<StoreLocation> get locations => _locations;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  Future<void> loadLocations() async {
    _isLoading = true;
    notifyListeners();

    try {
      _locations = await _locationRepository.getLocations(searchQuery: _searchQuery);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    loadLocations();
  }
}
