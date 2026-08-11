import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Wraps any screen body with a themed decorative background.
/// The background is purely visual — painted behind all content.
class ScreenBackground extends StatelessWidget {
  final Widget child;
  final ScreenTheme theme;

  const ScreenBackground({
    super.key,
    required this.child,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background canvas
        Positioned.fill(
          child: CustomPaint(
            painter: _BgPainter(theme: theme),
          ),
        ),
        // Actual content on top
        child,
      ],
    );
  }
}

enum ScreenTheme { dashboard, analyze, history, profile }

class _BgPainter extends CustomPainter {
  final ScreenTheme theme;
  const _BgPainter({required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    switch (theme) {
      case ScreenTheme.dashboard:
        _paintDashboard(canvas, size);
        break;
      case ScreenTheme.analyze:
        _paintAnalyze(canvas, size);
        break;
      case ScreenTheme.history:
        _paintHistory(canvas, size);
        break;
      case ScreenTheme.profile:
        _paintProfile(canvas, size);
        break;
    }
  }

  // ── Dashboard — air/wind circles ──────────────────────────────
  void _paintDashboard(Canvas canvas, Size s) {
    // Soft gradient background
    final bgRect = Rect.fromLTWH(0, 0, s.width, s.height);
    canvas.drawRect(
      bgRect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFF0F4FF), Color(0xFFF8FAFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bgRect),
    );

    // Large translucent rings (air quality circles)
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final colors = [
      AppTheme.primaryBlue.withValues(alpha: 0.06),
      AppTheme.primaryBlue.withValues(alpha: 0.04),
      AppTheme.accentBlue.withValues(alpha: 0.05),
    ];

    for (int i = 0; i < 3; i++) {
      ringPaint.color = colors[i];
      canvas.drawCircle(
        Offset(s.width * 0.85, s.height * 0.15),
        80.0 + i * 55,
        ringPaint,
      );
    }

    // Bottom-left decorative arcs
    for (int i = 0; i < 4; i++) {
      ringPaint.color =
          AppTheme.safeGreen.withValues(alpha: 0.04 + i * 0.01);
      canvas.drawCircle(
        Offset(-20, s.height * 0.85),
        60.0 + i * 40,
        ringPaint,
      );
    }

    // Tiny dot grid
    _drawDotGrid(canvas, s,
        color: AppTheme.primaryBlue.withValues(alpha: 0.04));
  }

