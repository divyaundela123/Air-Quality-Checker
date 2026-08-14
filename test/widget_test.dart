// AeroSense — unit tests
// Covers: kSupportedCities, kCityAreas, LocationProvider
// (city/area/custom-location), resolveLocation, resolveArea,
// filteredCities, filteredAreas, CustomLocation, GeocodingResult.

import 'package:flutter_test/flutter_test.dart';
import 'package:air_qualityp/providers/location_provider.dart';
import 'package:air_qualityp/services/geocoding_service.dart';

void main() {

  // ── kSupportedCities ──────────────────────────────────────────
  group('kSupportedCities', () {
    test('contains at least 35 cities', () {
      expect(kSupportedCities.length, greaterThanOrEqualTo(35));
    });

    test('every city has non-zero coordinates', () {
      for (final c in kSupportedCities) {
        expect(c.latitude,  isNonZero, reason: '${c.name} lat is 0');
        expect(c.longitude, isNonZero, reason: '${c.name} lon is 0');
      }
    });

    test('city names are unique', () {
      final names = kSupportedCities.map((c) => c.name).toList();
      expect(names.toSet().length, equals(names.length));
    });
  });

  // ── kCityAreas ────────────────────────────────────────────────
  group('kCityAreas', () {
    test('contains at least 200 areas', () {
      expect(kCityAreas.length, greaterThanOrEqualTo(200));
    });

    test('every area links to a known city', () {
      final cityNames = kSupportedCities.map((c) => c.name).toSet();
      for (final a in kCityAreas) {
        expect(cityNames.contains(a.cityName), isTrue,
            reason: '${a.name} references unknown city ${a.cityName}');
      }
    });

    test('every area has non-zero coordinates', () {
      for (final a in kCityAreas) {
        expect(a.latitude,  isNonZero, reason: '${a.name} lat is 0');
        expect(a.longitude, isNonZero, reason: '${a.name} lon is 0');
      }
    });

    test('each city has at least 5 areas', () {
      for (final city in kSupportedCities) {
        final count = kCityAreas.where((a) => a.cityName == city.name).length;
        expect(count, greaterThanOrEqualTo(5),
            reason: '${city.name} has only $count areas');
      }
    });
  });

  // ── LocationProvider defaults ──────────────────────────────────
  group('LocationProvider defaults', () {
    test('defaults to New Delhi', () {
      final p = LocationProvider();
      expect(p.selectedCity.name, equals('New Delhi'));
    });

    test('no area selected by default', () {
      final p = LocationProvider();
      expect(p.isAreaSelected, isFalse);
      expect(p.selectedArea, isNull);
    });

    test('no custom location by default', () {
      final p = LocationProvider();
      expect(p.isCustomLocation, isFalse);
      expect(p.customLocation, isNull);
    });

    test('latitude/longitude returns city coords by default', () {
      final p = LocationProvider();
      expect(p.latitude,  closeTo(28.6139, 0.001));
      expect(p.longitude, closeTo(77.2090, 0.001));
    });

    test('locationLabel returns city name by default', () {
      final p = LocationProvider();
      expect(p.locationLabel, equals('New Delhi'));
    });
  });

  // ── resolveLocation ───────────────────────────────────────────
  group('LocationProvider.resolveLocation()', () {
    final p = LocationProvider();

    test('exact city name matches', () {
      expect(p.resolveLocation('Mumbai')?.name, equals('Mumbai'));
    });

    test('case-insensitive match', () {
      expect(p.resolveLocation('mumbai')?.name, equals('Mumbai'));
    });

    test('strips filler words', () {
      expect(p.resolveLocation('weather in chennai')?.name, equals('Chennai'));
      expect(p.resolveLocation('city of delhi')?.name, equals('New Delhi'));
    });

    test('partial name match', () {
      expect(p.resolveLocation('bengal')?.name, isNotNull);
    });

    test('returns null for gibberish', () {
      expect(p.resolveLocation('xyzqwerty123'), isNull);
    });
  });

  // ── resolveArea ───────────────────────────────────────────────
  group('LocationProvider.resolveArea()', () {
    late LocationProvider p;
    setUp(() { p = LocationProvider(); });

    test('exact area name matches within city', () {
      final area = p.resolveArea('Rohini');
      expect(area?.name, equals('Rohini'));
      expect(area?.cityName, equals('New Delhi'));
    });

    test('partial area name matches', () {
      expect(p.resolveArea('Connaught')?.name, equals('Connaught Place'));
    });

    test('returns null for area in another city', () {
      expect(p.resolveArea('Bandra'), isNull);
    });

    test('returns null for gibberish', () {
      expect(p.resolveArea('xyzzznotanarea'), isNull);
    });
  });

  // ── selectCity / selectArea / clearArea ───────────────────────
  group('LocationProvider selection flow', () {
    test('selecting city resets area', () async {
      final p     = LocationProvider();
      final delhi = kSupportedCities.firstWhere((c) => c.name == 'New Delhi');
      final area  = kCityAreas.firstWhere((a) => a.cityName == 'New Delhi');
      await p.selectCity(delhi);
      await p.selectArea(area);
      expect(p.isAreaSelected, isTrue);

      final mumbai = kSupportedCities.firstWhere((c) => c.name == 'Mumbai');
      await p.selectCity(mumbai);
      expect(p.isAreaSelected, isFalse);
      expect(p.locationLabel, equals('Mumbai'));
    });

    test('area coords take priority over city coords', () async {
      final p    = LocationProvider();
      final area = kCityAreas.firstWhere(
          (a) => a.cityName == 'New Delhi' && a.name == 'Dwarka');
      await p.selectArea(area);
      expect(p.latitude,  closeTo(area.latitude,  0.001));
      expect(p.longitude, closeTo(area.longitude, 0.001));
    });

    test('clearArea reverts to city coords', () async {
      final p    = LocationProvider();
      final area = kCityAreas.firstWhere((a) => a.cityName == 'New Delhi');
      await p.selectArea(area);
      await p.clearArea();
      expect(p.isAreaSelected, isFalse);
      expect(p.latitude,  closeTo(p.selectedCity.latitude,  0.001));
      expect(p.longitude, closeTo(p.selectedCity.longitude, 0.001));
    });

    test('locationLabel shows area + city when area selected', () async {
      final p    = LocationProvider();
      final area = kCityAreas.firstWhere(
          (a) => a.cityName == 'New Delhi' && a.name == 'Rohini');
      await p.selectArea(area);
      expect(p.locationLabel, equals('Rohini, New Delhi'));
    });
  });

  // ── CustomLocation ────────────────────────────────────────────
  group('CustomLocation model', () {
    const custom = CustomLocation(
      displayName: 'Connaught Place, New Delhi, Delhi, India',
      shortLabel : 'Connaught Place',
      city       : 'New Delhi',
      state      : 'Delhi',
      latitude   : 28.6315,
      longitude  : 77.2167,
    );

    test('locationLabel returns shortLabel', () {
      expect(custom.locationLabel, equals('Connaught Place'));
    });

    test('isGps defaults to false', () {
      expect(custom.isGps, isFalse);
    });

    test('isGps can be set true', () {
      const gps = CustomLocation(
        displayName: 'Somewhere, India',
        shortLabel : 'Somewhere',
        city: '', state: '',
        latitude : 12.345,
        longitude: 77.123,
        isGps    : true,
      );
      expect(gps.isGps, isTrue);
    });
  });

  // ── setCustomLocation / clearCustomLocation ───────────────────
  group('LocationProvider.setCustomLocation()', () {
    test('overrides coords and locationLabel', () async {
      final p = LocationProvider();
      await p.setCustomLocation(const CustomLocation(
        displayName: 'Leh, Ladakh, India',
        shortLabel : 'Leh',
        city: 'Leh', state: 'Ladakh',
        latitude : 34.1526,
        longitude: 77.5771,
      ));
      expect(p.isCustomLocation, isTrue);
      expect(p.locationLabel, equals('Leh'));
      expect(p.latitude,  closeTo(34.1526, 0.001));
      expect(p.longitude, closeTo(77.5771, 0.001));
    });

    test('clearCustomLocation reverts to city', () async {
      final p = LocationProvider();
      await p.setCustomLocation(const CustomLocation(
        displayName: 'Test, India', shortLabel: 'Test',
        city: '', state: '', latitude: 20.0, longitude: 80.0,
      ));
      await p.clearCustomLocation();
      expect(p.isCustomLocation, isFalse);
      expect(p.locationLabel, equals('New Delhi'));
    });

    test('selectCity clears custom location', () async {
      final p = LocationProvider();
      await p.setCustomLocation(const CustomLocation(
        displayName: 'Test, India', shortLabel: 'Test',
        city: '', state: '', latitude: 20.0, longitude: 80.0,
      ));
      final mumbai = kSupportedCities.firstWhere((c) => c.name == 'Mumbai');
      await p.selectCity(mumbai);
      expect(p.isCustomLocation, isFalse);
      expect(p.locationLabel, equals('Mumbai'));
    });

    test('coords update correctly for remote location', () async {
      final p = LocationProvider();
      await p.setCustomLocation(const CustomLocation(
        displayName: 'Andaman Islands, India',
        shortLabel : 'Port Blair',
        city: 'Port Blair', state: 'Andaman & Nicobar',
        latitude : 11.6234,
        longitude: 92.7265,
      ));
      expect(p.latitude,  closeTo(11.6234, 0.001));
      expect(p.longitude, closeTo(92.7265, 0.001));
    });
  });

  // ── filteredCities ────────────────────────────────────────────
  group('LocationProvider.filteredCities', () {
    test('empty query returns all cities', () {
      final p = LocationProvider();
      p.setSearchQuery('');
      expect(p.filteredCities.length, equals(kSupportedCities.length));
    });

    test('query filters by name', () {
      final p = LocationProvider();
      p.setSearchQuery('mum');
      expect(p.filteredCities.any((c) => c.name == 'Mumbai'), isTrue);
    });

    test('query filters by state', () {
      final p = LocationProvider();
      p.setSearchQuery('karnataka');
      expect(p.filteredCities
          .every((c) => c.state.toLowerCase().contains('karnataka')), isTrue);
    });

    test('no match returns empty list', () {
      final p = LocationProvider();
      p.setSearchQuery('zzznomatch999');
      expect(p.filteredCities, isEmpty);
    });
  });

  // ── filteredAreas ─────────────────────────────────────────────
  group('LocationProvider.filteredAreas', () {
    test('empty query returns all areas for city', () async {
      final p = LocationProvider();
      final mumbai = kSupportedCities.firstWhere((c) => c.name == 'Mumbai');
      await p.selectCity(mumbai);
      p.setAreaSearchQuery('');
      expect(p.filteredAreas.length,
          equals(kCityAreas.where((a) => a.cityName == 'Mumbai').length));
    });

    test('query filters areas correctly', () async {
      final p = LocationProvider();
      final mumbai = kSupportedCities.firstWhere((c) => c.name == 'Mumbai');
      await p.selectCity(mumbai);
      p.setAreaSearchQuery('and');
      expect(p.filteredAreas.any((a) => a.name == 'Andheri'), isTrue);
    });
  });

  // ── GeocodingResult model ─────────────────────────────────────
  group('GeocodingResult.fromJson()', () {
    test('parses India result correctly', () {
      final r = GeocodingResult.fromJson({
        'display_name': 'Bandra, Mumbai, Maharashtra, India',
        'lat': '19.0596', 'lon': '72.8295',
        'type': 'suburb', 'class': 'place',
        'osm_type': 'W', 'osm_id': '12345678',
        'address': {
          'suburb' : 'Bandra',
          'city'   : 'Mumbai',
          'state'  : 'Maharashtra',
          'country': 'India',
        },
      });
      expect(r.city,      equals('Mumbai'));
      expect(r.state,     equals('Maharashtra'));
      expect(r.latitude,  closeTo(19.0596, 0.001));
      expect(r.longitude, closeTo(72.8295, 0.001));
      expect(r.isIndia,   isTrue);
      expect(r.osmId,     equals('W12345678'));
    });

    test('isIndia returns false for non-India result', () {
      final r = GeocodingResult.fromJson({
        'display_name': 'London, UK',
        'lat': '51.5074', 'lon': '-0.1278',
        'type': 'city', 'class': 'place',
        'osm_type': 'R', 'osm_id': '99',
        'address': {'city': 'London', 'country': 'United Kingdom'},
      });
      expect(r.isIndia, isFalse);
    });

    test('label is non-empty for valid result', () {
      final r = GeocodingResult.fromJson({
        'display_name': 'Koramangala, Bengaluru, Karnataka, India',
        'lat': '12.9352', 'lon': '77.6245',
        'type': 'suburb', 'class': 'place',
        'osm_type': 'W', 'osm_id': '777',
        'address': {
          'neighbourhood': 'Koramangala',
          'city'  : 'Bengaluru',
          'state' : 'Karnataka',
          'country': 'India',
        },
      });
      expect(r.label.isNotEmpty, isTrue);
      expect(r.isIndia, isTrue);
    });

    test('zero coords when lat/lon are empty strings', () {
      final r = GeocodingResult.fromJson({
        'display_name': 'Bad Result',
        'lat': '', 'lon': '',
        'type': 'place', 'class': 'place',
        'osm_type': 'N', 'osm_id': '0',
        'address': {'country': 'India'},
      });
      expect(r.latitude,  equals(0.0));
      expect(r.longitude, equals(0.0));
    });
  });

} // end main()

// ─────────────────────────────────────────────────────────────
// Custom matchers
// ─────────────────────────────────────────────────────────────
const Matcher isNonZero = _IsNonZero();

class _IsNonZero extends Matcher {
  const _IsNonZero();

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) =>
      item is num && item != 0;

  @override
  Description describe(Description d) => d.add('a non-zero number');
}
