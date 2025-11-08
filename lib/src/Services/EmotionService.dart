import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:nofacezone/src/Models/EmotionModel.dart';
import 'package:nofacezone/src/Services/UserService.dart';

/// Servicio para manejar operaciones de emociones con Supabase
class EmotionService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Registrar una nueva emoción
  static Future<Map<String, dynamic>> registerEmotion({
    required String emotion,
    String? comment,
  }) async {
    try {
      // Obtener el usuario actual
      final currentUser = UserService.getCurrentUser();
      if (currentUser == null) {
        return {
          'success': false,
          'error': 'Debes iniciar sesión para registrar emociones.',
        };
      }

      // Crear el registro de emoción
      final response = await _supabase
          .from('emociones')
          .insert({
            'emotion': emotion,
            'comment': comment,
            'user_id': currentUser.id,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return {
        'success': true,
        'emotion': EmotionModel.fromJson(response),
      };
    } on PostgrestException catch (e) {
      debugPrint('Error de base de datos al registrar emoción: ${e.message}');
      return {
        'success': false,
        'error': _handleDatabaseError(e),
      };
    } catch (e) {
      debugPrint('Error inesperado al registrar emoción: $e');
      return {
        'success': false,
        'error': 'Error inesperado. Inténtalo de nuevo.',
      };
    }
  }

  /// Obtener las emociones recientes del usuario actual
  static Future<List<EmotionModel>> getRecentEmotions({int limit = 10}) async {
    try {
      final currentUser = UserService.getCurrentUser();
      if (currentUser == null) {
        return [];
      }

      final response = await _supabase
          .from('emociones')
          .select()
          .eq('user_id', currentUser.id)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => EmotionModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error al obtener emociones: $e');
      return [];
    }
  }

  /// Obtener todas las emociones del usuario actual
  static Future<List<EmotionModel>> getAllEmotions() async {
    try {
      final currentUser = UserService.getCurrentUser();
      if (currentUser == null) {
        return [];
      }

      final response = await _supabase
          .from('emociones')
          .select()
          .eq('user_id', currentUser.id)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => EmotionModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error al obtener todas las emociones: $e');
      return [];
    }
  }

  /// Eliminar una emoción
  static Future<Map<String, dynamic>> deleteEmotion(int emotionId) async {
    try {
      final currentUser = UserService.getCurrentUser();
      if (currentUser == null) {
        return {
          'success': false,
          'error': 'Debes iniciar sesión para eliminar emociones.',
        };
      }

      await _supabase
          .from('emociones')
          .delete()
          .eq('id', emotionId)
          .eq('user_id', currentUser.id);

      return {
        'success': true,
      };
    } on PostgrestException catch (e) {
      debugPrint('Error al eliminar emoción: ${e.message}');
      return {
        'success': false,
        'error': _handleDatabaseError(e),
      };
    } catch (e) {
      debugPrint('Error inesperado al eliminar emoción: $e');
      return {
        'success': false,
        'error': 'Error inesperado. Inténtalo de nuevo.',
      };
    }
  }

  /// Manejar errores de base de datos
  static String _handleDatabaseError(PostgrestException e) {
    // Verificar si el error es por tabla no encontrada
    if (e.message.contains("Could not find the table") || 
        e.message.contains("does not exist") ||
        e.message.contains("schema cache")) {
      return 'La tabla de emociones no existe. Por favor, ejecuta el script SQL en Supabase para crear la tabla.';
    }
    
    switch (e.code) {
      case '23505': // Unique violation
        return 'Esta emoción ya está registrada.';
      case '23503': // Foreign key violation
        return 'Error de referencia en la base de datos.';
      case '23502': // Not null violation
        return 'Faltan datos requeridos.';
      case 'PGRST116': // No rows returned
        return 'No se encontró la emoción.';
      default:
        return 'Error en la base de datos: ${e.message}';
    }
  }
}

