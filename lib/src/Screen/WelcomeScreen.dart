import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'RegisterScreen.dart';
import 'LoginScreen.dart';
import 'package:nofacezone/src/Custom/AppColors.dart';
import 'package:nofacezone/src/Custom/AppLocalizations.dart';
import 'package:nofacezone/src/Custom/Config.dart';
import 'package:nofacezone/src/Custom/Constans.dart';
import 'package:nofacezone/src/Providers/AppProvider.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Escuchar cambios del AppProvider para actualizar el tema
    final appProvider = Provider.of<AppProvider>(context);
    AppColors.setTheme(appProvider.colorTheme);
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.backgroundGradient,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Contenido principal centrado
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                  // Icono con gradiente
                  Container(
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
                          'FB',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textLight,
                            shadows: [
                              Shadow(color: Color(0x80000000), blurRadius: 6, offset: Offset(0, 2)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Título con gradiente
                  ShaderMask(
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
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        shadows: [
                          Shadow(
                            color: Color(0x80000000),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.appSubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textLight.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.appDescriptionText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: AppColors.textLight.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 48),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: AppColors.accentGradient),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: AppColors.cardShadow,
                            ),
                            child: FilledButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                                );
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                              child: Text(
                                AppLocalizations.of(context)!.signIn,
                                style: TextStyle(
                                  color: AppColors.textLight,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (context) => const RegisterScreen()),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppColors.textLight.withValues(alpha: 0.8)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.signUp,
                              style: TextStyle(
                                color: AppColors.textLight,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Versión en la esquina inferior izquierda
              Positioned(
                bottom: 16,
                left: 16,
                child: FutureBuilder<String>(
                  future: Config.getAppVersion(),
                  builder: (context, snapshot) {
                    return Text(
                      'v${snapshot.data ?? "1.0.0"}',
                      style: TextStyle(
                        color: AppColors.textLight.withValues(alpha: 0.6),
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
    );
  }
}
