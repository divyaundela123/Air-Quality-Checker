// ============================================================
// AeroSense — Geocoding Service
// Uses Nominatim (OpenStreetMap) — free, no API key.
// Resolves any Indian state / city / area / landmark to
// real lat/lon coordinates.
// Rate limit: max 1 req/sec (we debounce in the UI).
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;

// ── Result model ─────────────────────────────────────────────
class GeocodingResult {
  final String  displayName;   // full human-readable name
  final String  shortName;     // first part before first comma
  final String  city;          // city / town / village
  final String  state;         // state / region
  final String  country;       // country name
  final double  latitude;
  final double  longitude;
  final String  type;          // city | suburb | neighbourhood | state | etc.
  final String  osmId;         // unique OSM id for dedup

  const GeocodingResult({
    required this.displayName,
    required this.shortName,
    required this.city,
    required this.state,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.type,
    required this.osmId,
  });

  /// True when this result is inside India.
  bool get isIndia => country.toLowerCase().contains('india');

  /// Label shown in the search results list.
  String get label {
    final parts = <String>[];
    if (shortName.isNotEmpty)  parts.add(shortName);
    if (city.isNotEmpty && city != shortName) parts.add(city);
    if (state.isNotEmpty)      parts.add(state);
    return parts.join(', ');
  }

  factory GeocodingResult.fromJson(Map<String, dynamic> j) {
    final addr    = j['address'] as Map<String, dynamic>? ?? {};
    final lat     = double.tryParse(j['lat']?.toString() ?? '') ?? 0;
    final lon     = double.tryParse(j['lon']?.toString() ?? '') ?? 0;
    final display = j['display_name'] as String? ?? '';
    final type    = j['type']    as String? ?? j['class'] as String? ?? 'place';
    final osmId   = '${j['osm_type'] ?? ''}${j['osm_id'] ?? ''}';

    // Extract meaningful name parts from address object
    final nameKey = _firstPresent(addr, [
      'amenity','leisure','tourism','shop','building',
      'neighbourhood','suburb','village','town','city',
      'county','state_district',
    ]) ?? display.split(',').first.trim();

    final cityVal  = _firstPresent(addr, [
      'city','town','village','municipality','city_district',
    ]) ?? '';
    final stateVal = addr['state'] as String? ?? '';
    final country  = addr['country'] as String? ?? '';

    return GeocodingResult(
      displayName : display,
      shortName   : nameKey,
      city        : cityVal,
      state       : stateVal,
      country     : country,
      latitude    : lat,
      longitude   : lon,
      type        : type,
      osmId       : osmId,
    );
  }

  static String? _firstPresent(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v is String && v.isNotEmpty) return v;
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is GeocodingResult && other.osmId == osmId;
  @override
  int get hashCode => osmId.hashCode;
}

// ── Service ───────────────────────────────────────────────────
class GeocodingService {
  static const String _baseUrl =
      'https://nominatim.openstreetmap.org/search';
  static const String _reverseUrl =
      'https://nominatim.openstreetmap.org/reverse';

  // Nominatim requires a descriptive User-Agent
  static const Map<String, String> _headers = {
    'User-Agent'  : 'AeroSenseAQI/2.0 (flutter; contact@aerosense.app)',
    'Accept'      : 'application/json',
    'Accept-Language': 'en',
  };

  /// Search for any Indian location by free text.
  /// Returns up to [limit] results, filtered to India only.
  static Future<List<GeocodingResult>> search(
    String query, {
    int limit = 8,
  }) async {
    if (query.trim().length < 2) return [];

    // Append ", India" if the query doesn't already mention India
    final q = query.toLowerCase().contains('india')
        ? query.trim()
        : '${query.trim()}, India';

    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'q'              : q,
      'format'         : 'json',
      'addressdetails' : '1',
      'limit'          : '$limit',
      'countrycodes'   : 'in',           // restrict to India
      'dedupe'         : '1',
    });

    try {
      final res = await http.get(uri, headers: _headers)
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return [];

      final list = jsonDecode(res.body) as List<dynamic>;
      return list
          .map((e) => GeocodingResult.fromJson(e as Map<String, dynamic>))
          .where((r) => r.isIndia && r.latitude != 0 && r.longitude != 0)
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Reverse geocode: lat/lon → location name.
  static Future<GeocodingResult?> reverse(double lat, double lon) async {
    final uri = Uri.parse(_reverseUrl).replace(queryParameters: {
      'lat'    : '$lat',
      'lon'    : '$lon',
      'format' : 'json',
      'addressdetails': '1',
    });

    try {
      final res = await http.get(uri, headers: _headers)
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;

      final j = jsonDecode(res.body) as Map<String, dynamic>;
      if (j['error'] != null) return null;
      final r = GeocodingResult.fromJson(j);
      return r.isIndia ? r : null;
    } catch (_) {
      return null;
    }
  }
}
