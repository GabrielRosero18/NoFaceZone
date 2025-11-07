import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nofacezone/src/Custom/Library.dart';
import 'package:nofacezone/src/Custom/AppColors.dart';
import 'package:nofacezone/src/Providers/AppProvider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleIn;
  late final Animation<double> _fadeIn;

  // Los gradientes se obtendrán dinámicamente en el build


  startTime() async {
    // Obtener el provider de la app
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    
    // Esperar a que se cargue el estado de la app
    while (appProvider.isLoading) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      
      // Navegar según el estado del onboarding
      if (appProvider.isOnboardingCompleted) {
        navigate(context, CustomScreen.welcome, finishCurrent: true);
      } else {
        navigate(context, CustomScreen.onboarding, finishCurrent: true);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    startTime();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scaleIn = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
        child: Stack(
          children: [
            // Icono superior con las iniciales NFZ
            Positioned(
              top: MediaQuery.of(context).padding.top + 36,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fadeIn,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: AppColors.accentGradient),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 16,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.darkSurface, // más oscuro para contraste
                        border: Border.all(color: Colors.white.withValues(alpha: 0.45), width: 1),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'NFZ',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                          color: AppColors.textLight,
                          shadows: [
                            Shadow(color: Color(0x80000000), blurRadius: 6, offset: Offset(0, 2)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Título de marca en el centro con leve animación
            Center(
              child: ScaleTransition(
                scale: _scaleIn,
                child: FadeTransition(
                  opacity: _fadeIn,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                            fontSize: 48,
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
                      const SizedBox(height: 12),
                      Text(
                        'Privacidad con estilo',
                        style: TextStyle(
                          color: AppColors.textLight.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Sutil brillo decorativo
            Positioned(
              bottom: -80,
              right: -40,
              child: IgnorePointer(
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Color(0x66B8C1FF), Color(0x00000000)],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}