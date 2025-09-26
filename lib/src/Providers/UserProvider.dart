import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nofacezone/src/Custom/Constans.dart';

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
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      profileImage: json['profileImage'],
      lastLogin: json['lastLogin'] != null 
          ? DateTime.parse(json['lastLogin']) 
          : null,
      isEmailVerified: json['isEmailVerified'] ?? false,
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
        // Aquí podrías parsear el JSON del usuario
        // Por ahora simulamos que está logueado si hay token
        _isLoggedIn = true;
      }
      
    } catch (e) {
      debugPrint('Error loading user data: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Iniciar sesión
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    
    try {
      // Aquí harías la llamada a tu API
      // Simulamos un login exitoso
      await Future.delayed(const Duration(seconds: 2));
      
      // Datos simulados del usuario
      _user = User(
        id: '1',
        email: email,
        name: 'Usuario Demo',
        lastLogin: DateTime.now(),
        isEmailVerified: true,
      );
      
      _token = 'demo_token_123';
      _isLoggedIn = true;
      
      // Guardar en SharedPreferences
      await _saveUserData();
      
      notifyListeners();
      return true;
      
    } catch (e) {
      debugPrint('Error during login: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Registrar nuevo usuario
  Future<bool> register(String email, String password, String name) async {
    _setLoading(true);
    
    try {
      // Aquí harías la llamada a tu API
      // Simulamos un registro exitoso
      await Future.delayed(const Duration(seconds: 2));
      
      // Datos del nuevo usuario
      _user = User(
        id: '2',
        email: email,
        name: name,
        lastLogin: DateTime.now(),
        isEmailVerified: false,
      );
      
      _token = 'demo_token_456';
      _isLoggedIn = true;
      
      // Guardar en SharedPreferences
      await _saveUserData();
      
      notifyListeners();
      return true;
      
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
        await prefs.setString(Constants.userDataKey, _user!.toJson().toString());
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
