// ============================================================
// AeroSense — Insights Screen
// Covers features 1–11:
//  1. Complete Pollutant Analysis (extended view)
//  2. AQI Prediction (ML future forecast)
//  3. Health Recommendations
//  4. Smart Pollution Alerts
//  5. Pollution Map (India state AQI overview)
//  6. Historical Trends (fl_chart bar + line charts)
//  7. Location Comparison
//  8. Pollution Insights (reasons for spikes)
//  9. Outdoor Activity Recommendations
// 10. Weather-AQI Analysis
// 11. Personal Exposure Score
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/aqi_provider.dart';
import '../providers/location_provider.dart';
import '../services/mock_ai_service.dart';
import '../services/ml_prediction_service.dart';
import '../services/weather_api_service.dart';
import '../services/geocoding_service.dart';
import '../theme/app_theme.dart';
import '../widgets/screen_background.dart';

// ─────────────────────────────────────────────────────────────
// Root Screen
// ─────────────────────────────────────────────────────────────
class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});
  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  static const _tabs = [
    _TabInfo(Icons.local_hospital_rounded,    'Health'),
    _TabInfo(Icons.psychology_rounded,         'Predict'),
    _TabInfo(Icons.trending_up_rounded,        'Trends'),
    _TabInfo(Icons.map_rounded,                'Map'),
    _TabInfo(Icons.compare_arrows_rounded,     'Compare'),
    _TabInfo(Icons.person_rounded,             'Exposure'),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width >= 700;
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: ScreenBackground(
        theme: ScreenTheme.analyze,
        child: SafeArea(
          child: Column(
            children: [
              _InsightsAppBar(isWeb: isWeb),
              _InsightsTabBar(controller: _tabCtrl, tabs: _tabs),
              Expanded(
                child: TabBarView(
                  controller: _tabCtrl,
                  children: const [
                    _HealthTab(),
                    _PredictTab(),
                    _TrendsTab(),
                    _MapTab(),
                    _CompareTab(),
                    _ExposureTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabInfo {
  final IconData icon;
  final String   label;
  const _TabInfo(this.icon, this.label);
}

// ─────────────────────────────────────────────────────────────
// Shared Header + TabBar widgets
// ─────────────────────────────────────────────────────────────
class _InsightsAppBar extends StatelessWidget {
  final bool isWeb;
  const _InsightsAppBar({required this.isWeb});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF48CAE4)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.insights_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Insights',
                  style: TextStyle(fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary)),
              Text('Detailed analysis & recommendations',
                  style: TextStyle(fontSize: 11,
                      color: AppTheme.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _InsightsTabBar extends StatelessWidget {
  final TabController            controller;
  final List<_TabInfo>           tabs;
  const _InsightsTabBar({required this.controller, required this.tabs});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 44,
      decoration: BoxDecoration(
        color: AppTheme.primaryBlueLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          color: AppTheme.primaryBlue,
          borderRadius: BorderRadius.circular(10),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.textSecondary,
        labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: tabs.map((t) => Tab(
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(t.icon, size: 13),
              const SizedBox(width: 3),
              Text(t.label),
            ],
          ),
        )).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Tab 1 — Health (features 3, 4, 9, 10)
// Health Recommendations + Smart Alerts + Activity Recs +
// Weather-AQI Analysis
// ─────────────────────────────────────────────────────────────
class _HealthTab extends StatelessWidget {
  const _HealthTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<AqiProvider>(builder: (_, aqi, __) {
      final status = aqi.latestStatus;
      final aqiVal = aqi.latestAqi;
      final temp   = aqi.latestTemperature;
      final hum    = aqi.latestHumidity;
      final pd     = aqi.livePollutants;
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Smart Pollution Alert ─────────────────────────
          _InsightCard(
            icon: Icons.notifications_active_rounded,
            iconColor: _alertColor(status),
            title: 'Smart Pollution Alert',
            child: _AlertBanner(status: status, aqi: aqiVal, pd: pd),
          ),
          const SizedBox(height: 14),
          // ── Health Recommendations ────────────────────────
          _InsightCard(
            icon: Icons.favorite_rounded,
            iconColor: const Color(0xFFE91E63),
            title: 'Health Recommendations',
            child: _HealthRecsContent(status: status, aqi: aqiVal),
          ),
          const SizedBox(height: 14),
          // ── Weather-AQI Analysis ──────────────────────────
          _InsightCard(
            icon: Icons.wb_cloudy_rounded,
            iconColor: const Color(0xFF2196F3),
            title: 'Weather–AQI Analysis',
            child: _WeatherAqiContent(
              temp: temp, humidity: hum,
              aqi: aqiVal, status: status),
          ),
          const SizedBox(height: 14),
          // ── Outdoor Activity Recommendations ─────────────
          _InsightCard(
            icon: Icons.directions_run_rounded,
            iconColor: const Color(0xFF4CAF50),
            title: 'Outdoor Activity Guide',
            child: _ActivityContent(status: status, aqi: aqiVal),
          ),
          const SizedBox(height: 14),
          // ── Pollution Insights ────────────────────────────
          _InsightCard(
            icon: Icons.lightbulb_rounded,
            iconColor: const Color(0xFFFF9800),
            title: 'Pollution Insights',
            child: _PollutionInsightsContent(
              aqi: aqiVal, status: status,
              temp: temp, humidity: hum, pd: pd),
          ),
          const SizedBox(height: 8),
        ],
      );
    });
  }

  Color _alertColor(String s) {
    switch (s) {
      case 'Hazardous': return const Color(0xFFF44336);
      case 'Warning'  : return const Color(0xFFFF9800);
      case 'Moderate' : return const Color(0xFFFFC107);
      default         : return const Color(0xFF4CAF50);
    }
  }
}

// ─────────── Alert Banner ───────────────────────────────────
class _AlertBanner extends StatelessWidget {
  final String       status;
  final double       aqi;
  final PollutantData? pd;
  const _AlertBanner({required this.status, required this.aqi, this.pd});

  @override
  Widget build(BuildContext context) {
    final alerts = _buildAlerts();
    if (alerts.isEmpty) {
      return const _DataRow(
          icon: Icons.check_circle_rounded,
          color: Color(0xFF4CAF50),
          text: 'Air quality is currently safe. No alerts triggered.');
    }
    return Column(
      children: alerts.map((a) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: a.color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: a.color.withOpacity(0.30)),
          ),
          child: Row(children: [
            Icon(a.icon, size: 16, color: a.color),
            const SizedBox(width: 8),
            Expanded(child: Text(a.msg,
                style: TextStyle(fontSize: 12, color: a.color,
                    fontWeight: FontWeight.w600))),
          ]),
        ),
      )).toList(),
    );
  }

  List<_AlertItem> _buildAlerts() {
    final list = <_AlertItem>[];
    if (aqi > 150) {
      list.add(_AlertItem(Icons.dangerous_rounded,
          const Color(0xFFF44336),
          '🚨 HAZARDOUS: AQI ${aqi.toStringAsFixed(0)} — Stay indoors. Use N95 mask outdoors.'));
    } else if (aqi > 100) {
      list.add(_AlertItem(Icons.warning_rounded,
          const Color(0xFFFF9800),
          '⚠️ WARNING: AQI ${aqi.toStringAsFixed(0)} — Sensitive groups should avoid outdoor activity.'));
    } else if (aqi > 50) {
      list.add(_AlertItem(Icons.info_rounded,
          const Color(0xFFFFC107),
          'ℹ️ MODERATE: AQI ${aqi.toStringAsFixed(0)} — Consider reducing prolonged outdoor exertion.'));
    }
    final pm25 = pd?.pm25.value;
    if (pm25 != null && pm25 > 55.4) {
      list.add(_AlertItem(Icons.grain_rounded,
          const Color(0xFFF44336),
          '🔴 PM2.5 at ${pm25.toStringAsFixed(1)} µg/m³ — Exceeds safe limit (WHO: 15 µg/m³/24h).'));
    }
    final no2 = pd?.no2.value;
    if (no2 != null && no2 > 80) {
      list.add(_AlertItem(Icons.factory_rounded,
          const Color(0xFFFF9800),
          '🏭 NO₂ elevated at ${no2.toStringAsFixed(1)} µg/m³ — Traffic or industrial pollution likely.'));
    }
    return list;
  }
}

class _AlertItem {
  final IconData icon;
  final Color    color;
  final String   msg;
  const _AlertItem(this.icon, this.color, this.msg);
}

// ─────────── Health Recommendations ─────────────────────────
class _HealthRecsContent extends StatelessWidget {
  final String status;
  final double aqi;
  const _HealthRecsContent({required this.status, required this.aqi});

  @override
  Widget build(BuildContext context) {
    final recs = _recs();
    return Column(
      children: recs.map((r) => _DataRow(
          icon: r.icon, color: r.color, text: r.text)).toList(),
    );
  }

  List<_Rec> _recs() {
    switch (status) {
      case 'Safe':
        return const [
          _Rec(Icons.check_circle_rounded, Color(0xFF4CAF50),
              'Air quality is good — safe for all activities including outdoor exercise.'),
          _Rec(Icons.air_rounded, Color(0xFF4CAF50),
              'Open windows for natural ventilation.'),
          _Rec(Icons.directions_bike_rounded, Color(0xFF4CAF50),
              'Great day for cycling, running, or outdoor sports.'),
        ];
      case 'Moderate':
        return const [
          _Rec(Icons.info_rounded, Color(0xFFFFC107),
              'Unusually sensitive people should consider reducing prolonged outdoor exertion.'),
          _Rec(Icons.masks_rounded, Color(0xFFFFC107),
              'If sensitive to air quality, wear a mask during heavy exercise.'),
          _Rec(Icons.local_drink_rounded, Color(0xFF2196F3),
              'Stay hydrated — dry air can irritate airways.'),
        ];
      case 'Warning':
        return const [
          _Rec(Icons.warning_rounded, Color(0xFFFF9800),
              'People with respiratory conditions (asthma, COPD) should stay indoors.'),
          _Rec(Icons.masks_rounded, Color(0xFFFF9800),
              'Wear N95/KN95 mask if going outside. Avoid strenuous outdoor activity.'),
          _Rec(Icons.home_rounded, Color(0xFFFF9800),
              'Keep doors and windows closed. Use air purifier if available.'),
          _Rec(Icons.medical_services_rounded, Color(0xFFFF9800),
              'Keep rescue inhaler nearby if you have asthma.'),
        ];
      default: // Hazardous
        return const [
          _Rec(Icons.dangerous_rounded, Color(0xFFF44336),
              'HAZARDOUS: Stay indoors. Avoid all outdoor activities.'),
          _Rec(Icons.masks_rounded, Color(0xFFF44336),
              'Wear N95 mask and eye protection if outdoor exposure is unavoidable.'),
          _Rec(Icons.home_rounded, Color(0xFFF44336),
              'Seal gaps in windows. Use HEPA air purifier on highest setting.'),
          _Rec(Icons.medical_services_rounded, Color(0xFFF44336),
              'Consult a doctor if you experience difficulty breathing, chest pain, or unusual fatigue.'),
          _Rec(Icons.child_care_rounded, Color(0xFFF44336),
              'Keep elderly, children, and pregnant women away from windows.'),
        ];
    }
  }
}

class _Rec {
  final IconData icon;
  final Color    color;
  final String   text;
  const _Rec(this.icon, this.color, this.text);
}

// ─────────── Weather-AQI Analysis ───────────────────────────
class _WeatherAqiContent extends StatelessWidget {
  final double temp, humidity, aqi;
  final String status;
  const _WeatherAqiContent(
      {required this.temp, required this.humidity,
       required this.aqi,  required this.status});

  @override
  Widget build(BuildContext context) {
    final insights = <String>[];
    if (temp > 35) {
      insights.add('🌡️ High temperature (${temp.toStringAsFixed(1)}°C) accelerates ground-level ozone formation and VOC off-gassing, worsening air quality.');
    } else if (temp < 10) {
      insights.add('❄️ Cold temperatures (${temp.toStringAsFixed(1)}°C) can trap pollutants close to the ground (temperature inversion), raising AQI.');
    } else {
      insights.add('🌤️ Temperature (${temp.toStringAsFixed(1)}°C) is within normal range — moderate influence on AQI.');
    }
    if (humidity > 80) {
      insights.add('💧 High humidity (${humidity.toStringAsFixed(0)}%) thickens particulate matter and slows dispersion — raises PM2.5 and PM10.');
    } else if (humidity < 30) {
      insights.add('🏜️ Low humidity (${humidity.toStringAsFixed(0)}%) can lift dust particles into the air, raising PM10.');
    } else {
      insights.add('💦 Humidity (${humidity.toStringAsFixed(0)}%) is balanced — neutral effect on pollutant dispersion.');
    }
    if (aqi > 0) {
      insights.add('📊 Combined weather effect: current AQI is ${aqi.toStringAsFixed(0)} ($status).');
    }
    return Column(
      children: insights.map((t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t, style: const TextStyle(
            fontSize: 12, color: AppTheme.textPrimary, height: 1.5)),
      )).toList(),
    );
  }
}

// ─────────── Activity Recommendations ───────────────────────
class _ActivityContent extends StatelessWidget {
  final String status;
  final double aqi;
  const _ActivityContent({required this.status, required this.aqi});

  @override
  Widget build(BuildContext context) {
    final activities = _activities();
    return Column(
      children: activities.map((a) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: a.ok
                  ? const Color(0xFF4CAF50).withOpacity(0.10)
                  : const Color(0xFFF44336).withOpacity(0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              a.ok ? Icons.check_rounded : Icons.close_rounded,
              size: 14,
              color: a.ok ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(a.name,
                  style: const TextStyle(fontSize: 12,
                      fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              Text(a.note,
                  style: const TextStyle(fontSize: 11,
                      color: AppTheme.textSecondary, height: 1.4)),
            ],
          )),
        ]),
      )).toList(),
    );
  }

  List<_Activity> _activities() {
    if (aqi <= 50) {
      return const [
        _Activity('Running / Jogging', true, 'Perfect conditions for long-distance running.'),
        _Activity('Cycling', true, 'Excellent for outdoor cycling.'),
        _Activity('Children\'s Outdoor Play', true, 'Safe for all age groups.'),
        _Activity('Gardening', true, 'Air is clean — great outdoor activity.'),
      ];
    } else if (aqi <= 100) {
      return const [
        _Activity('Running / Jogging', true, 'Generally safe; sensitive individuals may want to limit time.'),
        _Activity('Cycling', true, 'OK for short rides; reduce intensity if uncomfortable.'),
        _Activity('Children\'s Outdoor Play', true, 'Monitor sensitive children.'),
        _Activity('Intense Outdoor Sport', false, 'Consider indoor alternatives for high-intensity activities.'),
      ];
    } else if (aqi <= 150) {
      return const [
        _Activity('Running / Jogging', false, 'Not recommended for sensitive groups.'),
        _Activity('Cycling', false, 'Avoid unless necessary — wear a mask.'),
        _Activity('Children\'s Outdoor Play', false, 'Limit outdoor play for children.'),
        _Activity('Walking', true, 'Short walks are acceptable with a mask.'),
        _Activity('Intense Outdoor Sport', false, 'Move all high-intensity activity indoors.'),
      ];
    } else {
      return const [
        _Activity('Running / Jogging', false, 'Do not run outdoors today.'),
        _Activity('Cycling', false, 'Avoid cycling — use indoor alternatives.'),
        _Activity('Children\'s Outdoor Play', false, 'Keep children indoors.'),
        _Activity('Walking', false, 'Avoid walking outdoors; if essential, use N95 mask.'),
        _Activity('Indoor Exercise', true, 'Recommended: exercise indoors with air purifier running.'),
      ];
    }
  }
}

