import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/aqi_record.dart';
import '../services/mock_ai_service.dart';
import '../services/weather_api_service.dart';
import '../services/aqi_api_service.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/ml_prediction_service.dart';
import 'location_provider.dart';

class AqiProvider extends ChangeNotifier {
  static const String _boxName = 'aqi_records';

  // Optional LocationProvider — injected via setLocationProvider()
  LocationProvider? _locationProvider;

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

  // Live Open-Meteo Air Quality pollutant values
  PollutantData? _livePollutants;

  // ML Prediction
  MlPrediction? _mlPrediction;
  bool          _isFetchingMl = false;
  MlPrediction? get mlPrediction  => _mlPrediction;
  bool          get isFetchingMl  => _isFetchingMl;

  // Pollutants
  bool           _isFetchingPollutants = false;
  bool           get isFetchingPollutants => _isFetchingPollutants;
  PollutantData? get livePollutants       => _livePollutants;

  // Getters
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

  String get selectedCityName =>
      _locationProvider?.locationLabel ?? 'New Delhi';

  bool get isAreaSelected => _locationProvider?.isAreaSelected ?? false;

  String get selectedAreaType =>
      _locationProvider?.selectedArea?.type ?? '';

  double get latestTemperature => _liveTemp     != 0 ? _liveTemp     : (_latestRecord?.temperature ?? 0);
  double get latestHumidity    => _liveHumidity != 0 ? _liveHumidity : (_latestRecord?.humidity    ?? 0);
  double get latestCo2         => _liveCo2      != 0 ? _liveCo2      : (_latestRecord?.co2         ?? 0);
  double get latestVoc         => _liveVoc      != 0 ? _liveVoc      : (_latestRecord?.voc         ?? 0);

  AqiProvider() {
    _loadLocalThenCloud();
    _startLiveSensorFetch();
    _startCloudPoll();
  }

  void setLocationProvider(LocationProvider lp) {
    _locationProvider = lp;
    lp.addListener(_onCityChanged);
  }

  void _onCityChanged() {
    _liveTemp = 0; _liveHumidity = 0; _liveCo2 = 0; _liveVoc = 0;
    _mlPrediction    = null;
    _livePollutants  = null;
    notifyListeners();
    fetchLiveData();
  }

  @override
  void dispose() {
    _locationProvider?.removeListener(_onCityChanged);
    _liveTimer?.cancel();
    _cloudPollTimer?.cancel();
    super.dispose();
  }

  void _startLiveSensorFetch() {
    fetchLiveData();
    _liveTimer = Timer.periodic(const Duration(seconds: 30), (_) => fetchLiveData());
  }

  Future<void> fetchLiveData() async {
    _isFetchingLive = true; _liveError = null; notifyListeners();
    try {
      final lat = _locationProvider?.latitude  ?? 28.6139;
      final lon = _locationProvider?.longitude ?? 77.2090;
      final d = await WeatherApiService.fetchLiveData(lat: lat, lon: lon);
      _liveTemp     = d['temperature']!;
      _liveHumidity = d['humidity']!;
      _liveCo2      = d['co2']!;
      _liveVoc      = d['voc']!;
      _lastUpdated  = DateTime.now();
      _updateLiveRecord();
      _fetchMlPrediction();
      _fetchPollutants(lat: lat, lon: lon);
    } catch (e) {
      _liveError = 'Live sensor fetch failed';
      debugPrint('Live fetch error: $e');
    }
    _isFetchingLive = false; notifyListeners();
  }

  Future<void> _fetchPollutants({required double lat, required double lon}) async {
    _isFetchingPollutants = true; notifyListeners();
    try {
      _livePollutants = await WeatherApiService.fetchPollutants(
        lat          : lat,
        lon          : lon,
        co2Estimated : _liveCo2,
        vocEstimated : _liveVoc,
      );
    } catch (e) {
      debugPrint('Pollutant fetch error: $e');
    }
    _isFetchingPollutants = false; notifyListeners();
  }

  Future<void> refreshPollutants() async {
    final lat = _locationProvider?.latitude  ?? 28.6139;
    final lon = _locationProvider?.longitude ?? 77.2090;
    await _fetchPollutants(lat: lat, lon: lon);
  }

