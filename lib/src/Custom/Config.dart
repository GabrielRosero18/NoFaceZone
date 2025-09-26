import 'package:package_info_plus/package_info_plus.dart';

/// Configuración global de la aplicación NoFaceZone
class Config {
  // URLs del servidor
  static const String mSupabaseUrl = "https://jjxiobpjcpdktvdjypvf.supabase.co";
  static const String mSupabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpqeGlvYnBqY3Bka3R2ZGp5cHZmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg2ODQ3OTAsImV4cCI6MjA3NDI2MDc5MH0.FGVQserXI236SMhk8lMwXPrCFs0HxJhYhdP9uCbbBv4";
  
  // Configuración de la aplicación
  static const String appName = "NoFaceZone";
  static const String appDescription = "Control de Adicción a Facebook";
  
  // Configuración de tiempo
  static const int sessionTimeoutMinutes = 30;
  static const int maxLoginAttempts = 3;
  
  // Configuración de notificaciones
  static const bool enableNotifications = true;
  static const int notificationIntervalMinutes = 15;
  
  // Obtener información de la versión de la aplicación
  static Future<String> getAppVersion() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      return "1.0.0"; // Versión por defecto en caso de error
    }
  }
  
  // Obtener información completa del paquete
  static Future<PackageInfo> getPackageInfo() async {
    return await PackageInfo.fromPlatform();
  }
  
  // Configuración de desarrollo
  static const bool isDebugMode = true;
  static const bool enableLogging = true;
}
