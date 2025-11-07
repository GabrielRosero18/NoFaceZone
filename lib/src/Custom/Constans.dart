/// Constantes globales para la aplicación NoFaceZone
class Constants {
  // Rutas de navegación
  static const String splashRoute = '/splash';
  static const String onboardingRoute = '/onboarding';
  static const String welcomeRoute = '/welcome';
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String homeRoute = '/home';
  static const String profileRoute = '/profile';
  static const String settingsRoute = '/settings';
  
  // Claves de almacenamiento local
  static const String userTokenKey = 'user_token';
  static const String userDataKey = 'user_data';
  static const String isFirstTimeKey = 'is_first_time';
  static const String themeKey = 'theme_mode';
  static const String colorThemeKey = 'color_theme';
  static const String fontFamilyKey = 'font_family';
  static const String languageKey = 'language';
  static const String onboardingKey = 'onboarding';
  
  // Claves adicionales para funcionalidades
  static const String notificationsEnabledKey = 'notifications_enabled';
  static const String notificationIntervalKey = 'notification_interval';
  static const String dailyUsageLimitKey = 'daily_usage_limit';
  static const String todayUsageTimeKey = 'today_usage_time';
  static const String lastUsageDateKey = 'last_usage_date';
  static const String recordTimeWithoutFacebookKey = 'record_time_without_facebook';
  static const String privateModeEnabledKey = 'private_mode_enabled';
  static const String hideActivityKey = 'hide_activity';
  static const String weeklyStatsKey = 'weekly_stats';
  static const String weeklyGoalKey = 'weekly_goal';
  
  // Tamaños y dimensiones
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double smallBorderRadius = 8.0;
  static const double largeBorderRadius = 16.0;
  
  // Tamaños de fuente
  static const double smallFontSize = 12.0;
  static const double mediumFontSize = 16.0;
  static const double largeFontSize = 20.0;
  static const double extraLargeFontSize = 24.0;
  static const double titleFontSize = 32.0;
  
  // Duración de animaciones
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // Límites de la aplicación
  static const int maxUsernameLength = 20;
  static const int minPasswordLength = 6;
  static const int maxBioLength = 150;
  
  // Mensajes de error comunes
  static const String networkError = 'Error de conexión. Verifica tu internet.';
  static const String serverError = 'Error del servidor. Intenta más tarde.';
  static const String invalidCredentials = 'Credenciales inválidas.';
  static const String userNotFound = 'Usuario no encontrado.';
  static const String emailAlreadyExists = 'El email ya está registrado.';
  static const String weakPassword = 'La contraseña es muy débil.';
  
  // Mensajes de éxito
  static const String loginSuccess = 'Inicio de sesión exitoso.';
  static const String registerSuccess = 'Registro exitoso.';
  static const String profileUpdated = 'Perfil actualizado.';
  static const String passwordChanged = 'Contraseña cambiada.';
  
  // Configuración de Facebook
  static const String facebookAppId = 'your_facebook_app_id';
  static const String facebookClientToken = 'your_facebook_client_token';
  
  // Configuración de notificaciones
  static const String notificationChannelId = 'nofacezone_notifications';
  static const String notificationChannelName = 'NoFaceZone Notifications';
  static const String notificationChannelDescription = 'Notificaciones de NoFaceZone';
}
