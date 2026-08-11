import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class WeatherApiService {
  // Open-Meteo — completely free, no API key required
  // Using a fixed lat/lon (New Delhi, India) — change to your city as needed
  static const double _lat = 28.6139;
  static const double _lon = 77.2090;

  static final Random _rng = Random();

  /// Fetches current temperature (°C) and relative humidity (%) from Open-Meteo.
  /// Returns a map with keys: temperature, humidity, co2, voc
  static Future<Map<String, double>> fetchLiveData() async {
    final uri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$_lat&longitude=$_lon'
      '&current=temperature_2m,relative_humidity_2m'
      '&timezone=auto',
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Open-Meteo API error: ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final current = json['current'] as Map<String, dynamic>;

    final double temperature =
        (current['temperature_2m'] as num).toDouble();
    final double humidity =
        (current['relative_humidity_2m'] as num).toDouble();

    // CO2 and VOC: realistic ambient simulation
    // Typical indoor CO2: 400–1200 ppm; VOC: 50–500 ppb
    final double co2 = _realisticCo2(humidity);
    final double voc = _realisticVoc(temperature);

    return {
      'temperature': temperature,
      'humidity': humidity,
      'co2': co2,
      'voc': voc,
    };
  }

  /// Ambient CO2 correlated loosely with humidity (stuffiness proxy)
  static double _realisticCo2(double humidity) {
    final base = 400 + (humidity / 100) * 400; // 400–800 base
    final noise = (_rng.nextDouble() - 0.5) * 80; // ±40 ppm noise
    return (base + noise).clamp(380, 1200);
  }

  /// Ambient VOC correlated loosely with temperature (off-gassing proxy)
  static double _realisticVoc(double temperature) {
    final base = 50 + (temperature / 40) * 200; // 50–250 base
    final noise = (_rng.nextDouble() - 0.5) * 60; // ±30 ppb noise
    return (base + noise).clamp(20, 500);
  }
}
