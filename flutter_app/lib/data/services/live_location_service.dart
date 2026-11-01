import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class LiveLocationException implements Exception {
  final String message;
  const LiveLocationException(this.message);

  @override
  String toString() => message;
}

class LiveLocationResult {
  final double latitude;
  final double longitude;
  final String gpsCode;
  final String? detectedRegion;
  final String formattedCoordinates;

  const LiveLocationResult({
    required this.latitude,
    required this.longitude,
    required this.gpsCode,
    required this.formattedCoordinates,
    this.detectedRegion,
  });
}

class LiveLocationService {
  static const MethodChannel _channel = MethodChannel('com.siakaphones.app/location');

  static const Map<String, String> _regionPrefixes = {
    'Greater Accra': 'GA',
    'Ashanti': 'AK',
    'Central': 'CG',
    'Western': 'WS',
    'Western North': 'WN',
    'Eastern': 'EN',
    'Volta': 'VH',
    'Oti': 'OT',
    'Northern': 'NT',
    'Savannah': 'SV',
    'North East': 'NE',
    'Upper East': 'UB',
    'Upper West': 'UW',
    'Bono': 'BS',
    'Bono East': 'BE',
    'Ahafo': 'AH',
  };

  /// Fetches the user's current live coordinates and converts them into a Ghana GPS Digital Address.
  static Future<LiveLocationResult> fetchLiveGpsCode({String? selectedRegion}) async {
    double? lat;
    double? lng;

    // 1. Native Android GPS / Network hardware provider
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final raw = await _channel.invokeMethod<dynamic>('getCurrentLocation');
        if (raw is Map) {
          lat = (raw['latitude'] as num?)?.toDouble();
          lng = (raw['longitude'] as num?)?.toDouble();
        }
      } on PlatformException catch (e) {
        if (e.code == 'PERMISSION_DENIED') {
          throw const LiveLocationException(
            'Location permission denied. Allow location access or enter your GPS code manually.',
          );
        }
        debugPrint('ℹ️ Native GPS fallback notice (${e.code}): ${e.message}');
      } catch (e) {
        debugPrint('ℹ️ Native GPS channel error: $e');
      }
    }

    // 2. Network geolocation fallback (useful on emulators without mock GPS fix or desktop)
    if (lat == null || lng == null) {
      final netCoords = await _fetchNetworkLocationFallback();
      if (netCoords != null) {
        lat = netCoords.$1;
        lng = netCoords.$2;
      }
    }

    if (lat == null || lng == null) {
      throw const LiveLocationException(
        'Unable to detect live location right now. Please enable GPS or type your code.',
      );
    }

    final detectedRegion = detectGhanaRegion(lat, lng);
    final effectiveRegion = detectedRegion ?? selectedRegion ?? 'Greater Accra';
    final gpsCode = coordinatesToGhanaGpsCode(
      lat,
      lng,
      region: effectiveRegion,
    );

    return LiveLocationResult(
      latitude: lat,
      longitude: lng,
      gpsCode: gpsCode,
      detectedRegion: detectedRegion,
      formattedCoordinates: _formatCoords(lat, lng),
    );
  }

  static Future<(double, double)?> _fetchNetworkLocationFallback() async {
    final endpoints = [
      'https://ipwho.is/',
      'https://ipapi.co/json/',
    ];

    for (final url in endpoints) {
      try {
        final client = HttpClient()..connectionTimeout = const Duration(milliseconds: 2800);
        final req = await client.getUrl(Uri.parse(url));
        final resp = await req.close().timeout(const Duration(milliseconds: 2800));
        if (resp.statusCode == HttpStatus.ok) {
          final body = await resp.transform(utf8.decoder).join();
          final json = jsonDecode(body);
          if (json is Map<String, dynamic>) {
            final lat = (json['latitude'] as num?)?.toDouble();
            final lng = (json['longitude'] as num?)?.toDouble();
            if (lat != null && lng != null) {
              return (lat, lng);
            }
          }
        }
      } catch (_) {}
    }
    return null;
  }

  /// Detects the Ghana region if coordinates fall within Ghana's geographic bounds.
  static String? detectGhanaRegion(double lat, double lng) {
    // Ghana bounding box: lat 4.7°N to 11.2°N, lng -3.3°W to 1.25°E
    if (lat < 4.65 || lat > 11.25 || lng < -3.35 || lng > 1.30) {
      return null;
    }
    if (lat >= 10.2) {
      return lng < -1.4 ? 'Upper West' : 'Upper East';
    }
    if (lat >= 9.7 && lng >= -1.0) {
      return 'North East';
    }
    if (lat >= 8.5) {
      if (lng < -1.1) return 'Savannah';
      if (lng > 0.15) return 'Oti';
      return 'Northern';
    }
    if (lat >= 7.2) {
      if (lng > 0.1) return 'Oti';
      if (lng < -1.9) return 'Bono';
      return 'Bono East';
    }
    if (lat >= 6.75 && lng < -2.1) {
      return 'Ahafo';
    }
    if (lat >= 6.15 && lng >= -2.15 && lng <= -0.85) {
      return 'Ashanti';
    }
    if (lng > 0.05 && lat < 7.2) {
      return 'Volta';
    }
    if (lat >= 5.85 && lng > -1.05 && lng <= 0.10) {
      return 'Eastern';
    }
    if (lat < 6.5 && lng < -2.25 && lat >= 5.75) {
      return 'Western North';
    }
    if (lat < 5.75 && lng < -1.65) {
      return 'Western';
    }
    if (lat < 5.95 && lng >= -1.65 && lng < -0.45) {
      return 'Central';
    }
    return 'Greater Accra';
  }

  /// Generates a deterministic GhanaPostGPS-style code (`XX-DDD-DDDD`) from 5m grid coordinates.
  static String coordinatesToGhanaGpsCode(
    double lat,
    double lng, {
    String region = 'Greater Accra',
  }) {
    final prefix = _regionPrefixes[region] ?? 'GA';

    // 5-meter precision grid projection (~0.000045 degrees per 5m cell)
    final latCells = (lat.abs() * 22222).round();
    final lngCells = (lng.abs() * 22222).round();

    final zone = ((latCells ~/ 100) * 7 + (lngCells ~/ 100) * 13) % 900 + 100;
    final grid = ((latCells % 100) * 100 + (lngCells % 100)) % 10000;

    final zoneStr = zone.toString().padLeft(3, '0');
    final gridStr = grid.toString().padLeft(4, '0');
    return '$prefix-$zoneStr-$gridStr';
  }

  static String _formatCoords(double lat, double lng) {
    final ns = lat >= 0 ? 'N' : 'S';
    final ew = lng >= 0 ? 'E' : 'W';
    return '${lat.abs().toStringAsFixed(4)}° $ns, ${lng.abs().toStringAsFixed(4)}° $ew';
  }
}

