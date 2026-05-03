import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:nofacezone/src/Custom/Constans.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;

/// Recordatorios locales según el intervalo configurado en la app.
/// En web no hay soporte práctico; en móvil usa el canal [Constants.notificationChannelId].
class LocalNotificationService {
  LocalNotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static bool _timeZoneReady = false;

  static Future<void> configureTimeZone() async {
    if (_timeZoneReady) return;
    if (kIsWeb) {
      _timeZoneReady = true;
      return;
    }
    try {
      tzdata.initializeTimeZones();
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (e, st) {
      debugPrint('LocalNotificationService: zona horaria $e\n$st');
      try {
        tzdata.initializeTimeZones();
        tz.setLocalLocation(tz.getLocation('UTC'));
      } catch (_) {}
    }
    _timeZoneReady = true;
  }

  static Future<void> initialize() async {
    if (_initialized) return;
    if (kIsWeb) {
      _initialized = true;
      return;
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: android,
      iOS: darwin,
      macOS: darwin,
      linux: LinuxInitializationSettings(defaultActionName: 'Open'),
    );

    await _plugin.initialize(initSettings);

    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      const channel = AndroidNotificationChannel(
        Constants.notificationChannelId,
        Constants.notificationChannelName,
        description: Constants.notificationChannelDescription,
        importance: Importance.defaultImportance,
      );
      await androidPlugin?.createNotificationChannel(channel);
    }

    _initialized = true;
  }

  /// Solicita permiso en iOS/macOS y Android 13+.
  static Future<bool> requestPermissions() async {
    if (kIsWeb) return false;

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      final ok = await ios?.requestPermissions(alert: true, badge: true, sound: true);
      return ok ?? false;
    }
    if (defaultTargetPlatform == TargetPlatform.macOS) {
      final mac = _plugin.resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>();
      final ok = await mac?.requestPermissions(alert: true, badge: true, sound: true);
      return ok ?? false;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final ok = await android?.requestNotificationsPermission();
      return ok ?? true;
    }
    return true;
  }

  static String _body(String lang) {
    if (lang == 'en') {
      return 'Check in with your usage goal today and take a mindful break if you need it.';
    }
    return 'Revisa tu meta de uso de hoy y haz una pausa consciente si lo necesitas.';
  }

  /// Cancela y reprograma una cadena de recordatorios (se renueva al abrir la app o al cambiar ajustes).
  static Future<void> syncReminderSchedule({
    required bool enabled,
    required int intervalMinutes,
    required String resolvedLanguageCode,
  }) async {
    if (kIsWeb || !_initialized) return;
    if (intervalMinutes <= 0) return;

    for (var i = 0; i < Constants.localNotificationScheduleCount; i++) {
      await _plugin.cancel(Constants.localNotificationIdBase + i);
    }

    if (!enabled) return;

    final lang = resolvedLanguageCode == 'en' ? 'en' : 'es';
    const title = 'NoFaceZone';
    final body = _body(lang);

    final androidDetails = AndroidNotificationDetails(
      Constants.notificationChannelId,
      Constants.notificationChannelName,
      channelDescription: Constants.notificationChannelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    try {
      final now = tz.TZDateTime.now(tz.local);
      for (var i = 1; i <= Constants.localNotificationScheduleCount; i++) {
        final when = now.add(Duration(minutes: intervalMinutes * i));
        await _plugin.zonedSchedule(
          Constants.localNotificationIdBase + i - 1,
          title,
          body,
          when,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    } catch (e, st) {
      debugPrint('LocalNotificationService.syncReminderSchedule: $e\n$st');
    }
  }
}
