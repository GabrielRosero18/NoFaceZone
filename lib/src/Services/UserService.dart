import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

/// Servicio para manejar operaciones de usuarios con Supabase
class UserService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Registrar un nuevo usuario en la tabla usuarios (sin confirmación de email)
  static Future<Map<String, dynamic>> registerUser({
    required String name,
    required int age,
    required String gender,
    required String email,
    required String password,
    required String language,
    required String frequency,
    String? facebookUser,
    bool requireEmailConfirmation = false,
  }) async {
    try {
      // Primero registrar el usuario en Supabase Auth (SIN confirmación de email)
      final AuthResponse authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: null, // Deshabilitar completamente confirmación de email
      );

      if (authResponse.user == null) {
        throw Exception('Error al crear la cuenta de autenticación');
      }

      // El usuario se crea directamente sin confirmación de email

      // Luego insertar los datos del usuario en la tabla usuarios
      final response = await _supabase
          .from('usuarios')
          .insert({
            'nombre': name,
            'edad': age,
            'genero': gender,
            'email': email,
            'idioma_preferido': language,
            'frecuencia_uso_facebook': frequency,
            'usuario_facebook': facebookUser ?? '',
            'contraseña': password, // En producción deberías hashear esto
          })
          .select()
          .single();

      return {
        'success': true,
        'user': response,
        'authUser': authResponse.user,
      };
    } on PostgrestException catch (e) {
      debugPrint('Error de base de datos: ${e.message}');
      return {
        'success': false,
        'error': _handleDatabaseError(e),
      };
    } on AuthException catch (e) {
      debugPrint('Error de autenticación: ${e.message}');
      return {
        'success': false,
        'error': _handleAuthError(e),
      };
    } catch (e) {
      debugPrint('Error inesperado: $e');
      return {
        'success': false,
        'error': 'Error inesperado. Inténtalo de nuevo.',
      };
    }
  }

  /// Obtener información de un usuario por email
  static Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      final response = await _supabase
          .from('usuarios')
          .select()
          .eq('email', email)
          .single();

      return response;
    } catch (e) {
      debugPrint('Error al obtener usuario: $e');
      return null;
    }
  }

  /// Obtener información de un usuario por ID
  static Future<Map<String, dynamic>?> getUserById(int userId) async {
    try {
      final response = await _supabase
          .from('usuarios')
          .select()
          .eq('id_usuario', userId)
          .single();

      return response;
    } catch (e) {
      debugPrint('Error al obtener usuario: $e');
      return null;
    }
  }

  /// Actualizar información de un usuario
  static Future<Map<String, dynamic>> updateUser({
    required int userId,
    String? name,
    int? age,
    String? gender,
    String? language,
    String? frequency,
    String? facebookUser,
  }) async {
    try {
      final Map<String, dynamic> updateData = {};
      
      if (name != null) updateData['nombre'] = name;
      if (age != null) updateData['edad'] = age;
      if (gender != null) updateData['genero'] = gender;
      if (language != null) updateData['idioma_preferido'] = language;
      if (frequency != null) updateData['frecuencia_uso_facebook'] = frequency;
      if (facebookUser != null) updateData['usuario_facebook'] = facebookUser;

      final response = await _supabase
          .from('usuarios')
          .update(updateData)
          .eq('id_usuario', userId)
          .select()
          .single();

      return {
        'success': true,
        'user': response,
      };
    } on PostgrestException catch (e) {
      debugPrint('Error al actualizar usuario: ${e.message}');
      return {
        'success': false,
        'error': _handleDatabaseError(e),
      };
    } catch (e) {
      debugPrint('Error inesperado al actualizar: $e');
      return {
        'success': false,
        'error': 'Error inesperado. Inténtalo de nuevo.',
      };
    }
  }

  /// Verificar si un email ya existe
  static Future<bool> emailExists(String email) async {
    try {
      final response = await _supabase
          .from('usuarios')
          .select('id_usuario')
          .eq('email', email)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('Error al verificar email: $e');
      return false;
    }
  }

  /// Manejar errores de base de datos
  static String _handleDatabaseError(PostgrestException e) {
    switch (e.code) {
      case '23505': // Unique violation
        if (e.message.contains('email')) {
          return 'Este email ya está registrado. Usa otro email o inicia sesión.';
        }
        return 'Los datos ya existen en el sistema.';
      case '23503': // Foreign key violation
        return 'Error de referencia en la base de datos.';
      case '23502': // Not null violation
        return 'Faltan datos requeridos.';
      default:
        return 'Error en la base de datos: ${e.message}';
    }
  }

  /// Manejar errores de autenticación
  static String _handleAuthError(AuthException e) {
    switch (e.message) {
      case 'User already registered':
        return 'Este email ya está registrado. Usa otro email o inicia sesión.';
      case 'Password should be at least 6 characters':
        return 'La contraseña debe tener al menos 6 caracteres.';
      case 'Invalid email':
        return 'El formato del email no es válido.';
      default:
        return 'Error de autenticación: ${e.message}';
    }
  }

  /// Cerrar sesión
  static Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint('Error al cerrar sesión: $e');
    }
  }

  /// Obtener usuario actual autenticado
  static User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  /// Verificar si hay un usuario autenticado
  static bool isUserLoggedIn() {
    return _supabase.auth.currentUser != null;
  }

  /// Iniciar sesión con email y contraseña
  static Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      // Autenticar con Supabase Auth
      final AuthResponse authResponse = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        throw Exception('Error al autenticar usuario');
      }

      // Obtener datos del usuario de la tabla usuarios
      final userData = await getUserByEmail(email);
      
      if (userData == null) {
        // Si no existe en la tabla usuarios, cerrar sesión
        await _supabase.auth.signOut();
        return {
          'success': false,
          'error': 'Usuario no encontrado en la base de datos.',
        };
      }

      return {
        'success': true,
        'user': userData,
        'authUser': authResponse.user,
      };
    } on AuthException catch (e) {
      debugPrint('Error de autenticación: ${e.message}');
      return {
        'success': false,
        'error': _handleAuthError(e),
      };
    } catch (e) {
      debugPrint('Error inesperado en login: $e');
      return {
        'success': false,
        'error': 'Error inesperado. Inténtalo de nuevo.',
      };
    }
  }

  /// Verificar credenciales sin autenticar
  static Future<Map<String, dynamic>> verifyCredentials({
    required String email,
    required String password,
  }) async {
    try {
      // Buscar usuario en la tabla usuarios
      final userData = await getUserByEmail(email);
      
      if (userData == null) {
        return {
          'success': false,
          'error': 'Email no registrado.',
        };
      }

      // Verificar contraseña (en producción deberías comparar hashes)
      if (userData['contraseña'] != password) {
        return {
          'success': false,
          'error': 'Contraseña incorrecta.',
        };
      }

      return {
        'success': true,
        'user': userData,
      };
    } catch (e) {
      debugPrint('Error al verificar credenciales: $e');
      return {
        'success': false,
        'error': 'Error al verificar credenciales.',
      };
    }
  }
}
