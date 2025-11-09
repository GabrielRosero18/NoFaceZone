import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:nofacezone/src/Services/UserService.dart';

/// Servicio para manejar operaciones de recompensas con Supabase
class RewardService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Obtener todas las recompensas disponibles
  static Future<List<Map<String, dynamic>>> getAllRewards() async {
    try {
      final response = await _supabase
          .from('recompensas')
          .select('*, tipos_recompensas(name)')
          .eq('is_active', true)
          .order('display_order');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error al obtener recompensas: $e');
      return [];
    }
  }

  /// Obtener recompensas de un usuario específico
  static Future<List<Map<String, dynamic>>> getUserRewards() async {
    try {
      final currentUser = UserService.getCurrentUser();
      if (currentUser == null) {
        return [];
      }

      // Obtener el auth_user_id
      final authUser = _supabase.auth.currentUser;
      if (authUser == null) {
        return [];
      }

      // Llamar a la función de base de datos
      final response = await _supabase.rpc(
        'obtener_recompensas_usuario',
        params: {'p_usuario_id': authUser.id},
      );

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error al obtener recompensas del usuario: $e');
      return [];
    }
  }

  /// Obtener puntos del usuario actual
  static Future<Map<String, dynamic>?> getUserPoints() async {
    try {
      final authUser = _supabase.auth.currentUser;
      if (authUser == null) {
        return null;
      }

      final response = await _supabase
          .from('puntos_usuario')
          .select()
          .eq('usuario_id', authUser.id)
          .maybeSingle();

      if (response == null) {
        // Crear registro inicial si no existe
        await _supabase.from('puntos_usuario').insert({
          'usuario_id': authUser.id,
          'puntos_totales': 0,
          'puntos_actuales': 0,
          'puntos_gastados': 0,
        });

        return {
          'puntos_totales': 0,
          'puntos_actuales': 0,
          'puntos_gastados': 0,
        };
      }

      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint('Error al obtener puntos del usuario: $e');
      return null;
    }
  }

  /// Comprar una recompensa
  static Future<Map<String, dynamic>> purchaseReward(String rewardId) async {
    try {
      final authUser = _supabase.auth.currentUser;
      if (authUser == null) {
        return {
          'success': false,
          'error': 'Debes iniciar sesión para comprar recompensas',
        };
      }

      // Llamar a la función de base de datos
      final response = await _supabase.rpc(
        'comprar_recompensa',
        params: {
          'p_usuario_id': authUser.id,
          'p_recompensa_id': rewardId,
        },
      );

      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint('Error al comprar recompensa: $e');
      return {
        'success': false,
        'error': 'Error al comprar la recompensa: $e',
      };
    }
  }

  /// Agregar puntos a un usuario
  static Future<Map<String, dynamic>> addPoints(
    int points, {
    String description = 'Puntos ganados',
  }) async {
    try {
      final authUser = _supabase.auth.currentUser;
      if (authUser == null) {
        return {
          'success': false,
          'error': 'Debes iniciar sesión',
        };
      }

      // Llamar a la función de base de datos
      final response = await _supabase.rpc(
        'agregar_puntos_usuario',
        params: {
          'p_usuario_id': authUser.id,
          'p_puntos': points,
          'p_descripcion': description,
        },
      );

      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint('Error al agregar puntos: $e');
      return {
        'success': false,
        'error': 'Error al agregar puntos: $e',
      };
    }
  }

  /// Activar/desactivar una recompensa del usuario
  static Future<Map<String, dynamic>> toggleReward(
    String rewardId,
    bool isActive,
  ) async {
    try {
      final authUser = _supabase.auth.currentUser;
      if (authUser == null) {
        return {
          'success': false,
          'error': 'Debes iniciar sesión',
        };
      }

      // Verificar si el usuario tiene la recompensa
      final existingReward = await _supabase
          .from('recompensas_usuario')
          .select()
          .eq('usuario_id', authUser.id)
          .eq('recompensa_id', rewardId)
          .maybeSingle();

      if (existingReward == null) {
        return {
          'success': false,
          'error': 'No tienes esta recompensa',
        };
      }

      // Actualizar el estado
      await _supabase
          .from('recompensas_usuario')
          .update({'is_active': isActive})
          .eq('usuario_id', authUser.id)
          .eq('recompensa_id', rewardId);

      return {'success': true};
    } catch (e) {
      debugPrint('Error al actualizar recompensa: $e');
      return {
        'success': false,
        'error': 'Error al actualizar recompensa: $e',
      };
    }
  }

  /// Obtener recompensas por tipo
  static Future<List<Map<String, dynamic>>> getRewardsByType(
    String type,
  ) async {
    try {
      final response = await _supabase
          .from('recompensas')
          .select('*, tipos_recompensas(name)')
          .eq('tipo_recompensa_id', type)
          .eq('is_active', true)
          .order('display_order');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error al obtener recompensas por tipo: $e');
      return [];
    }
  }

  /// Obtener historial de transacciones de puntos
  static Future<List<Map<String, dynamic>>> getPointTransactions({
    int limit = 20,
  }) async {
    try {
      final authUser = _supabase.auth.currentUser;
      if (authUser == null) {
        return [];
      }

      final response = await _supabase
          .from('transacciones_puntos')
          .select()
          .eq('usuario_id', authUser.id)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error al obtener transacciones: $e');
      return [];
    }
  }

  /// Verificar si un usuario tiene una recompensa desbloqueada
  static Future<bool> hasReward(String rewardId) async {
    try {
      final authUser = _supabase.auth.currentUser;
      if (authUser == null) {
        return false;
      }

      final response = await _supabase
          .from('recompensas_usuario')
          .select('id')
          .eq('usuario_id', authUser.id)
          .eq('recompensa_id', rewardId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('Error al verificar recompensa: $e');
      return false;
    }
  }

  /// Obtener una recompensa específica
  static Future<Map<String, dynamic>?> getReward(String rewardId) async {
    try {
      final response = await _supabase
          .from('recompensas')
          .select('*, tipos_recompensas(name)')
          .eq('id', rewardId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint('Error al obtener recompensa: $e');
      return null;
    }
  }

  /// Desbloquear recompensas por defecto para un usuario nuevo
  static Future<void> unlockDefaultRewards(String userId) async {
    try {
      // Obtener todas las recompensas por defecto
      final defaultRewards = await _supabase
          .from('recompensas')
          .select('id')
          .eq('is_default', true)
          .eq('is_active', true);

      if (defaultRewards.isEmpty) {
        return;
      }

      // Insertar cada recompensa por defecto para el usuario
      for (final reward in defaultRewards) {
        try {
          await _supabase.from('recompensas_usuario').insert({
            'usuario_id': userId,
            'recompensa_id': reward['id'],
            'is_active': true,
            'unlocked_at': DateTime.now().toIso8601String(),
          });
        } catch (e) {
          // Ignorar si ya existe (ON CONFLICT)
          debugPrint('Recompensa por defecto ya existe: ${reward['id']}');
        }
      }
    } catch (e) {
      debugPrint('Error al desbloquear recompensas por defecto: $e');
    }
  }
}

