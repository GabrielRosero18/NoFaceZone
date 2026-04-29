import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:nofacezone/src/Services/PreferencesService.dart';
import 'package:nofacezone/src/Services/UsageLimitsService.dart';
import 'package:nofacezone/src/Custom/AppColors.dart';
import 'package:nofacezone/src/Custom/AppFonts.dart';
import 'package:nofacezone/src/Custom/AppMessages.dart';
import 'package:nofacezone/src/Custom/Constans.dart';

/// Provider para manejar el estado global de la aplicación
class AppProvider extends ChangeNotifier {
  // Estado del onboarding
  bool _isOnboardingCompleted = false;
  bool get isOnboardingCompleted => _isOnboardingCompleted;

  // Estado de carga
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Tema de la aplicación
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  // Tema de colores de la aplicación
  String _colorTheme = 'ocean';
  String get colorTheme => _colorTheme;

  // Fuente de la aplicación
  String _fontFamily = 'default';
  String get fontFamily => _fontFamily;

  // Colecciones de mensajes activas
  List<String> _activeMessageCollections = ['daily'];
  List<String> get activeMessageCollections => List.from(_activeMessageCollections);

  // Idioma de la aplicación
  String _language = 'es';
  String get language => _language;

  // Estado de conexión
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  // Configuraciones adicionales
  bool _notificationsEnabled = true;
  int _notificationInterval = 15;
  int _dailyUsageLimit = 60;
  bool _privateModeEnabled = false;
  int _weeklyGoal = 10;
  
  // Límites de uso desde Supabase
  int _todayUsageMinutes = 0;
  bool _nightBlockActive = false;
  bool _mandatoryBreaksActive = false;
  int? _currentSessionId;

  bool get notificationsEnabled => _notificationsEnabled;
  int get notificationInterval => _notificationInterval;
  int get dailyUsageLimit => _dailyUsageLimit;
  bool get privateModeEnabled => _privateModeEnabled;
  int get weeklyGoal => _weeklyGoal;
  int get todayUsageMinutes => _todayUsageMinutes;
  bool get nightBlockActive => _nightBlockActive;
  bool get mandatoryBreaksActive => _mandatoryBreaksActive;

  AppProvider() {
    _loadAppState();
  }