  // ── Analyze — wave/sensor lines ──────────────────────────────
  void _paintAnalyze(Canvas canvas, Size s) {
    final bgRect = Rect.fromLTWH(0, 0, s.width, s.height);
    canvas.drawRect(
      bgRect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFFF8F0), Color(0xFFFFFBF5)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ).createShader(bgRect),
    );

    // Sine wave lines representing sensor readings
    final wavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final waveColors = [
      const Color(0xFFFF8C42).withValues(alpha: 0.08),
      const Color(0xFF9575CD).withValues(alpha: 0.07),
      const Color(0xFF4FC3F7).withValues(alpha: 0.07),
      const Color(0xFF4DB6AC).withValues(alpha: 0.06),
    ];

    for (int w = 0; w < 4; w++) {
      wavePaint.color = waveColors[w];
      final path = Path();
      final yBase = s.height * (0.25 + w * 0.17);
      final amp = 18.0 + w * 8;
      final freq = 0.015 + w * 0.005;
      path.moveTo(0, yBase);
      for (double x = 0; x <= s.width; x += 2) {
        path.lineTo(x, yBase + amp * math.sin(freq * x + w));
      }
      canvas.drawPath(path, wavePaint);
    }

    // Corner accent circle
    canvas.drawCircle(
      Offset(s.width + 30, -30),
      120,
      Paint()
        ..color = const Color(0xFFFF8C42).withValues(alpha: 0.06)
        ..style = PaintingStyle.fill,
    );
  }

  // ── History — timeline dots and lines ────────────────────────
  void _paintHistory(Canvas canvas, Size s) {
    final bgRect = Rect.fromLTWH(0, 0, s.width, s.height);
    canvas.drawRect(
      bgRect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFF5F0FF), Color(0xFFFAF8FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bgRect),
    );

    // Vertical timeline line (right side)
    canvas.drawLine(
      Offset(s.width * 0.92, 0),
      Offset(s.width * 0.92, s.height),
      Paint()
        ..color = const Color(0xFF9575CD).withValues(alpha: 0.08)
        ..strokeWidth = 2,
    );

    // Timeline dots
    final dotPaint = Paint()
      ..style = PaintingStyle.fill;

    final dotColors = [
      AppTheme.safeGreen.withValues(alpha: 0.15),
      AppTheme.moderateYellow.withValues(alpha: 0.15),
      AppTheme.warningOrange.withValues(alpha: 0.12),
      AppTheme.hazardousRed.withValues(alpha: 0.10),
      const Color(0xFF9575CD).withValues(alpha: 0.12),
    ];

    for (int i = 0; i < 8; i++) {
      dotPaint.color = dotColors[i % dotColors.length];
      canvas.drawCircle(
        Offset(s.width * 0.92, s.height * (0.1 + i * 0.11)),
        6,
        dotPaint,
      );
    }

    // Bar chart silhouette (bottom-left)
    final barPaint = Paint()
      ..color = const Color(0xFF9575CD).withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;
    final barHeights = [60.0, 90.0, 45.0, 110.0, 75.0, 95.0];
    for (int i = 0; i < barHeights.length; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            20.0 + i * 22, s.height - barHeights[i] - 20,
            14, barHeights[i]),
          const Radius.circular(4),
        ),
        barPaint,
      );
    }
  }

  // ── Profile — abstract person silhouette + theme circles ──────
  void _paintProfile(Canvas canvas, Size s) {
    final bgRect = Rect.fromLTWH(0, 0, s.width, s.height);
    canvas.drawRect(
      bgRect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFF0FFF8), Color(0xFFF5FFFC)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ).createShader(bgRect),
    );

    // Gradient header band
    final headerRect = Rect.fromLTWH(0, 0, s.width, s.height * 0.28);
    canvas.drawRect(
      headerRect,
      Paint()
        ..shader = LinearGradient(
          colors: [
            AppTheme.primaryBlue.withValues(alpha: 0.08),
            const Color(0xFF26A69A).withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(headerRect),
    );

    // Decorative concentric arcs top-right
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (int i = 0; i < 4; i++) {
      arcPaint.color =
          const Color(0xFF26A69A).withValues(alpha: 0.06 + i * 0.01);
      canvas.drawArc(
        Rect.fromCircle(
            center: Offset(s.width, 0), radius: 80.0 + i * 50),
        math.pi / 2,
        math.pi / 2,
        false,
        arcPaint,
      );
    }

    // Bottom decorative leaf shapes (nature/air quality)
    final leafPaint = Paint()
      ..color = const Color(0xFF26A69A).withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 3; i++) {
      final cx = s.width * (0.15 + i * 0.35);
      final cy = s.height * 0.92;
      final path = Path();
      path.moveTo(cx, cy - 30);
      path.cubicTo(cx + 20, cy - 20, cx + 20, cy, cx, cy);
      path.cubicTo(cx - 20, cy, cx - 20, cy - 20, cx, cy - 30);
      canvas.drawPath(path, leafPaint);
    }

    _drawDotGrid(canvas, s,
        color: const Color(0xFF26A69A).withValues(alpha: 0.04));
  }

  // ── Shared: subtle dot grid ────────────────────────────────────
  void _drawDotGrid(Canvas canvas, Size s, {required Color color}) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    const spacing = 28.0;
    for (double x = spacing; x < s.width; x += spacing) {
      for (double y = spacing; y < s.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_BgPainter old) => old.theme != theme;
}
