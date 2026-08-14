// ============================================================
// AeroSense — ML Prediction Service  (v2)
// Calls Node.js backend → Python Flask ML API.
// Supports:
//   - Standard 1-hour prediction  (predict)
//   - Multi-hour future forecast   (predictFuture)
//   - Real pollutant inputs        (PM2.5, PM10, NO2, SO2, O3, CO)
//   - Graceful fallback when ML is offline
// ============================================================

import 'package:dio/dio.dart';
import 'api_service.dart';

// ─────────────────────────────────────────────────────────────
// Data models
// ─────────────────────────────────────────────────────────────

class MlForecastHour {
  final String hour;
  final double predictedAqi;
  final String status;
  final String source; // 'ml_model' | 'extrapolation'

  const MlForecastHour({
    required this.hour,
    required this.predictedAqi,
    required this.status,
    this.source = 'ml_model',
  });

  factory MlForecastHour.fromJson(Map<String, dynamic> j) => MlForecastHour(
    hour         : j['hour']           as String? ?? '+1h',
    predictedAqi : (j['predicted_aqi'] as num?)?.toDouble() ?? 0.0,
    status       : j['status']         as String? ?? 'Safe',
    source       : j['source']         as String? ?? 'ml_model',
  );
}

class MlAlert {
  final String level;   // 'critical' | 'warning' | 'info' | 'success'
  final String message;

  const MlAlert({required this.level, required this.message});

  factory MlAlert.fromJson(Map<String, dynamic> j) => MlAlert(
    level  : j['level']   as String? ?? 'info',
    message: j['message'] as String? ?? '',
  );
}

/// A single hourly entry from the future-forecast endpoint.
class MlFuturePoint {
  final int    hour;
  final String datetime;
  final double predictedAqi;
  final String status;
  final String trend;

  const MlFuturePoint({
    required this.hour,
    required this.datetime,
    required this.predictedAqi,
    required this.status,
    required this.trend,
  });

  factory MlFuturePoint.fromJson(Map<String, dynamic> j) => MlFuturePoint(
    hour         : (j['hour']          as num?)?.toInt()    ?? 0,
    datetime     : j['datetime']       as String? ?? '',
    predictedAqi : (j['predicted_aqi'] as num?)?.toDouble() ?? 0.0,
    status       : j['status']         as String? ?? 'Safe',
    trend        : j['trend']          as String? ?? 'stable',
  );
}

/// Result of the multi-hour future forecast endpoint.
class MlFutureForecast {
  final double              baseAqi;
  final String              baseStatus;
  final int                 hoursAhead;
  final List<MlFuturePoint> predictions;
  final String              modelSource;
  final double              mae;
  final String              dataNote;

  const MlFutureForecast({
    required this.baseAqi,
    required this.baseStatus,
    required this.hoursAhead,
    required this.predictions,
    required this.modelSource,
    required this.mae,
    required this.dataNote,
  });

  factory MlFutureForecast.fromJson(Map<String, dynamic> j) => MlFutureForecast(
    baseAqi    : (j['base_aqi']    as num?)?.toDouble() ?? 0.0,
    baseStatus : j['base_status']  as String? ?? 'Safe',
    hoursAhead : (j['hours_ahead'] as num?)?.toInt()    ?? 6,
    predictions: (j['predictions'] as List<dynamic>? ?? [])
        .map((e) => MlFuturePoint.fromJson(e as Map<String, dynamic>))
        .toList(),
    modelSource: j['model_source'] as String? ?? 'unknown',
    mae        : (j['mae']         as num?)?.toDouble() ?? 5.0,
    dataNote   : j['data_note']    as String? ?? '',
  );

  factory MlFutureForecast.offline() => const MlFutureForecast(
    baseAqi    : 0, baseStatus: 'Safe', hoursAhead: 0,
    predictions: [], modelSource: 'offline', mae: 0,
    dataNote   : 'ML service offline.',
  );
}

class MlPrediction {
  final double currentAqi;
  final double predictedAqi;
  final String predictionHorizon;
  final String currentStatus;
  final String predictedStatus;
  final String trend;         // 'stable' | 'improving' | 'worsening'
  final String change;        // e.g. '+3.2 AQI'
  final double confidence;    // 0.0 – 1.0
  final String confidencePct;
  final List<MlAlert>        alerts;
  final List<MlForecastHour> forecast3h;
  final String source;
  final double mae;
  final bool   isOnline;
  final bool   hasRealPollutants; // true when PM2.5/PM10/etc. from real API
  final String dataNote;          // transparency message shown in UI

  const MlPrediction({
    required this.currentAqi,
    required this.predictedAqi,
    required this.predictionHorizon,
    required this.currentStatus,
    required this.predictedStatus,
    required this.trend,
    required this.change,
    required this.confidence,
    required this.confidencePct,
    required this.alerts,
    required this.forecast3h,
    required this.source,
    required this.mae,
    required this.isOnline,
    this.hasRealPollutants = false,
    this.dataNote          = '',
  });

