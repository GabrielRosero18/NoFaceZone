import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:nofacezone/src/Custom/AppColors.dart';
import 'package:nofacezone/src/Custom/AppLocalizations.dart';
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
  double _pageOffset = 0;
  Timer? _autoPlayTimer;
  bool _autoPlayPausedByUser = false;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      if (!mounted) return;
      setState(() {
        _pageOffset = _pageController.page ?? _currentPage.toDouble();
      });
    });
    _startAutoPlay();
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    final pages = _localizedPages();
    if (_currentPage < pages.length - 1) {
      HapticFeedback.selectionClick();
      _pageController.nextPage(
        duration: Constants.mediumAnimation,
        curve: Curves.easeInOut,
      );
    } else {
      HapticFeedback.mediumImpact();
      _finishOnboarding();
    }
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || _autoPlayPausedByUser) return;
      final pages = _localizedPages();
      if (_currentPage < pages.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  void _pauseAutoPlay() {
    _autoPlayPausedByUser = true;
    _autoPlayTimer?.cancel();
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
    // Escuchar cambios del AppProvider para actualizar el tema
    final appProvider = Provider.of<AppProvider>(context);
    AppColors.setTheme(appProvider.colorTheme);
    final pages = _localizedPages();
    
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
            Positioned(
              top: -80 + (_pageOffset * 6),
              right: -60 + (_pageOffset * 10),
              child: IgnorePointer(
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Color(0x44C5B8FF), Color(0x00000000)],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -70,
              left: -40 - (_pageOffset * 10),
              child: IgnorePointer(
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Color(0x33FFFFFF), Color(0x00000000)],
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
              // Indicador de progreso
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    pages.length,
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
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTapDown: (_) => _pauseAutoPlay(),
                  onHorizontalDragStart: (_) => _pauseAutoPlay(),
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemCount: pages.length,
                    itemBuilder: (context, index) {
                      return _buildPage(pages[index], index);
                    },
                  ),
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
                        onPressed: () {
                          _pauseAutoPlay();
                          HapticFeedback.selectionClick();
                          _finishOnboarding();
                        },
                        child: Text(
                          AppLocalizations.of(context)!.onboardingSkip,
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
                        gradient: LinearGradient(colors: AppColors.accentGradient),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: AppColors.cardShadow,
                      ),
                      child: FilledButton(
                        onPressed: () {
                          _pauseAutoPlay();
                          _nextPage();
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
                          _currentPage == pages.length - 1
                              ? AppLocalizations.of(context)!.onboardingStart
                              : AppLocalizations.of(context)!.onboardingNext,
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
                ],
              ),
            ),
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
    );
  }

  List<OnboardingPage> _localizedPages() {
    final loc = AppLocalizations.of(context)!;
    return [
      OnboardingPage(
        title: loc.onboardingWelcomeTitle,
        description: loc.onboardingWelcomeDesc,
        icon: Icons.psychology,
      ),
      OnboardingPage(
        title: loc.onboardingControlTitle,
        description: loc.onboardingControlDesc,
        icon: Icons.timer,
      ),
      OnboardingPage(
        title: loc.onboardingPrivacyTitle,
        description: loc.onboardingPrivacyDesc,
        icon: Icons.security,
      ),
    ];
  }

  Widget _buildPage(OnboardingPage page, int index) {
    final delta = (index - _pageOffset).abs().clamp(0.0, 1.2);
    final isActive = _currentPage == index;

    return Transform.translate(
      offset: Offset((index - _pageOffset) * 24, 0),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSlide(
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
              offset: isActive ? Offset.zero : const Offset(0, 0.08),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 450),
                opacity: isActive ? 1 : 0.78,
                child: Transform.scale(
                  scale: 1 - (delta * 0.08),
                  child: (index == 0)
                      ? Hero(
                          tag: 'nfz_brand_mark',
                          child: Material(
                            color: Colors.transparent,
                            child: _buildOnboardingIcon(page),
                          ),
                        )
                      : _buildOnboardingIcon(page),
                ),
              ),
            ),
            const SizedBox(height: 44),
            AnimatedSlide(
              duration: const Duration(milliseconds: 520),
              curve: Curves.easeOutCubic,
              offset: isActive ? Offset.zero : const Offset(0.05, 0),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 520),
                opacity: isActive ? 1 : 0.8,
                child: Text(
                  page.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 29,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textLight,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            AnimatedSlide(
              duration: const Duration(milliseconds: 620),
              curve: Curves.easeOutCubic,
              offset: isActive ? Offset.zero : const Offset(0, 0.06),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 620),
                opacity: isActive ? 1 : 0.75,
                child: Text(
                  page.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.55,
                    color: AppColors.textLight.withValues(alpha: 0.82),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingIcon(OnboardingPage page) {
    return Container(
      width: 124,
      height: 124,
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
        child: Icon(
          page.icon,
          size: 50,
          color: AppColors.textLight,
        ),
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
