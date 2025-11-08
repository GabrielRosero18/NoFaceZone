import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

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
            'auth_user_id': authResponse.user!.id, // ID del usuario en Supabase Auth
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

  /// Obtener información de un usuario por auth_user_id (UUID de Supabase Auth)
  static Future<Map<String, dynamic>?> getUserByAuthId(String authUserId) async {
    try {
      final response = await _supabase
          .from('usuarios')
          .select()
          .eq('auth_user_id', authUserId)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Error al obtener usuario por auth_user_id: $e');
      return null;
    }
  }

  /// Obtener información del usuario actual autenticado
  static Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      final currentUser = getCurrentUser();
      if (currentUser == null) {
        return null;
      }

      // Primero intentar obtener por auth_user_id (más eficiente con RLS)
      final userByAuthId = await getUserByAuthId(currentUser.id);
      if (userByAuthId != null) {
        return userByAuthId;
      }

      // Si no se encuentra, intentar por email (fallback)
      if (currentUser.email != null) {
        return await getUserByEmail(currentUser.email!);
      }

      return null;
    } catch (e) {
      debugPrint('Error al obtener datos del usuario actual: $e');
      return null;
    }
  }

  /// Actualizar información de un usuario
  static Future<Map<String, dynamic>> updateUser({
    int? userId,
    String? name,
    int? age,
    String? gender,
    String? language,
    String? frequency,
    String? facebookUser,
    String? fotoPerfil,
  }) async {
    try {
      final Map<String, dynamic> updateData = {};
      
      if (name != null) updateData['nombre'] = name;
      if (age != null) updateData['edad'] = age;
      if (gender != null) updateData['genero'] = gender;
      if (language != null) updateData['idioma_preferido'] = language;
      if (frequency != null) updateData['frecuencia_uso_facebook'] = frequency;
      if (facebookUser != null) updateData['usuario_facebook'] = facebookUser;
      if (fotoPerfil != null) updateData['foto_perfil'] = fotoPerfil;

      // Si no hay datos para actualizar, retornar éxito
      if (updateData.isEmpty) {
        return {
          'success': true,
          'user': null,
        };
      }

      final currentUser = getCurrentUser();
      if (currentUser == null) {
        return {
          'success': false,
          'error': 'Debes iniciar sesión para actualizar tu perfil.',
        };
      }

      // Estrategia 1: Intentar actualizar usando auth_user_id
      try {
        final response = await _supabase
            .from('usuarios')
            .update(updateData)
            .eq('auth_user_id', currentUser.id)
            .select()
            .maybeSingle();

        if (response != null) {
          return {
            'success': true,
            'user': response,
          };
        }
      } catch (e) {
        debugPrint('Error al actualizar por auth_user_id: $e');
      }

      // Estrategia 2: Intentar actualizar usando email (más confiable)
      if (currentUser.email != null) {
        try {
          final response = await _supabase
              .from('usuarios')
              .update(updateData)
              .eq('email', currentUser.email!)
              .select()
              .maybeSingle();

          if (response != null) {
            return {
              'success': true,
              'user': response,
            };
          }
        } catch (e) {
          debugPrint('Error al actualizar por email: $e');
        }
      }

      // Estrategia 3: Usar id_usuario si se proporciona
      if (userId != null) {
        try {
          final response = await _supabase
              .from('usuarios')
              .update(updateData)
              .eq('id_usuario', userId)
              .select()
              .maybeSingle();

          if (response != null) {
            return {
              'success': true,
              'user': response,
            };
          }
        } catch (e) {
          debugPrint('Error al actualizar por id_usuario: $e');
        }
      }

      // Si ninguna estrategia funcionó, intentar obtener el usuario primero
      final userData = await getCurrentUserData();
      if (userData != null && userData['id_usuario'] != null) {
        try {
          final response = await _supabase
              .from('usuarios')
              .update(updateData)
              .eq('id_usuario', userData['id_usuario'])
              .select()
              .maybeSingle();

          if (response != null) {
            return {
              'success': true,
              'user': response,
            };
          }
        } catch (e) {
          debugPrint('Error al actualizar por id_usuario obtenido: $e');
        }
      }

      return {
        'success': false,
        'error': 'No se encontró el usuario en la base de datos. Por favor, cierra sesión y vuelve a iniciar sesión.',
      };
    } on PostgrestException catch (e) {
      debugPrint('Error de base de datos al actualizar usuario: ${e.message}');
      debugPrint('Código de error: ${e.code}');
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

  /// Subir foto de perfil a Supabase Storage
  static Future<Map<String, dynamic>> uploadProfileImage(File imageFile) async {
    try {
      final currentUser = getCurrentUser();
      if (currentUser == null) {
        return {
          'success': false,
          'error': 'Debes iniciar sesión para subir una foto.',
        };
      }

      // Obtener la extensión del archivo
      final fileExtension = path.extension(imageFile.path);
      final fileName = '${currentUser.id}_${DateTime.now().millisecondsSinceEpoch}$fileExtension';
      final filePath = 'profile-pictures/$fileName';

      // Leer el archivo como bytes
      final imageBytes = await imageFile.readAsBytes();

      // Determinar el content type basado en la extensión
      String contentType = 'image/jpeg';
      if (fileExtension.toLowerCase() == '.png') {
        contentType = 'image/png';
      } else if (fileExtension.toLowerCase() == '.gif') {
        contentType = 'image/gif';
      } else if (fileExtension.toLowerCase() == '.webp') {
        contentType = 'image/webp';
      }

      // Subir la imagen al bucket 'avatars' (o el bucket que tengas configurado)
      // Si no existe el bucket, puedes usar 'public' o crear uno llamado 'avatars'
      await _supabase.storage
          .from('avatars')
          .uploadBinary(
            filePath,
            imageBytes,
            fileOptions: FileOptions(
              upsert: true, // Si ya existe, lo reemplaza
              contentType: contentType,
            ),
          );

      // Obtener la URL pública de la imagen
      final imageUrl = _supabase.storage
          .from('avatars')
          .getPublicUrl(filePath);

      debugPrint('✅ Imagen subida exitosamente');
      debugPrint('📁 Ruta del archivo: $filePath');
      debugPrint('🔗 URL de la imagen: $imageUrl');

      return {
        'success': true,
        'url': imageUrl,
      };
    } on StorageException catch (e) {
      debugPrint('Error de Storage al subir imagen: ${e.message}');
      String errorMessage = 'Error al subir la imagen.';
      
      // Mensajes más específicos según el tipo de error
      if (e.message.contains('new row violates row-level security policy') || 
          e.message.contains('permission denied') ||
          e.message.contains('policy')) {
        errorMessage = 'No tienes permisos para subir imágenes. Verifica las políticas de Storage en Supabase.';
      } else if (e.message.contains('Bucket not found') || e.message.contains('does not exist')) {
        errorMessage = 'El bucket "avatars" no existe. Crea el bucket en Supabase Storage.';
      } else if (e.message.contains('The resource already exists')) {
        errorMessage = 'La imagen ya existe. Inténtalo de nuevo.';
      } else {
        errorMessage = 'Error al subir la imagen: ${e.message}';
      }
      
      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      debugPrint('Error inesperado al subir imagen: $e');
      return {
        'success': false,
        'error': 'Error al subir la imagen. Inténtalo de nuevo.',
      };
    }
  }
}