  factory MlPrediction.fromJson(Map<String, dynamic> j) {
    final alertList = (j['alerts'] as List<dynamic>? ?? [])
        .map((a) => MlAlert.fromJson(a as Map<String, dynamic>))
        .toList();
    final forecastList = (j['forecast_3h'] as List<dynamic>? ?? [])
        .map((f) => MlForecastHour.fromJson(f as Map<String, dynamic>))
        .toList();

    final src = j['source']       as String? ??
                j['model_source'] as String? ?? 'unknown';

    // Parse real_pollutants flag from nested inputs object
    final inputs = j['inputs'] as Map<String, dynamic>? ?? {};
    final hasReal = inputs['real_pollutants'] as bool? ?? false;

    return MlPrediction(
      currentAqi         : (j['current_aqi']    as num?)?.toDouble() ?? 0.0,
      predictedAqi       : (j['predicted_aqi']  as num?)?.toDouble() ?? 0.0,
      predictionHorizon  : j['prediction_horizon'] as String? ?? '1 hour',
      currentStatus      : j['current_status']  as String? ?? 'Safe',
      predictedStatus    : j['predicted_status'] as String? ?? 'Safe',
      trend              : j['trend']            as String? ?? 'stable',
      change             : j['change']           as String? ?? '0 AQI',
      confidence         : (j['confidence']      as num?)?.toDouble() ?? 0.72,
      confidencePct      : j['confidence_pct']   as String? ?? '72%',
      alerts             : alertList,
      forecast3h         : forecastList,
      source             : src,
      mae                : (j['mae']             as num?)?.toDouble() ?? 5.0,
      isOnline           : src.contains('python') || src.contains('ml_model'),
      hasRealPollutants  : hasReal,
      dataNote           : j['data_note'] as String? ?? '',
    );
  }

  factory MlPrediction.offline(double currentAqi, String currentStatus) =>
      MlPrediction(
        currentAqi         : currentAqi,
        predictedAqi       : currentAqi,
        predictionHorizon  : '1 hour',
        currentStatus      : currentStatus,
        predictedStatus    : currentStatus,
        trend              : 'stable',
        change             : '0 AQI',
        confidence         : 0.0,
        confidencePct      : '–',
        alerts             : const [MlAlert(level: 'info',
            message: '⚠️ ML service offline — connect to server for predictions.')],
        forecast3h         : const [],
        source             : 'offline',
        mae                : 0.0,
        isOnline           : false,
        dataNote           : 'ML service is not reachable.',
      );
}

// ─────────────────────────────────────────────────────────────
// Input model
// ─────────────────────────────────────────────────────────────

/// All available sensor inputs for an ML prediction.
/// Pass whatever your data source provides — the Python API
/// fills in missing fields with realistic defaults.
class MlInputs {
  // Core sensors (always available from Open-Meteo)
  final double temperature;
  final double humidity;

  // Pollutants from real API (optional — improves accuracy)
  final double? pm25;
  final double? pm10;
  final double? no2;
  final double? so2;
  final double? o3;
  final double? co; // µg/m³

  // Legacy sensor values (used when no real pollutants available)
  final double? co2; // ppm
  final double? voc; // ppb

  // Location for area-specific context
  final double lat;
  final double lon;

  const MlInputs({
    required this.temperature,
    required this.humidity,
    this.pm25,
    this.pm10,
    this.no2,
    this.so2,
    this.o3,
    this.co,
    this.co2,
    this.voc,
    this.lat = 28.6139,
    this.lon  = 77.2090,
  });

  Map<String, dynamic> toJson() => {
    'temperature': temperature,
    'humidity'   : humidity,
    if (pm25 != null) 'pm25': pm25,
    if (pm10 != null) 'pm10': pm10,
    if (no2  != null) 'no2' : no2,
    if (so2  != null) 'so2' : so2,
    if (o3   != null) 'o3'  : o3,
    if (co   != null) 'co'  : co,
    if (co2  != null) 'co2' : co2,
    if (voc  != null) 'voc' : voc,
    'lat': lat,
    'lon': lon,
  };
}

// ─────────────────────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────────────────────

class MlPredictionService {
  static final Dio _dio = ApiService.dio;

  /// Dedicated Dio for ML — no auth header, longer timeout.
  static final Dio _mlDio = Dio(BaseOptions(
    baseUrl        : 'http://localhost:3000',
    connectTimeout : const Duration(seconds: 10),
    receiveTimeout : const Duration(seconds: 15),
    headers        : {'Content-Type': 'application/json'},
  ));

  // ── 1-hour prediction ─────────────────────────────────────

  /// Primary prediction method. Accepts full [MlInputs] so all
  /// available sensor data — including real pollutants — is sent.
  static Future<MlPrediction> predict(MlInputs inputs) async {
    try {
      final res = await _mlDio.post('/api/ml/predict', data: inputs.toJson());
      return MlPrediction.fromJson(Map<String, dynamic>.from(res.data as Map));
    } catch (_) {
      return MlPrediction.offline(0, 'Safe');
    }
  }

  /// Legacy overload — kept for callers that only have temperature/humidity/CO2/VOC.
  static Future<MlPrediction> predictLegacy({
    required double temperature,
    required double humidity,
    required double co2,
    required double voc,
    double lat = 28.6139,
    double lon = 77.2090,
  }) => predict(MlInputs(
    temperature: temperature,
    humidity   : humidity,
    co2        : co2,
    voc        : voc,
    lat        : lat,
    lon        : lon,
  ));

  // ── Multi-hour future forecast ─────────────────────────────

  /// Returns hourly AQI predictions for the next [hours] hours (max 24).
  /// Requires the Python ML API to be running; returns an empty
  /// [MlFutureForecast] if offline.
  static Future<MlFutureForecast> predictFuture({
    required MlInputs inputs,
    int hours = 6,
  }) async {
    try {
      final body = {
        ...inputs.toJson(),
        'hours': hours.clamp(1, 24),
      };
      final res = await _mlDio.post('/api/ml/predict/future', data: body);
      return MlFutureForecast.fromJson(
          Map<String, dynamic>.from(res.data as Map));
    } catch (_) {
      return MlFutureForecast.offline();
    }
  }

  // ── Health check ───────────────────────────────────────────

  static Future<bool> checkMlHealth() async {
    try {
      final res = await _dio.get('/api/ml/health');
      return res.data['ml_api'] == 'online';
    } catch (_) {
      return false;
    }
  }
}
