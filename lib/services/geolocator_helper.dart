// ============================================================
// AeroSense — Geolocator Helper
// Isolated GPS wrapper so geolocator package import is in one
// place. Falls back gracefully on unsupported platforms.
// ============================================================

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';

/// A simple lat/lon pair returned from GPS.
class GpsCoordinates {
  final double latitude;
  final double longitude;
  const GpsCoordinates(this.latitude, this.longitude);
}

class GeolocatorHelper {
  /// Returns the current GPS position or null on failure/denial.
  static Future<GpsCoordinates?> getCurrentPosition() async {
    if (kIsWeb) return null; // web geolocation requires a different flow

    try {
      // Check service enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      // Check / request permission
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) return null;
      }
      if (perm == LocationPermission.deniedForever) return null;

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy : LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return GpsCoordinates(pos.latitude, pos.longitude);
    } catch (_) {
      return null;
    }
  }
}
