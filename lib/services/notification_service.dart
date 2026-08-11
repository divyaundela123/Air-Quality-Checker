import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Handles all in-app local push notifications for AeroSense.
/// Background notifications when app is CLOSED are handled by
/// WorkManager via background_service.dart.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialised = false;
  static String _lastStatus = '';

  // ── Channel IDs ───────────────────────────────────────────────
  static const String _channelIdAqi  = 'aqi_alerts';
  static const String _channelIdLive = 'live_sensor';

  // ── Notification IDs ─────────────────────────────────────────
  static const int _idStatusChange = 1;
  static const int _idWarning      = 2;
  static const int _idHazardous    = 3;
  static const int _idLive         = 4;

  /// Call once from main.dart before runApp().
  static Future<void> init() async {
    if (kIsWeb || _initialised) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios     = DarwinInitializationSettings(
      requestAlertPermission : true,
      requestBadgePermission : true,
      requestSoundPermission : true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onTap,
    );

    // Request notification permission on Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialised = true;
    debugPrint('✅ NotificationService initialised');
    // NOTE: Background (app closed) notifications handled by WorkManager
  }

  static void _onTap(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  // ── Android notification details helper ───────────────────────
  static AndroidNotificationDetails _androidDetails({
    required String channelId,
    required String channelName,
    required String channelDesc,
    Importance importance = Importance.high,
    Priority   priority  = Priority.high,
    Color?     color,
  }) =>
      AndroidNotificationDetails(
        channelId, channelName,
        channelDescription: channelDesc,
        importance        : importance,
        priority          : priority,
        color             : color,
        playSound         : true,
        enableVibration   : true,
        styleInformation  : const BigTextStyleInformation(''),
        icon              : '@mipmap/ic_launcher',
      );

  // ── Public notification triggers ─────────────────────────────

  /// Called every time the live AQI status is recalculated.
  /// Only fires a notification when the status **changes**.
  static Future<void> checkAndNotifyStatusChange({
    required String status,
    required double aqi,
    required double temperature,
    required double humidity,
    required double co2,
    required double voc,
  }) async {
    if (kIsWeb || !_initialised) return;
    if (status == _lastStatus) return;   // no change — skip

    final prev = _lastStatus;
    _lastStatus = status;

    // Only notify if worsening or if there's a meaningful first read
    final levels = ['Safe', 'Moderate', 'Warning', 'Hazardous'];
    final prevIdx = levels.indexOf(prev);
    final currIdx = levels.indexOf(status);

    if (prev.isNotEmpty && currIdx <= prevIdx) return; // improving — skip

    await _showStatusChangeNotification(
        status: status, aqi: aqi,
        temperature: temperature, humidity: humidity,
        co2: co2, voc: voc);
  }

  static Future<void> _showStatusChangeNotification({
    required String status,
    required double aqi,
    required double temperature,
    required double humidity,
    required double co2,
    required double voc,
  }) async {
    final icon     = _iconFor(status);
    final title    = '$icon AeroSense — Air Quality $status';
    final body     =
        'AQI: ${aqi.toStringAsFixed(1)}  |  🌡 ${temperature.toStringAsFixed(1)}°C  '
        '💧 ${humidity.toStringAsFixed(0)}%  ☁ ${co2.toStringAsFixed(0)}ppm CO₂';
    final color    = _colorFor(status);

    final details  = NotificationDetails(
      android: _androidDetails(
        channelId  : _channelIdAqi,
        channelName: 'Air Quality Alerts',
        channelDesc: 'Alerts when air quality status changes',
        importance : status == 'Hazardous'
            ? Importance.max : Importance.high,
        priority   : status == 'Hazardous'
            ? Priority.max  : Priority.high,
        color      : color,
      ),
    );

    final id = status == 'Hazardous' ? _idHazardous
             : status == 'Warning'   ? _idWarning
             : _idStatusChange;

    await _plugin.show(id, title, body, details,
        payload: 'status_change:$status');

    debugPrint('📣 Notification sent: $title');
  }

  /// Fires a live sensor snapshot notification (call when user taps "Save Analysis").
  static Future<void> showAnalysisSaved({
    required String status,
    required double aqi,
  }) async {
    if (kIsWeb || !_initialised) return;
    final icon  = _iconFor(status);
    final title = '$icon Analysis Saved — AQI ${aqi.toStringAsFixed(1)}';
    final body  = 'Your air quality reading ($status) has been saved to history.';

    await _plugin.show(
      _idLive,
      title,
      body,
      NotificationDetails(
        android: _androidDetails(
          channelId  : _channelIdLive,
          channelName: 'Live Sensor',
          channelDesc: 'Notifications when analysis is saved',
          importance : Importance.defaultImportance,
          priority   : Priority.defaultPriority,
        ),
      ),
      payload: 'analysis_saved',
    );
  }

  /// Fires a high-priority alert for hazardous/warning levels specifically.
  static Future<void> showDangerAlert({
    required String status,
    required double aqi,
  }) async {
    if (kIsWeb || !_initialised) return;
    if (status != 'Hazardous' && status != 'Warning') return;

    final title = status == 'Hazardous'
        ? '🚨 DANGER — Hazardous Air Quality Detected!'
        : '⚠️ Warning — Poor Air Quality';
    final body  = status == 'Hazardous'
        ? 'AQI ${aqi.toStringAsFixed(1)} — Evacuate area immediately! '
          'Open doors and windows if safe to do so.'
        : 'AQI ${aqi.toStringAsFixed(1)} — Sensitive individuals should '
          'avoid prolonged outdoor exposure.';

    await _plugin.show(
      status == 'Hazardous' ? _idHazardous : _idWarning,
      title,
      body,
      NotificationDetails(
        android: _androidDetails(
          channelId  : _channelIdAqi,
          channelName: 'Air Quality Alerts',
          channelDesc: 'Critical air quality alerts',
          importance : Importance.max,
          priority   : Priority.max,
          color      : _colorFor(status),
        ),
      ),
      payload: 'danger:$status',
    );
  }

  /// Cancel all pending notifications.
  static Future<void> cancelAll() async {
    if (kIsWeb || !_initialised) return;
    await _plugin.cancelAll();
  }

  // ── Battery Optimisation helpers ──────────────────────────────

  static const _batteryChannel =
      MethodChannel('com.aerosense/battery');

  /// Returns true if this app is already exempt from battery optimisation.
  static Future<bool> isIgnoringBatteryOptimizations() async {
    if (kIsWeb) return true;
    try {
      final result = await _batteryChannel
          .invokeMethod<bool>('isIgnoringBatteryOptimizations');
      return result ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Opens the system dialog asking the user to exempt this app.
  static Future<void> requestIgnoreBatteryOptimizations() async {
    if (kIsWeb) return;
    try {
      await _batteryChannel
          .invokeMethod('requestIgnoreBatteryOptimizations');
    } catch (_) {}
  }

  // ── Helpers ───────────────────────────────────────────────────

  static String _iconFor(String status) {
    switch (status) {
      case 'Safe':      return '✅';
      case 'Moderate':  return 'ℹ️';
      case 'Warning':   return '⚠️';
      case 'Hazardous': return '🚨';
      default:          return '🌬️';
    }
  }

  static Color _colorFor(String status) {
    switch (status) {
      case 'Safe':      return const Color(0xFF4CAF50);
      case 'Moderate':  return const Color(0xFFFFC107);
      case 'Warning':   return const Color(0xFFFF9800);
      case 'Hazardous': return const Color(0xFFF44336);
      default:          return const Color(0xFF4B7FFF);
    }
  }
}
