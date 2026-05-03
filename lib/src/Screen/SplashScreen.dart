import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nofacezone/src/Custom/AppColors.dart';
import 'package:nofacezone/src/Custom/AppLocalizations.dart';
import 'package:nofacezone/src/Providers/AppProvider.dart';
import 'package:nofacezone/src/Screen/OnboardingScreen.dart';
import 'package:nofacezone/src/Screen/WelcomeScreen.dart';
import 'package:nofacezone/src/Services/LocalNotificationService.dart';
import 'package:nofacezone/src/Services/PreferencesService.dart';

/// ~1 s menos que antes: ritmo streaming / cine, forma propia (no es marca de terceros).
const Duration _kIntroDuration = Duration(milliseconds: 2000);
const Duration _kPostIntroHold = Duration(milliseconds: 200);

/// Cinta luminosa con trazo fluido (reveal por longitud de path).
class _SplashRibbonPainter extends CustomPainter {
  _SplashRibbonPainter({
    required this.progress,
    required this.accentA,
    required this.accentB,
    required this.intensity,
  });

  final double progress;
  final Color accentA;
  final Color accentB;
  /// Pulso final de “aura” (0–1).
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final w = size.width;
    final h = size.height;

    final path = Path()
      ..moveTo(w * 0.02, h * 0.78)
      ..quadraticBezierTo(w * 0.22, h * 0.92, w * 0.38, h * 0.62)
      ..quadraticBezierTo(w * 0.52, h * 0.36, w * 0.68, h * 0.44)
      ..quadraticBezierTo(w * 0.86, h * 0.54, w * 0.96, h * 0.18);

    final metricsList = path.computeMetrics().toList();
    if (metricsList.isEmpty) return;
    final metric = metricsList.first;
    final len = metric.length * progress.clamp(0.0, 1.0);
    final extract = metric.extractPath(0, len);

    final aura = 18 + 10 * intensity;
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = aura
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 14 + 8 * intensity)
      ..color = accentA.withValues(alpha: 0.22 + 0.18 * intensity);

    final mid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
      ..color = accentB.withValues(alpha: 0.28);

    final core = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = LinearGradient(
        colors: [accentA, Colors.white.withValues(alpha: 0.92), accentB],
        stops: const [0.0, 0.52, 1.0],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(extract, glow);
    canvas.drawPath(extract, mid);
    canvas.drawPath(extract, core);

    if (progress > 0.88) {
      final haloT = ((progress - 0.88) / 0.12).clamp(0.0, 1.0);
      final halo = Paint()
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 26 + 12 * intensity)
        ..color = accentB.withValues(alpha: 0.18 * haloT * (0.6 + 0.4 * intensity));
      canvas.drawCircle(Offset(w * 0.72, h * 0.32), w * 0.1 * (0.85 + 0.15 * intensity), halo);
    }
  }

  @override
  bool shouldRepaint(covariant _SplashRibbonPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.accentA != accentA ||
      oldDelegate.accentB != accentB ||
      oldDelegate.intensity != intensity;
}

/// Viñeta + haz de luz que cruza (ambiente “proyección / plataforma”).
class _SplashAtmospherePainter extends CustomPainter {
  _SplashAtmospherePainter({
    required this.progress,
    required this.accentA,
    required this.accentB,
  });

  final double progress;
  final Color accentA;
  final Color accentB;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;

