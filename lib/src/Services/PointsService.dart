import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:nofacezone/src/Services/RewardService.dart';
import 'package:nofacezone/src/Services/PreferencesService.dart';

/// Servicio para gestionar el sistema de puntos
/// Otorga puntos automáticamente por diferentes acciones del usuario
class PointsService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // ============================================
  // CONFIGURACIÓN DE PUNTOS POR ACCIÓN
  // ============================================
  static const int pointsDailyLogin = 5; // Puntos por iniciar sesión diariamente
  static const int pointsEmotionRegister = 10; // Puntos por registrar una emoción
  static const int pointsDayWithoutFacebook = 20; // Puntos por completar un día sin Facebook
  static const int pointsWeekStreak = 50; // Puntos por racha de 7 días
  static const int pointsMonthStreak = 200; // Puntos por racha de 30 días
  static const int pointsFirstEmotion = 15; // Puntos bonus por primera emoción
  static const int pointsCompleteProfile = 25; // Puntos por completar perfil
  static const int pointsUpdateProfile = 5; // Puntos por actualizar perfil
  static const int pointsActivityCompletion = 3; // Puntos por completar actividad sugerida
  static const int maxActivityCompletionsPerDay = 3; // Límite de actividades con puntos por día

  // ============================================
  // MÉTODOS PARA OTORGAR PUNTOS
  // ============================================

  /// Otorgar puntos por inicio de sesión diario
  /// Solo otorga puntos una vez por día
  static Future<void> awardDailyLoginPoints() async {
    try {
      final authUser = _supabase.auth.currentUser;
      if (authUser == null) return;

      final today = DateTime.now();
      final todayKey = '${today.year}-${today.month}-${today.day}';
      final lastLoginKey = 'last_daily_login_${authUser.id}';

      // Verificar si ya obtuvo puntos hoy
      final lastLogin = PreferencesService.getString(lastLoginKey);
      if (lastLogin == todayKey) {
        return; // Ya obtuvo puntos hoy
      }

      // Otorgar puntos
      await RewardService.addPoints(
        pointsDailyLogin,
        description: 'Inicio de sesión diario',
      );

      // Guardar que obtuvo puntos hoy
      await PreferencesService.setString(lastLoginKey, todayKey);

      debugPrint('✅ Puntos otorgados por inicio de sesión: $pointsDailyLogin');
    } catch (e) {
      debugPrint('Error al otorgar puntos por inicio de sesión: $e');
    }
  }

  /// Otorgar puntos por registrar una emoción
  static Future<void> awardEmotionRegistrationPoints({bool isFirstEmotion = false}) async {
    try {
      final authUser = _supabase.auth.currentUser;
      if (authUser == null) return;

      int points = pointsEmotionRegister;
      String description = 'Registro de emoción';

      // Bonus por primera emoción
      if (isFirstEmotion) {
        points += pointsFirstEmotion;
        description = 'Primera emoción registrada';
      }

      await RewardService.addPoints(points, description: description);
      debugPrint('✅ Puntos otorgados por registrar emoción: $points');
    } catch (e) {
      debugPrint('Error al otorgar puntos por emoción: $e');
    }
  }

  /// Otorgar puntos por completar un día sin usar Facebook
  static Future<void> awardDayWithoutFacebookPoints() async {
    try {
      final authUser = _supabase.auth.currentUser;
      if (authUser == null) return;

      final today = DateTime.now();
      final todayKey = '${today.year}-${today.month}-${today.day}';
      final lastDayKey = 'last_day_without_fb_${authUser.id}';

      // Verificar si ya obtuvo puntos por este día
      final lastDay = PreferencesService.getString(lastDayKey);
      if (lastDay == todayKey) {
        return; // Ya obtuvo puntos por este día
      }

      // Otorgar puntos
      await RewardService.addPoints(
        pointsDayWithoutFacebook,
        description: 'Día completo sin usar Facebook',
      );

      // Guardar que obtuvo puntos por este día
      await PreferencesService.setString(lastDayKey, todayKey);

      debugPrint('✅ Puntos otorgados por día sin Facebook: $pointsDayWithoutFacebook');
    } catch (e) {
      debugPrint('Error al otorgar puntos por día sin Facebook: $e');
    }
  }

  /// Otorgar puntos por racha de días consecutivos
  static Future<void> checkAndAwardStreakPoints(int consecutiveDays) async {
    try {
      final authUser = _supabase.auth.currentUser;
      if (authUser == null) return;

      // Verificar racha de 7 días
      if (consecutiveDays == 7) {
        final lastWeekStreakKey = 'week_streak_awarded_${authUser.id}';
        final lastWeekStreak = PreferencesService.getString(lastWeekStreakKey);
        final today = DateTime.now();
        final todayKey = '${today.year}-${today.month}-${today.day}';

        if (lastWeekStreak != todayKey) {
          await RewardService.addPoints(
            pointsWeekStreak,
            description: 'Racha de 7 días consecutivos',
          );
          await PreferencesService.setString(lastWeekStreakKey, todayKey);
          debugPrint('✅ Puntos otorgados por racha de 7 días: $pointsWeekStreak');
        }
      }

      // Verificar racha de 30 días
      if (consecutiveDays == 30) {
        final lastMonthStreakKey = 'month_streak_awarded_${authUser.id}';
        final lastMonthStreak = PreferencesService.getString(lastMonthStreakKey);
        final today = DateTime.now();
        final todayKey = '${today.year}-${today.month}-${today.day}';

        if (lastMonthStreak != todayKey) {
          await RewardService.addPoints(
            pointsMonthStreak,
            description: 'Racha de 30 días consecutivos',
          );
          await PreferencesService.setString(lastMonthStreakKey, todayKey);
          debugPrint('✅ Puntos otorgados por racha de 30 días: $pointsMonthStreak');
        }
      }
    } catch (e) {
      debugPrint('Error al verificar racha de puntos: $e');
    }
  }

  /// Otorgar puntos por completar perfil
  static Future<void> awardCompleteProfilePoints() async {
    try {
      final authUser = _supabase.auth.currentUser;
      if (authUser == null) return;

      final profileCompletedKey = 'profile_completed_${authUser.id}';
      final isCompleted = PreferencesService.getBool(profileCompletedKey);

      if (!isCompleted) {
        await RewardService.addPoints(
          pointsCompleteProfile,
          description: 'Perfil completado',
        );
        await PreferencesService.setBool(profileCompletedKey, true);
        debugPrint('✅ Puntos otorgados por completar perfil: $pointsCompleteProfile');
      }
    } catch (e) {
      debugPrint('Error al otorgar puntos por completar perfil: $e');
    }
  }

  /// Otorgar puntos por actualizar perfil
  static Future<void> awardUpdateProfilePoints() async {
    try {
      final authUser = _supabase.auth.currentUser;
      if (authUser == null) return;

      final today = DateTime.now();
      final todayKey = '${today.year}-${today.month}-${today.day}';
      final lastUpdateKey = 'last_profile_update_${authUser.id}';

      // Solo otorgar puntos una vez por día por actualizar perfil
      final lastUpdate = PreferencesService.getString(lastUpdateKey);
      if (lastUpdate == todayKey) {
        return; // Ya obtuvo puntos hoy por actualizar perfil
      }

      await RewardService.addPoints(
        pointsUpdateProfile,
        description: 'Perfil actualizado',
      );

      await PreferencesService.setString(lastUpdateKey, todayKey);
      debugPrint('✅ Puntos otorgados por actualizar perfil: $pointsUpdateProfile');
    } catch (e) {
      debugPrint('Error al otorgar puntos por actualizar perfil: $e');
    }
  }

  /// Otorgar puntos por completar actividad recomendada (con límite diario).
  static Future<void> awardActivityCompletionPoints() async {
    try {
      final authUser = _supabase.auth.currentUser;
      if (authUser == null) return;

      final today = DateTime.now();
      final todayKey = '${today.year}-${today.month}-${today.day}';
      final dayKey = 'activity_points_day_${authUser.id}';
      final countKey = 'activity_points_count_${authUser.id}';

      final savedDay = PreferencesService.getString(dayKey);
      var count = int.tryParse(PreferencesService.getString(countKey) ?? '0') ?? 0;

      if (savedDay != todayKey) {
        await PreferencesService.setString(dayKey, todayKey);
        count = 0;
      }

      if (count >= maxActivityCompletionsPerDay) {
        return;
      }

      await RewardService.addPoints(
        pointsActivityCompletion,
        description: 'Actividad recomendada completada',
      );

      count += 1;
      await PreferencesService.setString(countKey, count.toString());
      debugPrint('✅ Puntos por actividad completada: $pointsActivityCompletion ($count/$maxActivityCompletionsPerDay)');
    } catch (e) {
      debugPrint('Error al otorgar puntos por actividad completada: $e');
    }
  }

  // ============================================
  // MÉTODOS AUXILIARES
  // ============================================

  /// Verificar si es la primera emoción del usuario
  static Future<bool> isFirstEmotion() async {
    try {
      final authUser = _supabase.auth.currentUser;
      if (authUser == null) return false;

      // Verificar en la base de datos si tiene emociones registradas
      // La tabla emociones usa 'user_id' como campo
      final response = await _supabase
          .from('emociones')
          .select('id')
          .eq('user_id', authUser.id)
          .limit(1)
          .maybeSingle();

      return response == null; // Si no hay resultados, es la primera
    } catch (e) {
      debugPrint('Error al verificar primera emoción: $e');
      return false;
    }
  }

  /// Días consecutivos con al menos un registro de emoción (aprox. hábito diario).
  static Future<int> getConsecutiveDays() async {
    try {
      final authUser = _supabase.auth.currentUser;
      if (authUser == null) return 0;

      final response = await _supabase
          .from('emociones')
          .select('created_at')
          .eq('user_id', authUser.id)
          .order('created_at', ascending: false);

      final list = List<Map<String, dynamic>>.from(response);
      if (list.isEmpty) return 0;

      String dayKey(DateTime d) =>
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

      final daysWithEmotion = <String>{};
      for (final row in list) {
        final dt = DateTime.parse(row['created_at'] as String);
        daysWithEmotion.add(dayKey(DateTime(dt.year, dt.month, dt.day)));
      }

      var streak = 0;
      var check = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      // Si hoy aún no hay emoción, la racha puede contar desde ayer.
      if (!daysWithEmotion.contains(dayKey(check))) {
        check = check.subtract(const Duration(days: 1));
      }
      while (daysWithEmotion.contains(dayKey(check))) {
        streak++;
        check = check.subtract(const Duration(days: 1));
      }
      return streak;
    } catch (e) {
      debugPrint('Error al obtener días consecutivos: $e');
      return 0;
    }
  }
}

