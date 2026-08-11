import 'package:dio/dio.dart';
import '../models/aqi_record.dart';
import 'api_service.dart';

/// Handles all /api/records/* calls.
class AqiApiService {
  static final Dio _dio = ApiService.dio;

  /// Fetch all records for the logged-in user, newest first.
  static Future<List<AqiRecord>> getRecords() async {
    final res = await _dio.get('/api/records');
    final list = res.data['records'] as List<dynamic>;
    return list.map((json) => _fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Save (upsert) a single record to the cloud.
  static Future<void> saveRecord(AqiRecord record) async {
    await _dio.post('/api/records', data: _toJson(record));
  }

  /// Delete one record by id.
  static Future<void> deleteRecord(String id) async {
    await _dio.delete('/api/records/$id');
  }

  /// Delete ALL records for the logged-in user.
  static Future<void> clearAllRecords() async {
    await _dio.delete('/api/records');
  }

  // ── JSON helpers ──────────────────────────────────────────────

  static Map<String, dynamic> _toJson(AqiRecord r) => {
    'id'         : r.id,
    'aqi_score'  : r.aqiScore,
    'status'     : r.status,
    'temperature': r.temperature,
    'humidity'   : r.humidity,
    'co2'        : r.co2,
    'voc'        : r.voc,
    'recorded_at': r.timestamp.toIso8601String(),
  };

  static AqiRecord _fromJson(Map<String, dynamic> j) => AqiRecord(
    id         : j['id'] as String,
    aqiScore   : (j['aqi_score']   as num).toDouble(),
    status     : j['status']       as String,
    temperature: (j['temperature'] as num).toDouble(),
    humidity   : (j['humidity']    as num).toDouble(),
    co2        : (j['co2']         as num).toDouble(),
    voc        : (j['voc']         as num).toDouble(),
    timestamp  : DateTime.parse(j['recorded_at'] as String),
  );
}