class _Activity {
  final String name, note;
  final bool   ok;
  const _Activity(this.name, this.ok, this.note);
}

// ─────────── Pollution Insights ─────────────────────────────
class _PollutionInsightsContent extends StatelessWidget {
  final double        aqi, temp, humidity;
  final String        status;
  final PollutantData? pd;
  const _PollutionInsightsContent(
      {required this.aqi,  required this.status,
       required this.temp, required this.humidity, this.pd});

  @override
  Widget build(BuildContext context) {
    final insights = _generateInsights();
    if (insights.isEmpty) {
      return const _DataRow(
          icon: Icons.eco_rounded,
          color: Color(0xFF4CAF50),
          text: 'Air quality is normal. No unusual pollution patterns detected.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: insights.map((s) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('•  ',
              style: TextStyle(fontSize: 14,
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w800)),
          Expanded(child: Text(s,
              style: const TextStyle(fontSize: 12,
                  color: AppTheme.textPrimary, height: 1.5))),
        ]),
      )).toList(),
    );
  }

  List<String> _generateInsights() {
    final list = <String>[];
    final pm25  = pd?.pm25.value;
    final pm10  = pd?.pm10.value;
    final no2   = pd?.no2.value;
    final so2   = pd?.so2.value;
    final o3    = pd?.o3.value;
    final co    = pd?.co.value;

    if (pm25 != null && pm25 > 35.4) {
      list.add('Elevated PM2.5 (${pm25.toStringAsFixed(1)} µg/m³) — likely caused by vehicle exhaust, construction dust, or nearby industrial activity.');
    }
    if (pm10 != null && pm10 > 100) {
      list.add('High PM10 (${pm10.toStringAsFixed(1)} µg/m³) — coarse dust from unpaved roads, demolition, or agricultural burning may be the cause.');
    }
    if (no2 != null && no2 > 40) {
      list.add('Elevated NO₂ (${no2.toStringAsFixed(1)} µg/m³) — indicates heavy road traffic or power plant emissions nearby.');
    }
    if (so2 != null && so2 > 40) {
      list.add('SO₂ above safe levels (${so2.toStringAsFixed(1)} µg/m³) — industrial combustion of fossil fuels is the primary suspect.');
    }
    if (o3 != null && o3 > 100) {
      list.add('High ozone (${o3.toStringAsFixed(1)} µg/m³) — photochemical smog; peaks on hot sunny afternoons when car exhaust reacts with sunlight.');
    }
    if (co != null && co > 4400) {
      list.add('CO levels elevated (${(co/1000).toStringAsFixed(1)} mg/m³) — incomplete combustion from vehicles or generators is a likely source.');
    }
    if (temp > 35 && (o3 ?? 0) > 60) {
      list.add('Hot temperature combined with existing NOₓ is accelerating ground-level ozone formation.');
    }
    if (humidity > 80 && (pm25 ?? 0) > 25) {
      list.add('High humidity is causing PM2.5 particles to absorb moisture and swell, worsening haze.');
    }
    if (aqi > 100 && list.isEmpty) {
      list.add('AQI is elevated (${aqi.toStringAsFixed(0)}). Possible causes: seasonal burning, fireworks, or stagnant air trapping local pollution.');
    }
    return list;
  }
}

