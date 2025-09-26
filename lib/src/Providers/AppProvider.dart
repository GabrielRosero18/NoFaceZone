import 'package:flutter/material.dart';
import 'package:nofacezone/src/Services/PreferencesService.dart';

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

  bool get notificationsEnabled => _notificationsEnabled;
  int get notificationInterval => _notificationInterval;
  int get dailyUsageLimit => _dailyUsageLimit;
  bool get privateModeEnabled => _privateModeEnabled;
  int get weeklyGoal => _weeklyGoal;

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
      
      // Cargar idioma
      _language = PreferencesService.getLanguage();
      
      // Cargar configuraciones adicionales
      _notificationsEnabled = PreferencesService.areNotificationsEnabled();
      _notificationInterval = PreferencesService.getNotificationInterval();
      _dailyUsageLimit = PreferencesService.getDailyUsageLimit();
      _privateModeEnabled = PreferencesService.isPrivateModeEnabled();
      _weeklyGoal = PreferencesService.getWeeklyGoal();
      
    } catch (e) {
      debugPrint('Error loading app state: $e');
    } finally {
      _setLoading(false);
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
      await PreferencesService.setDailyUsageLimit(minutes);
      _dailyUsageLimit = minutes;
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting daily usage limit: $e');
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
      await PreferencesService.setWeeklyGoal(hours);
      _weeklyGoal = hours;
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting weekly goal: $e');
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
