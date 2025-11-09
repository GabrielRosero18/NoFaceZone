import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

/// Servicio para operaciones administrativas
/// Solo para uso en desarrollo/pruebas
class AdminService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Agregar puntos a un usuario específico (solo para administradores)
  /// 
  /// ⚠️ ADVERTENCIA: Este método solo debe usarse en desarrollo o por administradores
  /// 
  /// [userId] - UUID del usuario (auth_user_id)
  /// [points] - Cantidad de puntos a agregar
  /// [description] - Descripción de la transacción
  static Future<Map<String, dynamic>> addPointsToUser(
    String userId,
    int points, {
    String description = 'Puntos administrativos',
  }) async {
    try {
      // Llamar a la función de base de datos
      final response = await _supabase.rpc(
        'agregar_puntos_usuario',
        params: {
          'p_usuario_id': userId,
          'p_puntos': points,
          'p_descripcion': description,
        },
      );

      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint('Error al agregar puntos administrativos: $e');
      return {
        'success': false,
        'error': 'Error al agregar puntos: $e',
      };
    }
  }

  /// Obtener el auth_user_id de un usuario por su id_usuario
  static Future<String?> getAuthUserIdByUsuarioId(int usuarioId) async {
    try {
      final response = await _supabase
          .from('usuarios')
          .select('auth_user_id')
          .eq('id_usuario', usuarioId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return response['auth_user_id'] as String?;
    } catch (e) {
      debugPrint('Error al obtener auth_user_id: $e');
      return null;
    }
  }

  /// Agregar puntos al administrador (usuario con id_usuario = 1)
  static Future<Map<String, dynamic>> addPointsToAdmin(int points) async {
    try {
      // Obtener el auth_user_id del administrador
      final authUserId = await getAuthUserIdByUsuarioId(1);
      
      if (authUserId == null) {
        return {
          'success': false,
          'error': 'No se encontró el usuario administrador (id_usuario = 1)',
        };
      }

      // Agregar puntos
      return await addPointsToUser(
        authUserId,
        points,
        description: 'Puntos de prueba para administrador',
      );
    } catch (e) {
      debugPrint('Error al agregar puntos al administrador: $e');
      return {
        'success': false,
        'error': 'Error al agregar puntos: $e',
      };
    }
  }

  /// Obtener información del usuario administrador
  static Future<Map<String, dynamic>?> getAdminInfo() async {
    try {
      final response = await _supabase
          .from('usuarios')
          .select('*, puntos_usuario(*)')
          .eq('id_usuario', 1)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint('Error al obtener información del administrador: $e');
      return null;
    }
  }

  /// Eliminar usuario administrador (id_usuario = 1)
  /// ⚠️ ADVERTENCIA: Esto eliminará permanentemente todos los datos del usuario
  static Future<Map<String, dynamic>> deleteAdminUser() async {
    try {
      // Obtener el auth_user_id del administrador
      final authUserId = await getAuthUserIdByUsuarioId(1);
      
      if (authUserId == null) {
        return {
          'success': false,
          'error': 'No se encontró el usuario administrador (id_usuario = 1)',
        };
      }

      // Eliminar datos relacionados primero
      // 1. Emociones
      await _supabase
          .from('emociones')
          .delete()
          .eq('user_id', authUserId);

      // 2. Transacciones de puntos
      await _supabase
          .from('transacciones_puntos')
          .delete()
          .eq('usuario_id', authUserId);

      // 3. Puntos del usuario
      await _supabase
          .from('puntos_usuario')
          .delete()
          .eq('usuario_id', authUserId);

      // 4. Recompensas del usuario
      await _supabase
          .from('recompensas_usuario')
          .delete()
          .eq('usuario_id', authUserId);

      // 5. Eliminar de la tabla usuarios
      await _supabase
          .from('usuarios')
          .delete()
          .eq('id_usuario', 1);

      // NOTA: Para eliminar de auth.users se necesitan permisos de administrador
      // Esto debe hacerse desde el dashboard de Supabase

      return {
        'success': true,
        'message': 'Usuario administrador eliminado exitosamente',
        'auth_user_id': authUserId,
      };
    } catch (e) {
      debugPrint('Error al eliminar usuario administrador: $e');
      return {
        'success': false,
        'error': 'Error al eliminar usuario: $e',
      };
    }
  }
}

