import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/aqi_record.dart';
import '../services/mock_ai_service.dart';
import '../services/weather_api_service.dart';
import '../services/aqi_api_service.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class AqiProvider extends ChangeNotifier {
  static const String _boxName = 'aqi_records';

  List<AqiRecord> _records        = [];
  bool            _isLoading      = false;
  bool            _isFetchingLive = false;
  bool            _isSyncing      = false;
  AqiRecord?      _latestRecord;
  DateTime?       _lastUpdated;
  String?         _liveError;
  String?         _syncError;
  Timer?          _liveTimer;
  Timer?          _cloudPollTimer;

  // Live Open-Meteo sensor values
  double _liveTemp     = 0;
  double _liveHumidity = 0;
  double _liveCo2      = 0;
  double _liveVoc      = 0;

  // ── Getters ─────────────────────────────────────────────────
  List<AqiRecord> get records        => _records;
  bool            get isLoading      => _isLoading;
  bool            get isFetchingLive => _isFetchingLive;
  bool            get isSyncing      => _isSyncing;
  AqiRecord?      get latestRecord   => _latestRecord;
  DateTime?       get lastUpdated    => _lastUpdated;
  String?         get liveError      => _liveError;
  String?         get syncError      => _syncError;
  bool            get hasLiveData    => _liveTemp != 0;

  double get latestAqi    => _latestRecord?.aqiScore  ?? 0;
  String get latestStatus => _latestRecord?.status    ?? 'Safe';
  double get latestTemperature => _liveTemp     != 0 ? _liveTemp     : (_latestRecord?.temperature ?? 0);
  double get latestHumidity    => _liveHumidity != 0 ? _liveHumidity : (_latestRecord?.humidity    ?? 0);
  double get latestCo2         => _liveCo2      != 0 ? _liveCo2      : (_latestRecord?.co2         ?? 0);
  double get latestVoc         => _liveVoc      != 0 ? _liveVoc      : (_latestRecord?.voc         ?? 0);

  AqiProvider() {
    _loadLocalThenCloud();
    _startLiveSensorFetch();
    _startCloudPoll();
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    _cloudPollTimer?.cancel();
    super.dispose();
  }

  // ── 1. Live sensor data (Open-Meteo, every 30s) ──────────────
  void _startLiveSensorFetch() {
    fetchLiveData();
    _liveTimer = Timer.periodic(const Duration(seconds: 30), (_) => fetchLiveData());
  }

  Future<void> fetchLiveData() async {
    _isFetchingLive = true; _liveError = null; notifyListeners();
    try {
      final d = await WeatherApiService.fetchLiveData();
      _liveTemp     = d['temperature']!;
      _liveHumidity = d['humidity']!;
      _liveCo2      = d['co2']!;
      _liveVoc      = d['voc']!;
      _lastUpdated  = DateTime.now();
      _updateLiveRecord();
    } catch (e) {
      _liveError = 'Live sensor fetch failed';
      debugPrint('Live fetch error: $e');
    }
    _isFetchingLive = false; notifyListeners();
  }

  void _updateLiveRecord() {
    final score  = MockAiService.calculateAqi(
      temperature: _liveTemp, humidity: _liveHumidity,
      co2: _liveCo2, voc: _liveVoc);
    final status = MockAiService.getStatus(score);
    _latestRecord = AqiRecord(
      id: 'live', aqiScore: score, status: status,
      temperature: _liveTemp, humidity: _liveHumidity,
      co2: _liveCo2, voc: _liveVoc, timestamp: DateTime.now());

    // Fire push notification if status worsened
    NotificationService.checkAndNotifyStatusChange(
      status     : status,
      aqi        : score,
      temperature: _liveTemp,
      humidity   : _liveHumidity,
      co2        : _liveCo2,
      voc        : _liveVoc,
    );

    // Immediate danger alert for Hazardous / Warning
    if (status == 'Hazardous' || status == 'Warning') {
      NotificationService.showDangerAlert(status: status, aqi: score);
    }
  }

  // ── 2. Cloud polling every 10s ───────────────────────────────
  void _startCloudPoll() {
    _cloudPollTimer = Timer.periodic(
      const Duration(seconds: 10), (_) => _silentCloudSync());
  }

  Future<void> _silentCloudSync() async {
    final hasToken = await ApiService.hasToken;
    if (!hasToken) return;
    try {
      final cloudRecords = await AqiApiService.getRecords();
      final box = Hive.box<AqiRecord>(_boxName);
      bool changed = false;
      for (final r in cloudRecords) {
        if (!box.containsKey(r.id)) { await box.put(r.id, r); changed = true; }
      }
      if (changed) {
        _records = box.values.toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
        notifyListeners();
      }
    } catch (_) { /* silent — don't disturb UI */ }
  }

  // ── 3. Initial load — Hive first, then cloud ────────────────
  Future<void> _loadLocalThenCloud() async {
    _isLoading = true; notifyListeners();
    try {
      final box = Hive.box<AqiRecord>(_boxName);
      _records = box.values.toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) { debugPrint('Hive load error: $e'); }
    _isLoading = false; notifyListeners();
    await syncFromCloud();
  }

  // ── Full cloud sync (called on load + manual refresh) ───────
  Future<void> syncFromCloud() async {
    final hasToken = await ApiService.hasToken;
    if (!hasToken) return;

    _isSyncing = true; _syncError = null; notifyListeners();
    try {
      final cloudRecords = await AqiApiService.getRecords();
      final box = Hive.box<AqiRecord>(_boxName);

      // Cloud is source of truth — replace local with cloud data
      await box.clear();
      for (final r in cloudRecords) { await box.put(r.id, r); }
      _records = cloudRecords; // already sorted DESC from API
      _syncError = null;
    } catch (e) {
      _syncError = ApiService.parseError(e);
      debugPrint('Cloud sync error: $e');
    }
    _isSyncing = false; notifyListeners();
  }

  // ── Add record — local + cloud ───────────────────────────────
  Future<void> addRecord({
    required double temperature,
    required double humidity,
    required double co2,
    required double voc,
  }) async {
    final score  = MockAiService.calculateAqi(
        temperature: temperature, humidity: humidity, co2: co2, voc: voc);
    final status = MockAiService.getStatus(score);
    final record = AqiRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      aqiScore: score, status: status,
      temperature: temperature, humidity: humidity,
      co2: co2, voc: voc, timestamp: DateTime.now());

    // Save locally immediately
    final box = Hive.box<AqiRecord>(_boxName);
    await box.put(record.id, record);
    _records.insert(0, record);
    _latestRecord = record;
    notifyListeners();

    // Push to cloud in background
    _pushToCloud(record);

    // Notify user
    NotificationService.showAnalysisSaved(
        status: status, aqi: score);
  }

  Future<void> _pushToCloud(AqiRecord r) async {
    if (!await ApiService.hasToken) return;
    try {
      await AqiApiService.saveRecord(r);
      debugPrint('✅ Record ${r.id} synced to cloud');
    } catch (e) {
      debugPrint('Cloud push failed: $e');
    }
  }

  // ── Delete record ────────────────────────────────────────────
  Future<void> deleteRecord(AqiRecord record) async {
    final box = Hive.box<AqiRecord>(_boxName);
    await box.delete(record.id);
    _records.remove(record);
    _latestRecord = _records.isNotEmpty ? _records.first : null;
    notifyListeners();

    if (!await ApiService.hasToken) return;
    try { await AqiApiService.deleteRecord(record.id); }
    catch (e) { debugPrint('Cloud delete failed: $e'); }
  }

  // ── Clear all records ────────────────────────────────────────
  Future<void> clearAllRecords() async {
    final box = Hive.box<AqiRecord>(_boxName);
    await box.clear();
    _records.clear(); _latestRecord = null;
    notifyListeners();

    if (!await ApiService.hasToken) return;
    try { await AqiApiService.clearAllRecords(); }
    catch (e) { debugPrint('Cloud clear failed: $e'); }
  }

  // ── Analytics ────────────────────────────────────────────────
  List<AqiRecord> getRecordsForLastNDays(int n) {
    final cutoff = DateTime.now().subtract(Duration(days: n));
    return _records.where((r) => r.timestamp.isAfter(cutoff)).toList();
  }

  double get weeklyAvgAqi {
    final w = getRecordsForLastNDays(7);
    if (w.isEmpty) return 0;
    return w.map((r) => r.aqiScore).reduce((a, b) => a + b) / w.length;
  }
}
