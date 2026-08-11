import 'package:flutter/material.dart';

class MockAiService {
  /// Calculates the AQI score based on sensor inputs.
  /// Temperature in Celsius, Humidity in %, CO2 in ppm, VOC in ppb.
  static double calculateAqi({
    required double temperature,
    required double humidity,
    required double co2,
    required double voc,
  }) {
    final double baseAqi = (co2 * 0.05) +
        (voc * 0.2) +
        (temperature > 35 ? 30 : 0) +
        (humidity > 80 ? 10 : 0);

    // Clamp to a sensible max of 500
    return baseAqi.clamp(0, 500);
  }

  /// Returns the status string for a given AQI score.
  static String getStatus(double aqi) {
    if (aqi <= 50) return 'Safe';
    if (aqi <= 100) return 'Moderate';
    if (aqi <= 150) return 'Warning';
    return 'Hazardous';
  }

  /// Returns the color for a given AQI status.
  static Color getStatusColor(String status) {
    switch (status) {
      case 'Safe':
        return const Color(0xFF4CAF50); // Green
      case 'Moderate':
        return const Color(0xFFFFC107); // Yellow/Amber
      case 'Warning':
        return const Color(0xFFFF9800); // Orange
      case 'Hazardous':
        return const Color(0xFFF44336); // Red
      default:
        return const Color(0xFF4CAF50);
    }
  }

  /// Returns an icon for a given AQI status.
  static IconData getStatusIcon(String status) {
    switch (status) {
      case 'Safe':
        return Icons.check_circle;
      case 'Moderate':
        return Icons.info;
      case 'Warning':
        return Icons.warning;
      case 'Hazardous':
        return Icons.dangerous;
      default:
        return Icons.check_circle;
    }
  }

  /// Returns a recommendation message for a given status.
  static String getRecommendation(String status) {
    switch (status) {
      case 'Safe':
        return 'Air quality is optimal. Enjoy your environment!';
      case 'Moderate':
        return 'Air quality is acceptable. Sensitive individuals should limit prolonged outdoor exertion.';
      case 'Warning':
        return 'Consider improving ventilation by opening windows or turning on exhaust fans.';
      case 'Hazardous':
        return 'Dangerous levels detected! Please evacuate the area immediately and open doors if safe to do so.';
      default:
        return '';
    }
  }
}