// ─────────────────────────────────────────────────────────────
// Tab 2 — Predict (feature 2)
// AQI Prediction + ML Future Forecast
// ─────────────────────────────────────────────────────────────
class _PredictTab extends StatefulWidget {
  const _PredictTab();
  @override
  State<_PredictTab> createState() => _PredictTabState();
}

class _PredictTabState extends State<_PredictTab> {
  MlFutureForecast? _forecast;
  bool _loading = false;
  int  _hours   = 6;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  Future<void> _fetch() async {
    if (!mounted) return;
    final aqi = context.read<AqiProvider>();
    setState(() => _loading = true);
    final forecast = await MlPredictionService.predictFuture(
      inputs: MlInputs(
        temperature: aqi.latestTemperature,
        humidity   : aqi.latestHumidity,
        co2        : aqi.latestCo2,
        voc        : aqi.latestVoc,
        lat        : context.read<LocationProvider>().latitude,
        lon        : context.read<LocationProvider>().longitude,
      ),
      hours: _hours,
    );
    if (mounted) setState(() { _forecast = forecast; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AqiProvider>(builder: (_, aqi, __) {
      final ml = aqi.mlPrediction;
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── 1-hour prediction summary ─────────────────
          _InsightCard(
            icon: Icons.schedule_rounded,
            iconColor: const Color(0xFF6C63FF),
            title: '1-Hour ML Prediction',
            child: ml == null
                ? const Center(child: CircularProgressIndicator())
                : _OneHourPrediction(ml: ml),
          ),
          const SizedBox(height: 14),
          // ── Multi-hour forecast chart ─────────────────
          _InsightCard(
            icon: Icons.show_chart_rounded,
            iconColor: const Color(0xFF2196F3),
            title: 'Future AQI Forecast',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [6, 12, 24].map((h) => GestureDetector(
                onTap: () { _hours = h; _fetch(); },
                child: Container(
                  margin: const EdgeInsets.only(left: 4),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _hours == h
                        ? AppTheme.primaryBlue
                        : AppTheme.primaryBlueLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${h}h',
                      style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        color: _hours == h
                            ? Colors.white
                            : AppTheme.primaryBlue,
                      )),
                ),
              )).toList(),
            ),
            child: _loading
                ? const SizedBox(height: 140,
                    child: Center(child: CircularProgressIndicator()))
                : _forecast == null || _forecast!.predictions.isEmpty
                    ? const Text('Start the ML API (port 5000) to enable predictions.',
                        style: TextStyle(fontSize: 12,
                            color: AppTheme.textSecondary))
                    : _ForecastChart(forecast: _forecast!),
          ),
          const SizedBox(height: 8),
        ],
      );
    });
  }
}

