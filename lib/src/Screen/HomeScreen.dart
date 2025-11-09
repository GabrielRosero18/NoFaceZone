import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nofacezone/src/Custom/AppColors.dart';
import 'package:nofacezone/src/Custom/AppLocalizations.dart';
import 'package:nofacezone/src/Custom/AppMessages.dart';
import 'package:nofacezone/src/Custom/CustomSnackBar.dart';
import 'package:nofacezone/src/Providers/UserProvider.dart';
import 'package:nofacezone/src/Providers/AppProvider.dart';
import 'package:nofacezone/src/Services/PointsService.dart';
import 'package:nofacezone/src/Custom/Library.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeInAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
    
    // Mostrar mensaje motivacional después de que la pantalla se construya
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showWelcomeMessage();
      // Otorgar puntos por inicio de sesión diario
      PointsService.awardDailyLoginPoints();
    });
  }

  /// Mostrar mensaje motivacional al entrar a la app
  void _showWelcomeMessage() {
    if (!mounted) return;
    
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return;
    
    // Lista de mensajes motivacionales para cuando entra a la app
    final welcomeMessages = [
      '¡Sigue así! Cada día es una nueva oportunidad 🌟',
      'Estás haciendo un gran trabajo 💪',
      'Tu progreso es increíble, ¡continúa! 🎯',
      'Cada momento sin redes sociales te hace más fuerte ⚡',
      'Estás construyendo hábitos increíbles 🚀',
      'Tu futuro yo te lo agradecerá 🌈',
      '¡Eres más fuerte de lo que piensas! 💎',
      'Cada paso cuenta, sigue adelante 🎉',
      'Tu bienestar es tu prioridad ✨',
      'Estás tomando el control de tu vida 🎊',
    ];
    
    final random = Random();
    final message = welcomeMessages[random.nextInt(welcomeMessages.length)];
    
    // Esperar un poco para que la animación termine
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        CustomSnackBar.showTheme(
          context,
          message,
          icon: Icons.auto_awesome_rounded,
          duration: const Duration(milliseconds: 2500),
        );
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Escuchar cambios del AppProvider para actualizar el tema
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
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
          child: FadeTransition(
            opacity: _fadeInAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header con saludo y perfil
                    _buildHeader(),
                    const SizedBox(height: 24),
                    
                    // Mensaje motivacional
                    _buildMotivationalMessage(),
                    const SizedBox(height: 24),
                    
                    // Resumen de uso
                    _buildUsageSummary(),
                    const SizedBox(height: 24),
                    
                    // Límites de uso
                    _buildUsageLimits(),
                    const SizedBox(height: 24),
                    
                    // Progreso semanal
                    _buildWeeklyProgress(),
                    const SizedBox(height: 24),
                    
                    // Navegación rápida
                    _buildQuickNavigation(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
      },
    );
  }

  Widget _buildHeader() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final localizations = AppLocalizations.of(context)!;
        final user = userProvider.user;
        final userName = user?.name ?? localizations.user;
        final currentHour = DateTime.now().hour;
        String greeting = localizations.goodMorning;
        
        if (currentHour >= 12 && currentHour < 18) {
          greeting = localizations.goodAfternoon;
        } else if (currentHour >= 18) {
          greeting = localizations.goodEvening;
        }

        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textLight.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
            // Avatar del usuario
            Consumer<UserProvider>(
              builder: (context, userProvider, child) {
                final user = userProvider.user;
                return Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: AppColors.accentGradient),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.darkSurface,
                    ),
                    child: user?.profileImage != null && user!.profileImage!.isNotEmpty
                        ? Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: NetworkImage(user.profileImage!),
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            color: AppColors.textLight,
                            size: 28,
                          ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildMotivationalMessage() {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final localizations = AppLocalizations.of(context)!;
        // Obtener un mensaje aleatorio de las colecciones activas traducido
        final message = AppMessages.getRandomMessage(localizations);
        
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.accentPurple.withValues(alpha: 0.3),
                AppColors.accentBlue.withValues(alpha: 0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.textLight.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentPurple.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.textLight.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: AppColors.textLight,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💬 ${localizations.messageOfDay}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textLight.withValues(alpha: 0.8),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textLight,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUsageSummary() {
    final localizations = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.textLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textLight.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📱 ${localizations.usageSummary}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildUsageCard(
                  localizations.timeWithoutFacebook,
                  '2h 45m',
                  Icons.access_time,
                  AppColors.accentBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildUsageCard(
                  localizations.blockedSessions,
                  '3',
                  Icons.block,
                  AppColors.accentPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildUsageCard(
                  localizations.timeSaved,
                  '1h 20m',
                  Icons.savings,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildUsageCard(
                  localizations.consecutiveDays,
                  '5',
                  Icons.calendar_today,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsageCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.textLight.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.textLight.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textLight,
              shadows: [
                Shadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textLight.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageLimits() {
    final localizations = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.textLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textLight.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '⏰ ${localizations.usageLimitsTitleHome}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 16),
          _buildLimitItem(
            localizations.dailyLimitHome,
            '2 ${localizations.hours}',
            '1h 15m ${localizations.remaining}',
            Icons.access_time,
            AppColors.accentBlue,
            0.4, // 40% usado
          ),
          const SizedBox(height: 12),
          _buildLimitItem(
            localizations.nightBlock,
            '22:00 - 07:00',
            localizations.active,
            Icons.bedtime,
            AppColors.accentPurple,
            1.0, // 100% activo
          ),
          const SizedBox(height: 12),
          _buildLimitItem(
            localizations.mandatoryBreaks,
            'Cada 30 min',
            '${localizations.nextIn} 15 min',
            Icons.pause,
            Colors.orange,
            0.5, // 50% del tiempo transcurrido
          ),
        ],
      ),
    );
  }

  Widget _buildLimitItem(String title, String value, String status, IconData icon, Color color, double progress) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.textLight.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.textLight.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                // Barra de progreso mejorada
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.textLight.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color, color.withValues(alpha: 0.8)],
                        ),
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyProgress() {
    final localizations = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.textLight.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textLight.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentPurple.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.textLight.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.trending_up,
                  color: AppColors.accentPurple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                localizations.weeklyProgress,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Barra de progreso mejorada
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.textLight.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 0.75,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: AppColors.accentGradient),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentPurple.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '5 ${localizations.ofWord} 7 ${localizations.daysCompleted}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textLight.withValues(alpha: 0.9),
                ),
              ),
              Text(
                '75%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentPurple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickNavigation() {
    final localizations = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🚀 ${localizations.quickNavigation}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textLight,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildNavigationCard(
                localizations.statistics,
                Icons.analytics,
                AppColors.accentBlue,
                () => navigate(context, CustomScreen.statistics),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildNavigationCard(
                localizations.rewards,
                Icons.card_giftcard,
                Colors.orange,
                () => navigate(context, CustomScreen.rewards),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildNavigationCard(
                localizations.settings,
                Icons.settings,
                AppColors.accentPurple,
                () => navigate(context, CustomScreen.settings),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildNavigationCard(
                localizations.emotionTracking,
                Icons.sentiment_satisfied_alt,
                Colors.pink,
                () => navigate(context, CustomScreen.emotionTracking),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNavigationCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.textLight.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.textLight.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