    // Viñeta: más profunda al inicio, se abre un poco con el logo.
    final vignetteStrength = (0.62 * (1.0 - progress * 0.55)).clamp(0.22, 0.62);
    final vignette = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.08),
        radius: 1.05,
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: vignetteStrength),
        ],
        stops: const [0.42, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, vignette);

    // Haz diagonal tipo “spot” (Interval ~0.25–0.72 del progreso global).
    final sweepPhase = ((progress - 0.22) / 0.48).clamp(0.0, 1.0);
    if (sweepPhase <= 0) return;

    final fade = math.sin(sweepPhase * math.pi);
    final cx = w * (-0.35 + sweepPhase * 1.65);
    final cy = h * 0.12;

    final beam = Paint()
      ..shader = LinearGradient(
        begin: Alignment(cx / w - 0.4, cy / h - 0.9),
        end: Alignment(cx / w + 0.5, cy / h + 1.0),
        colors: [
          Colors.transparent,
          accentA.withValues(alpha: 0.07 * fade),
          Colors.white.withValues(alpha: 0.11 * fade),
          accentB.withValues(alpha: 0.06 * fade),
          Colors.transparent,
        ],
        stops: const [0.0, 0.32, 0.48, 0.62, 1.0],
      ).createShader(rect)
      ..blendMode = BlendMode.softLight;
    canvas.drawRect(rect, beam);

    // Brillo esquina superior (aura estática suave).
    final corner = Paint()
      ..shader = RadialGradient(
        center: Alignment(-0.95, -1.0),
        radius: 0.95,
        colors: [
          accentA.withValues(alpha: 0.14 * (0.35 + 0.65 * progress)),
          Colors.transparent,
        ],
      ).createShader(rect)
      ..blendMode = BlendMode.plus;
    canvas.drawRect(rect, corner);
  }

  @override
  bool shouldRepaint(covariant _SplashAtmospherePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.accentA != accentA ||
      oldDelegate.accentB != accentB;
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _intro;
  late final Animation<double> _ribbon;
  late final Animation<double> _nReveal;
  late final Animation<double> _fReveal;
  late final Animation<double> _zReveal;
  late final Animation<double> _wordmark;
  late final Animation<double> _tagline;
  late final Animation<double> _pulse;
  late final Animation<double> _flash;
  late final Animation<double> _aura;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: _kIntroDuration,
    );

    // Ritmo más denso: ~2 s total, curvas tipo reveal streaming.
    _ribbon = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.0, 0.34, curve: Curves.easeOutCubic),
    );
    _nReveal = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.14, 0.46, curve: Curves.easeOutCubic),
    );
    _fReveal = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.20, 0.52, curve: Curves.easeOutCubic),
    );
    // No usar easeOutBack aquí: puede dar t > 1.0 y romper Curves que exigen [0, 1].
    _zReveal = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.26, 0.58, curve: Curves.easeOutCubic),
    );
    _wordmark = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.40, 0.78, curve: Curves.easeOutCubic),
    );
    _flash = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.74, 0.82, curve: Curves.easeOut),
    );
    _tagline = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.58, 0.94, curve: Curves.easeOut),
    );
    _pulse = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.52, 1.0, curve: Curves.easeInOut),
    );
    _aura = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.48, 1.0, curve: Curves.easeInOutCubic),
    );

    _intro.forward();
    startTime();
  }

  Future<void> startTime() async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);

    while (appProvider.isLoading) {
      await Future.delayed(const Duration(milliseconds: 80));
      if (!mounted) return;
    }

    if (mounted) {
      await _maybeRequestNotificationPermissionOnColdStart(appProvider);
    }

    while (!_intro.isCompleted && mounted) {
      await Future.delayed(const Duration(milliseconds: 40));
    }

    if (!mounted) return;
    await Future.delayed(_kPostIntroHold);
    if (!mounted) return;
    _navigateFromSplash(appProvider.isOnboardingCompleted);
  }

  Future<void> _maybeRequestNotificationPermissionOnColdStart(AppProvider appProvider) async {
    if (kIsWeb) return;
    if (PreferencesService.wasNotificationAutoPromptDone()) return;
    await PreferencesService.setNotificationAutoPromptDone(true);
    if (!appProvider.notificationsEnabled) {
      await appProvider.syncLocalNotificationSchedule();
      return;
    }
    await LocalNotificationService.requestPermissions();
    await appProvider.syncLocalNotificationSchedule();
  }

  void _navigateFromSplash(bool isOnboardingCompleted) {
    final target = isOnboardingCompleted ? const WelcomeScreen() : const OnboardingScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 520),
        pageBuilder: (_, __, ___) => target,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final fade = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          final scale = Tween<double>(begin: 1.045, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          );
          return FadeTransition(
            opacity: fade,
            child: ScaleTransition(scale: scale, child: child),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  Widget _letterSlot(String letter, Animation<double> reveal) {
    return FadeTransition(
      opacity: reveal,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.72),
          end: Offset.zero,
        ).animate(reveal),
        child: Transform.scale(
          scale: 0.82 + 0.18 * reveal.value.clamp(0.0, 1.0),
          child: ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (rect) => LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: AppColors.accentGradient,
            ).createShader(rect),
            child: Text(
              letter,
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                height: 1.0,
                letterSpacing: 0,
                shadows: [
                  Shadow(
                    color: Color(0x66000000),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    AppColors.setTheme(appProvider.colorTheme);
    final loc = AppLocalizations.of(context);
    final accentA = AppColors.accentGradient.first;
    final accentB = AppColors.accentGradient.last;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _intro,
        builder: (context, _) {
          final t = _intro.value;
          final flashOpacity = (math.sin(_flash.value * math.pi) * 0.14).clamp(0.0, 0.14) * _flash.value;

          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppColors.backgroundGradient,
              ),
            ),
            child: Stack(
              children: [
                // Capa extra: “sala oscura” al arranque que se disipa.
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.42 * (1.0 - t).clamp(0.0, 1.0)),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.28 * (1.0 - t).clamp(0.0, 1.0)),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: -100,
                  left: -70,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: 0.28 + 0.32 * _ribbon.value + 0.12 * _aura.value,
                      child: Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              accentA.withValues(alpha: 0.55),
                              accentB.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -120,
                  right: -80,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: 0.22 + 0.28 * _wordmark.value + 0.15 * math.sin(_pulse.value * math.pi * 2) * 0.5,
                      child: Container(
                        width: 320,
                        height: 320,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              accentB.withValues(alpha: 0.5),
                              accentA.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _SplashAtmospherePainter(
                        progress: t,
                        accentA: accentA,
                        accentB: accentB,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Transform.scale(
                    scale: 1.0 + 0.018 * math.sin(_pulse.value * math.pi * 2),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RepaintBoundary(
                          child: SizedBox(
                            width: 340,
                            height: 170,
                            child: CustomPaint(
                              painter: _SplashRibbonPainter(
                                progress: _ribbon.value,
                                accentA: accentA,
                                accentB: accentB,
                                intensity: _aura.value,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Material(
                          color: Colors.transparent,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _letterSlot('N', _nReveal),
                              const SizedBox(width: 8),
                              _letterSlot('F', _fReveal),
                              const SizedBox(width: 8),
                              _letterSlot('Z', _zReveal),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        FadeTransition(
                          opacity: _wordmark,
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 1.14, end: 1.0).animate(
                              CurvedAnimation(parent: _wordmark, curve: Curves.easeOutCubic),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              clipBehavior: Clip.none,
                              children: [
                                Transform.scale(
                                  scale: 1.02 + 0.04 * _aura.value,
                                  child: Opacity(
                                    opacity: 0.4 + 0.35 * _wordmark.value,
                                    child: Text(
                                      'NoFaceZone',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 46,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.8,
                                        color: accentA.withValues(alpha: 0.22),
                                        shadows: [
                                          Shadow(
                                            color: accentB.withValues(alpha: 0.55),
                                            blurRadius: 36,
                                            offset: Offset.zero,
                                          ),
                                          Shadow(
                                            color: accentA.withValues(alpha: 0.45),
                                            blurRadius: 52,
                                            offset: Offset.zero,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                ShaderMask(
                                  shaderCallback: (Rect bounds) {
                                    final sweep = -0.9 + t * 2.1;
                                    return LinearGradient(
                                      begin: Alignment(sweep, -0.6),
                                      end: Alignment(sweep + 1.4, 0.7),
                                      colors: [
                                        accentA,
                                        const Color(0xFFF2F4FF),
                                        accentB,
                                        accentA,
                                      ],
                                      stops: const [0.0, 0.42, 0.58, 1.0],
                                    ).createShader(bounds);
                                  },
                                  blendMode: BlendMode.srcIn,
                                  child: const Text(
                                    'NoFaceZone',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 46,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.8,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          color: Color(0x90000000),
                                          blurRadius: 14,
                                          offset: Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        FadeTransition(
                          opacity: _tagline,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.2),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(parent: _tagline, curve: Curves.easeOutCubic)),
                            child: Text(
                              loc?.splashTagline ?? 'Menos ruido digital, más vida real',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textLight.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: 216,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: FractionallySizedBox(
                                    widthFactor: t.clamp(0.0, 1.0),
                                    child: Container(
                                      height: 5,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(999),
                                        gradient: LinearGradient(
                                          colors: [
                                            accentA.withValues(alpha: 0.85),
                                            Colors.white.withValues(alpha: 0.95),
                                            accentB.withValues(alpha: 0.9),
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: accentB.withValues(alpha: 0.45),
                                            blurRadius: 10,
                                            spreadRadius: 0,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Opacity(
                          opacity: 0.5 + 0.4 * _tagline.value,
                          child: Text(
                            loc?.splashLoading ?? 'Preparando tu experiencia...',
                            style: TextStyle(
                              color: AppColors.textLight.withValues(alpha: 0.72),
                              fontSize: 12.5,
                              letterSpacing: 0.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Destello breve al enganchar el wordmark (cine).
                Positioned.fill(
                  child: IgnorePointer(
                    child: ColoredBox(
                      color: Colors.white.withValues(alpha: flashOpacity),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
