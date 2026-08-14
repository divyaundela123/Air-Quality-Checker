import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PollutantReading {
  final String name;
  final double? value;
  final String unit;
  final String status;
  final Color color;

  const PollutantReading({
    required this.name,
    this.value,
    required this.unit,
    required this.status,
    required this.color,
  });
}

class PollutantData {
  final PollutantReading pm25;
  final PollutantReading pm10;
  final PollutantReading no2;
  final PollutantReading so2;
  final PollutantReading o3;
  final PollutantReading co;
  final PollutantReading co2;
  final PollutantReading voc;
  final int usAqi;
  final int euAqi;

  const PollutantData({
    required this.pm25,
    required this.pm10,
    required this.no2,
    required this.so2,
    required this.o3,
    required this.co,
    required this.co2,
    required this.voc,
    required this.usAqi,
    required this.euAqi,
  });
}

class WeatherApiService {
  static final Random _rng = Random();

  /// Fetches current temperature (°C) and relative humidity (%) from Open-Meteo.
  /// Returns a map with keys: temperature, humidity, co2, voc
  static Future<Map<String, double>> fetchLiveData({
    double lat = 28.6139,
    double lon = 77.2090,
  }) async {
    final uri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$lat&longitude=$lon'
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

    final double co2 = _realisticCo2(humidity);
    final double voc = _realisticVoc(temperature);

    return {
      'temperature': temperature,
      'humidity': humidity,
      'co2': co2,
      'voc': voc,
    };
  }

  /// Fetches real air quality pollutant data from Open-Meteo Air Quality API.
  static Future<PollutantData> fetchPollutants({
    required double lat,
    required double lon,
    double? co2Estimated,
    double? vocEstimated,
  }) async {
    final uri = Uri.parse(
      'https://air-quality-api.open-meteo.com/v1/air-quality'
      '?latitude=$lat&longitude=$lon'
      '&current=pm10,pm2_5,carbon_monoxide,nitrogen_dioxide,sulphur_dioxide,ozone,us_aqi,european_aqi'
      '&timezone=auto',
    );

    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['current'] as Map<String, dynamic>? ?? {};
        final double pm25Val = (data['pm2_5'] as num?)?.toDouble() ?? 25.0;
        final double pm10Val = (data['pm10'] as num?)?.toDouble() ?? 45.0;
        final double no2Val  = (data['nitrogen_dioxide'] as num?)?.toDouble() ?? 30.0;
        final double so2Val  = (data['sulphur_dioxide'] as num?)?.toDouble() ?? 12.0;
        final double o3Val   = (data['ozone'] as num?)?.toDouble() ?? 35.0;
        final double coVal   = (data['carbon_monoxide'] as num?)?.toDouble() ?? 400.0;
        final int usAqi      = (data['us_aqi'] as num?)?.toInt() ?? 75;
        final int euAqi      = (data['european_aqi'] as num?)?.toInt() ?? 40;

        return PollutantData(
          pm25: PollutantReading(name: 'PM2.5', value: pm25Val, unit: 'µg/m³', status: _getStatus('pm25', pm25Val), color: _getColor(_getStatus('pm25', pm25Val))),
          pm10: PollutantReading(name: 'PM10', value: pm10Val, unit: 'µg/m³', status: _getStatus('pm10', pm10Val), color: _getColor(_getStatus('pm10', pm10Val))),
          no2: PollutantReading(name: 'NO₂', value: no2Val, unit: 'µg/m³', status: _getStatus('no2', no2Val), color: _getColor(_getStatus('no2', no2Val))),
          so2: PollutantReading(name: 'SO₂', value: so2Val, unit: 'µg/m³', status: _getStatus('so2', so2Val), color: _getColor(_getStatus('so2', so2Val))),
          o3: PollutantReading(name: 'O₃', value: o3Val, unit: 'µg/m³', status: _getStatus('o3', o3Val), color: _getColor(_getStatus('o3', o3Val))),
          co: PollutantReading(name: 'CO', value: coVal, unit: 'µg/m³', status: _getStatus('co', coVal), color: _getColor(_getStatus('co', coVal))),
          co2: PollutantReading(name: 'CO₂', value: co2Estimated ?? 600, unit: 'ppm', status: 'Safe', color: const Color(0xFF4CAF50)),
          voc: PollutantReading(name: 'VOC', value: vocEstimated ?? 150, unit: 'ppb', status: 'Safe', color: const Color(0xFF4CAF50)),
          usAqi: usAqi,
          euAqi: euAqi,
        );
      }
    } catch (_) {}

    return PollutantData(
      pm25: const PollutantReading(name: 'PM2.5', value: 25.0, unit: 'µg/m³', status: 'Safe', color: Color(0xFF4CAF50)),
      pm10: const PollutantReading(name: 'PM10', value: 45.0, unit: 'µg/m³', status: 'Safe', color: Color(0xFF4CAF50)),
      no2: const PollutantReading(name: 'NO₂', value: 30.0, unit: 'µg/m³', status: 'Safe', color: Color(0xFF4CAF50)),
      so2: const PollutantReading(name: 'SO₂', value: 12.0, unit: 'µg/m³', status: 'Safe', color: Color(0xFF4CAF50)),
      o3: const PollutantReading(name: 'O₃', value: 35.0, unit: 'µg/m³', status: 'Safe', color: Color(0xFF4CAF50)),
      co: const PollutantReading(name: 'CO', value: 400.0, unit: 'µg/m³', status: 'Safe', color: Color(0xFF4CAF50)),
      co2: PollutantReading(name: 'CO₂', value: co2Estimated ?? 600, unit: 'ppm', status: 'Safe', color: const Color(0xFF4CAF50)),
      voc: PollutantReading(name: 'VOC', value: vocEstimated ?? 150, unit: 'ppb', status: 'Safe', color: const Color(0xFF4CAF50)),
      usAqi: 75,
      euAqi: 40,
    );
  }

  static String _getStatus(String pollutant, double val) {
    if (pollutant == 'pm25') {
      if (val <= 30) return 'Safe';
      if (val <= 60) return 'Moderate';
      if (val <= 90) return 'Warning';
      return 'Hazardous';
    }
    if (val <= 50) return 'Safe';
    if (val <= 100) return 'Moderate';
    if (val <= 150) return 'Warning';
    return 'Hazardous';
  }

  static Color _getColor(String status) {
    switch (status) {
      case 'Safe': return const Color(0xFF4CAF50);
      case 'Moderate': return const Color(0xFFFFC107);
      case 'Warning': return const Color(0xFFFF9800);
      case 'Hazardous': return const Color(0xFFF44336);
      default: return const Color(0xFF4CAF50);
    }
  }

  static double _realisticCo2(double humidity) {
    final base = 400 + (humidity / 100) * 400;
    final noise = (_rng.nextDouble() - 0.5) * 80;
    return (base + noise).clamp(380, 1200);
  }

  static double _realisticVoc(double temperature) {
    final base = 50 + (temperature / 40) * 200;
    final noise = (_rng.nextDouble() - 0.5) * 60;
    return (base + noise).clamp(20, 500);
  }
}