class _OneHourPrediction extends StatelessWidget {
  final MlPrediction ml;
  const _OneHourPrediction({required this.ml});

  @override
  Widget build(BuildContext context) {
    final trendColor = ml.trend == 'improving'
        ? const Color(0xFF4CAF50)
        : ml.trend == 'worsening'
            ? const Color(0xFFF44336)
            : const Color(0xFF4B7FFF);
    return Column(children: [
      Row(children: [
        Expanded(child: _AqiMini(
            label: 'Current', value: ml.currentAqi,
            status: ml.currentStatus)),
        const SizedBox(width: 12),
        Icon(ml.trend == 'improving'
            ? Icons.trending_down_rounded
            : ml.trend == 'worsening'
                ? Icons.trending_up_rounded
                : Icons.trending_flat_rounded,
            color: trendColor, size: 28),
        const SizedBox(width: 12),
        Expanded(child: _AqiMini(
            label: 'In 1 Hour', value: ml.predictedAqi,
            status: ml.predictedStatus)),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: trendColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(ml.change,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                  color: trendColor)),
        ),
        const SizedBox(width: 8),
        Text('Confidence: ${ml.confidencePct}  •  MAE ±${ml.mae.toStringAsFixed(1)}',
            style: const TextStyle(fontSize: 10,
                color: AppTheme.textSecondary)),
      ]),
      if (!ml.isOnline) ...[
        const SizedBox(height: 8),
        const _DataRow(icon: Icons.offline_bolt_rounded,
            color: Colors.orange,
            text: 'ML API offline — rule-based fallback used.'),
      ],
    ]);
  }
}

class _AqiMini extends StatelessWidget {
  final String label, status;
  final double value;
  const _AqiMini(
      {required this.label, required this.value, required this.status});

  @override
  Widget build(BuildContext context) {
    final c = MockAiService.getStatusColor(status);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withOpacity(0.25)),
      ),
      child: Column(children: [
        Text(label, style: const TextStyle(fontSize: 10,
            color: AppTheme.textSecondary)),
        const SizedBox(height: 4),
        Text(value.toStringAsFixed(1),
            style: TextStyle(fontSize: 22,
                fontWeight: FontWeight.w800, color: c)),
        Text(status, style: TextStyle(fontSize: 10,
            fontWeight: FontWeight.w700, color: c)),
      ]),
    );
  }
}

// ─────────── Future Forecast Chart ──────────────────────────
class _ForecastChart extends StatelessWidget {
  final MlFutureForecast forecast;
  const _ForecastChart({required this.forecast});

  Color _aqiColor(double aqi) {
    if (aqi <= 50)  return AppTheme.safeGreen;
    if (aqi <= 100) return AppTheme.moderateYellow;
    if (aqi <= 150) return AppTheme.warningOrange;
    return AppTheme.hazardousRed;
  }

