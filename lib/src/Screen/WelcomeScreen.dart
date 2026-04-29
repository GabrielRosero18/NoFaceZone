import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'RegisterScreen.dart';
import 'LoginScreen.dart';
import 'package:nofacezone/src/Custom/AppColors.dart';
import 'package:nofacezone/src/Custom/AuthTheme.dart';
import 'package:nofacezone/src/Custom/AuthWidgets.dart';
import 'package:nofacezone/src/Custom/AppLocalizations.dart';
import 'package:nofacezone/src/Custom/Config.dart';
import 'package:nofacezone/src/Custom/Constans.dart';
import 'package:nofacezone/src/Custom/ProAnimations.dart';
import 'package:nofacezone/src/Providers/AppProvider.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  Offset _parallax = Offset.zero;

  void _onPanUpdate(DragUpdateDetails details) {
    final next = _parallax + details.delta * 0.12;
    setState(() {
      _parallax = Offset(
        next.dx.clamp(-10.0, 10.0),
        next.dy.clamp(-10.0, 10.0),
      );
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() => _parallax = Offset.zero);
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final loc = AppLocalizations.of(context)!;
    AppColors.setTheme(appProvider.colorTheme);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: AuthTheme.backgroundDecoration(),
        child: GestureDetector(
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: Stack(
            children: [
              Transform.translate(
                offset: Offset(_parallax.dx * 0.35, _parallax.dy * 0.35),
                child: Stack(children: AuthTheme.buildBackgroundOrbs()),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
                  child: Column(
                    children: [
                      const ProEntrance(
                        delayMs: 20,
                        child: AuthHeaderChip(
                          icon: Icons.auto_graph_rounded,
                          text: 'Menos scroll, mas control',
                        ),
                      ),
                      const SizedBox(height: 18),
                      ProEntrance(
                        delayMs: 90,
                        child: Transform.translate(
                          offset: Offset(_parallax.dx * 0.8, _parallax.dy * 0.8),
                          child: ProPressable(
                            onTap: () {},
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(colors: AppColors.accentGradient),
                                boxShadow: AppColors.elevatedShadow,
                              ),
                              child: Container(
                                margin: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.darkSurface,
                                  border: Border.all(color: AppColors.textLight.withValues(alpha: 0.45), width: 1),
                                ),
                                child: const Center(
                                  child: Text(
                                    'NF',
                                    style: TextStyle(
                                      fontSize: 46,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textLight,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ProEntrance(
                        delayMs: 150,
                        child: ShaderMask(
                          shaderCallback: (rect) => LinearGradient(colors: AppColors.accentGradient).createShader(rect),
                          blendMode: BlendMode.srcIn,
                          child: const Text(
                            'NoFaceZone',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.7,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ProEntrance(
                        delayMs: 200,
                        child: Text(
                          loc.appSubtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textLight.withValues(alpha: 0.92),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ProEntrance(
                          delayMs: 260,
                          child: Transform.translate(
                            offset: Offset(_parallax.dx * 0.45, _parallax.dy * 0.45),
                            child: AuthGlassCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    loc.appDescriptionText,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 15,
                                      height: 1.45,
                                      color: AppColors.textLight.withValues(alpha: 0.82),
                                    ),
                                  ),
                                  const SizedBox(height: 22),
                                  Row(
                                    children: [
                                      Expanded(child: _buildFeaturePill(icon: Icons.timer_outlined, label: 'Limites diarios')),
                                      const SizedBox(width: 10),
                                      Expanded(child: _buildFeaturePill(icon: Icons.emoji_events_outlined, label: 'Recompensas')),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(child: _buildFeaturePill(icon: Icons.track_changes_rounded, label: 'Seguimiento')),
                                      const SizedBox(width: 10),
                                      Expanded(child: _buildFeaturePill(icon: Icons.notifications_active_outlined, label: 'Recordatorios')),
                                    ],
                                  ),
                                  const Spacer(),
                                  ProEntrance(
                                    delayMs: 340,
                                    child: AuthPrimaryButton(
                                      text: loc.signIn,
                                      isLoading: false,
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ProEntrance(
                                    delayMs: 390,
                                    child: SizedBox(
                                      height: 56,
                                      child: OutlinedButton(
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(builder: (context) => const RegisterScreen()),
                                          );
                                        },
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(color: AppColors.textLight.withValues(alpha: 0.8)),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                        ),
                                        child: Text(
                                          loc.signUp,
                                          style: const TextStyle(
                                            color: AppColors.textLight,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 17,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ProEntrance(
                        delayMs: 450,
                        child: FutureBuilder<String>(
                          future: Config.getAppVersion(),
                          builder: (context, snapshot) {
                            return Text(
                              'v${snapshot.data ?? "1.0.0"}',
                              style: TextStyle(
                                color: AppColors.textLight.withValues(alpha: 0.62),
                                fontSize: Constants.smallFontSize,
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturePill({required IconData icon, required String label}) {
    return ProPressable(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.textLight.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.textLight.withValues(alpha: 0.14)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: AppColors.textLight.withValues(alpha: 0.9)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textLight.withValues(alpha: 0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
