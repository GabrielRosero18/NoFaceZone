import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nofacezone/src/Custom/AppColors.dart';
import 'package:nofacezone/src/Custom/AppLocalizations.dart';
import 'package:nofacezone/src/Custom/AppMessages.dart';
import 'package:nofacezone/src/Custom/CustomSnackBar.dart';
import 'package:nofacezone/src/Providers/UserProvider.dart';
import 'package:nofacezone/src/Providers/AppProvider.dart';
import 'package:nofacezone/src/Services/PointsService.dart';
import 'package:nofacezone/src/Services/UsageLimitsService.dart';
import 'package:nofacezone/src/Screen/UsageLimitBlockedScreen.dart';
import 'package:nofacezone/src/Custom/Library.dart';

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
  bool _isBlockedScreenShown = false;
  bool _isLoadingUsageData = false;
  DateTime? _appStartTime;
  DateTime? _blockDismissedTime; // Tiempo cuando se quitó el bloqueo

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
            _showBlockedScreen();
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
        _appStartTime = DateTime.now();
        
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
        
        // Actualizar AppProvider
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        await appProvider.finishUsageSession();
        
        _currentSessionId = null;
        _appStartTime = null;
      }
    } catch (e) {
      debugPrint('Error ending app session: $e');
    }
  }

  /// Cargar datos de uso desde Supabase
  Future<void> _loadUsageData() async {
    // Prevenir múltiples llamadas simultáneas
    if (_isLoadingUsageData) {
      return;
    }

    _isLoadingUsageData = true;
    
    try {
      // Cargar límite y tiempo restante
      final limit = await UsageLimitsService.getCurrentDailyLimit();
      final remaining = await UsageLimitsService.getRemainingTimeToday();
      final used = await UsageLimitsService.getTodayUsageMinutes();
      
      if (mounted) {
        debugPrint('📊 Datos de uso cargados:');
        debugPrint('   Límite: $limit minutos');
        debugPrint('   Usado: $used minutos');
        debugPrint('   Restante: $remaining minutos');
        
        setState(() {
          _dailyLimitMinutes = limit;
          _remainingMinutes = remaining;
        });
        
        // También actualizar el AppProvider
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        await appProvider.updateTodayUsage();
        await appProvider.refreshUsageLimits(); // Recargar límites desde Supabase
        
        // Verificar si se alcanzó el límite y mostrar pantalla de bloqueo
        // No mostrar si se quitó el bloqueo recientemente (últimos 5 minutos)
        final canShowBlock = _blockDismissedTime == null || 
            DateTime.now().difference(_blockDismissedTime!).inMinutes >= 5;
        
        debugPrint('🔍 Verificación de bloqueo:');
        debugPrint('   Tiempo restante: $remaining minutos');
        debugPrint('   Bloqueo mostrado: $_isBlockedScreenShown');
        debugPrint('   Puede mostrar bloqueo: $canShowBlock');
        debugPrint('   Tiempo desde último bloqueo quitado: ${_blockDismissedTime != null ? DateTime.now().difference(_blockDismissedTime!).inMinutes : "N/A"} minutos');
        
        if (remaining <= 0 && !_isBlockedScreenShown && canShowBlock) {
          debugPrint('🚨 Mostrando pantalla de bloqueo');
          _showBlockedScreen();
        } else if (remaining > 0 && _isBlockedScreenShown) {
          // Si hay tiempo restante y la pantalla está mostrada, cerrarla
          debugPrint('✅ Hay tiempo restante, cerrando bloqueo');
          _isBlockedScreenShown = false;
          _blockDismissedTime = null; // Resetear el tiempo de bloqueo quitado
        } else if (remaining <= 0 && _isBlockedScreenShown) {
          debugPrint('⚠️ Tiempo restante es 0 pero bloqueo ya está mostrado');
        } else if (remaining <= 0 && !canShowBlock) {
          debugPrint('⏸️ Tiempo restante es 0 pero bloqueo fue quitado recientemente');
        }
      }
    } catch (e) {
      debugPrint('Error loading usage data: $e');
    } finally {
      _isLoadingUsageData = false;
    }
  }

  /// Mostrar pantalla de bloqueo cuando se alcanza el límite
  void _showBlockedScreen() {
    if (!mounted || _isBlockedScreenShown) return;
    
    _isBlockedScreenShown = true;
    
    // Mostrar como overlay/modal
    showDialog(
      context: context,
      barrierDismissible: false, // No se puede cerrar tocando fuera
      barrierColor: Colors.black.withValues(alpha: 0.95),
      builder: (context) => WillPopScope(
        onWillPop: () async => false, // Prevenir cierre con botón atrás
        child: UsageLimitBlockedScreen(
          onTimeAdded: () async {
            // Cuando se agrega tiempo, recargar datos y cerrar
            _isBlockedScreenShown = false;
            
            // Esperar un momento para que la BD se actualice completamente
            await Future.delayed(const Duration(milliseconds: 1500));
            
            // Forzar recarga de datos directamente desde la tabla (sin caché)
            final supabase = Supabase.instance.client;
            final userId = supabase.auth.currentUser?.id;
            if (userId != null) {
              // Obtener el registro más reciente (puede ser de hoy o ayer)
              final directRead = await supabase
                  .from('registros_uso_diario')
                  .select()
                  .eq('usuario_id', userId)
                  .order('fecha', ascending: false)
                  .limit(1)
                  .maybeSingle();
              
              if (directRead != null) {
                final limitDelDia = directRead['limite_del_dia_minutos'] as int? ?? 0;
                final tiempoUsado = directRead['tiempo_usado_minutos'] as int? ?? 0;
                final remaining = limitDelDia - tiempoUsado;
                
                debugPrint('🔄 Lectura DIRECTA después de agregar tiempo:');
                debugPrint('   Límite del día: $limitDelDia minutos');
                debugPrint('   Tiempo usado: $tiempoUsado minutos');
                debugPrint('   Tiempo restante: $remaining minutos');
                
                if (remaining > 0) {
                  // Si hay tiempo restante, no mostrar el bloqueo por al menos 5 minutos
                  _blockDismissedTime = DateTime.now().subtract(const Duration(minutes: 4));
                  debugPrint('✅ Hay tiempo restante, bloqueo no se mostrará por 5 minutos');
                } else {
                  _blockDismissedTime = null;
                }
              }
            }
            
            // Recargar datos usando el método normal
            await _loadUsageData();
            
            // Recargar datos de nuevo después de un momento para asegurar sincronización
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                _loadUsageData();
              }
            });
          },
          onBlockRemoved: () {
            // Cuando se quita el bloqueo, marcar el tiempo para no mostrar de nuevo por 5 minutos
            _isBlockedScreenShown = false;
            _blockDismissedTime = DateTime.now();
            debugPrint('🚫 Bloqueo quitado. No se mostrará de nuevo por 5 minutos');
            // No recargar datos inmediatamente para evitar que se muestre de nuevo
          },
        ),
      ),
    ).then((_) {
      // Cuando se cierra el diálogo
      _isBlockedScreenShown = false;
    });
  }

  /// Iniciar timer para actualizar el contador cada 10 segundos
  void _startUsageTimer() {
    _usageTimer?.cancel(); // Cancelar timer anterior si existe
    _usageTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      // Actualizar datos de uso solo una vez por ciclo
      await _loadUsageData();
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
          Consumer<AppProvider>(
            builder: (context, appProvider, child) {
              // Calcular tiempo usado y restante
              final usedMinutes = appProvider.todayUsageMinutes;
              final limitMinutes = appProvider.dailyUsageLimit;
              final remainingMinutes = (limitMinutes - usedMinutes).clamp(0, limitMinutes);
              
              // Formatear límite
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
              
              // Formatear tiempo restante
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
              
              return GestureDetector(
                onTap: () => _showTimeRemainingDialog(localizations),
                child: _buildLimitItem(
                  localizations.dailyLimitHome,
                  limitText,
                  '$remainingText ${localizations.remaining}',
                  Icons.access_time,
                  AppColors.accentBlue,
                  progress.clamp(0.0, 1.0),
                ),
              );
            },
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
    // NO resetear el contador cuando se actualiza el widget
    // El contador debe seguir contando independientemente
    // Solo actualizar el valor inicial si cambió significativamente (más de 30 segundos)
    final newInitialSeconds = widget.remainingMinutes * 60;
    final diff = newInitialSeconds - _initialRemainingSeconds;
    
    if (diff.abs() > 30) {
      // Solo actualizar si hay un cambio muy grande (probablemente se agregó tiempo)
      _initialRemainingSeconds = newInitialSeconds;
      // Calcular cuánto tiempo ha pasado desde que se abrió el diálogo
      final elapsed = DateTime.now().difference(_dialogStartTime).inSeconds;
      _currentRemainingSeconds = (_initialRemainingSeconds - elapsed).clamp(0, _initialRemainingSeconds);
    }
  }

  void _startTimer() {
    // Timer principal que cuenta hacia atrás cada segundo
    // Calcula el tiempo restante basado en el tiempo transcurrido desde que se abrió el diálogo
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        final elapsed = DateTime.now().difference(_dialogStartTime).inSeconds;
        final calculatedRemaining = _initialRemainingSeconds - elapsed;
        
        setState(() {
          if (calculatedRemaining > 0) {
            _currentRemainingSeconds = calculatedRemaining;
          } else {
            _currentRemainingSeconds = 0;
            // Si llegó a 0, recargar datos una vez
            if (!_isSyncing) {
              _isSyncing = true;
              widget.onRefresh();
              Future.delayed(const Duration(seconds: 1), () {
                _isSyncing = false;
              });
            }
          }
        });
      }
    });
    
    // Timer para sincronizar con Supabase cada 30 segundos (menos frecuente)
    // Solo para actualizar el valor inicial si cambió significativamente
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted && !_isSyncing) {
        _isSyncing = true;
        widget.onRefresh();
        
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            final newInitialSeconds = widget.remainingMinutes * 60;
            final diff = newInitialSeconds - _initialRemainingSeconds;
            
            // Solo actualizar si hay un cambio significativo (más de 30 segundos)
            // Esto podría ser porque se agregó tiempo extra
            if (diff.abs() > 30) {
              _initialRemainingSeconds = newInitialSeconds;
              // Recalcular el tiempo restante basado en el tiempo transcurrido
              final elapsed = DateTime.now().difference(_dialogStartTime).inSeconds;
              _currentRemainingSeconds = (_initialRemainingSeconds - elapsed).clamp(0, _initialRemainingSeconds);
            }
            _isSyncing = false;
          }
        });
      }
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
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 8,
                      backgroundColor: AppColors.textLight.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(clockColor),
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