  Future<void> _fetchMlPrediction() async {
    final temp = _liveTemp != 0 ? _liveTemp : (_latestRecord?.temperature ?? 0);
    final hum  = _liveHumidity != 0 ? _liveHumidity : (_latestRecord?.humidity ?? 0);
    final co2  = _liveCo2 != 0 ? _liveCo2 : (_latestRecord?.co2 ?? 0);
    final voc  = _liveVoc != 0 ? _liveVoc : (_latestRecord?.voc ?? 0);

    if (temp == 0 && co2 == 0) return;

    final lat = _locationProvider?.latitude  ?? 28.6139;
    final lon = _locationProvider?.longitude ?? 77.2090;

    _isFetchingMl = true; notifyListeners();
    try {
      _mlPrediction = await MlPredictionService.predict(
        MlInputs(
          temperature: temp,
          humidity   : hum,
          co2        : co2,
          voc        : voc,
          lat        : lat,
          lon        : lon,
        ),
      );
    } catch (e) {
      debugPrint('ML prediction error: $e');
      _mlPrediction = MlPrediction.offline(latestAqi, latestStatus);
    }
    _isFetchingMl = false; notifyListeners();
  }

  Future<void> refreshMlPrediction() => _fetchMlPrediction();

  void _updateLiveRecord() {
    final score  = MockAiService.calculateAqi(
      temperature: _liveTemp, humidity: _liveHumidity,
      co2: _liveCo2, voc: _liveVoc);
    final status = MockAiService.getStatus(score);
    _latestRecord = AqiRecord(
      id: 'live', aqiScore: score, status: status,
      temperature: _liveTemp, humidity: _liveHumidity,
      co2: _liveCo2, voc: _liveVoc, timestamp: DateTime.now());

    NotificationService.checkAndNotifyStatusChange(
      status     : status,
      aqi        : score,
      temperature: _liveTemp,
      humidity   : _liveHumidity,
      co2        : _liveCo2,
      voc        : _liveVoc,
    );

    if (status == 'Hazardous' || status == 'Warning') {
      NotificationService.showDangerAlert(status: status, aqi: score);
    }
  }

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
    } catch (_) {}
  }

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

  Future<void> syncFromCloud() async {
    final hasToken = await ApiService.hasToken;
    if (!hasToken) return;

    _isSyncing = true; _syncError = null; notifyListeners();
    try {
      final cloudRecords = await AqiApiService.getRecords();
      final box = Hive.box<AqiRecord>(_boxName);
      for (final r in cloudRecords) {
        await box.put(r.id, r);
      }
      _records = box.values.toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      _syncError = 'Sync failed';
    }
    _isSyncing = false; notifyListeners();
  }

  Future<void> addRecord(AqiRecord record) async {
    final box = Hive.box<AqiRecord>(_boxName);
    await box.put(record.id, record);
    _records = box.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    notifyListeners();

    final hasToken = await ApiService.hasToken;
    if (hasToken) {
      try {
        await AqiApiService.saveRecord(record);
      } catch (_) {}
    }
  }

  Future<void> addRecordFromValues({
    double? temperature,
    double? humidity,
    double? co2,
    double? voc,
  }) async {
    final double t = temperature ?? latestTemperature;
    final double h = humidity ?? latestHumidity;
    final double c = co2 ?? latestCo2;
    final double v = voc ?? latestVoc;
    final score = MockAiService.calculateAqi(temperature: t, humidity: h, co2: c, voc: v);
    final status = MockAiService.getStatus(score);
    final record = AqiRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      aqiScore: score,
      status: status,
      temperature: t,
      humidity: h,
      co2: c,
      voc: v,
      timestamp: DateTime.now(),
    );
    await addRecord(record);
  }

  Future<void> deleteRecord(dynamic recordOrId) async {
    final String id = (recordOrId is AqiRecord) ? recordOrId.id : recordOrId.toString();
    final box = Hive.box<AqiRecord>(_boxName);
    await box.delete(id);
    _records = box.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    notifyListeners();

    final hasToken = await ApiService.hasToken;
    if (hasToken) {
      try {
        await AqiApiService.deleteRecord(id);
      } catch (_) {}
    }
  }

  double get weeklyAvgAqi {
    if (_records.isEmpty) return latestAqi;
    final sum = _records.fold(0.0, (prev, r) => prev + r.aqiScore);
    return sum / _records.length;
  }

  Future<void> clearHistory() async {
    final box = Hive.box<AqiRecord>(_boxName);
    await box.clear();
    _records = [];
    notifyListeners();
  }

  Future<void> clearAllRecords() => clearHistory();
}
