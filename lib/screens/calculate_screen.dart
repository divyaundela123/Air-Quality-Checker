import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/aqi_provider.dart';
import '../providers/language_provider.dart';
import '../l10n/app_strings.dart';
import '../services/mock_ai_service.dart';
import '../theme/app_theme.dart';
import '../widgets/screen_background.dart';

class CalculateScreen extends StatefulWidget {
  const CalculateScreen({super.key});

  @override
  State<CalculateScreen> createState() => _CalculateScreenState();
}

class _CalculateScreenState extends State<CalculateScreen>
    with SingleTickerProviderStateMixin {
  bool _isAnalyzing = false;

  late AnimationController _resultController;
  late Animation<double> _resultAnim;

  @override
  void initState() {
    super.initState();
    _resultController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _resultAnim = CurvedAnimation(
      parent: _resultController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _resultController.dispose();
    super.dispose();
  }

  Future<void> _analyzeAirQuality(AqiProvider provider) async {
    if (!provider.hasLiveData) return;
    setState(() => _isAnalyzing = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    await provider.addRecord(
      temperature: provider.latestTemperature,
      humidity: provider.latestHumidity,
      co2: provider.latestCo2,
      voc: provider.latestVoc,
    );
    setState(() => _isAnalyzing = false);
    _resultController..reset()..forward();
    if (!mounted) return;
    final status = provider.latestStatus;
    final color = MockAiService.getStatusColor(status);
    final snackColor =
        status == 'Hazardous' || status == 'Warning' ? color : AppTheme.safeGreen;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(MockAiService.getStatusIcon(status), color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Analysis saved! AQI: ${provider.latestAqi.toStringAsFixed(1)} – $status',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: snackColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width >= 700;
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: isWeb
          ? null
          : AppBar(
              title: Text(context.read<LanguageProvider>().strings.analyzeTitle),
              automaticallyImplyLeading: false,
            ),
      body: Consumer<AqiProvider>(
        builder: (context, provider, _) {
          return ScreenBackground(
            theme: ScreenTheme.analyze,
            child: isWeb
              ? _WebLayout(
                  provider: provider,
                  isAnalyzing: _isAnalyzing,
                  resultAnim: _resultAnim,
                  onAnalyze: () => _analyzeAirQuality(provider),
                )
              : _MobileLayout(
                  provider: provider,
                  isAnalyzing: _isAnalyzing,
                  resultAnim: _resultAnim,
                  onAnalyze: () => _analyzeAirQuality(provider),
                ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// WEB layout — two-column, matches dashboard
// ─────────────────────────────────────────────
class _WebLayout extends StatelessWidget {
  final AqiProvider provider;
  final bool isAnalyzing;
  final Animation<double> resultAnim;
  final VoidCallback onAnalyze;

  const _WebLayout({
    required this.provider,
    required this.isAnalyzing,
    required this.resultAnim,
    required this.onAnalyze,
  });

  @override
  Widget build(BuildContext context) {
    final hasLive = provider.hasLiveData;
    final isFetching = provider.isFetchingLive;
    final status = provider.latestStatus;
    final aqi = provider.latestAqi;
    final color = MockAiService.getStatusColor(status);
    final s = context.read<LanguageProvider>().strings;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(s.analyzeTitle,
                  style: const TextStyle(fontSize: 22,
                      fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
              const Spacer(),
              _RefreshButton(provider: provider),
            ],
          ),
          const SizedBox(height: 4),
          Text(s.realTimeSensorSubtitle,
              style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    _AqiPreviewCard(
                      hasLive: hasLive, isFetching: isFetching,
                      aqi: aqi, status: status, color: color, resultAnim: resultAnim,
                    ),
                    const SizedBox(height: 16),
                    if (hasLive) _WebRecommendationCard(status: status, color: color),
                    if (hasLive) const SizedBox(height: 16),
                    _AnalyzeButton(
                      hasLive: hasLive, isAnalyzing: isAnalyzing,
                      color: color, onAnalyze: onAnalyze,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 2,
                child: _OverviewPanel(provider: provider, hasLive: hasLive),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// MOBILE layout — original single-column scroll
// ─────────────────────────────────────────────
class _MobileLayout extends StatelessWidget {
  final AqiProvider provider;
  final bool isAnalyzing;
  final Animation<double> resultAnim;
  final VoidCallback onAnalyze;

  const _MobileLayout({
    required this.provider,
    required this.isAnalyzing,
    required this.resultAnim,
    required this.onAnalyze,
  });

  @override
  Widget build(BuildContext context) {
    final hasLive = provider.hasLiveData;
    final isFetching = provider.isFetchingLive;
    final status = provider.latestStatus;
    final aqi = provider.latestAqi;
    final color = MockAiService.getStatusColor(status);
    final s = context.read<LanguageProvider>().strings;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AqiPreviewCard(
            hasLive: hasLive, isFetching: isFetching,
            aqi: aqi, status: status, color: color, resultAnim: resultAnim,
          ),
          if (!hasLive && isFetching) ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(s.fetchingLiveSensor,
                      style: const TextStyle(color: AppTheme.textSecondary)),
                ]),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Text(s.liveSensorReadings,
                  style: const TextStyle(fontSize: 18,
                      fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
              const Spacer(),
              _RefreshButton(provider: provider),
            ],
          ),
          const SizedBox(height: 4),
          Text(s.valuesAutoRead,
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          const SizedBox(height: 20),
          _SensorReadingCard(
            label: s.temperature,
            value: hasLive ? '${provider.latestTemperature.toStringAsFixed(1)} °C' : '– –',
            icon: Icons.thermostat, color: const Color(0xFFFF6B6B),
            subtitle: _tempLabel(provider.latestTemperature, s),
            isLoading: !hasLive && isFetching,
          ),
          const SizedBox(height: 14),
          _SensorReadingCard(
            label: s.humidity,
            value: hasLive ? '${provider.latestHumidity.toStringAsFixed(0)} %' : '– –',
            icon: Icons.water_drop, color: const Color(0xFF4FC3F7),
            subtitle: _humidityLabel(provider.latestHumidity, s),
            isLoading: !hasLive && isFetching,
          ),
          const SizedBox(height: 14),
          _SensorReadingCard(
            label: 'CO₂',
            value: hasLive ? '${provider.latestCo2.toStringAsFixed(0)} ppm' : '– –',
            icon: Icons.cloud, color: const Color(0xFF9575CD),
            subtitle: _co2Label(provider.latestCo2, s),
            isLoading: !hasLive && isFetching,
          ),
          const SizedBox(height: 14),
          _SensorReadingCard(
            label: 'VOC',
            value: hasLive ? '${provider.latestVoc.toStringAsFixed(0)} ppb' : '– –',
            icon: Icons.science, color: const Color(0xFF4DB6AC),
            subtitle: _vocLabel(provider.latestVoc, s),
            isLoading: !hasLive && isFetching,
          ),
          if (provider.lastUpdated != null) ...[
            const SizedBox(height: 12),
            Center(child: Text(
              'Last updated: ${_fmt(provider.lastUpdated!)}  •  ${s.lastUpdatedAuto}',
              style: const TextStyle(fontSize: 11, color: AppTheme.textLight),
            )),
          ],
          const SizedBox(height: 32),
          _AnalyzeButton(
            hasLive: hasLive, isAnalyzing: isAnalyzing,
            color: color, onAnalyze: onAnalyze,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// AQI Preview Card (shared mobile + web)
// ─────────────────────────────────────────────
class _AqiPreviewCard extends StatelessWidget {
  final bool hasLive;
  final bool isFetching;
  final double aqi;
  final String status;
  final Color color;
  final Animation<double> resultAnim;

  const _AqiPreviewCard({
    required this.hasLive,
    required this.isFetching,
    required this.aqi,
    required this.status,
    required this.color,
    required this.resultAnim,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasLive && isFetching) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.cardShadow,
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 14),
              Text('Fetching live sensor data…',
                  style: TextStyle(color: AppTheme.textSecondary)),
            ],
          ),
        ),
      );
    }
    if (!hasLive) return const SizedBox.shrink();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Builder(builder: (context) {
            final s = context.read<LanguageProvider>().strings;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.realTimeAqi,
                    style: const TextStyle(color: Colors.white70, fontSize: 12,
                        fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                const SizedBox(height: 6),
                Text(aqi.toStringAsFixed(1),
                    style: const TextStyle(color: Colors.white, fontSize: 42,
                        fontWeight: FontWeight.w800, letterSpacing: -1)),
                Text(s.aqiScore,
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            );
          }),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Builder(builder: (ctx) => Text(
                    ctx.read<LanguageProvider>().strings.statusLabel(status),
                    style: const TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w700, fontSize: 14))),
              ),
              const SizedBox(height: 12),
              Icon(MockAiService.getStatusIcon(status), color: Colors.white, size: 36),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Overview Panel (web right column)
// ─────────────────────────────────────────────
class _OverviewPanel extends StatelessWidget {
  final AqiProvider provider;
  final bool hasLive;

  const _OverviewPanel({required this.provider, required this.hasLive});

  @override
  Widget build(BuildContext context) {
    final s = context.read<LanguageProvider>().strings;
    final sensors = [
      _SensorRow(icon: Icons.thermostat, color: const Color(0xFFFF6B6B),
          label: s.temperature,
          value: hasLive ? '${provider.latestTemperature.toStringAsFixed(1)} °C' : '– –',
          subtitle: _tempLabel(provider.latestTemperature, s)),
      _SensorRow(icon: Icons.water_drop, color: const Color(0xFF4FC3F7),
          label: s.humidity,
          value: hasLive ? '${provider.latestHumidity.toStringAsFixed(0)} %' : '– –',
          subtitle: _humidityLabel(provider.latestHumidity, s)),
      _SensorRow(icon: Icons.cloud, color: const Color(0xFF9575CD),
          label: 'CO₂',
          value: hasLive ? '${provider.latestCo2.toStringAsFixed(0)} ppm' : '– –',
          subtitle: _co2Label(provider.latestCo2, s)),
      _SensorRow(icon: Icons.science, color: const Color(0xFF4DB6AC),
          label: 'VOC',
          value: hasLive ? '${provider.latestVoc.toStringAsFixed(0)} ppb' : '– –',
          subtitle: _vocLabel(provider.latestVoc, s)),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded, color: AppTheme.primaryBlue, size: 20),
              const SizedBox(width: 8),
              Text(s.overview,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          ...sensors.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: s,
          )),
          if (provider.lastUpdated != null) ...[
            const Divider(height: 24),
            Text(
              s.updatedAt(_fmt(provider.lastUpdated!)),
              style: const TextStyle(fontSize: 11, color: AppTheme.textLight),
            ),
          ],
        ],
      ),
    );
  }
}

class _SensorRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String? subtitle;

  const _SensorRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 13,
                    fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                if (subtitle != null)
                  Text(subtitle!, style: TextStyle(
                    fontSize: 11,
                    color: subtitle!.contains('High') || subtitle!.contains('!')
                        ? AppTheme.warningOrange : AppTheme.textSecondary,
                  )),
              ],
            ),
          ),
          Text(value, style: TextStyle(fontSize: 14,
              fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Web Recommendation Card
// ─────────────────────────────────────────────
class _WebRecommendationCard extends StatelessWidget {
  final String status;
  final Color color;

  const _WebRecommendationCard({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Row(
        children: [
          Icon(MockAiService.getStatusIcon(status), color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Builder(builder: (ctx) => Text(
                    ctx.read<LanguageProvider>().strings.recommendation,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                        color: color, letterSpacing: 0.5))),
                const SizedBox(height: 4),
                Builder(builder: (ctx) => Text(
                    ctx.read<LanguageProvider>().strings.recommendationText(status),
                    style: const TextStyle(fontSize: 13,
                        color: AppTheme.textSecondary, height: 1.5))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Analyze / Save button (shared)
// ─────────────────────────────────────────────
class _AnalyzeButton extends StatelessWidget {
  final bool hasLive;
  final bool isAnalyzing;
  final Color color;
  final VoidCallback onAnalyze;

  const _AnalyzeButton({
    required this.hasLive,
    required this.isAnalyzing,
    required this.color,
    required this.onAnalyze,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.read<LanguageProvider>().strings;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: (hasLive && !isAnalyzing) ? onAnalyze : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppTheme.textLight.withValues(alpha: 0.3),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        child: isAnalyzing
            ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
                const SizedBox(width: 12),
                Text(s.analyzing),
              ])
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.analytics, size: 20),
                const SizedBox(width: 10),
                Text(s.saveAnalysis),
              ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Refresh Button (shared)
// ─────────────────────────────────────────────
class _RefreshButton extends StatelessWidget {
  final AqiProvider provider;
  const _RefreshButton({required this.provider});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LanguageProvider>().strings;
    final isFetching = provider.isFetchingLive;
    return GestureDetector(
      onTap: isFetching ? null : provider.fetchLiveData,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.primaryBlueLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            isFetching
                ? const SizedBox(width: 12, height: 12,
                    child: CircularProgressIndicator(
                        strokeWidth: 1.5, color: AppTheme.primaryBlue))
                : const Icon(Icons.refresh_rounded, size: 14, color: AppTheme.primaryBlue),
            const SizedBox(width: 5),
            Text(s.refresh,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                    color: AppTheme.primaryBlue)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Sensor Reading Card (mobile only)
// ─────────────────────────────────────────────
class _SensorReadingCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final bool isLoading;

  const _SensorReadingCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 15,
                    fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: TextStyle(
                    fontSize: 12,
                    color: subtitle!.contains('High') || subtitle!.contains('!')
                        ? AppTheme.warningOrange : AppTheme.textSecondary,
                    fontWeight: subtitle!.contains('High') || subtitle!.contains('!')
                        ? FontWeight.w600 : FontWeight.normal,
                  )),
                ],
              ],
            ),
          ),
          if (isLoading)
            const SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2))
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(value, style: TextStyle(color: color, fontSize: 15,
                  fontWeight: FontWeight.w800)),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Shared label helpers
// ─────────────────────────────────────────────
String? _tempLabel(double v, AppStrings s) {
  if (v <= 0) return null;
  if (v > 35) return s.highTemp;
  if (v > 28) return s.warm;
  if (v < 10) return s.cold;
  return s.comfortable;
}

String? _humidityLabel(double v, AppStrings s) {
  if (v <= 0) return null;
  if (v > 80) return s.highHumidity;
  if (v > 60) return s.humid;
  if (v < 30) return s.dry;
  return s.comfortableRange;
}

String? _co2Label(double v, AppStrings s) {
  if (v <= 0) return null;
  if (v > 1500) return s.highCo2;
  if (v > 1000) return s.elevated;
  return s.acceptable;
}

String? _vocLabel(double v, AppStrings s) {
  if (v <= 0) return null;
  if (v > 700) return s.highVoc;
  if (v > 300) return s.acceptable;
  return s.good;
}

String _fmt(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  final s = dt.second.toString().padLeft(2, '0');
  return '$h:$m:$s';
}
