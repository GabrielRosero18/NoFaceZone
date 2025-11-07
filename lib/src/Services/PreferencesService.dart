import 'package:shared_preferences/shared_preferences.dart';
import 'package:nofacezone/src/Custom/Constans.dart';

/// Servicio centralizado para manejar todas las preferencias de la aplicación
class PreferencesService {
  static SharedPreferences? _prefs;
  
  /// Inicializar SharedPreferences
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }
  
  /// Obtener instancia de SharedPreferences
  static SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('PreferencesService not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // ===== PREFERENCIAS DE USUARIO =====
  
  /// Guardar token de autenticación
  static Future<bool> setUserToken(String token) async {
    return await prefs.setString(Constants.userTokenKey, token);
  }
  
  /// Obtener token de autenticación
  static String? getUserToken() {
    return prefs.getString(Constants.userTokenKey);
  }
  
  /// Guardar datos del usuario
  static Future<bool> setUserData(String userData) async {
    return await prefs.setString(Constants.userDataKey, userData);
  }
  
  /// Obtener datos del usuario
  static String? getUserData() {
    return prefs.getString(Constants.userDataKey);
  }
  
  /// Limpiar datos del usuario (logout)
  static Future<bool> clearUserData() async {
    bool success = true;
    success &= await prefs.remove(Constants.userTokenKey);
    success &= await prefs.remove(Constants.userDataKey);
    return success;
  }

  // ===== PREFERENCIAS DE LA APLICACIÓN =====
  
  /// Guardar estado del onboarding
  static Future<bool> setOnboardingCompleted(bool completed) async {
    return await prefs.setString(Constants.onboardingKey, completed ? "completed" : "");
  }
  
  /// Verificar si el onboarding está completado
  static bool isOnboardingCompleted() {
    return prefs.getString(Constants.onboardingKey) == "completed";
  }
  
  /// Guardar tema de la aplicación
  static Future<bool> setThemeMode(String themeMode) async {
    return await prefs.setString(Constants.themeKey, themeMode);
  }
  
  /// Obtener tema de la aplicación
  static String? getThemeMode() {
    return prefs.getString(Constants.themeKey);
  }
  
  /// Guardar idioma de la aplicación
  static Future<bool> setLanguage(String languageCode) async {
    return await prefs.setString(Constants.languageKey, languageCode);
  }
  
  /// Obtener idioma de la aplicación
  static String getLanguage() {
    return prefs.getString(Constants.languageKey) ?? 'es';
  }

  /// Guardar tema de colores seleccionado
  static Future<bool> setColorTheme(String themeId) async {
    return await prefs.setString(Constants.colorThemeKey, themeId);
  }

  /// Obtener tema de colores seleccionado
  static String getColorTheme() {
    return prefs.getString(Constants.colorThemeKey) ?? 'ocean'; // 'ocean' es el tema predeterminado
  }

  /// Guardar fuente seleccionada
  static Future<bool> setFontFamily(String fontId) async {
    return await prefs.setString(Constants.fontFamilyKey, fontId);
  }

  /// Obtener fuente seleccionada
  static String getFontFamily() {
    return prefs.getString(Constants.fontFamilyKey) ?? 'default'; // 'default' es la fuente predeterminada (Roboto)
  }

  // ===== PREFERENCIAS DE CONFIGURACIÓN =====
  
  /// Guardar si las notificaciones están habilitadas
  static Future<bool> setNotificationsEnabled(bool enabled) async {
    return await prefs.setBool('notifications_enabled', enabled);
  }
  
  /// Verificar si las notificaciones están habilitadas
  static bool areNotificationsEnabled() {
    return prefs.getBool('notifications_enabled') ?? true;
  }
  
  /// Guardar intervalo de notificaciones
  static Future<bool> setNotificationInterval(int minutes) async {
    return await prefs.setInt('notification_interval', minutes);
  }
  
  /// Obtener intervalo de notificaciones
  static int getNotificationInterval() {
    return prefs.getInt('notification_interval') ?? 15;
  }
  
  /// Guardar si es la primera vez que se abre la app
  static Future<bool> setFirstTimeOpen(bool isFirstTime) async {
    return await prefs.setBool(Constants.isFirstTimeKey, isFirstTime);
  }
  
  /// Verificar si es la primera vez que se abre la app
  static bool isFirstTimeOpen() {
    return prefs.getBool(Constants.isFirstTimeKey) ?? true;
  }

  // ===== PREFERENCIAS DE USO =====
  
  /// Guardar tiempo de uso diario límite
  static Future<bool> setDailyUsageLimit(int minutes) async {
    return await prefs.setInt('daily_usage_limit', minutes);
  }
  
  /// Obtener tiempo de uso diario límite
  static int getDailyUsageLimit() {
    return prefs.getInt('daily_usage_limit') ?? 60; // 60 minutos por defecto
  }
  
  /// Guardar tiempo de uso actual del día
  static Future<bool> setTodayUsageTime(int minutes) async {
    return await prefs.setInt('today_usage_time', minutes);
  }
  
  /// Obtener tiempo de uso actual del día
  static int getTodayUsageTime() {
    return prefs.getInt('today_usage_time') ?? 0;
  }
  
  /// Guardar fecha del último uso
  static Future<bool> setLastUsageDate(String date) async {
    return await prefs.setString('last_usage_date', date);
  }
  
  /// Obtener fecha del último uso
  static String? getLastUsageDate() {
    return prefs.getString('last_usage_date');
  }
  
  /// Guardar record de tiempo sin usar Facebook
  static Future<bool> setRecordTimeWithoutFacebook(int hours) async {
    return await prefs.setInt('record_time_without_facebook', hours);
  }
  
  /// Obtener record de tiempo sin usar Facebook
  static int getRecordTimeWithoutFacebook() {
    return prefs.getInt('record_time_without_facebook') ?? 0;
  }

  // ===== PREFERENCIAS DE PRIVACIDAD =====
  
  /// Guardar si el modo privado está habilitado
  static Future<bool> setPrivateModeEnabled(bool enabled) async {
    return await prefs.setBool('private_mode_enabled', enabled);
  }
  
  /// Verificar si el modo privado está habilitado
  static bool isPrivateModeEnabled() {
    return prefs.getBool('private_mode_enabled') ?? false;
  }
  
  /// Guardar si se debe ocultar la actividad
  static Future<bool> setHideActivity(bool hide) async {
    return await prefs.setBool('hide_activity', hide);
  }
  
  /// Verificar si se debe ocultar la actividad
  static bool shouldHideActivity() {
    return prefs.getBool('hide_activity') ?? false;
  }

  // ===== PREFERENCIAS DE ESTADÍSTICAS =====
  
  /// Guardar estadísticas semanales
  static Future<bool> setWeeklyStats(Map<String, dynamic> stats) async {
    return await prefs.setString('weekly_stats', stats.toString());
  }
  
  /// Obtener estadísticas semanales
  static String? getWeeklyStats() {
    return prefs.getString('weekly_stats');
  }
  
  /// Guardar meta semanal
  static Future<bool> setWeeklyGoal(int hours) async {
    return await prefs.setInt('weekly_goal', hours);
  }
  
  /// Obtener meta semanal
  static int getWeeklyGoal() {
    return prefs.getInt('weekly_goal') ?? 10; // 10 horas por defecto
  }

  // ===== MÉTODOS UTILITARIOS =====
  
  /// Limpiar todas las preferencias (reset completo)
  static Future<bool> clearAll() async {
    return await prefs.clear();
  }
  
  /// Limpiar solo preferencias de usuario (mantener configuraciones)
  static Future<bool> clearUserPreferences() async {
    bool success = true;
    success &= await prefs.remove(Constants.userTokenKey);
    success &= await prefs.remove(Constants.userDataKey);
    success &= await prefs.remove('today_usage_time');
    success &= await prefs.remove('last_usage_date');
    return success;
  }
  
  /// Verificar si existe una preferencia
  static bool containsKey(String key) {
    return prefs.containsKey(key);
  }
  
  /// Obtener todas las claves
  static Set<String> getAllKeys() {
    return prefs.getKeys();
  }
  
  /// Obtener el tamaño de las preferencias (para debugging)
  static int getPreferencesSize() {
    return prefs.getKeys().length;
  }
}