  /// Cargar el estado de la aplicación desde SharedPreferences
  Future<void> _loadAppState() async {
    _setLoading(true);
    
    try {
      // Inicializar PreferencesService
      await PreferencesService.init();
      
      // Cargar estado del onboarding
      _isOnboardingCompleted = PreferencesService.isOnboardingCompleted();
      
      // Cargar tema
      String? themeString = PreferencesService.getThemeMode();
      if (themeString != null) {
        _themeMode = ThemeMode.values.firstWhere(
          (mode) => mode.toString() == themeString,
          orElse: () => ThemeMode.system,
        );
      }
      
      // Cargar idioma (detectar automáticamente si no hay uno guardado)
      final hasLanguageSaved = PreferencesService.prefs.containsKey(Constants.languageKey);
      if (!hasLanguageSaved) {
        // Si no hay idioma guardado, detectar el idioma del dispositivo
        final deviceLocale = ui.PlatformDispatcher.instance.locale;
        final deviceLanguage = deviceLocale.languageCode;
        // Solo usar el idioma del dispositivo si es español o inglés
        if (deviceLanguage == 'es' || deviceLanguage == 'en') {
          _language = deviceLanguage;
          // Guardar el idioma detectado para futuras sesiones
          await PreferencesService.setLanguage(deviceLanguage);
        } else {
          // Si el idioma del dispositivo no es español ni inglés, usar español por defecto
          _language = 'es';
          await PreferencesService.setLanguage('es');
        }
      } else {
        _language = PreferencesService.getLanguage();
      }
      
      // Cargar tema de colores
      _colorTheme = PreferencesService.getColorTheme();
      AppColors.setTheme(_colorTheme);
      
      // Cargar fuente
      _fontFamily = PreferencesService.getFontFamily();
      AppFonts.setFont(_fontFamily);
      
      // Cargar colecciones de mensajes activas
      _activeMessageCollections = PreferencesService.getActiveMessageCollections();
      AppMessages.setActiveCollections(_activeMessageCollections);
      
      // Cargar configuraciones adicionales
      _notificationsEnabled = PreferencesService.areNotificationsEnabled();
      _notificationInterval = PreferencesService.getNotificationInterval();
      _privateModeEnabled = PreferencesService.isPrivateModeEnabled();
      
      // Cargar límites de uso desde Supabase (si el usuario está autenticado)
      await _loadUsageLimitsFromSupabase();
      
      // Si no hay límites en Supabase, usar valores de PreferencesService como fallback
      if (_dailyUsageLimit == 60) {
        _dailyUsageLimit = PreferencesService.getDailyUsageLimit();
      }
      if (_weeklyGoal == 10) {
        _weeklyGoal = PreferencesService.getWeeklyGoal();
      }
      
    } catch (e) {
      debugPrint('Error loading app state: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Cargar límites de uso desde Supabase
  Future<void> _loadUsageLimitsFromSupabase() async {
    try {
      final limits = await UsageLimitsService.getOrCreateUsageLimits();
      if (limits != null) {
        _dailyUsageLimit = limits['limite_diario_minutos'] as int? ?? 60;
        _weeklyGoal = limits['meta_semanal_horas'] as int? ?? 10;
        _nightBlockActive = limits['bloqueo_nocturno_activo'] as bool? ?? false;
        _mandatoryBreaksActive = limits['pausas_obligatorias_activas'] as bool? ?? false;
        _notificationsEnabled = limits['notificaciones_activas'] as bool? ?? true;
        _notificationInterval = limits['intervalo_notificacion_minutos'] as int? ?? 15;
      }

      // Cargar tiempo usado hoy
      _todayUsageMinutes = await UsageLimitsService.getTodayUsageMinutes();
      
      // IMPORTANTE: Obtener el límite del día ACTUAL del registro diario
      // Esto puede ser diferente del límite general si se agregó tiempo extra
      final todayUsage = await UsageLimitsService.getOrCreateTodayUsage();
      if (todayUsage != null) {
        final limiteDelDia = todayUsage['limite_del_dia_minutos'] as int?;
        final tiempoUsado = todayUsage['tiempo_usado_minutos'] as int? ?? 0;
        if (limiteDelDia != null && limiteDelDia > 0) {
          // Actualizar el límite del día con el valor del registro (puede incluir tiempo extra)
          _dailyUsageLimit = limiteDelDia;
          debugPrint('📊 Límite del día actualizado desde registro: $limiteDelDia minutos');
          debugPrint('📊 Tiempo usado actualizado: $tiempoUsado minutos');
        }
        // Actualizar también el tiempo usado
        _todayUsageMinutes = tiempoUsado;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading usage limits from Supabase: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Recargar límites de uso desde Supabase
  Future<void> refreshUsageLimits() async {
    try {
      await _loadUsageLimitsFromSupabase();
      notifyListeners();
      debugPrint('✅ Límites de uso recargados desde Supabase');
    } catch (e, stackTrace) {
      debugPrint('❌ Error al recargar límites de uso: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Marcar onboarding como completado
  Future<void> completeOnboarding() async {
    try {
      await PreferencesService.setOnboardingCompleted(true);
      _isOnboardingCompleted = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error completing onboarding: $e');
    }
  }

  /// Cambiar tema de la aplicación
  Future<void> setThemeMode(ThemeMode mode) async {
    try {
      await PreferencesService.setThemeMode(mode.toString());
      _themeMode = mode;
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting theme: $e');
    }
  }

  /// Cambiar idioma de la aplicación
  Future<void> setLanguage(String languageCode) async {
    try {
      await PreferencesService.setLanguage(languageCode);
      _language = languageCode;
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting language: $e');
    }
  }

  /// Cambiar tema de colores de la aplicación
  Future<void> setColorTheme(String themeId) async {
    try {
      await PreferencesService.setColorTheme(themeId);
      _colorTheme = themeId;
      AppColors.setTheme(themeId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting color theme: $e');
    }
  }

  /// Cambiar fuente de la aplicación
  Future<void> setFontFamily(String fontId) async {
    try {
      await PreferencesService.setFontFamily(fontId);
      _fontFamily = fontId;
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting font family: $e');
    }
  }

  /// Cambiar colecciones de mensajes activas
  Future<void> setActiveMessageCollections(List<String> collectionIds) async {
    try {
      await PreferencesService.setActiveMessageCollections(collectionIds);
      _activeMessageCollections = collectionIds;
      AppMessages.setActiveCollections(collectionIds);
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting active message collections: $e');
    }
  }

  /// Agregar una colección de mensajes activa
  Future<void> addMessageCollection(String collectionId) async {
    if (!_activeMessageCollections.contains(collectionId)) {
      final updated = List<String>.from(_activeMessageCollections)..add(collectionId);
      await setActiveMessageCollections(updated);
    }
  }

  /// Remover una colección de mensajes activa
  Future<void> removeMessageCollection(String collectionId) async {
    // No permitir remover la colección 'daily' (predeterminada)
    if (collectionId == 'daily') return;
    
    if (_activeMessageCollections.contains(collectionId)) {
      final updated = List<String>.from(_activeMessageCollections)..remove(collectionId);
      // Asegurar que siempre haya al menos una colección activa
      if (updated.isEmpty) {
        updated.add('daily');
      }
      await setActiveMessageCollections(updated);
    }
  }

  /// Alternar una colección de mensajes (activar/desactivar)
  Future<void> toggleMessageCollection(String collectionId) async {
    if (_activeMessageCollections.contains(collectionId)) {
      await removeMessageCollection(collectionId);
    } else {
      await addMessageCollection(collectionId);
    }
  }

  /// Cambiar configuración de notificaciones
  Future<void> setNotificationsEnabled(bool enabled) async {
    try {
      await PreferencesService.setNotificationsEnabled(enabled);
      _notificationsEnabled = enabled;
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting notifications: $e');
    }
  }

  /// Cambiar intervalo de notificaciones
  Future<void> setNotificationInterval(int minutes) async {
    try {
      await PreferencesService.setNotificationInterval(minutes);
      _notificationInterval = minutes;
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting notification interval: $e');
    }
  }

  /// Cambiar límite de uso diario
  Future<void> setDailyUsageLimit(int minutes) async {
    try {
      debugPrint('🔄 Actualizando límite diario a: $minutes minutos');
      
      // Actualizar en Supabase
      final success = await UsageLimitsService.updateDailyLimit(minutes);
      if (success) {
        // Reiniciar contador del día para aplicar el nuevo límite desde cero.
        await UsageLimitsService.resetTodayUsageCounter(limitForToday: minutes);
        _dailyUsageLimit = minutes;
        // También guardar en PreferencesService como respaldo
        await PreferencesService.setDailyUsageLimit(minutes);
        
        // Recargar datos de uso para actualizar el tiempo restante
        await _loadUsageLimitsFromSupabase();
        await updateTodayUsage();
        
        debugPrint('✅ Límite actualizado correctamente');
        notifyListeners();
      } else {
        debugPrint('⚠️ Error al actualizar en Supabase, usando fallback');
        // Si falla Supabase, usar PreferencesService como fallback
        await PreferencesService.setDailyUsageLimit(minutes);
        _dailyUsageLimit = minutes;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error setting daily usage limit: $e');
      // Fallback a PreferencesService
      await PreferencesService.setDailyUsageLimit(minutes);
      _dailyUsageLimit = minutes;
      notifyListeners();
    }
  }

  /// Cambiar modo privado
  Future<void> setPrivateModeEnabled(bool enabled) async {
    try {
      await PreferencesService.setPrivateModeEnabled(enabled);
      _privateModeEnabled = enabled;
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting private mode: $e');
    }
  }

  /// Cambiar meta semanal
  Future<void> setWeeklyGoal(int hours) async {
    try {
      // Actualizar en Supabase
      final success = await UsageLimitsService.updateWeeklyGoal(hours);
      if (success) {
        _weeklyGoal = hours;
        // También guardar en PreferencesService como respaldo
        await PreferencesService.setWeeklyGoal(hours);
        notifyListeners();
      } else {
        // Si falla Supabase, usar PreferencesService como fallback
        await PreferencesService.setWeeklyGoal(hours);
        _weeklyGoal = hours;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error setting weekly goal: $e');
      // Fallback a PreferencesService
      await PreferencesService.setWeeklyGoal(hours);
      _weeklyGoal = hours;
      notifyListeners();
    }
  }

  /// Iniciar sesión de uso
  Future<void> startUsageSession() async {
    try {
      final sessionId = await UsageLimitsService.startUsageSession();
      if (sessionId != null) {
        _currentSessionId = sessionId;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error starting usage session: $e');
    }
  }

  /// Finalizar sesión de uso actual
  Future<void> finishUsageSession() async {
    try {
      final sessionId = _currentSessionId;
      if (sessionId != null) {
        await UsageLimitsService.finishUsageSession(sessionId);
        // Recargar tiempo usado hoy
        _todayUsageMinutes = await UsageLimitsService.getTodayUsageMinutes();
        _currentSessionId = null;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error finishing usage session: $e');
    }
  }

  /// Actualizar tiempo usado hoy
  Future<void> updateTodayUsage() async {
    try {
      _todayUsageMinutes = await UsageLimitsService.getTodayUsageMinutes();
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating today usage: $e');
    }
  }

  /// Actualizar estado de conexión
  void setOnlineStatus(bool isOnline) {
    _isOnline = isOnline;
    notifyListeners();
  }

  /// Establecer estado de carga
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Limpiar datos de la aplicación (logout)
  Future<void> clearAppData() async {
    try {
      await PreferencesService.clearUserPreferences();
      // No limpiar onboarding, tema e idioma
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing app data: $e');
    }
  }
}
