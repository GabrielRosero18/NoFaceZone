import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nofacezone/src/Custom/AppColors.dart';
import 'package:nofacezone/src/Custom/Config.dart';
import 'package:nofacezone/src/Custom/Constans.dart';
import 'package:nofacezone/src/Custom/Library.dart';
import 'package:nofacezone/src/Providers/AppProvider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: "¡Bienvenido a NoFaceZone!",
      description: "Toma el control de tu tiempo en redes sociales y mejora tu bienestar digital.",
      icon: Icons.psychology,
    ),
    OnboardingPage(
      title: "Controla tu adicción",
      description: "Monitorea tu uso de Facebook y establece límites saludables para tu tiempo en línea.",
      icon: Icons.timer,
    ),
    OnboardingPage(
      title: "Privacidad garantizada",
      description: "Tus datos están seguros con nosotros. Enfócate en lo que realmente importa.",
      icon: Icons.security,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: Constants.mediumAnimation,
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _finishOnboarding() async {
    // Marcar que el usuario ya completó el onboarding usando Provider
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    await appProvider.completeOnboarding();
    
    if (mounted) {
      navigate(context, CustomScreen.welcome, finishCurrent: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.backgroundGradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Indicador de progreso
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index 
                            ? AppColors.textLight 
                            : AppColors.textLight.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Contenido de las páginas
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _buildPage(_pages[index]);
                  },
                ),
              ),
              
              // Botones de navegación
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Botón saltar (solo en la primera página)
                    if (_currentPage == 0)
                      TextButton(
                        onPressed: _finishOnboarding,
                        child: Text(
                          'Saltar',
                          style: TextStyle(
                            color: AppColors.textLight.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 60),
                    
                    // Botón siguiente/empezar
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: AppColors.accentGradient),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: AppColors.cardShadow,
                      ),
                      child: FilledButton(
                        onPressed: _nextPage,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: Text(
                          _currentPage == _pages.length - 1 ? 'Empezar' : 'Siguiente',
                          style: const TextStyle(
                            color: AppColors.textLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
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

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icono
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: AppColors.accentGradient),
              boxShadow: AppColors.elevatedShadow,
            ),
            child: Container(
              margin: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.darkSurface,
                border: Border.all(color: AppColors.textLight.withValues(alpha: 0.45), width: 1),
              ),
              child: Icon(
                page.icon,
                size: 48,
                color: AppColors.textLight,
              ),
            ),
          ),
          
          const SizedBox(height: 48),
          
          // Título
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textLight,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Descripción
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: AppColors.textLight.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
  });
}
