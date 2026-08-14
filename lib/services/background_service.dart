// ============================================================
// AeroSense — True Background Notification Service
//
// Uses WorkManager to run an AQI check every 15 minutes —
// even when the app is FULLY CLOSED and removed from recents.
//
// Fires a notification every time it runs (app is closed, so
// the user needs to be alerted regardless of status change).
// ============================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'weather_api_service.dart';
import 'mock_ai_service.dart' show MockAiService;

const _taskName = 'aeroSenseAqiCheck';
const _taskTag  = 'aeroSenseAqiCheck';

// ─────────────────────────────────────────────────────────────
// TOP-LEVEL callback — MUST be a top-level function.
// WorkManager calls this in a separate isolate when the task fires.
// ─────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == _taskName) {
      await _runAqiCheck();
    }
    return Future.value(true);
  });
}

/// Initialise WorkManager and schedule the periodic task.
/// Call once from main() — safe to call multiple times (idempotent).
Future<void> initBackgroundService() async {
  if (kIsWeb || (defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS)) {
    debugPrint('ℹ️ WorkManager background service skipped (non-mobile platform: $defaultTargetPlatform)');
    return;
  }
  try {
    await Workmanager().initialize(
      callbackDispatcher,
    );

    await Workmanager().registerPeriodicTask(
      _taskTag,
      _taskName,
      frequency: const Duration(minutes: 15),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      backoffPolicy: BackoffPolicy.linear,
      backoffPolicyDelay: const Duration(minutes: 5),
    );

    debugPrint('✅ WorkManager background AQI task scheduled (every 15 min)');
  } catch (e) {
    debugPrint('WorkManager init failed: $e');
  }
}

// ─────────────────────────────────────────────────────────────
// Actual work — fetch AQI and show notification
// ─────────────────────────────────────────────────────────────
Future<void> _runAqiCheck() async {
  try {
    // Init notifications inside isolate (required — separate isolate has no state)
    final plugin = FlutterLocalNotificationsPlugin();
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await plugin.initialize(const InitializationSettings(android: androidInit));

    // Create high-priority notification channel
    await plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          'aqi_background',
          'AQI Background Monitor',
          description: 'Air quality alerts when app is closed',
          importance: Importance.high,
        ));

    // Fetch live sensor data
    final data = await WeatherApiService.fetchLiveData()
        .timeout(const Duration(seconds: 20));

    final aqi = MockAiService.calculateAqi(
      temperature: data['temperature']!,
      humidity   : data['humidity']!,
      co2        : data['co2']!,
      voc        : data['voc']!,
    );
    final status      = MockAiService.getStatus(aqi);
    final isDangerous = status == 'Warning' || status == 'Hazardous';

    // Always show when app is closed — user needs to know current air quality
    await plugin.show(
      901,
      _titleFor(status),
      'AQI ${aqi.toStringAsFixed(1)}  •  '
      '🌡 ${data['temperature']!.toStringAsFixed(1)}°C  '
      '💧 ${data['humidity']!.toStringAsFixed(0)}%  '
      '☁ ${data['co2']!.toStringAsFixed(0)} ppm',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'aqi_background',
          'AQI Background Monitor',
          channelDescription: 'Air quality alerts when app is closed',
          importance     : isDangerous ? Importance.max  : Importance.high,
          priority       : isDangerous ? Priority.max    : Priority.high,
          color          : _colorFor(status),
          playSound      : true,
          enableVibration: isDangerous,
          icon           : '@mipmap/ic_launcher',
          // Show as heads-up notification even when screen is on
          fullScreenIntent: isDangerous,
        ),
      ),
    );

    debugPrint('📣 Background notification sent: $status (AQI ${aqi.toStringAsFixed(1)})');
  } catch (e) {
    // Network may be unavailable — show a generic offline notification
    try {
      final plugin = FlutterLocalNotificationsPlugin();
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      await plugin.initialize(const InitializationSettings(android: androidInit));

      await plugin.show(
        902,
        '🌬️ AeroSense — Unable to fetch data',
        'Could not reach the sensor. Will retry in 15 minutes.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'aqi_background',
            'AQI Background Monitor',
            channelDescription: 'Air quality alerts when app is closed',
            importance: Importance.low,
            priority  : Priority.low,
            icon      : '@mipmap/ic_launcher',
          ),
        ),
      );
    } catch (_) {}

    debugPrint('Background AQI check failed: $e');
  }
}

String _titleFor(String status) {
  switch (status) {
    case 'Safe':      return '✅ AeroSense — Air Quality is Safe';
    case 'Moderate':  return 'ℹ️ AeroSense — Moderate Air Quality';
    case 'Warning':   return '⚠️ AeroSense — Air Quality Warning!';
    case 'Hazardous': return '🚨 AeroSense — HAZARDOUS Air Quality!';
    default:          return '🌬️ AeroSense — Air Quality Update';
  }
}

Color _colorFor(String status) {
  switch (status) {
    case 'Safe':      return const Color(0xFF4CAF50);
    case 'Moderate':  return const Color(0xFFFFC107);
    case 'Warning':   return const Color(0xFFFF9800);
    case 'Hazardous': return const Color(0xFFF44336);
    default:          return const Color(0xFF4B7FFF);
  }
}
