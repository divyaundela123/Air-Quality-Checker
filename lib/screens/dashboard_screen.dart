import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/aqi_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../services/mock_ai_service.dart';
import '../widgets/db_status_banner.dart';
import '../widgets/screen_background.dart';
import 'calculate_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  static List<_NavItem> _buildNavItems(AppStrings s) => [
    _NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: s.dashboard),
    _NavItem(icon: Icons.calculate_outlined, activeIcon: Icons.calculate, label: s.analyze),
    _NavItem(icon: Icons.history_outlined,   activeIcon: Icons.history,   label: s.history),
    _NavItem(icon: Icons.person_outline,     activeIcon: Icons.person,    label: s.profile),
  ];

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LanguageProvider>().strings;
    final navItems = _buildNavItems(s);
    final isWeb = MediaQuery.of(context).size.width >= 700;

    final List<Widget> screens = [
      _HomeTab(onNavigateToAnalyze: () => setState(() => _currentIndex = 1)),
      const CalculateScreen(),
      const HistoryScreen(),
      const ProfileScreen(),
    ];

    if (isWeb) {
      return Scaffold(
        backgroundColor: AppTheme.scaffoldBg,
        body: Column(
          children: [
            _WebTopBar(
              currentIndex: _currentIndex,
              items: navItems,
              onTap: (i) => setState(() => _currentIndex = i),
            ),
            const DbStatusBanner(),
            Expanded(
              child: Stack(
                children: [
                  IndexedStack(index: _currentIndex, children: screens),
                  Positioned(
                    right: 0, top: 0, bottom: 0,
                    child: Center(
                      child: _FloatingRingNav(
                        currentIndex: _currentIndex,
                        items: navItems,
                        onTap: (i) => setState(() => _currentIndex = i),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            elevation: 0,
            backgroundColor: Colors.transparent,
            selectedItemColor: AppTheme.primaryBlue,
            unselectedItemColor: AppTheme.textLight,
            type: BottomNavigationBarType.fixed,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
            items: navItems
                .map((e) => BottomNavigationBarItem(
                      icon: Icon(e.icon),
                      activeIcon: Icon(e.activeIcon),
                      label: e.label,
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Nav item data class
// ─────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}

// ─────────────────────────────────────────────
// Slim Web Top Bar — logo + live + avatar only
// ─────────────────────────────────────────────
class _WebTopBar extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;

  const _WebTopBar({
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<AqiProvider, AuthProvider>(
      builder: (context, aqiProvider, authProvider, _) {
        return Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 28),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 16,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Logo
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryBlue, AppTheme.accentBlue],
                  ),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.air, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              const Text('AeroSense',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary)),

              const Spacer(),

              // Nav labels — REMOVED (ring nav handles navigation)

              // Live indicator only — avatar is in the ring nav
              _LiveIndicator(aqiProvider: aqiProvider),
              const SizedBox(width: 12),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Floating Circular Ring Nav
// Fixed right side, vertically centered
// Large donut with 4 arc segments + labels
// Each segment has its own theme color
// ─────────────────────────────────────────────

// Per-segment theme colors matching each screen
const _segmentColors = [
  Color(0xFF4B7FFF), // Dashboard — primary blue
  Color(0xFFFF8C42), // Analyze   — amber/orange (air quality feel)
  Color(0xFF9575CD), // History   — purple
  Color(0xFF26A69A), // Profile   — teal
];

const _segmentInactiveColors = [
  Color(0xFFDDE6FF), // Dashboard inactive
  Color(0xFFFFEDD8), // Analyze inactive
  Color(0xFFEDE7F6), // History inactive
  Color(0xFFE0F2F1), // Profile inactive
];

class _FloatingRingNav extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;

  const _FloatingRingNav({
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const double ringSize = 180;
    final activeColor = _segmentColors[currentIndex];

    return Container(
      width: ringSize + 48,
      height: ringSize + 48,
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow shadow behind ring
          Container(
            width: ringSize + 8,
            height: ringSize + 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: activeColor.withValues(alpha: 0.22),
                  blurRadius: 32,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),

          // Ring segments
          CustomPaint(
            size: const Size(ringSize, ringSize),
            painter: _RingNavPainter(
              count: items.length,
              activeIndex: currentIndex,
              segmentColors: _segmentColors,
              inactiveColors: _segmentInactiveColors,
              gapRadians: 0.08,
            ),
          ),

          // Center circle — AeroSense logo with active color
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [activeColor, activeColor.withValues(alpha: 0.75)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: activeColor.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.air, color: Colors.white, size: 26),
          ),

          // Tap zones + icons + labels over each segment
          ...List.generate(items.length, (i) => _RingSegmentButton(
            index: i,
            count: items.length,
            ringSize: ringSize,
            icon: i == currentIndex ? items[i].activeIcon : items[i].icon,
            label: items[i].label,
            isActive: i == currentIndex,
            activeColor: _segmentColors[i],
            onTap: () => onTap(i),
          )),
        ],
      ),
    );
  }
}

// ─── Ring painter — per-segment colors ────────────────────────────────────
class _RingNavPainter extends CustomPainter {
  final int count;
  final int activeIndex;
  final List<Color> segmentColors;
  final List<Color> inactiveColors;
  final double gapRadians;

  const _RingNavPainter({
    required this.count,
    required this.activeIndex,
    required this.segmentColors,
    required this.inactiveColors,
    this.gapRadians = 0.08,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outerR = size.width / 2;
    final innerR = outerR * 0.36;
    final sweepAngle = (2 * math.pi / count) - gapRadians;

    for (int i = 0; i < count; i++) {
      final startAngle = -math.pi / 2 + i * (2 * math.pi / count) + gapRadians / 2;
      final isActive = i == activeIndex;
      final color = isActive ? segmentColors[i] : inactiveColors[i];

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;

      final path = Path();
      path.arcTo(Rect.fromCircle(center: Offset(cx, cy), radius: outerR),
          startAngle, sweepAngle, false);
      path.arcTo(Rect.fromCircle(center: Offset(cx, cy), radius: innerR),
          startAngle + sweepAngle, -sweepAngle, false);
      path.close();
      canvas.drawPath(path, paint);

      // Active segment border glow
      if (isActive) {
        final glowPaint = Paint()
          ..color = segmentColors[i].withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..isAntiAlias = true;
        canvas.drawPath(path, glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_RingNavPainter old) =>
      old.activeIndex != activeIndex || old.count != count;
}

// ─── Individual segment button with icon + label ───────────────────────────
class _RingSegmentButton extends StatelessWidget {
  final int index;
  final int count;
  final double ringSize;
  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _RingSegmentButton({
    required this.index,
    required this.count,
    required this.ringSize,
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final outerR = ringSize / 2;
    final innerR = outerR * 0.36;
    final midR = (outerR + innerR) / 2;

    final segAngle = 2 * math.pi / count;
    final midAngle = -math.pi / 2 + index * segAngle + segAngle / 2;

    final cx = ringSize / 2 + midR * math.cos(midAngle);
    final cy = ringSize / 2 + midR * math.sin(midAngle);
    final segW = (outerR - innerR) * 0.9;

    return Positioned(
      left: cx - segW / 2,
      top: cy - segW / 2,
      child: Tooltip(
        message: label,
        preferBelow: false,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: segW,
            height: segW,
            color: Colors.transparent,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                  size: 16,
                  color: isActive ? Colors.white : activeColor,
                ),
                const SizedBox(height: 3),
                Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: isActive ? Colors.white : activeColor,
                    letterSpacing: 0.1,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────
// Home Tab (AQI Gauge + Quick stats)
// ─────────────────────────────────────────────
class _HomeTab extends StatefulWidget {
  final VoidCallback onNavigateToAnalyze;
  const _HomeTab({required this.onNavigateToAnalyze});

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AqiProvider, AuthProvider>(
      builder: (context, aqiProvider, authProvider, _) {
        final double aqi = aqiProvider.latestAqi;
        final String status = aqiProvider.latestStatus;
        final Color statusColor = MockAiService.getStatusColor(status);
        final bool hasData = aqiProvider.latestRecord != null && aqiProvider.hasLiveData;
        final bool isWeb = MediaQuery.of(context).size.width >= 700;
        final s = context.read<LanguageProvider>().strings;

        return Scaffold(
          backgroundColor: AppTheme.scaffoldBg,
          body: ScreenBackground(
            theme: ScreenTheme.dashboard,
            child: CustomScrollView(
            slivers: [
              // App Bar — mobile only
              if (!isWeb)
                SliverAppBar(
                  expandedHeight: 0,
                  floating: true,
                  pinned: false,
                  backgroundColor: AppTheme.cardBg,
                  elevation: 0,
                  title: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.primaryBlue, AppTheme.accentBlue],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.air, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Text('AeroSense',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary)),
                    ],
                  ),
                  actions: [
                    _LiveIndicator(aqiProvider: aqiProvider),
                    const SizedBox(width: 8),
                  ],
                ),

              // DB status banner — mobile only, shown below AppBar
              if (!isWeb)
                const SliverToBoxAdapter(child: SizedBox.shrink()),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Greeting
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${s.hello}, ${authProvider.currentUserName.isNotEmpty ? authProvider.currentUserName.split(' ').first : 'there'} 👋',
                                  style: const TextStyle(fontSize: 22,
                                      fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                                ),
                                const SizedBox(height: 4),
                                Text(s.airQualityReport,
                                    style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                              ],
                            ),
                          ),
                          // Cloud sync button — web only
                          if (isWeb) ...[
                            if (aqiProvider.isSyncing)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlueLight,
                                  borderRadius: BorderRadius.circular(20)),
                                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                  SizedBox(width: 10, height: 10,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 1.5, color: AppTheme.primaryBlue)),
                                  SizedBox(width: 6),
                                  Text('Syncing', style: TextStyle(
                                      fontSize: 11, color: AppTheme.primaryBlue,
                                      fontWeight: FontWeight.w600)),
                                ]),
                              )
                            else
                              IconButton(
                                icon: const Icon(Icons.cloud_sync_rounded,
                                    size: 20, color: AppTheme.primaryBlue),
                                tooltip: 'Sync with cloud database',
                                onPressed: () => aqiProvider.syncFromCloud(),
                              ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Main Gauge Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              statusColor.withValues(alpha: 0.12),
                              statusColor.withValues(alpha: 0.04),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.25),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            // Status Badge
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: statusColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    MockAiService.getStatusIcon(status),
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    s.statusLabel(status),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Gauge
                            SizedBox(
                              height: 220,
                              child: hasData
                                  ? _buildGauge(aqi, statusColor, s)
                                  : aqiProvider.isFetchingLive
                                      ? const Center(
                                          child: CircularProgressIndicator(),
                                        )
                                      : _buildEmptyGauge(),
                            ),

                            if (!hasData && !aqiProvider.isFetchingLive) ...[
                              const SizedBox(height: 12),
                              const Text(
                                'No data yet. Tap Analyzer to get started!',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: widget.onNavigateToAnalyze,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryBlue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.analytics, size: 18),
                                label: const Text('Go to Analyzer', style: TextStyle(fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Quick stats row
                      _QuickStatsRow(
                        temperature: aqiProvider.latestTemperature,
                        humidity: aqiProvider.latestHumidity,
                        co2: aqiProvider.latestCo2,
                        voc: aqiProvider.latestVoc,
                        hasData: aqiProvider.hasLiveData || hasData,
                      ),

                      const SizedBox(height: 20),

                      // Recommendation card
                      if (hasData || aqiProvider.hasLiveData)
                        _RecommendationCard(
                          status: status,
                          statusColor: statusColor,
                        ),

                      const SizedBox(height: 20),

                      // Recent readings summary
                      if (aqiProvider.records.length > 1)
                        _WeeklySummaryCard(provider: aqiProvider),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),  // ScreenBackground
        );
      },
    );
  }

  Widget _buildGauge(double aqi, Color statusColor, AppStrings s) {
    return SfRadialGauge(
      animationDuration: 1500,
      enableLoadingAnimation: true,
      axes: [
        RadialAxis(
          minimum: 0,
          maximum: 300,
          interval: 50,
          startAngle: 150,
          endAngle: 30,
          showLabels: true,
          showTicks: true,
          labelOffset: 12,
          majorTickStyle: const MajorTickStyle(
            length: 10,
            thickness: 2,
            color: Color(0xFFDDE1E7),
          ),
          minorTickStyle: const MinorTickStyle(
            length: 6,
            thickness: 1,
            color: Color(0xFFDDE1E7),
          ),
          axisLineStyle: const AxisLineStyle(
            thickness: 18,
            cornerStyle: CornerStyle.bothCurve,
            color: Color(0xFFEEF0F5),
          ),
          axisLabelStyle: const GaugeTextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
          ),
          ranges: [
            GaugeRange(
              startValue: 0,
              endValue: 50,
              color: AppTheme.safeGreen,
              startWidth: 18,
              endWidth: 18,
            ),
            GaugeRange(
              startValue: 50,
              endValue: 100,
              color: AppTheme.moderateYellow,
              startWidth: 18,
              endWidth: 18,
            ),
            GaugeRange(
              startValue: 100,
              endValue: 150,
              color: AppTheme.warningOrange,
              startWidth: 18,
              endWidth: 18,
            ),
            GaugeRange(
              startValue: 150,
              endValue: 300,
              color: AppTheme.hazardousRed,
              startWidth: 18,
              endWidth: 18,
            ),
          ],
          pointers: [
            NeedlePointer(
              value: aqi.clamp(0, 300),
              needleLength: 0.75,
              needleStartWidth: 2,
              needleEndWidth: 8,
              needleColor: statusColor,
              knobStyle: KnobStyle(
                color: statusColor,
                borderColor: Colors.white,
                borderWidth: 0.05,
                knobRadius: 0.08,
              ),
              enableAnimation: true,
              animationType: AnimationType.ease,
            ),
          ],
          annotations: [
            GaugeAnnotation(
              widget: SizedBox(
                width: 130,
                height: 90,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      aqi.toStringAsFixed(0),
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                        letterSpacing: -1,
                      ),
                    ),
                    Text(
                      s.aqiScore,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              angle: 90,
              positionFactor: 0.5,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyGauge() {
    return SfRadialGauge(
      axes: [
        RadialAxis(
          minimum: 0,
          maximum: 300,
          interval: 50,
          startAngle: 150,
          endAngle: 30,
          showLabels: true,
          showTicks: true,
          axisLineStyle: const AxisLineStyle(
            thickness: 18,
            cornerStyle: CornerStyle.bothCurve,
            color: Color(0xFFEEF0F5),
          ),
          axisLabelStyle: const GaugeTextStyle(
            color: AppTheme.textLight,
            fontSize: 11,
          ),
          annotations: [
            GaugeAnnotation(
              widget: SizedBox(
                width: 120,
                height: 90,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.air,
                      size: 36,
                      color: AppTheme.textLight,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '– –',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textLight,
                      ),
                    ),
                    Builder(builder: (ctx) => Text(
                      ctx.read<LanguageProvider>().strings.noReading,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textLight,
                      ),
                    )),
                  ],
                ),
              ),
              angle: 90,
              positionFactor: 0.5,
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Quick Stats Row
// ─────────────────────────────────────────────
class _QuickStatsRow extends StatelessWidget {
  final double temperature;
  final double humidity;
  final double co2;
  final double voc;
  final bool hasData;

  const _QuickStatsRow({
    required this.temperature,
    required this.humidity,
    required this.co2,
    required this.voc,
    required this.hasData,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.read<LanguageProvider>().strings;
    return Row(
      children: [
        _StatCard(
          icon: Icons.thermostat,
          label: s.temperature,
          value: hasData ? '${temperature.toStringAsFixed(1)}°C' : '–',
          color: const Color(0xFFFF6B6B),
        ),
        const SizedBox(width: 10),
        _StatCard(
          icon: Icons.water_drop,
          label: s.humidity,
          value: hasData ? '${humidity.toStringAsFixed(0)}%' : '–',
          color: const Color(0xFF4FC3F7),
        ),
        const SizedBox(width: 10),
        _StatCard(
          icon: Icons.cloud,
          label: 'CO₂',
          value: hasData ? '${co2.toStringAsFixed(0)}ppm' : '–',
          color: const Color(0xFF9575CD),
        ),
        const SizedBox(width: 10),
        _StatCard(
          icon: Icons.science,
          label: 'VOC',
          value: hasData ? '${voc.toStringAsFixed(0)}ppb' : '–',
          color: const Color(0xFF4DB6AC),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Recommendation Card
// ─────────────────────────────────────────────
class _RecommendationCard extends StatelessWidget {
  final String status;
  final Color statusColor;
  const _RecommendationCard({required this.status, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    final s = context.read<LanguageProvider>().strings;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
        border: Border(
          left: BorderSide(color: statusColor, width: 4),
        ),
      ),
      child: Row(
        children: [
          Icon(
            MockAiService.getStatusIcon(status),
            color: statusColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.recommendation,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s.recommendationText(status),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Weekly Summary Card
// ─────────────────────────────────────────────
class _WeeklySummaryCard extends StatelessWidget {
  final AqiProvider provider;

  const _WeeklySummaryCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final s = context.read<LanguageProvider>().strings;
    final weeklyAvg = provider.weeklyAvgAqi;
    final totalReadings = provider.records.length;
    final bestReading = provider.records.isNotEmpty
        ? provider.records.map((r) => r.aqiScore).reduce((a, b) => a < b ? a : b)
        : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryBlue, AppTheme.accentBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.summary,
              style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SummaryItem(label: s.avgAqi7d,     value: weeklyAvg.toStringAsFixed(1)),
              _SummaryItem(label: s.totalReadings, value: '$totalReadings'),
              _SummaryItem(label: s.bestReading,   value: bestReading.toStringAsFixed(0)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Live Indicator (badge + refresh + timestamp)
// ─────────────────────────────────────────────
class _LiveIndicator extends StatelessWidget {
  final AqiProvider aqiProvider;
  const _LiveIndicator({required this.aqiProvider});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LanguageProvider>().strings;
    final isFetching = aqiProvider.isFetchingLive;
    final lastUpdated = aqiProvider.lastUpdated;
    final hasError = aqiProvider.liveError != null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // LIVE badge or error
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: hasError
                ? Colors.red.withValues(alpha: 0.12)
                : const Color(0xFF4CAF50).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasError
                  ? Colors.red.withValues(alpha: 0.4)
                  : const Color(0xFF4CAF50).withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isFetching)
                const SizedBox(
                  width: 8,
                  height: 8,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: Color(0xFF4CAF50),
                  ),
                )
              else
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: hasError ? Colors.red : const Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                  ),
                ),
              const SizedBox(width: 5),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasError ? s.offline : s.live,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: hasError ? Colors.red : const Color(0xFF4CAF50),
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (lastUpdated != null && !hasError)
                    Text(
                      DateFormat('HH:mm:ss').format(lastUpdated),
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        // Manual refresh button
        IconButton(
          icon: const Icon(Icons.refresh_rounded, size: 20),
          color: AppTheme.primaryBlue,
          tooltip: 'Refresh live data',
          onPressed: isFetching ? null : () => aqiProvider.fetchLiveData(),
        ),
      ],
    );
  }
}
