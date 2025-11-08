import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nofacezone/src/Custom/Constans.dart';
import 'package:nofacezone/src/Services/UserService.dart';

/// Modelo de usuario
class User {
  final String id;
  final String email;
  final String name;
  final String? profileImage;
  final DateTime? lastLogin;
  final bool isEmailVerified;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.profileImage,
    this.lastLogin,
    this.isEmailVerified = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? json['id_usuario']?.toString() ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? json['nombre'] ?? '',
      profileImage: json['profileImage'] ?? json['foto_perfil'],
      lastLogin: json['lastLogin'] != null 
          ? DateTime.parse(json['lastLogin']) 
          : null,
      isEmailVerified: json['isEmailVerified'] ?? json['email_verificado'] ?? false,
    );
  }

  /// Crear User desde datos de Supabase
  factory User.fromSupabaseData(Map<String, dynamic> userData, Map<String, dynamic>? authUser) {
    return User(
      id: userData['id_usuario']?.toString() ?? authUser?['id']?.toString() ?? '',
      email: userData['email'] ?? authUser?['email'] ?? '',
      name: userData['nombre'] ?? '',
      profileImage: userData['foto_perfil'],
      lastLogin: DateTime.now(),
      isEmailVerified: authUser?['email_confirmed_at'] != null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'profileImage': profileImage,
      'lastLogin': lastLogin?.toIso8601String(),
      'isEmailVerified': isEmailVerified,
    };
  }
}

/// Provider para manejar el estado del usuario
class UserProvider extends ChangeNotifier {
  User? _user;
  String? _token;
  bool _isLoggedIn = false;
  bool _isLoading = false;

  User? get user => _user;
  String? get token => _token;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;

  UserProvider() {
    _loadUserData();
  }

  /// Cargar datos del usuario desde SharedPreferences
  Future<void> _loadUserData() async {
    _setLoading(true);
    
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // Cargar token
      _token = prefs.getString(Constants.userTokenKey);
      
      // Cargar datos del usuario
      String? userDataString = prefs.getString(Constants.userDataKey);
      if (userDataString != null && _token != null) {
        try {
          // Parsear el JSON del usuario
          final Map<String, dynamic> userJson = jsonDecode(userDataString);
          _user = User.fromJson(userJson);
          _isLoggedIn = true;
        } catch (e) {
          debugPrint('Error parsing user data: $e');
          // Si hay error al parsear, intentar cargar desde Supabase
          await _loadUserFromSupabase();
        }
      } else {
        // Si no hay datos guardados, verificar si hay sesión activa en Supabase
        await _loadUserFromSupabase();
      }
      
    } catch (e) {
      debugPrint('Error loading user data: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Cargar usuario desde Supabase si hay sesión activa
  Future<void> _loadUserFromSupabase() async {
    try {
      if (UserService.isUserLoggedIn()) {
        final authUser = UserService.getCurrentUser();
        if (authUser != null) {
          // Obtener datos del usuario desde la base de datos usando getCurrentUserData
          // que intenta primero por auth_user_id y luego por email
          final userData = await UserService.getCurrentUserData();
          if (userData != null) {
            _user = User.fromSupabaseData(userData, {
              'id': authUser.id,
              'email': authUser.email,
              'email_confirmed_at': authUser.emailConfirmedAt != null ? authUser.emailConfirmedAt.toString() : null,
            });
            _token = authUser.id;
            _isLoggedIn = true;
            await _saveUserData();
            notifyListeners();
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading user from Supabase: $e');
    }
  }

  /// Iniciar sesión
  Future<bool> login(String email, String password, {Map<String, dynamic>? userData, Map<String, dynamic>? authUser}) async {
    _setLoading(true);
    
    try {
      // Si se proporcionan los datos del usuario desde Supabase, usarlos
      if (userData != null && authUser != null) {
        _user = User.fromSupabaseData(userData, authUser);
        _token = authUser['id']?.toString() ?? authUser['user']?['id']?.toString() ?? '';
        _isLoggedIn = true;
        
        // Guardar en SharedPreferences
        await _saveUserData();
        
        notifyListeners();
        return true;
      }
      
      // Si no se proporcionan datos, intentar obtenerlos desde Supabase
      if (UserService.isUserLoggedIn()) {
        final currentAuthUser = UserService.getCurrentUser();
        if (currentAuthUser != null) {
          // Usar getCurrentUserData que es más eficiente con RLS
          final dbUserData = await UserService.getCurrentUserData();
          if (dbUserData != null) {
            _user = User.fromSupabaseData(dbUserData, {
              'id': currentAuthUser.id,
              'email': currentAuthUser.email,
              'email_confirmed_at': currentAuthUser.emailConfirmedAt != null ? currentAuthUser.emailConfirmedAt.toString() : null,
            });
            _token = currentAuthUser.id;
            _isLoggedIn = true;
            
            // Guardar en SharedPreferences
            await _saveUserData();
            
            notifyListeners();
            return true;
          }
        }
      }
      
      return false;
      
    } catch (e) {
      debugPrint('Error during login: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Registrar nuevo usuario
  Future<bool> register(String email, String password, String name, {Map<String, dynamic>? userData, Map<String, dynamic>? authUser}) async {
    _setLoading(true);
    
    try {
      // Si se proporcionan los datos del usuario desde Supabase, usarlos
      if (userData != null && authUser != null) {
        _user = User.fromSupabaseData(userData, authUser);
        _token = authUser['id']?.toString() ?? authUser['user']?['id']?.toString() ?? '';
        _isLoggedIn = true;
        
        // Guardar en SharedPreferences
        await _saveUserData();
        
        notifyListeners();
        return true;
      }
      
      // Si no se proporcionan datos, crear usuario básico (fallback)
      _user = User(
        id: '',
        email: email,
        name: name,
        lastLogin: DateTime.now(),
        isEmailVerified: false,
      );
      
      _token = '';
      _isLoggedIn = false;
      
      notifyListeners();
      return false;
      
    } catch (e) {
      debugPrint('Error during registration: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Cerrar sesión
  Future<void> logout() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(Constants.userTokenKey);
      await prefs.remove(Constants.userDataKey);
      
      _user = null;
      _token = null;
      _isLoggedIn = false;
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error during logout: $e');
    }
  }

  /// Actualizar perfil del usuario
  Future<bool> updateProfile({
    String? name,
    String? profileImage,
  }) async {
    if (_user == null) return false;
    
    _setLoading(true);
    
    try {
      // Aquí harías la llamada a tu API
      await Future.delayed(const Duration(seconds: 1));
      
      _user = User(
        id: _user!.id,
        email: _user!.email,
        name: name ?? _user!.name,
        profileImage: profileImage ?? _user!.profileImage,
        lastLogin: _user!.lastLogin,
        isEmailVerified: _user!.isEmailVerified,
      );
      
      await _saveUserData();
      notifyListeners();
      return true;
      
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Guardar datos del usuario en SharedPreferences
  Future<void> _saveUserData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      if (_token != null) {
        await prefs.setString(Constants.userTokenKey, _token!);
      }
      
      if (_user != null) {
        await prefs.setString(Constants.userDataKey, jsonEncode(_user!.toJson()));
      }
      
    } catch (e) {
      debugPrint('Error saving user data: $e');
    }
  }

  /// Establecer estado de carga
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
