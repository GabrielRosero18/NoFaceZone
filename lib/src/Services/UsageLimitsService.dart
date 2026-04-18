import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

/// Servicio para gestionar límites de uso desde Supabase
/// Permite tracking dinámico del tiempo de uso
class UsageLimitsService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // ============================================
  // LÍMITES DE USO
  // ============================================

  /// Obtener o crear límites de uso del usuario actual
  static Future<Map<String, dynamic>?> getOrCreateUsageLimits() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('Usuario no autenticado');
        return null;
      }

      // Usar función RPC para obtener o crear límites
      final response = await _supabase.rpc(
        'obtener_o_crear_limites_uso',
        params: {'p_usuario_id': userId},
      );

      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint('Error al obtener límites de uso: $e');
      return null;
    }
  }

  /// Actualizar límite diario
  static Future<bool> updateDailyLimit(int minutes) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      // Verificar si ya existe un registro de límites para este usuario
      final existingLimits = await _supabase
          .from('limites_uso')
          .select('id')
          .eq('usuario_id', userId)
          .maybeSingle();

      if (existingLimits != null) {
        // Si existe, actualizar
        await _supabase
            .from('limites_uso')
            .update({
              'limite_diario_minutos': minutes,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('usuario_id', userId)
            .select()
            .single();
      } else {
        // Si no existe, insertar
        await _supabase
            .from('limites_uso')
            .insert({
              'usuario_id': userId,
              'limite_diario_minutos': minutes,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .select()
            .single();
      }

      // Actualizar también el límite del día actual en registros_uso_diario
      // Esto es importante porque el registro diario tiene un snapshot del límite del día
      final today = DateTime.now();
      final todayString = today.toIso8601String().split('T')[0];
      
      // Verificar si existe un registro para hoy
      final todayRecord = await _supabase
          .from('registros_uso_diario')
          .select('id')
          .eq('usuario_id', userId)
          .eq('fecha', todayString)
          .maybeSingle();

      if (todayRecord != null) {
        // Actualizar el límite del día en el registro existente
        await _supabase
            .from('registros_uso_diario')
            .update({
              'limite_del_dia_minutos': minutes,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', todayRecord['id']);
      } else {
        // Si no existe registro para hoy, crear uno nuevo
        await _supabase
            .from('registros_uso_diario')
            .insert({
              'usuario_id': userId,
              'fecha': todayString,
              'tiempo_usado_minutos': 0,
              'limite_del_dia_minutos': minutes,
              'numero_sesiones': 0,
            });
      }

      return true;
    } catch (e) {
      debugPrint('Error al actualizar límite diario: $e');
      return false;
    }
  }

  /// Actualizar bloqueo nocturno
  static Future<bool> updateNightBlock({
    required bool active,
    String? startTime,
    String? endTime,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final updateData = {
        'bloqueo_nocturno_activo': active,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (startTime != null) {
        updateData['bloqueo_nocturno_inicio'] = startTime;
      }
      if (endTime != null) {
        updateData['bloqueo_nocturno_fin'] = endTime;
      }

      // Verificar si existe un registro
      final existing = await _supabase
          .from('limites_uso')
          .select('id')
          .eq('usuario_id', userId)
          .maybeSingle();

      if (existing != null) {
        await _supabase
            .from('limites_uso')
            .update(updateData)
            .eq('usuario_id', userId)
            .select()
            .single();
      } else {
        // Si no existe, crear uno nuevo con valores por defecto
        final insertData = Map<String, dynamic>.from(updateData);
        insertData['usuario_id'] = userId;
        insertData['limite_diario_minutos'] = 60; // Valor por defecto
        await _supabase
            .from('limites_uso')
            .insert(insertData)
            .select()
            .single();
      }

      return true;
    } catch (e) {
      debugPrint('Error al actualizar bloqueo nocturno: $e');
      return false;
    }
  }

  /// Actualizar pausas obligatorias
  static Future<bool> updateMandatoryBreaks({
    required bool active,
    int? intervalMinutes,
    int? durationMinutes,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final updateData = {
        'pausas_obligatorias_activas': active,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (intervalMinutes != null) {
        updateData['intervalo_pausa_minutos'] = intervalMinutes;
      }
      if (durationMinutes != null) {
        updateData['duracion_pausa_minutos'] = durationMinutes;
      }

      // Verificar si existe un registro
      final existing = await _supabase
          .from('limites_uso')
          .select('id')
          .eq('usuario_id', userId)
          .maybeSingle();

      if (existing != null) {
        await _supabase
            .from('limites_uso')
            .update(updateData)
            .eq('usuario_id', userId)
            .select()
            .single();
      } else {
        // Si no existe, crear uno nuevo con valores por defecto
        final insertData = Map<String, dynamic>.from(updateData);
        insertData['usuario_id'] = userId;
        insertData['limite_diario_minutos'] = 60; // Valor por defecto
        await _supabase
            .from('limites_uso')
            .insert(insertData)
            .select()
            .single();
      }

      return true;
    } catch (e) {
      debugPrint('Error al actualizar pausas obligatorias: $e');
      return false;
    }
  }

  /// Actualizar meta semanal
  static Future<bool> updateWeeklyGoal(int hours) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      // Verificar si existe un registro
      final existing = await _supabase
          .from('limites_uso')
          .select('id')
          .eq('usuario_id', userId)
          .maybeSingle();

      if (existing != null) {
        await _supabase
            .from('limites_uso')
            .update({
              'meta_semanal_horas': hours,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('usuario_id', userId)
            .select()
            .single();
      } else {
        // Si no existe, crear uno nuevo con valores por defecto
        await _supabase
            .from('limites_uso')
            .insert({
              'usuario_id': userId,
              'meta_semanal_horas': hours,
              'limite_diario_minutos': 60, // Valor por defecto
              'updated_at': DateTime.now().toIso8601String(),
            })
            .select()
            .single();
      }

      return true;
    } catch (e) {
      debugPrint('Error al actualizar meta semanal: $e');
      return false;
    }
  }

  /// Actualizar configuración de notificaciones
  static Future<bool> updateNotificationSettings({
    required bool active,
    int? intervalMinutes,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final updateData = {
        'notificaciones_activas': active,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (intervalMinutes != null) {
        updateData['intervalo_notificacion_minutos'] = intervalMinutes;
      }

      // Verificar si existe un registro
      final existing = await _supabase
          .from('limites_uso')
          .select('id')
          .eq('usuario_id', userId)
          .maybeSingle();

      if (existing != null) {
        await _supabase
            .from('limites_uso')
            .update(updateData)
            .eq('usuario_id', userId)
            .select()
            .single();
      } else {
        // Si no existe, crear uno nuevo con valores por defecto
        final insertData = Map<String, dynamic>.from(updateData);
        insertData['usuario_id'] = userId;
        insertData['limite_diario_minutos'] = 60; // Valor por defecto
        await _supabase
            .from('limites_uso')
            .insert(insertData)
            .select()
            .single();
      }

      return true;
    } catch (e) {
      debugPrint('Error al actualizar configuración de notificaciones: $e');
      return false;
    }
  }

  // ============================================
  // REGISTRO DE USO DIARIO
  // ============================================

  /// Obtener o crear registro de uso del día actual
  static Future<Map<String, dynamic>?> getOrCreateTodayUsage() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('❌ Usuario no autenticado al obtener registro diario');
        return null;
      }

      final today = DateTime.now();
      final todayString = today.toIso8601String().split('T')[0];

      // Primero intentar leer directamente de la tabla (más rápido y sin caché)
      final directRead = await _supabase
          .from('registros_uso_diario')
          .select()
          .eq('usuario_id', userId)
          .eq('fecha', todayString)
          .maybeSingle();

      if (directRead != null) {
        debugPrint('✅ Registro encontrado para hoy: $todayString');
        return Map<String, dynamic>.from(directRead);
      }

      // Si no existe para hoy, verificar si hay uno de ayer (puede ser temprano en la mañana)
      final recentUsage = await _supabase
          .from('registros_uso_diario')
          .select()
          .eq('usuario_id', userId)
          .order('fecha', ascending: false)
          .limit(1)
          .maybeSingle();
      
      if (recentUsage != null) {
        final fechaRegistro = recentUsage['fecha'] as String?;
        if (fechaRegistro != null) {
          final fechaRegistroDate = DateTime.parse(fechaRegistro);
          final diffDays = today.difference(fechaRegistroDate).inDays;
          if (diffDays <= 1) {
            debugPrint('📅 Usando registro reciente de fecha: $fechaRegistro (diferencia: $diffDays días)');
            return Map<String, dynamic>.from(recentUsage);
          }
        }
      }

      // Si no existe, usar función RPC para crear uno nuevo
      debugPrint('🆕 Creando nuevo registro para hoy mediante RPC');
      final response = await _supabase.rpc(
        'obtener_registro_dia_actual',
        params: {'p_usuario_id': userId},
      );

      return Map<String, dynamic>.from(response);
    } catch (e, stackTrace) {
      debugPrint('❌ Error al obtener registro de uso diario: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Obtener registro de uso de una fecha específica
  static Future<Map<String, dynamic>?> getUsageByDate(DateTime date) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final dateString = date.toIso8601String().split('T')[0];

      final response = await _supabase
          .from('registros_uso_diario')
          .select()
          .eq('usuario_id', userId)
          .eq('fecha', dateString)
          .maybeSingle();

      if (response == null) return null;
      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint('Error al obtener registro de uso por fecha: $e');
      return null;
    }
  }

  /// Obtener registros de uso de los últimos N días
  static Future<List<Map<String, dynamic>>> getUsageHistory(int days) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      final cutoffDateString = cutoffDate.toIso8601String().split('T')[0];

      final response = await _supabase
          .from('registros_uso_diario')
          .select()
          .eq('usuario_id', userId)
          .gte('fecha', cutoffDateString)
          .order('fecha', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error al obtener historial de uso: $e');
      return [];
    }
  }

  /// Registros diarios entre dos fechas (inclusive), orden ascendente por [fecha].
  static Future<List<Map<String, dynamic>>> getDailyUsageRecordsInRange(
    DateTime fromInclusive,
    DateTime toInclusive,
  ) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final fromStr = DateTime(fromInclusive.year, fromInclusive.month, fromInclusive.day)
          .toIso8601String()
          .split('T')[0];
      final toStr = DateTime(toInclusive.year, toInclusive.month, toInclusive.day)
          .toIso8601String()
          .split('T')[0];

      final response = await _supabase
          .from('registros_uso_diario')
          .select()
          .eq('usuario_id', userId)
          .gte('fecha', fromStr)
          .lte('fecha', toStr)
          .order('fecha', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error al obtener registros diarios en rango: $e');
      return [];
    }
  }

  /// Obtener tiempo usado hoy en minutos
  static Future<int> getTodayUsageMinutes() async {
    try {
      final todayUsage = await getOrCreateTodayUsage();
      if (todayUsage == null) return 0;
      return todayUsage['tiempo_usado_minutos'] as int? ?? 0;
    } catch (e) {
      debugPrint('Error al obtener tiempo usado hoy: $e');
      return 0;
    }
  }

  /// Obtener límite diario actual en minutos
  static Future<int> getCurrentDailyLimit() async {
    try {
      final limits = await getOrCreateUsageLimits();
      if (limits == null) return 60; // Valor por defecto
      return limits['limite_diario_minutos'] as int? ?? 60;
    } catch (e) {
      debugPrint('Error al obtener límite diario: $e');
      return 60;
    }
  }

  /// Obtener tiempo restante hoy en minutos
  static Future<int> getRemainingTimeToday() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('❌ Usuario no autenticado al calcular tiempo restante');
        return 0;
      }

      // Obtener el registro del día actual DIRECTAMENTE de la tabla (sin caché)
      final today = DateTime.now();
      final todayString = today.toIso8601String().split('T')[0];
      
      // Leer directamente de la tabla para evitar caché
      final todayUsage = await _supabase
          .from('registros_uso_diario')
          .select()
          .eq('usuario_id', userId)
          .eq('fecha', todayString)
          .maybeSingle();

      // Si no hay registro para hoy, verificar si hay uno de ayer (puede ser temprano en la mañana)
      Map<String, dynamic>? usageRecord = todayUsage;
      if (usageRecord == null) {
        // Intentar obtener el registro más reciente (puede ser de ayer si es temprano)
        final recentUsage = await _supabase
            .from('registros_uso_diario')
            .select()
            .eq('usuario_id', userId)
            .order('fecha', ascending: false)
            .limit(1)
            .maybeSingle();
        
        if (recentUsage != null) {
          final fechaRegistro = recentUsage['fecha'] as String?;
          // Si el registro es de hoy o ayer (dentro de las últimas 24 horas), usarlo
          if (fechaRegistro != null) {
            final fechaRegistroDate = DateTime.parse(fechaRegistro);
            final diffDays = today.difference(fechaRegistroDate).inDays;
            if (diffDays <= 1) {
              usageRecord = recentUsage;
              debugPrint('📅 Usando registro de fecha: $fechaRegistro (diferencia: $diffDays días)');
            }
          }
        }
      }

      // Si todavía no hay registro, crear uno nuevo usando la función RPC
      if (usageRecord == null) {
        try {
          final response = await _supabase.rpc(
            'obtener_registro_dia_actual',
            params: {'p_usuario_id': userId},
          );
          
          // Verificar que la respuesta no sea null
          if (response == null) {
            debugPrint('❌ Error: RPC retornó null');
            final limit = await getCurrentDailyLimit();
            debugPrint('⚠️ Usando límite general como fallback: $limit minutos');
            return limit;
          }
          
          usageRecord = Map<String, dynamic>.from(response);
          debugPrint('✅ Registro creado/obtenido mediante RPC');
        } catch (e) {
          debugPrint('⚠️ Error al crear registro mediante RPC: $e');
          // Fallback: usar límite actual como tiempo restante
          final limit = await getCurrentDailyLimit();
          debugPrint('⚠️ Usando límite general como fallback: $limit minutos');
          return limit;
        }
      }
      
      // SIEMPRE usar el límite del día del registro (limite_del_dia_minutos)
      // Este es el límite real para hoy, que puede ser diferente si se agregó tiempo extra
      final limitDelDia = usageRecord['limite_del_dia_minutos'] as int?;
      var tiempoUsado = usageRecord['tiempo_usado_minutos'] as int? ?? 0;
      
      // Si no hay límite del día, usar el límite general como fallback
      final limiteAUsar = limitDelDia ?? await getCurrentDailyLimit();
      
      // CONSIDERAR EL TIEMPO DE LA SESIÓN ACTIVA
      // Obtener sesiones activas y agregar el tiempo transcurrido
      final activeSessions = await getActiveSessions();
      var tiempoSesionActiva = 0;
      final now = DateTime.now();
      
      if (activeSessions.isNotEmpty) {
        for (var session in activeSessions) {
          final inicioSesion = session['inicio_sesion'] as String?;
          if (inicioSesion != null) {
            try {
              final inicio = DateTime.parse(inicioSesion);
              // Calcular en segundos primero para mayor precisión, luego convertir a minutos
              final tiempoTranscurridoSegundos = now.difference(inicio).inSeconds;
              final tiempoTranscurridoMinutos = tiempoTranscurridoSegundos / 60.0;
              tiempoSesionActiva += tiempoTranscurridoMinutos.ceil();
            } catch (e) {
              debugPrint('⚠️ Error al calcular tiempo de sesión activa: $e');
            }
          }
        }
      }
      
      // Calcular tiempo total usado (BD + sesión activa)
      final tiempoUsadoTotal = tiempoUsado + tiempoSesionActiva;
      
      // Calcular tiempo restante con mayor precisión
      final remaining = (limiteAUsar - tiempoUsadoTotal).ceil();
      
      // Solo loggear si hay cambios significativos para mejorar rendimiento
      if (remaining <= 5 || tiempoSesionActiva > 0) {
        debugPrint('🔍 Cálculo tiempo restante:');
        debugPrint('   Límite: $limiteAUsar min | Usado (BD): $tiempoUsado min | Sesión activa: $tiempoSesionActiva min');
        debugPrint('   Total usado: $tiempoUsadoTotal min | Restante: $remaining min');
      }
      
      // Retornar 0 si el tiempo se agotó (incluso si hay tiempo negativo)
      return remaining > 0 ? remaining : 0;
    } catch (e, stackTrace) {
      debugPrint('❌ Error al calcular tiempo restante: $e');
      debugPrint('Stack trace: $stackTrace');
      // Fallback: usar límite actual
      try {
        final limit = await getCurrentDailyLimit();
        return limit;
      } catch (e2) {
        return 60; // Valor por defecto
      }
    }
  }

  // ============================================
  // SESIONES DE USO
  // ============================================

  /// Iniciar una nueva sesión de uso
  static Future<int?> startUsageSession() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase.rpc(
        'iniciar_sesion_uso',
        params: {'p_usuario_id': userId},
      );

      return response as int?;
    } catch (e) {
      debugPrint('Error al iniciar sesión de uso: $e');
      return null;
    }
  }

  /// Finalizar una sesión de uso
  static Future<Map<String, dynamic>?> finishUsageSession(int sessionId) async {
    try {
      final response = await _supabase.rpc(
        'finalizar_sesion_uso',
        params: {'p_sesion_id': sessionId},
      );

      if (response == null) return null;
      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint('Error al finalizar sesión de uso: $e');
      return null;
    }
  }

  /// Obtener sesiones activas del usuario
  static Future<List<Map<String, dynamic>>> getActiveSessions() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('sesiones_uso')
          .select()
          .eq('usuario_id', userId)
          .eq('estado', 'activa')
          .order('inicio_sesion', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error al obtener sesiones activas: $e');
      return [];
    }
  }

  /// Obtener sesiones del día actual
  static Future<List<Map<String, dynamic>>> getTodaySessions() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await _supabase
          .from('sesiones_uso')
          .select()
          .eq('usuario_id', userId)
          .gte('inicio_sesion', startOfDay.toIso8601String())
          .lt('inicio_sesion', endOfDay.toIso8601String())
          .order('inicio_sesion', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error al obtener sesiones del día: $e');
      return [];
    }
  }

  // ============================================
  // ESTADÍSTICAS Y REPORTES
  // ============================================

  /// Obtener estadísticas semanales
  static Future<Map<String, dynamic>> getWeeklyStats() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return {
          'total_minutos': 0,
          'total_horas': 0.0,
          'promedio_diario_minutos': 0,
          'dias_con_uso': 0,
        };
      }

      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      final weekAgoString = weekAgo.toIso8601String().split('T')[0];

      final response = await _supabase
          .from('registros_uso_diario')
          .select('tiempo_usado_minutos')
          .eq('usuario_id', userId)
          .gte('fecha', weekAgoString);

      final records = List<Map<String, dynamic>>.from(response);
      final totalMinutos = records.fold<int>(
        0,
        (sum, record) => sum + (record['tiempo_usado_minutos'] as int? ?? 0),
      );

      final diasConUso = records.where((r) => (r['tiempo_usado_minutos'] as int? ?? 0) > 0).length;

      return {
        'total_minutos': totalMinutos,
        'total_horas': totalMinutos / 60.0,
        'promedio_diario_minutos': diasConUso > 0 ? totalMinutos ~/ diasConUso : 0,
        'dias_con_uso': diasConUso,
      };
    } catch (e) {
      debugPrint('Error al obtener estadísticas semanales: $e');
      return {
        'total_minutos': 0,
        'total_horas': 0.0,
        'promedio_diario_minutos': 0,
        'dias_con_uso': 0,
      };
    }
  }

  /// Verificar si el usuario ha alcanzado su límite diario
  static Future<bool> hasReachedDailyLimit() async {
    try {
      final remaining = await getRemainingTimeToday();
      return remaining <= 0;
    } catch (e) {
      debugPrint('Error al verificar límite diario: $e');
      return false;
    }
  }

  /// Verificar si está en horario de bloqueo nocturno
  static Future<bool> isInNightBlockTime() async {
    try {
      final limits = await getOrCreateUsageLimits();
      if (limits == null || limits['bloqueo_nocturno_activo'] != true) {
        return false;
      }

      final now = DateTime.now();
      final currentTime = TimeOfDay.fromDateTime(now);
      final startTimeStr = limits['bloqueo_nocturno_inicio'] as String? ?? '22:00:00';
      final endTimeStr = limits['bloqueo_nocturno_fin'] as String? ?? '07:00:00';

      final startParts = startTimeStr.split(':');
      final endParts = endTimeStr.split(':');
      final startHour = int.parse(startParts[0]);
      final startMinute = int.parse(startParts[1]);
      final endHour = int.parse(endParts[0]);
      final endMinute = int.parse(endParts[1]);

      final startTime = TimeOfDay(hour: startHour, minute: startMinute);
      final endTime = TimeOfDay(hour: endHour, minute: endMinute);

      // Si el bloqueo cruza medianoche (ej: 22:00 - 07:00)
      if (startHour > endHour || (startHour == endHour && startMinute > endMinute)) {
        // Bloqueo activo si es después de startTime o antes de endTime
        final currentMinutes = currentTime.hour * 60 + currentTime.minute;
        final startMinutes = startTime.hour * 60 + startTime.minute;
        final endMinutes = endTime.hour * 60 + endTime.minute;

        return currentMinutes >= startMinutes || currentMinutes < endMinutes;
      } else {
        // Bloqueo normal (no cruza medianoche)
        final currentMinutes = currentTime.hour * 60 + currentTime.minute;
        final startMinutes = startTime.hour * 60 + startTime.minute;
        final endMinutes = endTime.hour * 60 + endTime.minute;

        return currentMinutes >= startMinutes && currentMinutes < endMinutes;
      }
    } catch (e) {
      debugPrint('Error al verificar bloqueo nocturno: $e');
      return false;
    }
  }

  /// Obtener tiempo hasta la próxima pausa obligatoria
  static Future<int?> getTimeUntilNextBreak() async {
    try {
      final limits = await getOrCreateUsageLimits();
      if (limits == null || limits['pausas_obligatorias_activas'] != true) {
        return null;
      }

      final intervalMinutes = limits['intervalo_pausa_minutos'] as int? ?? 30;
      final sessions = await getTodaySessions();

      if (sessions.isEmpty) {
        return intervalMinutes;
      }

      // Obtener la última sesión finalizada
      final finishedSessions = sessions
          .where((s) => s['estado'] == 'finalizada' && s['fin_sesion'] != null)
          .toList();

      if (finishedSessions.isEmpty) {
        // Si hay una sesión activa, calcular desde su inicio
        final activeSessions = sessions.where((s) => s['estado'] == 'activa').toList();
        if (activeSessions.isNotEmpty) {
          final lastActive = activeSessions.first;
          final startTime = DateTime.parse(lastActive['inicio_sesion'] as String);
          final elapsed = DateTime.now().difference(startTime).inMinutes;
          final remaining = intervalMinutes - elapsed;
          return remaining > 0 ? remaining : 0;
        }
        return intervalMinutes;
      }

      // Calcular desde la última sesión finalizada
      final lastSession = finishedSessions.first;
      final lastEndTime = DateTime.parse(lastSession['fin_sesion'] as String);
      final elapsed = DateTime.now().difference(lastEndTime).inMinutes;
      final remaining = intervalMinutes - elapsed;

      return remaining > 0 ? remaining : 0;
    } catch (e) {
      debugPrint('Error al calcular tiempo hasta próxima pausa: $e');
      return null;
    }
  }
}

