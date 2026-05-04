import 'dart:math';

import 'package:flutter/material.dart';
import 'package:nofacezone/src/Custom/AppColors.dart';

/// Pro: círculo dual-ring (estilo por defecto).
class TimeRemainingClockProPainter extends CustomPainter {
  final double remainingProgress;
  final double usedProgress;
  final Color mainColor;
  final Color tickColor;
  final double entryProgress;
  final bool showCriticalParticles;
  final double particlePhase;

  const TimeRemainingClockProPainter({
    required this.remainingProgress,
    required this.usedProgress,
    required this.mainColor,
    required this.tickColor,
    required this.entryProgress,
    required this.showCriticalParticles,
    required this.particlePhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 8;
    const startAngle = -1.5708;
    const fullSweep = 6.28318;

    final baseRing = Paint()
      ..color = AppColors.textLight.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final usedRing = Paint()
      ..color = AppColors.accentBlue.withValues(alpha: 0.32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final reveal = entryProgress.clamp(0.0, 1.0);
    final remainingSweep = (remainingProgress.clamp(0.0, 1.0)) * fullSweep * reveal;
    final remainingRing = Paint()
      ..shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + remainingSweep,
        colors: [
          mainColor.withValues(alpha: 0.65),
          mainColor,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, baseRing);

    final tickPaint = Paint()
      ..color = tickColor
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 4; i++) {
      final angle = startAngle + (i * (fullSweep / 4));
      final p1 = Offset(
        center.dx + (radius - 10) * cos(angle),
        center.dy + (radius - 10) * sin(angle),
      );
      final p2 = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      canvas.drawLine(p1, p2, tickPaint);
    }

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      remainingSweep,
      false,
      remainingRing,
    );

    final usedRadius = radius - 16;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: usedRadius),
      startAngle,
      (usedProgress.clamp(0.0, 1.0)) * fullSweep * reveal,
      false,
      usedRing,
    );

    if (reveal < 1.0) {
      final sweepHead = startAngle + (fullSweep * reveal);
      final sweepPaint = Paint()
        ..shader = SweepGradient(
          startAngle: sweepHead - 0.45,
          endAngle: sweepHead + 0.15,
          colors: [
            Colors.transparent,
            mainColor.withValues(alpha: 0.05),
            mainColor.withValues(alpha: 0.85),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 13
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        sweepHead - 0.45,
        0.60,
        false,
        sweepPaint,
      );
    }

    final endAngle = startAngle + remainingSweep;
    final endPoint = Offset(
      center.dx + radius * cos(endAngle),
      center.dy + radius * sin(endAngle),
    );
    final glow = Paint()
      ..color = mainColor.withValues(alpha: 0.95)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(endPoint, 4.2, glow);

    if (showCriticalParticles) {
      final pPaint = Paint()..style = PaintingStyle.fill;
      final alphaBase = (0.22 + (0.20 * particlePhase)).clamp(0.0, 1.0);
      const particleAngles = <double>[0.15, 0.9, 1.75, 2.45, 3.2, 4.05, 4.9, 5.55];
      for (var i = 0; i < particleAngles.length; i++) {
        final a = startAngle + particleAngles[i];
        final r = radius + 3 + (i.isEven ? 2.0 : 0.0);
        final p = Offset(
          center.dx + r * cos(a),
          center.dy + r * sin(a),
        );
        pPaint.color = mainColor.withValues(alpha: (alphaBase * (0.6 + ((i % 3) * 0.15))).clamp(0.0, 1.0));
        canvas.drawCircle(p, i.isEven ? 1.9 : 1.4, pPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant TimeRemainingClockProPainter oldDelegate) {
    return oldDelegate.remainingProgress != remainingProgress ||
        oldDelegate.usedProgress != usedProgress ||
        oldDelegate.mainColor != mainColor ||
        oldDelegate.tickColor != tickColor ||
        oldDelegate.entryProgress != entryProgress ||
        oldDelegate.showCriticalParticles != showCriticalParticles ||
        oldDelegate.particlePhase != particlePhase;
  }
}

/// Classic: anillo cuadrado redondeado.
class TimeRemainingClockSquarePainter extends CustomPainter {
  final double remainingProgress;
  final double usedProgress;
  final Color mainColor;
  final Color tickColor;
  final double entryProgress;
  final bool showCriticalParticles;
  final double particlePhase;

  const TimeRemainingClockSquarePainter({
    required this.remainingProgress,
    required this.usedProgress,
    required this.mainColor,
    required this.tickColor,
    required this.entryProgress,
    required this.showCriticalParticles,
    required this.particlePhase,
  });

  Path _roundedSquarePath(Size size) {
    const pad = 10.0;
    const corner = 22.0;
    final rect = Rect.fromLTWH(pad, pad, size.width - 2 * pad, size.height - 2 * pad);
    return Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(corner)));
  }

  Path _innerPath(Size size) {
    const pad = 28.0;
    const corner = 14.0;
    final rect = Rect.fromLTWH(pad, pad, size.width - 2 * pad, size.height - 2 * pad);
    return Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(corner)));
  }

  void _strokeSubPath(Canvas canvas, Path path, double t0, double t1, Paint paint) {
    for (final m in path.computeMetrics(forceClosed: true)) {
      final len = m.length;
      final a = (t0 * len).clamp(0.0, len);
      final b = (t1 * len).clamp(0.0, len);
      if (b > a) {
        canvas.drawPath(m.extractPath(a, b), paint);
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final outer = _roundedSquarePath(size);
    final inner = _innerPath(size);
    final reveal = entryProgress.clamp(0.0, 1.0);
    final rem = (remainingProgress.clamp(0.0, 1.0)) * reveal;
    final used = (usedProgress.clamp(0.0, 1.0)) * reveal;

    final base = Paint()
      ..color = AppColors.textLight.withValues(alpha: 0.09)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final remPaint = Paint()
      ..color = mainColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final usedPaint = Paint()
      ..color = AppColors.accentBlue.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(outer, base);
    _strokeSubPath(canvas, outer, 0, rem, remPaint);
    final innerTrack = Paint()
      ..color = AppColors.textLight.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(inner, innerTrack);
    _strokeSubPath(canvas, inner, 0, used, usedPaint);

    for (var i = 0; i < 4; i++) {
      for (final m in outer.computeMetrics(forceClosed: true)) {
        final len = m.length;
        final off = len * (i / 4.0);
        final tan = m.getTangentForOffset(off);
        if (tan == null) continue;
        final p = tan.position;
        final n = tan.vector;
        final p1 = p - n * 6;
        final p2 = p + n * 2;
        canvas.drawLine(
          p1,
          p2,
          Paint()
            ..color = tickColor
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    if (showCriticalParticles) {
      final pPaint = Paint()..style = PaintingStyle.fill;
      final alphaBase = (0.2 + (0.18 * particlePhase)).clamp(0.0, 1.0);
      for (var i = 0; i < 6; i++) {
        for (final m in outer.computeMetrics(forceClosed: true)) {
          final off = m.length * (i / 6.0 + 0.04);
          final tan = m.getTangentForOffset(off);
          if (tan == null) continue;
          final outward = Offset(-tan.vector.dy, tan.vector.dx);
          final p = tan.position + outward * 5;
          pPaint.color = mainColor.withValues(alpha: alphaBase * (0.5 + (i % 3) * 0.12));
          canvas.drawCircle(p, i.isEven ? 1.6 : 1.2, pPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant TimeRemainingClockSquarePainter oldDelegate) {
    return oldDelegate.remainingProgress != remainingProgress ||
        oldDelegate.usedProgress != usedProgress ||
        oldDelegate.mainColor != mainColor ||
        oldDelegate.tickColor != tickColor ||
        oldDelegate.entryProgress != entryProgress ||
        oldDelegate.showCriticalParticles != showCriticalParticles ||
        oldDelegate.particlePhase != particlePhase;
  }
}

/// Neon: perímetro hexagonal.
class TimeRemainingClockHexPainter extends CustomPainter {
  final double remainingProgress;
  final double usedProgress;
  final Color mainColor;
  final Color accentColor;
  final double entryProgress;
  final bool showCriticalParticles;
  final double particlePhase;

  const TimeRemainingClockHexPainter({
    required this.remainingProgress,
    required this.usedProgress,
    required this.mainColor,
    required this.accentColor,
    required this.entryProgress,
    required this.showCriticalParticles,
    required this.particlePhase,
  });

  Path _hexPath(Size size, double inset) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = min(size.width, size.height) / 2 - inset;
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final a = -pi / 2 + i * pi / 3;
      final x = cx + r * cos(a);
      final y = cy + r * sin(a);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  void _strokeSubPath(Canvas canvas, Path path, double t0, double t1, Paint paint) {
    for (final m in path.computeMetrics(forceClosed: true)) {
      final len = m.length;
      final a = (t0 * len).clamp(0.0, len);
      final b = (t1 * len).clamp(0.0, len);
      if (b > a) {
        canvas.drawPath(m.extractPath(a, b), paint);
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final outer = _hexPath(size, 10);
    final inner = _hexPath(size, 28);
    final reveal = entryProgress.clamp(0.0, 1.0);
    final rem = (remainingProgress.clamp(0.0, 1.0)) * reveal;
    final used = (usedProgress.clamp(0.0, 1.0)) * reveal;

    final base = Paint()
      ..color = AppColors.textLight.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final glowUnder = Paint()
      ..color = accentColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final remPaint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: -pi / 2,
        endAngle: 3 * pi / 2,
        colors: [
          mainColor.withValues(alpha: 0.75),
          AppColors.accentBlue,
          accentColor,
        ],
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final usedPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(outer, base);
    _strokeSubPath(canvas, outer, 0, rem, glowUnder);
    _strokeSubPath(canvas, outer, 0, rem, remPaint);

    final innerTrack = Paint()
      ..color = AppColors.textLight.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(inner, innerTrack);
    _strokeSubPath(canvas, inner, 0, used, usedPaint);

    if (reveal < 1.0) {
      for (final m in outer.computeMetrics(forceClosed: true)) {
        final head = m.length * reveal;
        final sweepLen = (m.length * 0.08).clamp(8.0, m.length);
        final a = (head - sweepLen * 0.5).clamp(0.0, m.length);
        final b = (head + sweepLen * 0.5).clamp(0.0, m.length);
        if (b > a) {
          canvas.drawPath(
            m.extractPath(a, b),
            Paint()
              ..color = mainColor.withValues(alpha: 0.9)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 14
              ..strokeCap = StrokeCap.round
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
          );
        }
      }
    }

    if (showCriticalParticles) {
      final pPaint = Paint()..style = PaintingStyle.fill;
      final alphaBase = (0.25 + (0.22 * particlePhase)).clamp(0.0, 1.0);
      for (var v = 0; v < 6; v++) {
        final a = -pi / 2 + v * pi / 3;
        final rad = min(size.width, size.height) / 2 - 4;
        final p = Offset(
          size.width / 2 + (rad + 6) * cos(a),
          size.height / 2 + (rad + 6) * sin(a),
        );
        pPaint.color = mainColor.withValues(alpha: alphaBase);
        canvas.drawCircle(p, 2.2, pPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant TimeRemainingClockHexPainter oldDelegate) {
    return oldDelegate.remainingProgress != remainingProgress ||
        oldDelegate.usedProgress != usedProgress ||
        oldDelegate.mainColor != mainColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.entryProgress != entryProgress ||
        oldDelegate.showCriticalParticles != showCriticalParticles ||
        oldDelegate.particlePhase != particlePhase;
  }
}

/// Aurora: elipse.
class TimeRemainingClockEllipsePainter extends CustomPainter {
  final double remainingProgress;
  final double usedProgress;
  final Color mainColor;
  final Color auraMint;
  final Color auraDeep;
  final double entryProgress;
  final bool showCriticalParticles;
  final double particlePhase;

  const TimeRemainingClockEllipsePainter({
    required this.remainingProgress,
    required this.usedProgress,
    required this.mainColor,
    required this.auraMint,
    required this.auraDeep,
    required this.entryProgress,
    required this.showCriticalParticles,
    required this.particlePhase,
  });

  Path _ovalPath(Size size) {
    const padX = 12.0;
    const padY = 14.0;
    return Path()
      ..addOval(Rect.fromLTWH(padX, padY, size.width - 2 * padX, size.height - 2 * padY));
  }

  Path _innerOval(Size size) {
    const padX = 30.0;
    const padY = 32.0;
    return Path()
      ..addOval(Rect.fromLTWH(padX, padY, size.width - 2 * padX, size.height - 2 * padY));
  }

  void _strokeSubPath(Canvas canvas, Path path, double t0, double t1, Paint paint) {
    for (final m in path.computeMetrics(forceClosed: true)) {
      final len = m.length;
      final a = (t0 * len).clamp(0.0, len);
      final b = (t1 * len).clamp(0.0, len);
      if (b > a) {
        canvas.drawPath(m.extractPath(a, b), paint);
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final outer = _ovalPath(size);
    final inner = _innerOval(size);
    final reveal = entryProgress.clamp(0.0, 1.0);
    final rem = (remainingProgress.clamp(0.0, 1.0)) * reveal;
    final used = (usedProgress.clamp(0.0, 1.0)) * reveal;

    final base = Paint()
      ..color = auraDeep.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final remPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -pi / 2,
        endAngle: 3 * pi / 2,
        colors: [
          auraMint.withValues(alpha: 0.35),
          mainColor.withValues(alpha: 0.75),
          const Color(0xFF6B8CFF).withValues(alpha: 0.65),
          auraMint.withValues(alpha: 0.5),
        ],
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11
      ..strokeCap = StrokeCap.round;

    final usedPaint = Paint()
      ..color = auraMint.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(outer, base);
    _strokeSubPath(canvas, outer, 0, rem, remPaint);

    final innerTrack = Paint()
      ..color = auraMint.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(inner, innerTrack);
    _strokeSubPath(canvas, inner, 0, used, usedPaint);

    final bounds = Rect.fromLTWH(12, 14, size.width - 24, size.height - 28);
    canvas.drawOval(
      bounds,
      Paint()
        ..shader = RadialGradient(
          colors: [
            auraMint.withValues(alpha: 0.06),
            Colors.transparent,
          ],
        ).createShader(bounds),
    );

    if (showCriticalParticles) {
      final pPaint = Paint()..style = PaintingStyle.fill;
      final alphaBase = (0.18 + (0.16 * particlePhase)).clamp(0.0, 1.0);
      for (var k = 0; k < 8; k++) {
        final t = k / 8.0;
        for (final m in outer.computeMetrics(forceClosed: true)) {
          final off = m.length * t;
          final tan = m.getTangentForOffset(off);
          if (tan == null) continue;
          final n = Offset(-tan.vector.dy, tan.vector.dx);
          final p = tan.position + n * (4 + (k % 2) * 2.0);
          pPaint.color = auraMint.withValues(alpha: alphaBase * (0.45 + (k % 3) * 0.1));
          canvas.drawCircle(p, 1.4, pPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant TimeRemainingClockEllipsePainter oldDelegate) {
    return oldDelegate.remainingProgress != remainingProgress ||
        oldDelegate.usedProgress != usedProgress ||
        oldDelegate.mainColor != mainColor ||
        oldDelegate.auraMint != auraMint ||
        oldDelegate.auraDeep != auraDeep ||
        oldDelegate.entryProgress != entryProgress ||
        oldDelegate.showCriticalParticles != showCriticalParticles ||
        oldDelegate.particlePhase != particlePhase;
  }
}

/// Quantum: rombo HUD.
class TimeRemainingClockDiamondPainter extends CustomPainter {
  final double remainingProgress;
  final double usedProgress;
  final Color mainColor;
  final Color hudColor;
  final double entryProgress;
  final bool showCriticalParticles;
  final double particlePhase;

  const TimeRemainingClockDiamondPainter({
    required this.remainingProgress,
    required this.usedProgress,
    required this.mainColor,
    required this.hudColor,
    required this.entryProgress,
    required this.showCriticalParticles,
    required this.particlePhase,
  });

  Path _diamondPath(Size size, double inset) {
    final c = Offset(size.width / 2, size.height / 2);
    final hw = size.width / 2 - inset;
    final hh = size.height / 2 - inset;
    return Path()
      ..moveTo(c.dx, c.dy - hh)
      ..lineTo(c.dx + hw, c.dy)
      ..lineTo(c.dx, c.dy + hh)
      ..lineTo(c.dx - hw, c.dy)
      ..close();
  }

  void _strokeSubPath(Canvas canvas, Path path, double t0, double t1, Paint paint) {
    for (final m in path.computeMetrics(forceClosed: true)) {
      final len = m.length;
      final a = (t0 * len).clamp(0.0, len);
      final b = (t1 * len).clamp(0.0, len);
      if (b > a) {
        canvas.drawPath(m.extractPath(a, b), paint);
      }
    }
  }

  void _paintDashedPortion(Canvas canvas, Path path, double endT, Paint paint, double dash, double gap) {
    for (final m in path.computeMetrics(forceClosed: true)) {
      final len = m.length;
      final limit = (endT * len).clamp(0.0, len);
      var d = 0.0;
      while (d < limit) {
        final e = (d + dash).clamp(0.0, limit);
        if (e > d) {
          canvas.drawPath(m.extractPath(d, e), paint);
        }
        d += dash + gap;
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final outer = _diamondPath(size, 10);
    final inner = _diamondPath(size, 30);
    final reveal = entryProgress.clamp(0.0, 1.0);
    final rem = (remainingProgress.clamp(0.0, 1.0)) * reveal;
    final used = (usedProgress.clamp(0.0, 1.0)) * reveal;

    final base = Paint()
      ..color = hudColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.miter;

    final remPaint = Paint()
      ..color = mainColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.miter;

    final remGlow = Paint()
      ..color = hudColor.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.miter
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    final usedDash = Paint()
      ..color = hudColor.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(outer, base);
    _strokeSubPath(canvas, outer, 0, rem, remGlow);
    _strokeSubPath(canvas, outer, 0, rem, remPaint);

    final innerTrack = Paint()
      ..color = hudColor.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.miter;
    canvas.drawPath(inner, innerTrack);
    _paintDashedPortion(canvas, inner, used, usedDash, 5, 4);

    if (reveal < 1.0) {
      for (final m in outer.computeMetrics(forceClosed: true)) {
        final head = m.length * ((remainingProgress.clamp(0.0, 1.0) * reveal).clamp(0.0, 1.0));
        final tan = m.getTangentForOffset(head.clamp(0.0, m.length - 0.001));
        if (tan != null) {
          final perp = Offset(-tan.vector.dy, tan.vector.dx);
          final mid = tan.position;
          canvas.drawLine(
            mid - perp * 10,
            mid + perp * 10,
            Paint()
              ..color = hudColor.withValues(alpha: 0.75)
              ..strokeWidth = 1.5,
          );
        }
      }
    }

    if (showCriticalParticles) {
      final pPaint = Paint()..style = PaintingStyle.fill;
      final alphaBase = (0.28 + (0.2 * particlePhase)).clamp(0.0, 1.0);
      for (var v = 0; v < 4; v++) {
        final a = -pi / 2 + v * pi / 2;
        final rad = min(size.width, size.height) / 2 - 6;
        final p = Offset(
          size.width / 2 + (rad + 8) * cos(a),
          size.height / 2 + (rad + 8) * sin(a),
        );
        pPaint.color = hudColor.withValues(alpha: alphaBase);
        canvas.drawRect(Rect.fromCenter(center: p, width: 3, height: 3), pPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant TimeRemainingClockDiamondPainter oldDelegate) {
    return oldDelegate.remainingProgress != remainingProgress ||
        oldDelegate.usedProgress != usedProgress ||
        oldDelegate.mainColor != mainColor ||
        oldDelegate.hudColor != hudColor ||
        oldDelegate.entryProgress != entryProgress ||
        oldDelegate.showCriticalParticles != showCriticalParticles ||
        oldDelegate.particlePhase != particlePhase;
  }
}