  @override
  Widget build(BuildContext context) {
    final pts = forecast.predictions;
    final spots = pts.asMap().entries.map((e) =>
        FlSpot(e.key.toDouble(), e.value.predictedAqi)).toList();
    final maxY = (pts.map((p) => p.predictedAqi).reduce(
            (a, b) => a > b ? a : b) + 30).clamp(0, 300).toDouble();
    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          minX: 0, maxX: (pts.length - 1).toDouble(),
          minY: 0, maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawHorizontalLine: true,
            drawVerticalLine: false,
            horizontalInterval: 50,
            getDrawingHorizontalLine: (_) => FlLine(
                color: AppTheme.textLight.withOpacity(0.50),
                strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true, reservedSize: 30,
                interval: 50,
                getTitlesWidget: (v, _) => Text(
                    v.toInt().toString(),
                    style: const TextStyle(fontSize: 9,
                        color: AppTheme.textLight)),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true, reservedSize: 20,
                interval: (pts.length / 6).ceilToDouble().clamp(1, 24),
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= pts.length) return const SizedBox();
                  return Text('+${pts[i].hour}h',
                      style: const TextStyle(fontSize: 9,
                          color: AppTheme.textLight));
                },
              ),
            ),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots.map((s) {
                final i = s.x.toInt();
                if (i < 0 || i >= pts.length) return null;
                return LineTooltipItem(
                  '+${pts[i].hour}h: ${s.y.toStringAsFixed(1)}\n${pts[i].status}',
                  TextStyle(fontSize: 10,
                      color: _aqiColor(s.y), fontWeight: FontWeight.w700),
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: AppTheme.primaryBlue,
              barWidth: 2.5,
              dotData: FlDotData(
                show: true,
                getDotPainter: (s, _, __, ___) => FlDotCirclePainter(
                  radius: 3,
                  color: _aqiColor(s.y),
                  strokeWidth: 1.5,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryBlue.withOpacity(0.20),
                    AppTheme.primaryBlue.withOpacity(0.20),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          extraLinesData: ExtraLinesData(horizontalLines: [
            HorizontalLine(y: 50,  color: AppTheme.safeGreen.withOpacity(0.30),
                strokeWidth: 1, dashArray: [4, 4]),
            HorizontalLine(y: 100, color: AppTheme.moderateYellow.withOpacity(0.30),
                strokeWidth: 1, dashArray: [4, 4]),
            HorizontalLine(y: 150, color: AppTheme.warningOrange.withOpacity(0.30),
                strokeWidth: 1, dashArray: [4, 4]),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Tab 3 — Trends (feature 6)
// Historical AQI bar chart + pollutant trends
// ─────────────────────────────────────────────────────────────
class _TrendsTab extends StatefulWidget {
  const _TrendsTab();
  @override
  State<_TrendsTab> createState() => _TrendsTabState();
}

class _TrendsTabState extends State<_TrendsTab> {
  int _days = 7;

  @override
  Widget build(BuildContext context) {
    return Consumer<AqiProvider>(builder: (_, aqi, __) {
      final records = aqi.records;
      final now     = DateTime.now();
      final filtered = records.where((r) =>
          now.difference(r.timestamp).inDays < _days).toList();

      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Period selector ────────────────────────────
          Row(
            children: [7, 14, 30].map((d) => GestureDetector(
              onTap: () => setState(() => _days = d),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: _days == d
                      ? AppTheme.primaryBlue
                      : AppTheme.primaryBlueLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${d}d',
                    style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: _days == d ? Colors.white : AppTheme.primaryBlue,
                    )),
              ),
            )).toList(),
          ),
          const SizedBox(height: 14),

          // ── AQI Bar Chart ──────────────────────────────
          _InsightCard(
            icon: Icons.bar_chart_rounded,
            iconColor: AppTheme.primaryBlue,
            title: 'AQI History — Last $_days Days',
            child: filtered.isEmpty
                ? const _EmptyDataMsg()
                : _AqiBarChart(records: filtered),
          ),
          const SizedBox(height: 14),

          // ── Sensor Trend Lines ─────────────────────────
          _InsightCard(
            icon: Icons.show_chart_rounded,
            iconColor: const Color(0xFF9C27B0),
            title: 'Sensor Trends',
            child: filtered.isEmpty
                ? const _EmptyDataMsg()
                : _SensorLineChart(records: filtered),
          ),
          const SizedBox(height: 14),

          // ── Statistics summary ─────────────────────────
          _InsightCard(
            icon: Icons.analytics_rounded,
            iconColor: const Color(0xFF00BCD4),
            title: 'Summary Statistics',
            child: _StatsSummary(records: filtered),
          ),
          const SizedBox(height: 8),
        ],
      );
    });
  }
}

class _AqiBarChart extends StatelessWidget {
  final List<dynamic> records;
  const _AqiBarChart({required this.records});

  Color _bar(double v) {
    if (v <= 50)  return AppTheme.safeGreen;
    if (v <= 100) return AppTheme.moderateYellow;
    if (v <= 150) return AppTheme.warningOrange;
    return AppTheme.hazardousRed;
  }

  @override
  Widget build(BuildContext context) {
    final recent = records.reversed.take(14).toList().reversed.toList();
    return SizedBox(
      height: 160,
      child: BarChart(
        BarChartData(
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
                rod.toY.toStringAsFixed(1),
                const TextStyle(color: Colors.white,
                    fontSize: 10, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true, reservedSize: 28, interval: 50,
              getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                  style: const TextStyle(fontSize: 8,
                      color: AppTheme.textLight)),
            )),
            bottomTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true, reservedSize: 16,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= recent.length) return const SizedBox();
                final d = recent[i].timestamp as DateTime;
                return Text('${d.day}/${d.month}',
                    style: const TextStyle(fontSize: 8,
                        color: AppTheme.textLight));
              },
            )),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: 50,
            getDrawingHorizontalLine: (_) => FlLine(
                color: AppTheme.textLight.withOpacity(0.50),
                strokeWidth: 1),
          ),
          barGroups: recent.asMap().entries.map((e) {
            final aqi = (e.value.aqiScore as double);
            return BarChartGroupData(x: e.key, barRods: [
              BarChartRodData(
                toY: aqi,
                color: _bar(aqi),
                width: 10,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4)),
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}

class _SensorLineChart extends StatelessWidget {
  final List<dynamic> records;
  const _SensorLineChart({required this.records});

  @override
  Widget build(BuildContext context) {
    final recent = records.reversed.take(14).toList().reversed.toList();
    if (recent.isEmpty) return const _EmptyDataMsg();

    LineChartBarData buildLine(
        List<FlSpot> spots, Color color) =>
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: color,
          barWidth: 2,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        );

    final tempSpots = recent.asMap().entries.map((e) =>
        FlSpot(e.key.toDouble(), e.value.temperature as double)).toList();
    final humSpots = recent.asMap().entries.map((e) =>
        FlSpot(e.key.toDouble(), e.value.humidity as double)).toList();

    return Column(children: [
      SizedBox(
        height: 140,
        child: LineChart(LineChartData(
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
                color: AppTheme.textLight.withOpacity(0.50),
                strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true, reservedSize: 28, interval: 20,
              getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                  style: const TextStyle(fontSize: 8,
                      color: AppTheme.textLight)),
            )),
            bottomTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            buildLine(tempSpots, const Color(0xFFFF6B6B)),
            buildLine(humSpots,  const Color(0xFF4FC3F7)),
          ],
        )),
      ),
      const SizedBox(height: 8),
      const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _LegendDot(color: Color(0xFFFF6B6B), label: 'Temperature °C'),
        SizedBox(width: 16),
        _LegendDot(color: Color(0xFF4FC3F7), label: 'Humidity %'),
      ]),
    ]);
  }
}

class _LegendDot extends StatelessWidget {
  final Color  color;
  final String label;
  const _LegendDot({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 10, height: 10,
          decoration: BoxDecoration(color: color,
              shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(
          fontSize: 10, color: AppTheme.textSecondary)),
    ],
  );
}

