import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/widgets/glass_container.dart';
import '../../../domain/models/store_location.dart';
import 'locations_view_model.dart';

class LocationsView extends StatefulWidget {
  final LocationsViewModel viewModel;

  const LocationsView({super.key, required this.viewModel});

  @override
  State<LocationsView> createState() => _LocationsViewState();
}

class _LocationsViewState extends State<LocationsView> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.loadLocations();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Store & Service Centers'),
          ),
          body: widget.viewModel.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.cyan))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Search bar
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: TextField(
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Search city or zip code...',
                          hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                          prefixIcon: Icon(Icons.location_searching, color: AppColors.cyan, size: 20),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onChanged: (val) => widget.viewModel.setSearchQuery(val),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Map View Simulation Glass Banner
                    GlassContainer(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Icon(Icons.map_outlined, size: 40, color: AppColors.cyan),
                          const SizedBox(height: 8),
                          const Text('3 Boutiques Near You', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 4),
                          const Text('All locations support same-day pickup and warranty diagnostics.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text('Official Siaka Stores', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 12),

                    ...widget.viewModel.locations.map((loc) => _buildLocationCard(loc)),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildLocationCard(StoreLocation loc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    loc.name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: loc.isOpenNow ? AppColors.neonEmerald.withOpacity(0.15) : AppColors.neonPink.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: loc.isOpenNow ? AppColors.neonEmerald : AppColors.neonPink),
                  ),
                  child: Text(
                    loc.isOpenNow ? 'Open Now' : 'Closed',
                    style: TextStyle(color: loc.isOpenNow ? AppColors.neonEmerald : AppColors.neonPink, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, color: AppColors.cyan, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('${loc.address}, ${loc.city}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time_rounded, color: AppColors.textMuted, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(loc.openHours, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                ),
              ],
            ),
            const Divider(color: AppColors.borderLight, height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${loc.distanceKm} miles away',
                  style: const TextStyle(color: AppColors.cyan, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surfaceElevated,
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.borderLight),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: const Icon(Icons.directions_outlined, size: 14, color: AppColors.cyan),
                  label: const Text('Get Directions', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Opening navigation to ${loc.name}')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
