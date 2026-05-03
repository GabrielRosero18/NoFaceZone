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

/// Cinta / trazo fluido estilo “reveal” cinematográfico (referencia de calidad,
/// forma propia — no es el logo de Netflix).
class _SplashRibbonPainter extends CustomPainter {
  _SplashRibbonPainter({
    required this.progress,
    required this.accentA,
    required this.accentB,
  });

  final double progress;
  final Color accentA;
  final Color accentB;

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

    // Materializar métricas: el iterable de computeMetrics() no debe combinarse
    // con .isEmpty + .first (puede consumirse y lanzar "Bad state: No element").
    final metricsList = path.computeMetrics().toList();
    if (metricsList.isEmpty) return;
    final metric = metricsList.first;
    final len = metric.length * progress.clamp(0.0, 1.0);
    final extract = metric.extractPath(0, len);

    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
      ..color = accentA.withValues(alpha: 0.35);

    final core = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = LinearGradient(
        colors: [accentA, accentB, accentA.withValues(alpha: 0.85)],
        stops: const [0.0, 0.55, 1.0],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(extract, glow);
    canvas.drawPath(extract, core);

    if (progress > 0.92) {
      final halo = Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22)
        ..color = accentB.withValues(alpha: 0.12 * ((progress - 0.92) / 0.08).clamp(0.0, 1.0));
      canvas.drawCircle(Offset(w * 0.72, h * 0.32), w * 0.08, halo);
    }
  }

  @override
  bool shouldRepaint(covariant _SplashRibbonPainter oldDelegate) =>
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

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _ribbon = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.0, 0.36, curve: Curves.easeInOutCubic),
    );
    _nReveal = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.24, 0.52, curve: Curves.easeOutCubic),
    );
    _fReveal = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.30, 0.58, curve: Curves.easeOutCubic),
    );
    _zReveal = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.36, 0.64, curve: Curves.easeOutCubic),
    );
    _wordmark = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.50, 0.82, curve: Curves.easeOutCubic),
    );
    _tagline = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.62, 0.92, curve: Curves.easeOut),
    );
    _pulse = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.55, 1.0, curve: Curves.easeInOut),
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
    await Future.delayed(const Duration(milliseconds: 380));
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

  /// Primera instalación o primer uso: no hay clave `onboarding` = "completed" → se muestra
  /// la guía (páginas informativas). Tras "Empezar" o "Saltar" queda guardado y aquí se va
  /// directo al welcome. Eso solo afecta a este dispositivo (SharedPreferences).
  void _navigateFromSplash(bool isOnboardingCompleted) {
    final target = isOnboardingCompleted ? const WelcomeScreen() : const OnboardingScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 720),
        pageBuilder: (_, __, ___) => target,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final fade = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          final scale = Tween<double>(begin: 1.03, end: 1.0).animate(
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
          begin: const Offset(0, 0.55),
          end: Offset.zero,
        ).animate(reveal),
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
              fontSize: 44,
              fontWeight: FontWeight.w900,
              height: 1.0,
              letterSpacing: 0,
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
                Positioned(
                  top: -80,
                  left: -50,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: 0.35 + 0.25 * _ribbon.value,
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [Color(0x55C3B6FF), Color(0x00000000)],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -100,
                  right: -60,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: 0.28 + 0.2 * _wordmark.value,
                      child: Container(
                        width: 260,
                        height: 260,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [Color(0x55B8C1FF), Color(0x00000000)],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RepaintBoundary(
                        child: SizedBox(
                          width: 320,
                          height: 160,
                          child: CustomPaint(
                            painter: _SplashRibbonPainter(
                              progress: _ribbon.value,
                              accentA: accentA,
                              accentB: accentB,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Material(
                        color: Colors.transparent,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _letterSlot('N', _nReveal),
                            const SizedBox(width: 6),
                            _letterSlot('F', _fReveal),
                            const SizedBox(width: 6),
                            _letterSlot('Z', _zReveal),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      FadeTransition(
                        opacity: _wordmark,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.88, end: 1.0).animate(_wordmark),
                          child: ShaderMask(
                            shaderCallback: (rect) => LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: AppColors.accentGradient,
                            ).createShader(rect),
                            blendMode: BlendMode.srcIn,
                            child: const Text(
                              'NoFaceZone',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 46,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                                shadows: [
                                  Shadow(
                                    color: Color(0x80000000),
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      FadeTransition(
                        opacity: _tagline,
                        child: Text(
                          loc?.splashTagline ?? 'Menos ruido digital, más vida real',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textLight.withValues(alpha: 0.88),
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.45,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(height: 36),
                      SizedBox(
                        width: 200,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.97, end: 1.0).animate(_pulse),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              minHeight: 6,
                              value: _intro.value.clamp(0.0, 1.0),
                              backgroundColor: const Color(0x33FFFFFF),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.textLight.withValues(alpha: 0.92),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Opacity(
                        opacity: 0.55 + 0.35 * _tagline.value,
                        child: Text(
                          loc?.splashLoading ?? 'Preparando tu experiencia...',
                          style: TextStyle(
                            color: AppColors.textLight.withValues(alpha: 0.72),
                            fontSize: 12.5,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
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