class _StatsSummary extends StatelessWidget {
  final List<dynamic> records;
  const _StatsSummary({required this.records});

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) return const _EmptyDataMsg();
    final aqis = records.map((r) => r.aqiScore as double).toList();
    final avg  = aqis.reduce((a, b) => a + b) / aqis.length;
    final best = aqis.reduce((a, b) => a < b ? a : b);
    final worst= aqis.reduce((a, b) => a > b ? a : b);
    final safe = aqis.where((a) => a <= 50).length;
    return Wrap(spacing: 10, runSpacing: 10, children: [
      _StatChip('Readings',   '${records.length}',     Icons.numbers_rounded,     AppTheme.primaryBlue),
      _StatChip('Avg AQI',    avg.toStringAsFixed(1),  Icons.analytics_rounded,   const Color(0xFF9C27B0)),
      _StatChip('Best AQI',   best.toStringAsFixed(1), Icons.thumb_up_rounded,    AppTheme.safeGreen),
      _StatChip('Worst AQI',  worst.toStringAsFixed(1),Icons.thumb_down_rounded,  AppTheme.hazardousRed),
      _StatChip('Safe Days',  '$safe',                 Icons.eco_rounded,         AppTheme.safeGreen),
    ]);
  }
}

class _StatChip extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color    color;
  const _StatChip(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withOpacity(0.25)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: color),
      const SizedBox(width: 6),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 9,
            color: AppTheme.textSecondary)),
        Text(value, style: TextStyle(fontSize: 13,
            fontWeight: FontWeight.w800, color: color)),
      ]),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────
// Tab 4 — Map (feature 5)
// India State AQI Overview (color-coded list, real coords)
// ─────────────────────────────────────────────────────────────
class _MapTab extends StatelessWidget {
  const _MapTab();

  // Real approximate coords for each state capital
  static const _states = [
    _StateAqi('Delhi',          28.6139, 77.2090),
    _StateAqi('Maharashtra',    19.0760, 72.8777),
    _StateAqi('Karnataka',      12.9716, 77.5946),
    _StateAqi('Tamil Nadu',     13.0827, 80.2707),
    _StateAqi('West Bengal',    22.5726, 88.3639),
    _StateAqi('Telangana',      17.3850, 78.4867),
    _StateAqi('Gujarat',        23.0225, 72.5714),
    _StateAqi('Rajasthan',      26.9124, 75.7873),
    _StateAqi('Uttar Pradesh',  26.8467, 80.9462),
    _StateAqi('Punjab',         30.7333, 76.7794),
    _StateAqi('Madhya Pradesh', 23.2599, 77.4126),
    _StateAqi('Bihar',          25.5941, 85.1376),
    _StateAqi('Odisha',         20.2961, 85.8245),
    _StateAqi('Kerala',          9.9312, 76.2673),
    _StateAqi('Assam',          26.1445, 91.7362),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AqiProvider>(builder: (_, aqi, __) {
      final currentLoc  = aqi.selectedCityName;
      final currentAqi  = aqi.latestAqi;
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Current location highlight ────────────────
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B6FE8), Color(0xFF5B8AF0)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(children: [
              const Icon(Icons.my_location_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Your Location',
                      style: TextStyle(color: Colors.white70, fontSize: 11)),
                  Text(currentLoc,
                      style: const TextStyle(color: Colors.white,
                          fontSize: 14, fontWeight: FontWeight.w800)),
                ],
              )),
              Column(children: [
                Text(currentAqi.toStringAsFixed(0),
                    style: const TextStyle(color: Colors.white,
                        fontSize: 24, fontWeight: FontWeight.w800)),
                const Text('AQI', style: TextStyle(
                    color: Colors.white70, fontSize: 10)),
              ]),
            ]),
          ),

          // ── Disclaimer ────────────────────────────────
          Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: const Color(0xFF2196F3).withOpacity(0.25)),
            ),
            child: const Row(children: [
              Icon(Icons.info_outline_rounded,
                  size: 13, color: Color(0xFF2196F3)),
              SizedBox(width: 8),
              Expanded(child: Text(
                'AQI values below are fetched live for each state capital from Open-Meteo. Tap a state to change your location.',
                style: TextStyle(fontSize: 10, color: Color(0xFF2196F3)),
              )),
            ]),
          ),

          // ── State list ────────────────────────────────
          const _InsightCard(
            icon: Icons.public_rounded,
            iconColor: AppTheme.primaryBlue,
            title: 'India State AQI Overview',
            child: _StateAqiList(states: _states),
          ),          const SizedBox(height: 8),
        ],
      );
    });
  }
}

class _StateAqi {
  final String name;
  final double lat, lon;
  const _StateAqi(this.name, this.lat, this.lon);
}

class _StateAqiList extends StatefulWidget {
  final List<_StateAqi> states;
  const _StateAqiList({required this.states});
  @override
  State<_StateAqiList> createState() => _StateAqiListState();
}

class _StateAqiListState extends State<_StateAqiList> {
  final Map<String, double?> _aqiMap = {};
  bool _fetching = false;

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    if (_fetching) return;
    setState(() => _fetching = true);
    for (final s in widget.states) {
      if (!mounted) return;
      try {
        final pd = await WeatherApiService.fetchPollutants(
            lat: s.lat, lon: s.lon);
        // Compute simple AQI from PM2.5 sub-index
        final pm25 = pd.pm25.value ?? 40.0;
        double aqi;
        if (pm25 <= 30) {
          aqi = (pm25 / 30) * 50;
        } else if (pm25 <= 60) {
          aqi = 50 + ((pm25 - 30) / 30) * 50;
        } else if (pm25 <= 90) {
          aqi = 100 + ((pm25 - 60) / 30) * 100;
        } else {
          aqi = 200 + ((pm25 - 90) / 100) * 100;
        }
        if (mounted) { setState(() => _aqiMap[s.name] = aqi.clamp(0, 300)); }
      } catch (_) {
        if (mounted) setState(() => _aqiMap[s.name] = null);
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    if (mounted) setState(() => _fetching = false);
  }

  Color _color(double? v) {
    if (v == null) return AppTheme.textLight;
    if (v <= 50)   return AppTheme.safeGreen;
    if (v <= 100)  return AppTheme.moderateYellow;
    if (v <= 150)  return AppTheme.warningOrange;
    return AppTheme.hazardousRed;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: widget.states.map((s) {
        final aqiVal = _aqiMap[s.name];
        final c      = _color(aqiVal);
        return InkWell(
          onTap: () async {
            final loc = context.read<LocationProvider>();
            // Find closest city in static list or set custom location
            final result = await GeocodingService.search(s.name, limit: 1);
            if (!context.mounted) return;
            if (result.isNotEmpty && result.first.isIndia) {
              final r = result.first;
              await loc.setCustomLocation(CustomLocation(
                displayName: r.displayName,
                shortLabel : s.name,
                city: s.name, state: s.name,
                latitude: s.lat, longitude: s.lon,
              ));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('📍 Switched to ${s.name}'),
                  backgroundColor: AppTheme.safeGreen,
                  duration: const Duration(seconds: 2),
                ));
              }
            }
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: c.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: c.withOpacity(0.25)),
            ),
            child: Row(children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                    shape: BoxShape.circle, color: c),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(s.name,
                  style: const TextStyle(fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary))),
              aqiVal == null
                  ? const SizedBox(width: 14, height: 14,
                      child: CircularProgressIndicator(strokeWidth: 1.5))
                  : Text(aqiVal.toStringAsFixed(0),
                      style: TextStyle(fontSize: 14,
                          fontWeight: FontWeight.w800, color: c)),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 10, color: AppTheme.textLight),
            ]),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Tab 5 — Compare (feature 7)
