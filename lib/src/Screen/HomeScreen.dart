import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nofacezone/src/Custom/AppColors.dart';
import 'package:nofacezone/src/Custom/AppLocalizations.dart';
import 'package:nofacezone/src/Custom/AppMessages.dart';
import 'package:nofacezone/src/Custom/CustomSnackBar.dart';
import 'package:nofacezone/src/Providers/UserProvider.dart';
import 'package:nofacezone/src/Providers/AppProvider.dart';
import 'package:nofacezone/src/Services/PointsService.dart';
import 'package:nofacezone/src/Services/UsageLimitsService.dart';
import 'package:nofacezone/src/Services/PreferencesService.dart';
import 'package:nofacezone/src/Screen/UsageLimitBlockedScreen.dart';
import 'package:nofacezone/src/Screen/EditProfileScreen.dart';
import 'package:nofacezone/src/Custom/Library.dart';
import 'package:nofacezone/src/Custom/AppImageProviders.dart';

enum _BlockReason { dailyLimit, nightBlock, mandatoryBreak }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideAnimation;
  Timer? _usageTimer;
  int _remainingMinutes = 0;
  int _dailyLimitMinutes = 60;
  int? _currentSessionId;
  DateTime? _localSessionStartAt;
  bool _isBlockedScreenShown = false;
  bool _isLoadingUsageData = false;
  DateTime? _blockDismissedTime; // Ventana de gracia temporal para bloqueo diario
  DateTime? _dailyBlockDismissedUntil; // "Quitar bloqueo por hoy" (hasta fin del día)
  DateTime? _nightBlockDismissedTime;
  DateTime? _mandatoryBreakDismissedTime;
  /// Última carga completa de uso (para espaciar llamadas a red desde el timer periódico).
  DateTime? _lastUsageDataFetchAt;

  int _consecutiveDaysWithEmotions = 0;
  double _weeklyProgressFactor = 0.0;
  int _weeklyDaysWithUsage = 0;
  String _nightWindowLabel = '—';
  String _pauseIntervalLabel = '—';
  int? _minutesToNextMandatoryPause;
  int _mandatoryPauseIntervalMinutes = 30;
  bool _isInNightBlockWindow = false;

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _animationController.value = 1.0;
      } else {
        _animationController.forward();
      }
    });
    
    // Registrar observer para detectar cambios en el ciclo de vida de la app
    WidgetsBinding.instance.addObserver(this);
    
    // Iniciar sesión de uso cuando se abre la app
    _startAppSession();
    
    // Cargar límites y tiempo restante después de iniciar sesión (con delay para evitar múltiples llamadas)
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _loadUsageData().then((_) {
          // Verificar límite después de cargar datos iniciales
          if (mounted && _remainingMinutes <= 0) {
            _showBlockedScreen(_BlockReason.dailyLimit);
          }
        });
      }
    });
    
    // Iniciar timer para actualizar cada 10 segundos (más frecuente)
    _startUsageTimer();
    
    // Mostrar mensaje motivacional después de que la pantalla se construya
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showWelcomeMessage();
      // Otorgar puntos por inicio de sesión diario
      PointsService.awardDailyLoginPoints();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        // App volvió a primer plano - iniciar nueva sesión
        _startAppSession();
        // Cargar datos después de un pequeño delay para evitar múltiples llamadas
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _loadUsageData();
          }
        });
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // App fue a segundo plano - finalizar sesión actual
        _endAppSession();
        break;
      case AppLifecycleState.detached:
        // App está siendo cerrada - finalizar sesión
        _endAppSession();
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  /// Iniciar sesión de uso cuando se abre la app
  Future<void> _startAppSession() async {
    try {
      // Finalizar cualquier sesión activa anterior (por si acaso)
      final activeSessions = await UsageLimitsService.getActiveSessions();
      for (var session in activeSessions) {
        final sessionId = session['id'] as int;
        await UsageLimitsService.finishUsageSession(sessionId);
      }
      
      // Iniciar nueva sesión
      final sessionId = await UsageLimitsService.startUsageSession();
      if (sessionId != null) {
        _currentSessionId = sessionId;
        _localSessionStartAt = DateTime.now();
        
        if (!mounted) return;
        // Actualizar AppProvider
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        await appProvider.startUsageSession();
      }
    } catch (e) {
      debugPrint('Error starting app session: $e');
    }
  }

  /// Finalizar sesión cuando la app se cierra o va a segundo plano
  Future<void> _endAppSession() async {
    try {
      if (_currentSessionId != null) {
        await UsageLimitsService.finishUsageSession(_currentSessionId!);
        
        if (!mounted) return;
        // Actualizar AppProvider
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        await appProvider.finishUsageSession();
        
        _currentSessionId = null;
        _localSessionStartAt = null;
      }
    } catch (e) {
      debugPrint('Error ending app session: $e');
    }
  }

  /// Cargar datos de uso desde Supabase (optimizado)
  Future<void> _loadUsageData({bool fromPeriodicTimer = false}) async {
    if (fromPeriodicTimer && _lastUsageDataFetchAt != null) {
      final since = DateTime.now().difference(_lastUsageDataFetchAt!);
      if (since < const Duration(seconds: 8)) {
        return;
      }
    }
    // Prevenir múltiples llamadas simultáneas
    if (_isLoadingUsageData) {
      return;
    }

    _isLoadingUsageData = true;
    
    try {
      // Obtener datos de uso de manera más eficiente
      // Primero obtener el registro del día que ya contiene toda la información
      final todayUsage = await UsageLimitsService.getOrCreateTodayUsage();
      
      if (todayUsage == null) {
        if (mounted) {
          await _refreshHomeSummaryMetrics();
        }
        _isLoadingUsageData = false;
        return;
      }
      
      final limit = todayUsage['limite_del_dia_minutos'] as int? ?? 
                    await UsageLimitsService.getCurrentDailyLimit();
      final used = todayUsage['tiempo_usado_minutos'] as int? ?? 0;
      
      // Calcular tiempo restante considerando sesiones activas
      final remainingFromService = await UsageLimitsService.getRemainingTimeToday();

      // Fallback local: sumar minutos de sesión activa en vivo para evitar
      // depender totalmente de la sincronización de Supabase.
      int localActiveMinutes = 0;
      if (_localSessionStartAt != null) {
        final elapsed = DateTime.now().difference(_localSessionStartAt!).inMinutes;
        localActiveMinutes = elapsed.clamp(0, 24 * 60);
      }
      final localRemaining = (limit - (used + localActiveMinutes)).clamp(0, limit);
      final remaining = remainingFromService < localRemaining
          ? remainingFromService
          : localRemaining;
      
      if (mounted) {
        // Solo loggear si hay cambios significativos para mejorar rendimiento
        if ((_dailyLimitMinutes != limit || _remainingMinutes != remaining) && 
            (_remainingMinutes - remaining).abs() > 1) {
          debugPrint('📊 Datos de uso actualizados:');
          debugPrint('   Límite: $limit minutos');
          debugPrint('   Usado: $used minutos');
          debugPrint('   Sesión local activa: $localActiveMinutes minutos');
          debugPrint('   Restante (servicio): $remainingFromService minutos');
          debugPrint('   Restante (local): $localRemaining minutos');
          debugPrint('   Restante: $remaining minutos');
        }
        
        setState(() {
          _dailyLimitMinutes = limit;
          _remainingMinutes = remaining;
        });
        
        // Actualizar AppProvider de manera más eficiente (solo cuando es necesario)
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        // No actualizar cada vez, solo cuando hay cambios significativos
        if (appProvider.dailyUsageLimit != limit) {
          await appProvider.refreshUsageLimits();
        }
        if (!mounted) return;
        if (appProvider.todayUsageMinutes != used) {
          await appProvider.updateTodayUsage();
        }
        if (!mounted) return;
        
        // Verificar si se alcanzó el límite y mostrar pantalla de bloqueo.
        // Respeta "quitar bloqueo por hoy" y una gracia corta después de sumar tiempo.
        final now = DateTime.now();
        final isDailySnoozedForToday = _dailyBlockDismissedUntil != null &&
            now.isBefore(_dailyBlockDismissedUntil!);
        final isInDailyGraceWindow = _blockDismissedTime != null &&
            now.difference(_blockDismissedTime!).inMinutes < 3;
        final canShowBlock = !isDailySnoozedForToday && !isInDailyGraceWindow;
        
        // Solo loggear si hay cambios significativos
        if (remaining <= 0 || (remaining != _remainingMinutes && _remainingMinutes > 0)) {
          debugPrint('🔍 Verificación de bloqueo:');
          debugPrint('   Tiempo restante: $remaining minutos');
          debugPrint('   Bloqueo mostrado: $_isBlockedScreenShown');
          debugPrint('   Puede mostrar bloqueo: $canShowBlock');
        }
        
        // Verificar si el tiempo se acabó
        if (remaining <= 0 && !_isBlockedScreenShown && canShowBlock) {
          debugPrint('🚨 Tiempo agotado. Mostrando pantalla de bloqueo');
          _showBlockedScreen(_BlockReason.dailyLimit);
        } else if (remaining > 0 && _isBlockedScreenShown) {
          // Si hay tiempo restante y la pantalla está mostrada, cerrarla
          debugPrint('✅ Hay tiempo restante ($remaining min), cerrando bloqueo');
          _isBlockedScreenShown = false;
          _blockDismissedTime = null;
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        }

        // Bloqueo automático por horario nocturno (con cooldown de 5 min al quitar)
        final isInNightBlock = await UsageLimitsService.isInNightBlockTime();
        final canShowNightBlock = _nightBlockDismissedTime == null ||
            DateTime.now().difference(_nightBlockDismissedTime!).inMinutes >= 5;

        if (isInNightBlock && !_isBlockedScreenShown && remaining > 0 && canShowNightBlock) {
          debugPrint('🌙 Bloqueo nocturno activo. Mostrando pantalla de bloqueo.');
          _showBlockedScreen(_BlockReason.nightBlock);
        }

        // Bloqueo automático por pausas obligatorias (cuando llegue a 0 min al próximo descanso)
        final minutesToBreak = await UsageLimitsService.getTimeUntilNextBreak();
        final shouldShowBreakBlock = appProvider.mandatoryBreaksActive &&
            minutesToBreak != null &&
            minutesToBreak <= 0;
        final canShowBreakBlock = _mandatoryBreakDismissedTime == null ||
            DateTime.now().difference(_mandatoryBreakDismissedTime!).inMinutes >= 5;

        if (shouldShowBreakBlock &&
            !_isBlockedScreenShown &&
            remaining > 0 &&
            !isInNightBlock &&
            canShowBreakBlock) {
          debugPrint('⏸️ Pausa obligatoria alcanzada. Mostrando pantalla de bloqueo.');
          _showBlockedScreen(_BlockReason.mandatoryBreak);
        }

        await _refreshHomeSummaryMetrics();

        _lastUsageDataFetchAt = DateTime.now();
      }
    } catch (e) {
      debugPrint('Error loading usage data: $e');
    } finally {
      _isLoadingUsageData = false;
    }
  }

  /// Mostrar pantalla de bloqueo cuando se alcanza el límite
  void _showBlockedScreen(_BlockReason reason) {
    if (!mounted || _isBlockedScreenShown) return;
    
    _isBlockedScreenShown = true;
    PreferencesService.incrementBlockedSessionsCount();

    final isDailyLimit = reason == _BlockReason.dailyLimit;
    final title = switch (reason) {
      _BlockReason.dailyLimit => '⏰ Límite Alcanzado',
      _BlockReason.nightBlock => '🌙 Bloqueo Nocturno',
      _BlockReason.mandatoryBreak => '⏸️ Pausa Obligatoria',
    };
    final message = switch (reason) {
      _BlockReason.dailyLimit => '¡Has alcanzado tu límite diario de uso! 🌟',
      _BlockReason.nightBlock => 'Estás dentro del horario de descanso nocturno configurado. Es momento de desconectarte.',
      _BlockReason.mandatoryBreak => 'Llegó la pausa obligatoria. Toma un descanso breve para cuidar tu bienestar.',
    };
    
    // Mostrar como overlay/modal
    showDialog(
      context: context,
      barrierDismissible: false, // No se puede cerrar tocando fuera
      barrierColor: Colors.black.withValues(alpha: 0.95),
      builder: (context) => PopScope(
        canPop: false, // Prevenir cierre con botón atrás
        child: UsageLimitBlockedScreen(
          title: title,
          message: message,
          showAddTimeButton: isDailyLimit,
          showDismissButton: true,
          onTimeAdded: () async {
            if (!isDailyLimit) return;
            // Al sumar tiempo, dar una ventana de gracia para evitar reaparición inmediata
            // mientras se sincronizan los datos.
            _isBlockedScreenShown = false;
            _blockDismissedTime = DateTime.now();
            _dailyBlockDismissedUntil = null;

            await Future.delayed(const Duration(milliseconds: 1200));
            await _loadUsageData();

            final remaining = await UsageLimitsService.getRemainingTimeToday();
            if (mounted) {
              setState(() {
                _remainingMinutes = remaining;
              });
            }

            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                _loadUsageData();
              }
            });
          },
          onBlockRemoved: () {
            _isBlockedScreenShown = false;
            switch (reason) {
              case _BlockReason.dailyLimit:
                // "Quitar bloqueo por hoy": no volver a mostrar hasta fin del día.
                final now = DateTime.now();
                _dailyBlockDismissedUntil =
                    DateTime(now.year, now.month, now.day, 23, 59, 59);
                _blockDismissedTime = now;
                debugPrint('🚫 Bloqueo diario quitado por hoy.');
                break;
              case _BlockReason.nightBlock:
                _nightBlockDismissedTime = DateTime.now();
                debugPrint('🚫 Bloqueo nocturno quitado manualmente por el usuario.');
                break;
              case _BlockReason.mandatoryBreak:
                _mandatoryBreakDismissedTime = DateTime.now();
                debugPrint('🚫 Pausa obligatoria omitida manualmente por el usuario.');
                break;
            }
          },
        ),
      ),
    ).then((_) {
      // Cuando se cierra el diálogo
      _isBlockedScreenShown = false;
    });
  }

  /// Iniciar timer para actualizar el contador cada 10 segundos (optimizado)
  void _startUsageTimer() {
    _usageTimer?.cancel(); // Cancelar timer anterior si existe
    _usageTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      // Actualizar datos de uso solo una vez por ciclo
      // No actualizar si ya se está cargando para evitar múltiples llamadas
      if (!_isLoadingUsageData) {
        try {
          await _loadUsageData(fromPeriodicTimer: true);
        } catch (e) {
          debugPrint('❌ Error en timer de actualización de uso: $e');
        }
      }
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
    // Finalizar sesión al cerrar la app
    _endAppSession();
    
    // Remover observer
    WidgetsBinding.instance.removeObserver(this);
    
    _animationController.dispose();
    _usageTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Solo reconstruir el shell cuando cambian tema o idioma (menos trabajo que Consumer completo).
    return Selector<AppProvider, String>(
      selector: (_, p) =>
          '${p.colorTheme}|${p.language}|${p.nightBlockActive}|${p.mandatoryBreaksActive}|${p.dailyUsageLimit}|${p.todayUsageMinutes}',
      builder: (context, _, __) {
        final appProvider = Provider.of<AppProvider>(context, listen: false);
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
            Semantics(
              button: true,
              label: localizations.editProfile,
              child: GestureDetector(
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                  );
                  if (mounted) {
                    setState(() {});
                  }
                },
                child: ExcludeSemantics(
                  child: Container(
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
                                  image: networkAvatarProvider(user.profileImage!, logicalDiameter: 52),
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
                  ),
                ),
              ),
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

  Future<void> _refreshHomeSummaryMetrics() async {
    try {
      final consecutive = await PointsService.getConsecutiveDays();
      final weekly = await UsageLimitsService.getWeeklyStats();
      final limits = await UsageLimitsService.getOrCreateUsageLimits();
      final nextBreak = await UsageLimitsService.getTimeUntilNextBreak();
      final inNight = await UsageLimitsService.isInNightBlockTime();

      if (!mounted) return;
      final app = Provider.of<AppProvider>(context, listen: false);
      final goalHours = app.weeklyGoal.clamp(1, 200);
      final totalMin = weekly['total_minutos'] as int? ?? 0;
      final usedHours = totalMin / 60.0;
      final factor = (usedHours / goalHours).clamp(0.0, 1.0);
      final diasUso = weekly['dias_con_uso'] as int? ?? 0;

      String nightLbl = '—';
      int pauseInterval = 30;
      if (limits != null) {
        final s = limits['bloqueo_nocturno_inicio'] as String?;
        final e = limits['bloqueo_nocturno_fin'] as String?;
        nightLbl = _compactTimeRange(s, e);
        pauseInterval = limits['intervalo_pausa_minutos'] as int? ?? 30;
      }

      setState(() {
        _consecutiveDaysWithEmotions = consecutive;
        _weeklyProgressFactor = factor;
        _weeklyDaysWithUsage = diasUso;
        _nightWindowLabel = nightLbl;
        _pauseIntervalLabel = '$pauseInterval min';
        _minutesToNextMandatoryPause = nextBreak;
        _mandatoryPauseIntervalMinutes = pauseInterval;
        _isInNightBlockWindow = inNight;
      });
    } catch (e) {
      debugPrint('Error refrescando métricas del home: $e');
    }
  }

  String _compactTimeRange(String? start, String? end) {
    if (start == null || end == null) return '—';
    String short(String t) {
      final p = t.split(':');
      if (p.length >= 2) return '${p[0]}:${p[1]}';
      return t;
    }
    return '${short(start)} – ${short(end)}';
  }

  String _formatRecordHours(int hours) {
    if (hours <= 0) return '0 h';
    return '$hours h';
  }

  String _formatMinutesHm(int minutes) {
    if (minutes <= 0) return '0m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  double _mandatoryBreakProgress(bool mandatoryActive) {
    if (!mandatoryActive) return 0.05;
    final interval = _mandatoryPauseIntervalMinutes.clamp(1, 9999);
    final next = _minutesToNextMandatoryPause;
    if (next == null) return 0.35;
    return (1.0 - (next / interval)).clamp(0.0, 1.0);
  }

  Widget _buildUsageSummary() {
    final localizations = AppLocalizations.of(context)!;
    final recordHours = PreferencesService.getRecordTimeWithoutFacebook();
    final blocked = PreferencesService.getBlockedSessionsCount();
    final app = Provider.of<AppProvider>(context, listen: false);
    final savedToday = (app.dailyUsageLimit - app.todayUsageMinutes).clamp(0, app.dailyUsageLimit);

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
                  _formatRecordHours(recordHours),
                  Icons.access_time,
                  AppColors.accentBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildUsageCard(
                  localizations.blockedSessions,
                  '$blocked',
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
                  _formatMinutesHm(savedToday),
                  Icons.savings,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildUsageCard(
                  localizations.consecutiveDays,
                  '$_consecutiveDaysWithEmotions',
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
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final usedMinutes = appProvider.todayUsageMinutes;
    final limitMinutes = appProvider.dailyUsageLimit;
    final remainingMinutes = (limitMinutes - usedMinutes).clamp(0, limitMinutes);

    String limitText;
    if (limitMinutes >= 60) {
      final hours = limitMinutes ~/ 60;
      final mins = limitMinutes % 60;
      if (mins > 0) {
        limitText = '${hours}h ${mins}m';
      } else {
        limitText = '$hours ${localizations.hours}';
      }
    } else {
      limitText = '$limitMinutes ${localizations.minutesShort}';
    }

    String remainingText;
    if (remainingMinutes >= 60) {
      final hours = remainingMinutes ~/ 60;
      final mins = remainingMinutes % 60;
      if (mins > 0) {
        remainingText = '${hours}h ${mins}m';
      } else {
        remainingText = '${hours}h';
      }
    } else {
      remainingText = '${remainingMinutes}m';
    }

    final progress = limitMinutes > 0 ? usedMinutes / limitMinutes : 0.0;

    final nightStatus = !appProvider.nightBlockActive
        ? localizations.featureOff
        : (_isInNightBlockWindow ? localizations.active : localizations.usageStatusStandby);
    final nightProgress = !appProvider.nightBlockActive
        ? 0.05
        : (_isInNightBlockWindow ? 0.95 : 0.35);

    final mandatoryStatus = !appProvider.mandatoryBreaksActive
        ? localizations.featureOff
        : (_minutesToNextMandatoryPause != null
            ? '${localizations.nextIn} $_minutesToNextMandatoryPause ${localizations.minutesShort}'
            : localizations.usageStatusStandby);

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
          GestureDetector(
            onTap: () => _showTimeRemainingDialog(localizations),
            child: _buildLimitItem(
              localizations.dailyLimitHome,
              limitText,
              '$remainingText ${localizations.remaining}',
              Icons.access_time,
              AppColors.accentBlue,
              progress.clamp(0.0, 1.0),
            ),
          ),
          const SizedBox(height: 12),
          _buildLimitItem(
            localizations.nightBlock,
            appProvider.nightBlockActive ? _nightWindowLabel : '—',
            nightStatus,
            Icons.bedtime,
            AppColors.accentPurple,
            nightProgress,
          ),
          const SizedBox(height: 12),
          _buildLimitItem(
            localizations.mandatoryBreaks,
            appProvider.mandatoryBreaksActive ? _pauseIntervalLabel : '—',
            mandatoryStatus,
            Icons.pause,
            Colors.orange,
            _mandatoryBreakProgress(appProvider.mandatoryBreaksActive),
          ),
        ],
      ),
    );
  }


  /// Mostrar diálogo con reloj de tiempo restante
  void _showTimeRemainingDialog(AppLocalizations localizations) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return _TimeRemainingDialog(
          remainingMinutes: _remainingMinutes,
          dailyLimitMinutes: _dailyLimitMinutes,
          onRefresh: () async {
            // Solo recargar si no está ya cargando
            if (!_isLoadingUsageData) {
              await _loadUsageData();
            }
          },
        );
      },
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
              widthFactor: _weeklyProgressFactor.clamp(0.0, 1.0),
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
                '$_weeklyDaysWithUsage/7 ${localizations.days}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textLight.withValues(alpha: 0.9),
                ),
              ),
              Text(
                '${(_weeklyProgressFactor * 100).round()}%',
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

/// Diálogo con reloj que muestra el tiempo restante
class _TimeRemainingDialog extends StatefulWidget {
  final int remainingMinutes;
  final int dailyLimitMinutes;
  final VoidCallback onRefresh;

  const _TimeRemainingDialog({
    required this.remainingMinutes,
    required this.dailyLimitMinutes,
    required this.onRefresh,
  });

  @override
  State<_TimeRemainingDialog> createState() => _TimeRemainingDialogState();
}

class _TimeRemainingDialogState extends State<_TimeRemainingDialog> {
  Timer? _updateTimer;
  Timer? _syncTimer;
  int _currentRemainingSeconds = 0;
  DateTime _dialogStartTime = DateTime.now();
  int _initialRemainingSeconds = 0;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _initialRemainingSeconds = widget.remainingMinutes * 60;
    _currentRemainingSeconds = _initialRemainingSeconds;
    _dialogStartTime = DateTime.now();
    _startTimer();
  }

  @override
  void didUpdateWidget(_TimeRemainingDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Actualizar el contador cuando cambia el tiempo restante
    final newInitialSeconds = widget.remainingMinutes * 60;
    final oldInitialSeconds = oldWidget.remainingMinutes * 60;
    final now = DateTime.now();
    final currentElapsed = now.difference(_dialogStartTime).inSeconds;
    final currentCalculated = _initialRemainingSeconds - currentElapsed;
    final newRemainingSeconds = newInitialSeconds;
    
    // Si el tiempo restante aumentó (probablemente se agregó tiempo)
    if (newInitialSeconds > oldInitialSeconds) {
      // Calcular la diferencia de tiempo agregado
      final tiempoAgregado = newInitialSeconds - oldInitialSeconds;
      // Ajustar el tiempo inicial
      _initialRemainingSeconds = newInitialSeconds;
      // Ajustar el tiempo actual agregando el tiempo adicional
      final newCurrentSeconds = (_currentRemainingSeconds + tiempoAgregado).clamp(0, _initialRemainingSeconds);
      
      setState(() {
        _currentRemainingSeconds = newCurrentSeconds;
      });
      
      // Resetear el tiempo de inicio para mantener la sincronización correcta
      // El nuevo tiempo de inicio debe ser tal que: nuevo_tiempo_inicial - elapsed = nuevo_tiempo_actual
      _dialogStartTime = now.subtract(Duration(
        seconds: _initialRemainingSeconds - _currentRemainingSeconds
      ));
    } else if (newInitialSeconds != oldInitialSeconds) {
      // Si el tiempo cambió pero no aumentó, verificar si hay desincronización
      final diff = newRemainingSeconds - currentCalculated;
      if (diff.abs() > 10) {
        // Hay una desincronización significativa, ajustar
        _initialRemainingSeconds = newInitialSeconds;
        final newCalculated = (_initialRemainingSeconds - currentElapsed).clamp(0, _initialRemainingSeconds);
        setState(() {
          _currentRemainingSeconds = newCalculated;
        });
        // Ajustar el tiempo de inicio para sincronizar
        _dialogStartTime = now.subtract(Duration(
          seconds: _initialRemainingSeconds - _currentRemainingSeconds
        ));
      }
    }
  }

  void _startTimer() {
    // Timer principal que cuenta hacia atrás cada segundo
    // Calcula el tiempo restante basado en el tiempo transcurrido desde que se abrió el diálogo
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      final now = DateTime.now();
      final elapsed = now.difference(_dialogStartTime).inSeconds;
      final calculatedRemaining = _initialRemainingSeconds - elapsed;
      
      setState(() {
        if (calculatedRemaining > 0) {
          _currentRemainingSeconds = calculatedRemaining;
        } else {
          _currentRemainingSeconds = 0;
          // Si llegó a 0, recargar datos para verificar si realmente se agotó
          if (!_isSyncing) {
            _isSyncing = true;
            widget.onRefresh();
            // Resetear el estado de sincronización después de un momento
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (mounted) {
                _isSyncing = false;
              }
            });
          }
        }
      });
    });
    
    // Timer para sincronizar con Supabase cada 15 segundos (optimizado)
    // Sincroniza el tiempo restante con el servidor para mantener precisión
    _syncTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (!mounted || _isSyncing) {
        return;
      }
      
      _isSyncing = true;
      widget.onRefresh();
      
      // Actualizar el tiempo después de la sincronización
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) {
          _isSyncing = false;
          return;
        }
        
        final newInitialSeconds = widget.remainingMinutes * 60;
        final currentElapsed = DateTime.now().difference(_dialogStartTime).inSeconds;
        final currentCalculated = _initialRemainingSeconds - currentElapsed;
        final diff = newInitialSeconds - currentCalculated;
        
        // Si la diferencia es significativa (más de 10 segundos), actualizar
        // Esto puede ocurrir si se agregó tiempo o si hay desincronización
        if (diff.abs() > 10) {
          final oldInitial = _initialRemainingSeconds;
          _initialRemainingSeconds = newInitialSeconds;
          
          // Recalcular el tiempo restante actual considerando el tiempo transcurrido
          final newCalculated = (_initialRemainingSeconds - currentElapsed).clamp(0, _initialRemainingSeconds);
          
          setState(() {
            _currentRemainingSeconds = newCalculated;
          });
          
          // Si el tiempo aumentó, resetear el tiempo de inicio del diálogo para sincronización
          if (newInitialSeconds > oldInitial) {
            _dialogStartTime = DateTime.now().subtract(Duration(
              seconds: _initialRemainingSeconds - _currentRemainingSeconds
            ));
          }
        }
        
        _isSyncing = false;
      });
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _syncTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calcular horas, minutos y segundos
    final hours = _currentRemainingSeconds ~/ 3600;
    final minutes = (_currentRemainingSeconds % 3600) ~/ 60;
    final seconds = _currentRemainingSeconds % 60;

    // Color según el tiempo restante
    Color clockColor;
    if (_currentRemainingSeconds <= 0) {
      clockColor = Colors.red;
    } else if (_currentRemainingSeconds <= widget.dailyLimitMinutes * 60 * 0.25) {
      clockColor = Colors.orange;
    } else {
      clockColor = Colors.green;
    }

    // Calcular porcentaje usado
    final totalSeconds = widget.dailyLimitMinutes * 60;
    final progress = totalSeconds > 0 
        ? (1.0 - (_currentRemainingSeconds / totalSeconds)).clamp(0.0, 1.0)
        : 0.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.darkSurface,
              AppColors.darkSurface.withValues(alpha: 0.95),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: clockColor.withValues(alpha: 0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: clockColor.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Título
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '⏱️ Tiempo Restante',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textLight,
                  ),
                ),
                IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  icon: const Icon(Icons.close, color: AppColors.textLight),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Reloj circular
            Container(
              width: 240,
              height: 240,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    clockColor.withValues(alpha: 0.15),
                    clockColor.withValues(alpha: 0.05),
                  ],
                ),
                border: Border.all(
                  color: clockColor.withValues(alpha: 0.5),
                  width: 3,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Indicador de progreso circular
                  SizedBox(
                    width: 224,
                    height: 224,
                    child: Semantics(
                    label: 'Progreso de uso del día',
                    value: '${(progress * 100).round()} por ciento',
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 8,
                      backgroundColor: AppColors.textLight.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(clockColor),
                    ),
                  ),
                  ),
                  // Tiempo en el centro - layout flexible para evitar overflow
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hours > 0) ...[
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              hours.toString().padLeft(2, '0'),
                              style: const TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textLight,
                                height: 1.0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'horas',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textLight.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 2),
                        ],
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            minutes.toString().padLeft(2, '0'),
                            style: TextStyle(
                              fontSize: hours > 0 ? 30 : 38,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textLight,
                              height: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'minutos',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textLight.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            seconds.toString().padLeft(2, '0'),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textLight.withValues(alpha: 0.9),
                              height: 1.0,
                            ),
                          ),
                        ),
                        Text(
                          'segundos',
                          style: TextStyle(
                            fontSize: 9,
                            color: AppColors.textLight.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Tiempo en formato digital
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: clockColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: clockColor.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Text(
                hours > 0
                    ? '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}'
                    : '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textLight,
                  fontFeatures: [const FontFeature.tabularFigures()],
                  shadows: [
                    Shadow(
                      color: clockColor.withValues(alpha: 0.5),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Información adicional
            Builder(
              builder: (context) {
                // Calcular valores basados en el tiempo actual del contador
                final currentRemainingMinutes = (_currentRemainingSeconds / 60).ceil();
                final usedMinutes = widget.dailyLimitMinutes - currentRemainingMinutes;
                
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildInfoItem(
                      'Límite',
                      '${widget.dailyLimitMinutes}m',
                      Icons.timer_outlined,
                    ),
                    _buildInfoItem(
                      'Usado',
                      '${usedMinutes.clamp(0, widget.dailyLimitMinutes)}m',
                      Icons.access_time,
                    ),
                    _buildInfoItem(
                      'Restante',
                      '${currentRemainingMinutes.clamp(0, widget.dailyLimitMinutes)}m',
                      Icons.hourglass_empty,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.textLight.withValues(alpha: 0.7), size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textLight,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textLight.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
