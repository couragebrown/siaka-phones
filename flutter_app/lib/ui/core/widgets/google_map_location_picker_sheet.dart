import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/services/live_location_service.dart';

/// Shows the Google Maps Location Picker Modal Bottom Sheet.
Future<LiveLocationResult?> showGoogleMapLocationPicker({
  required BuildContext context,
  String? initialGpsCode,
  String? initialRegion,
}) {
  return showModalBottomSheet<LiveLocationResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => GoogleMapLocationPickerSheet(
      initialGpsCode: initialGpsCode,
      initialRegion: initialRegion,
    ),
  );
}

class GoogleMapLocationPickerSheet extends StatefulWidget {
  final String? initialGpsCode;
  final String? initialRegion;

  const GoogleMapLocationPickerSheet({
    super.key,
    this.initialGpsCode,
    this.initialRegion,
  });

  @override
  State<GoogleMapLocationPickerSheet> createState() =>
      _GoogleMapLocationPickerSheetState();
}

class _GoogleMapLocationPickerSheetState
    extends State<GoogleMapLocationPickerSheet> {
  late double _currentLat;
  late double _currentLng;
  late String _currentGpsCode;
  late String _currentPlusCode;
  late String _currentAreaName;
  String? _detectedRegion;
  bool _isLocating = false;
  final TextEditingController _searchController = TextEditingController();

  Offset _pinPixelOffset = const Offset(0.5, 0.45); // Normalized 0..1 in canvas

  @override
  void initState() {
    super.initState();
    // Default to Accra Central / Ridge or initial matched hub
    GhanaMapLocation defaultLoc = LiveLocationService.popularGhanaLocations.first;

    if (widget.initialGpsCode != null && widget.initialGpsCode!.isNotEmpty) {
      final match = LiveLocationService.popularGhanaLocations.firstWhere(
        (loc) => loc.gpsCode.toUpperCase() == widget.initialGpsCode!.toUpperCase(),
        orElse: () => defaultLoc,
      );
      defaultLoc = match;
    }

    _currentLat = defaultLoc.latitude;
    _currentLng = defaultLoc.longitude;
    _currentGpsCode = defaultLoc.gpsCode;
    _currentPlusCode = defaultLoc.plusCode;
    _currentAreaName = defaultLoc.name;
    _detectedRegion = defaultLoc.region;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectLocation(GhanaMapLocation loc) {
    setState(() {
      _currentLat = loc.latitude;
      _currentLng = loc.longitude;
      _currentGpsCode = loc.gpsCode;
      _currentPlusCode = loc.plusCode;
      _currentAreaName = loc.name;
      _detectedRegion = loc.region;
      _pinPixelOffset = const Offset(0.5, 0.45);
      _searchController.text = loc.name;
    });
  }

  Future<void> _detectLiveLocation() async {
    if (_isLocating) return;
    setState(() => _isLocating = true);
    try {
      final res = await LiveLocationService.fetchLiveGpsCode(
        selectedRegion: _detectedRegion ?? widget.initialRegion,
      );
      if (!mounted) return;
      setState(() {
        _currentLat = res.latitude;
        _currentLng = res.longitude;
        _currentGpsCode = res.gpsCode;
        _currentPlusCode = res.googlePlusCode;
        _currentAreaName = [
          if (res.suburb != null && res.suburb!.isNotEmpty) res.suburb!,
          if (res.city != null && res.city!.isNotEmpty && res.city != res.suburb)
            res.city!,
        ].join(', ');
        if (_currentAreaName.isEmpty) {
          _currentAreaName = 'Live Detected Location';
        }
        _detectedRegion = res.detectedRegion;
        _pinPixelOffset = const Offset(0.5, 0.45);
        _searchController.text = _currentAreaName;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📍 Live GPS code updated: $_currentGpsCode'),
          backgroundColor: const Color(0xFF0F172A),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: const Color(0xFFDC2626),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  void _onMapTapped(Offset localPosition, Size canvasSize) {
    final normX = (localPosition.dx / canvasSize.width).clamp(0.08, 0.92);
    final normY = (localPosition.dy / canvasSize.height).clamp(0.12, 0.88);

    // Minor latitude & longitude perturbation proportional to tap offset
    final dLat = (0.45 - normY) * 0.006;
    final dLng = (normX - 0.5) * 0.006;

    final newLat = double.parse((_currentLat + dLat).toStringAsFixed(5));
    final newLng = double.parse((_currentLng + dLng).toStringAsFixed(5));

    final newGps = LiveLocationService.coordinatesToGhanaGpsCode(
      newLat,
      newLng,
      region: _detectedRegion,
    );
    final newPlus = LiveLocationService.coordinatesToGooglePlusCode(newLat, newLng);

    setState(() {
      _currentLat = newLat;
      _currentLng = newLng;
      _currentGpsCode = newGps;
      _currentPlusCode = newPlus;
      _pinPixelOffset = Offset(normX, normY);
    });
  }

  void _filterSearch(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return;

    // Check if it's a Plus Code (contains '+')
    if (q.contains('+')) {
      final matchedPlus = LiveLocationService.popularGhanaLocations.firstWhere(
        (l) => l.plusCode.toLowerCase().contains(q),
        orElse: () => LiveLocationService.popularGhanaLocations.first,
      );
      _selectLocation(matchedPlus);
      return;
    }

    // Check if it's a GPS Code (e.g. GA-183)
    if (RegExp(r'^[a-z]{2}-\d{2,4}', caseSensitive: false).hasMatch(q)) {
      final matchedGps = LiveLocationService.popularGhanaLocations.firstWhere(
        (l) => l.gpsCode.toLowerCase().startsWith(q),
        orElse: () => LiveLocationService.popularGhanaLocations.first,
      );
      _selectLocation(matchedGps);
      return;
    }

    // Name match
    for (final loc in LiveLocationService.popularGhanaLocations) {
      if (loc.name.toLowerCase().contains(q) ||
          loc.district.toLowerCase().contains(q) ||
          loc.region.toLowerCase().contains(q)) {
        _selectLocation(loc);
        break;
      }
    }
  }

  void _confirmSelection() {
    final result = LiveLocationResult(
      latitude: _currentLat,
      longitude: _currentLng,
      gpsCode: _currentGpsCode,
      googlePlusCode: _currentPlusCode,
      fullPlusCode: LiveLocationService.coordinatesToFullPlusCode(_currentLat, _currentLng),
      detectedRegion: _detectedRegion,
      formattedCoordinates:
          '${_currentLat.abs().toStringAsFixed(4)}° N, ${_currentLng.abs().toStringAsFixed(4)}° W • $_currentAreaName',
      googleMapsUrl:
          'https://www.google.com/maps/search/?api=1&query=$_currentLat,$_currentLng',
      city: _detectedRegion,
      suburb: _currentAreaName,
    );
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 14,
        bottom: bottomInset + bottomPadding + 14,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Icon(
                  Icons.map_rounded,
                  color: Color(0xFF1C7BFF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Google Maps GPS Picker',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Tap map or select Ghana landmark for exact GPS code',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search / paste field
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: _filterSearch,
                    textInputAction: TextInputAction.search,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Search suburb, Plus Code (HR5R+M6), or GPS...',
                      hintStyle: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() {});
                    },
                    child: const Icon(Icons.clear_rounded, size: 16, color: Color(0xFF94A3B8)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Interactive Visual Google Map
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final mapHeight = 175.0;
                      return Container(
                        height: mapHeight,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFBFDBFE), width: 1.4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              GestureDetector(
                                onTapDown: (details) => _onMapTapped(
                                  details.localPosition,
                                  Size(constraints.maxWidth, mapHeight),
                                ),
                                child: CustomPaint(
                                  painter: _GoogleMapCanvasPainter(
                                    pinNormalized: _pinPixelOffset,
                                    areaName: _currentAreaName,
                                  ),
                                ),
                              ),

                              // Top-left Google Maps Badge
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.94),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.location_pin, size: 13, color: Color(0xFFEA4335)),
                                      SizedBox(width: 4),
                                      Text(
                                        'Google Maps Pin',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Top-right "My Location" GPS button
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Tooltip(
                                  message: 'Center on my live GPS',
                                  child: InkWell(
                                    onTap: _isLocating ? null : _detectLiveLocation,
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.94),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: const Color(0xFFBFDBFE)),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.05),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: _isLocating
                                            ? const SizedBox(
                                                width: 14,
                                                height: 14,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Color(0xFF1C7BFF),
                                                ),
                                              )
                                            : const Icon(
                                                Icons.my_location_rounded,
                                                size: 16,
                                                color: Color(0xFF1C7BFF),
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Bottom Tap Hint
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  color: const Color(0xFF0F172A).withValues(alpha: 0.75),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.touch_app_rounded, size: 12, color: Colors.white),
                                      SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          'Tap anywhere on map to pin-point your exact house or store',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Dual Code Details Card (Ghana GPS + Google Plus Code)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'GhanaPost GPS Address',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _currentGpsCode,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: _currentGpsCode));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Copied $_currentGpsCode to clipboard'),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.copy_rounded, size: 17, color: Color(0xFF1C7BFF)),
                              tooltip: 'Copy GPS Code',
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        const Divider(height: 16, color: Color(0xFFE2E8F0)),
                        Row(
                          children: [
                            const Icon(Icons.tag_rounded, size: 15, color: Color(0xFF16A34A)),
                            const SizedBox(width: 6),
                            const Text(
                              'Google Plus Code: ',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF475569),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                _currentPlusCode,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF16A34A),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.pin_drop_outlined, size: 15, color: Color(0xFF64748B)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Area: $_currentAreaName (${_currentLat.toStringAsFixed(4)}° N, ${_currentLng.toStringAsFixed(4)}° W)',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Popular Areas in Ghana
                  const Text(
                    'Quick Pick Ghana Area / Landmark:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: LiveLocationService.popularGhanaLocations.map((loc) {
                      final isSelected = loc.gpsCode == _currentGpsCode;
                      return InkWell(
                        onTap: () => _selectLocation(loc),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF1C7BFF) : const Color(0xFFE2E8F0),
                              width: isSelected ? 1.4 : 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.place_rounded,
                                size: 12,
                                color: isSelected ? const Color(0xFF1C7BFF) : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                loc.name,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? const Color(0xFF1C7BFF) : const Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Bottom Buttons
          Row(
            children: [
              // Open in Google Maps button
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 46,
                  child: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    LiveLocationService.openGoogleMapsApp(
                      latitude: _currentLat,
                      longitude: _currentLng,
                      query: '$_currentAreaName, Ghana',
                    );
                  },
                  child: const FittedBox(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.open_in_new_rounded, size: 16, color: Color(0xFFEA4335)),
                        SizedBox(width: 6),
                        Text(
                          'Google Maps App',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Use This Location button
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1C7BFF),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _confirmSelection,
                    child: FittedBox(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 17),
                          const SizedBox(width: 6),
                          Text(
                            'Use GPS: $_currentGpsCode',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Canvas painter replicating Google Maps UI style with streets, park patches, ocean, and interactive pin
class _GoogleMapCanvasPainter extends CustomPainter {
  final Offset pinNormalized;
  final String areaName;

  const _GoogleMapCanvasPainter({
    required this.pinNormalized,
    required this.areaName,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Canvas background
    final bgPaint = Paint()..color = const Color(0xFFF2EFE9);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Green park shapes
    final parkPaint = Paint()..color = const Color(0xFFCDEBD0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.04, size.height * 0.12, size.width * 0.28, size.height * 0.45),
        const Radius.circular(8),
      ),
      parkPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.70, size.height * 0.15, size.width * 0.26, size.height * 0.38),
        const Radius.circular(8),
      ),
      parkPaint,
    );

    // Water body at bottom right (Gulf of Guinea curve)
    final waterPaint = Paint()..color = const Color(0xFFA5D6A7).withValues(alpha: 0.1);
    final seaPaint = Paint()..color = const Color(0xFFAAD3DF);
    final waterPath = Path()
      ..moveTo(size.width * 0.62, size.height)
      ..quadraticBezierTo(
        size.width * 0.76,
        size.height * 0.65,
        size.width,
        size.height * 0.52,
      )
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(waterPath, seaPaint);

    // Minor residential roads
    final minorRoadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;
    for (final frac in [0.20, 0.42, 0.64, 0.84]) {
      canvas.drawLine(
        Offset(size.width * frac, 0),
        Offset(size.width * (frac + 0.05), size.height),
        minorRoadPaint,
      );
    }
    canvas.drawLine(
      Offset(0, size.height * 0.28),
      Offset(size.width, size.height * 0.24),
      minorRoadPaint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.72),
      Offset(size.width, size.height * 0.76),
      minorRoadPaint,
    );

    // Main Arterial Highway (Yellow Google Maps style)
    final casingPaint = Paint()
      ..color = const Color(0xFFE2D6B5)
      ..strokeWidth = 8.0
      ..style = PaintingStyle.stroke;
    final highwayPaint = Paint()
      ..color = const Color(0xFFFFD166)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke;

    final highwayPath = Path()
      ..moveTo(0, size.height * 0.52)
      ..quadraticBezierTo(
        size.width * 0.45,
        size.height * 0.38,
        size.width,
        size.height * 0.46,
      );
    canvas.drawPath(highwayPath, casingPaint);
    canvas.drawPath(highwayPath, highwayPaint);

    // Secondary Highway (Orange/Yellow)
    final secondPath = Path()
      ..moveTo(size.width * 0.35, 0)
      ..quadraticBezierTo(
        size.width * 0.48,
        size.height * 0.55,
        size.width * 0.58,
        size.height,
      );
    canvas.drawPath(secondPath, casingPaint);
    canvas.drawPath(secondPath, highwayPaint);

    // Interactive Pin
    final pinCenter = Offset(
      size.width * pinNormalized.dx,
      size.height * pinNormalized.dy,
    );

    // Radar pulse ring
    canvas.drawCircle(
      pinCenter,
      22,
      Paint()..color = const Color(0xFF1C7BFF).withValues(alpha: 0.16),
    );
    canvas.drawCircle(
      pinCenter,
      12,
      Paint()..color = const Color(0xFF1C7BFF).withValues(alpha: 0.25),
    );

    // Google Red Pin shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(pinCenter.dx, pinCenter.dy + 8),
        width: 14,
        height: 6,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.22),
    );

    // Google Maps teardrop marker
    final pinPath = Path()
      ..moveTo(pinCenter.dx, pinCenter.dy + 7)
      ..cubicTo(
        pinCenter.dx - 10,
        pinCenter.dy - 3,
        pinCenter.dx - 10,
        pinCenter.dy - 18,
        pinCenter.dx,
        pinCenter.dy - 18,
      )
      ..cubicTo(
        pinCenter.dx + 10,
        pinCenter.dy - 18,
        pinCenter.dx + 10,
        pinCenter.dy - 3,
        pinCenter.dx,
        pinCenter.dy + 7,
      )
      ..close();

    canvas.drawPath(pinPath, Paint()..color = const Color(0xFFEA4335));
    // White inner dot of Google pin
    canvas.drawCircle(
      Offset(pinCenter.dx, pinCenter.dy - 9),
      4.0,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _GoogleMapCanvasPainter oldDelegate) {
    return oldDelegate.pinNormalized != pinNormalized ||
        oldDelegate.areaName != areaName;
  }
}