// Location Comparison — up to 3 locations side-by-side
// ─────────────────────────────────────────────────────────────
class _CompareTab extends StatefulWidget {
  const _CompareTab();
  @override
  State<_CompareTab> createState() => _CompareTabState();
}

class _CompareTabState extends State<_CompareTab> {
  final List<_CmpLocation> _locations = [];
  final TextEditingController _searchCtrl = TextEditingController();
  List<GeocodingResult> _suggestions = [];
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    // Seed with current location
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final loc = context.read<LocationProvider>();
      _addLocation(
        name: loc.locationLabel,
        lat : loc.latitude,
        lon : loc.longitude,
      );
    });
  }

  Future<void> _search(String q) async {
    if (q.trim().length < 2) {
      setState(() => _suggestions = []);
      return;
    }
    setState(() => _searching = true);
    final results = await GeocodingService.search(q, limit: 5);
    if (mounted) setState(() { _suggestions = results; _searching = false; });
  }

  void _addLocation({required String name,
      required double lat, required double lon}) {
    if (_locations.length >= 3) return;
    if (_locations.any((l) => l.name == name)) return;
    final entry = _CmpLocation(name: name, lat: lat, lon: lon);
    setState(() => _locations.add(entry));
    _fetchAqi(entry);
  }

  Future<void> _fetchAqi(_CmpLocation loc) async {
    try {
      final pd = await WeatherApiService.fetchPollutants(
          lat: loc.lat, lon: loc.lon);
      final pm25 = pd.pm25.value ?? 40.0;
      double aqi;
      if (pm25 <= 30) {
        aqi = (pm25 / 30) * 50;
      } else if (pm25 <= 60) {
        aqi = 50 + ((pm25 - 30) / 30) * 50;
      } else if (pm25 <= 90) {
        aqi = 100 + ((pm25 - 60) / 30) * 100;
      } else {
        aqi = 200 + ((pm25 - 90) / 100) * 100;
      }
      if (mounted) {
        setState(() {
          loc.aqi   = aqi.clamp(0, 300);
          loc.pm25  = pd.pm25.value;
          loc.pm10  = pd.pm10.value;
          loc.no2   = pd.no2.value;
          loc.ready = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() { loc.ready = true; });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Add location ─────────────────────────────
        _InsightCard(
          icon: Icons.add_location_alt_rounded,
          iconColor: AppTheme.primaryBlue,
          title: 'Add Location to Compare (max 3)',
          child: Column(children: [
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search city or area in India…',
                hintStyle: const TextStyle(
                    fontSize: 12, color: AppTheme.textLight),
                prefixIcon: const Icon(Icons.search_rounded,
                    size: 16, color: AppTheme.textSecondary),
                suffixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 1.5)))
                    : null,
                filled: true,
                fillColor: AppTheme.scaffoldBg,
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 8, horizontal: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                        color: AppTheme.textLight.withOpacity(0.40))),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                        color: AppTheme.textLight.withOpacity(0.40))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: AppTheme.primaryBlue, width: 1.5)),
              ),
              onChanged: _search,
            ),
            if (_suggestions.isNotEmpty) ...[
              const SizedBox(height: 8),
              ..._suggestions.map((r) => ListTile(
                dense: true,
                leading: const Icon(Icons.location_on_rounded,
                    size: 16, color: AppTheme.primaryBlue),
                title: Text(r.label,
                    style: const TextStyle(fontSize: 12,
                        color: AppTheme.textPrimary)),
                subtitle: Text(r.state,
                    style: const TextStyle(fontSize: 10,
                        color: AppTheme.textSecondary)),
                onTap: () {
                  _addLocation(name: r.label,
                      lat: r.latitude, lon: r.longitude);
                  _searchCtrl.clear();
                  setState(() => _suggestions = []);
                },
              )),
            ],
          ]),
        ),
        const SizedBox(height: 14),

        // ── Comparison table ─────────────────────────
        if (_locations.isNotEmpty)
          _InsightCard(
            icon: Icons.compare_arrows_rounded,
            iconColor: const Color(0xFF9C27B0),
            title: 'Comparison',
            child: _ComparisonTable(locations: _locations,
                onRemove: (l) => setState(() => _locations.remove(l))),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _CmpLocation {
  final String name;
  final double lat, lon;
  double? aqi, pm25, pm10, no2;
  bool    ready = false;
  _CmpLocation({required this.name, required this.lat, required this.lon});
}

class _ComparisonTable extends StatelessWidget {
  final List<_CmpLocation> locations;
  final void Function(_CmpLocation) onRemove;
  const _ComparisonTable(
      {required this.locations, required this.onRemove});

  Color _c(double? v) {
    if (v == null) return AppTheme.textLight;
    if (v <= 50)   return AppTheme.safeGreen;
    if (v <= 100)  return AppTheme.moderateYellow;
    if (v <= 150)  return AppTheme.warningOrange;
    return AppTheme.hazardousRed;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header row
        Row(children: [
          const Expanded(flex: 2, child: Text('Location',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary))),
          ...['AQI', 'PM2.5', 'PM10', 'NO₂'].map((h) =>
              Expanded(child: Center(child: Text(h,
                  style: const TextStyle(fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary))))),
          const SizedBox(width: 24),
        ]),
        const Divider(height: 8),
        ...locations.map((loc) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            Expanded(flex: 2, child: Row(children: [
              Expanded(child: Text(loc.name,
                  style: const TextStyle(fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary),
                  overflow: TextOverflow.ellipsis)),
            ])),
            ...[(loc.aqi, null), (loc.pm25, null),
               (loc.pm10, null), (loc.no2, null)].map((pair) {
              final v = pair.$1;
              return Expanded(child: Center(
                child: loc.ready
                    ? Text(
                        v != null ? v.toStringAsFixed(0) : '—',
                        style: TextStyle(fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: _c(v ?? loc.aqi)),
                      )
                    : const SizedBox(width: 12, height: 12,
                        child: CircularProgressIndicator(strokeWidth: 1.5)),
              ));
            }),
            GestureDetector(
              onTap: () => onRemove(loc),
              child: const Icon(Icons.close_rounded,
                  size: 16, color: AppTheme.textLight),
            ),
          ]),
        )),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Tab 6 — Exposure (feature 11)
// Personal Exposure Score calculator
// ─────────────────────────────────────────────────────────────
class _ExposureTab extends StatefulWidget {
  const _ExposureTab();
  @override
  State<_ExposureTab> createState() => _ExposureTabState();
}

class _ExposureTabState extends State<_ExposureTab> {
  double _hoursOutdoor  = 2.0;
  String _activityLevel = 'Light';
  double _score         = 0;
  bool   _calculated    = false;

  static const _activities = ['Resting', 'Light', 'Moderate', 'Heavy'];
  static const _breathMultiplier = {
    'Resting' : 0.5,
    'Light'   : 1.0,
    'Moderate': 1.8,
    'Heavy'   : 2.5,
  };

  void _calculate() {
    final aqi = context.read<AqiProvider>().latestAqi;
    final mult = _breathMultiplier[_activityLevel] ?? 1.0;
    // Exposure score = AQI × hours × breathing rate multiplier (capped 0–100)
    final raw = (aqi / 300) * _hoursOutdoor * mult * 100 / 8;
    setState(() { _score = raw.clamp(0, 100); _calculated = true; });
  }

  String _scoreLabel() {
    if (_score < 20) return 'Minimal';
    if (_score < 40) return 'Low';
    if (_score < 60) return 'Moderate';
    if (_score < 80) return 'High';
    return 'Very High';
  }

  Color _scoreColor() {
    if (_score < 20) return AppTheme.safeGreen;
    if (_score < 40) return const Color(0xFF8BC34A);
    if (_score < 60) return AppTheme.moderateYellow;
    if (_score < 80) return AppTheme.warningOrange;
    return AppTheme.hazardousRed;
  }

  String _advice() {
    if (_score < 20) return 'Your estimated exposure is minimal. No precautions needed.';
    if (_score < 40) return 'Low exposure risk. Healthy individuals should be fine.';
    if (_score < 60) return 'Moderate exposure. Consider reducing outdoor time or wearing a mask.';
    if (_score < 80) return 'High exposure risk. Wear an N95 mask and take breaks indoors.';
    return 'Very high exposure risk. Strongly consider staying indoors or significantly reducing outdoor activity.';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AqiProvider>(builder: (_, aqi, __) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Current conditions ────────────────────────
          _InsightCard(
            icon: Icons.person_rounded,
            iconColor: const Color(0xFF6C63FF),
            title: 'Personal Exposure Calculator',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DataRow(
                  icon: Icons.air_rounded,
                  color: MockAiService.getStatusColor(aqi.latestStatus),
                  text: 'Current AQI: ${aqi.latestAqi.toStringAsFixed(0)} '
                        '(${aqi.latestStatus}) at ${aqi.selectedCityName}',
                ),
                const SizedBox(height: 16),
                const Text('Hours spent outdoors today:',
                    style: TextStyle(fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 6),
                Row(children: [
                  Expanded(
                    child: Slider(
                      value: _hoursOutdoor,
                      min: 0, max: 12, divisions: 24,
                      activeColor: AppTheme.primaryBlue,
                      onChanged: (v) =>
                          setState(() => _hoursOutdoor = v),
                    ),
                  ),
                  Text('${_hoursOutdoor.toStringAsFixed(1)}h',
                      style: const TextStyle(fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryBlue)),
                ]),
                const SizedBox(height: 12),
                const Text('Activity level outdoors:',
                    style: TextStyle(fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _activities.map((a) => GestureDetector(
                    onTap: () => setState(() => _activityLevel = a),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: _activityLevel == a
                            ? AppTheme.primaryBlue
                            : AppTheme.primaryBlueLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(a, style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700,
                        color: _activityLevel == a
                            ? Colors.white
                            : AppTheme.primaryBlue,
                      )),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _calculate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.calculate_rounded, size: 18),
                    label: const Text('Calculate Exposure Score',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Score result ──────────────────────────────
          if (_calculated)
            _InsightCard(
              icon: Icons.health_and_safety_rounded,
              iconColor: _scoreColor(),
              title: 'Exposure Score',
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: _score),
                    duration: const Duration(milliseconds: 800),
                    builder: (_, v, __) => Text(
                      v.toStringAsFixed(0),
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w900,
                        color: _scoreColor(),
                      ),
                    ),
                  ),
                  const Text('/100',
                      style: TextStyle(fontSize: 18,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600)),
                ]),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: _scoreColor(),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(_scoreLabel(),
                      style: const TextStyle(color: Colors.white,
                          fontWeight: FontWeight.w800, fontSize: 14)),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _score / 100,
                    minHeight: 10,
                    backgroundColor: _scoreColor().withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation(_scoreColor()),
                  ),
                ),
                const SizedBox(height: 12),
                Text(_advice(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12,
                        color: AppTheme.textPrimary, height: 1.5)),
                const SizedBox(height: 8),
                Text(
                  'Based on: AQI ${aqi.latestAqi.toStringAsFixed(0)} × '
                  '${_hoursOutdoor.toStringAsFixed(1)}h × '
                  '${_activityLevel.toLowerCase()} activity',
                  style: const TextStyle(fontSize: 10,
                      color: AppTheme.textLight),
                ),
              ]),
            ),
          const SizedBox(height: 8),
        ],
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────
// Shared helper widgets
// ─────────────────────────────────────────────────────────────
class _InsightCard extends StatelessWidget {
  final IconData  icon;
  final Color     iconColor;
  final String    title;
  final Widget    child;
  final Widget?   trailing;

  const _InsightCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 8),
            child: Row(children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 15, color: iconColor),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(title,
                  style: const TextStyle(fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary))),
              if (trailing != null) trailing!,
            ]),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.all(14),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   text;
  const _DataRow(
      {required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(text,
            style: const TextStyle(fontSize: 12,
                color: AppTheme.textPrimary, height: 1.4))),
      ]),
    );
  }
}

class _EmptyDataMsg extends StatelessWidget {
  const _EmptyDataMsg();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 16),
    child: Center(
      child: Column(children: [
        Icon(Icons.history_rounded,
            size: 32, color: AppTheme.textLight),
        SizedBox(height: 8),
        Text('No readings yet. Use the Analyze tab to save data.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12,
                color: AppTheme.textSecondary)),
      ]),
    ),
  );
}
