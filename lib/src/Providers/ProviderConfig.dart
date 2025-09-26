import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:nofacezone/src/Providers/AppProvider.dart';
import 'package:nofacezone/src/Providers/UserProvider.dart';

/// Configuración de todos los providers de la aplicación
class ProviderConfig {
  static List<SingleChildWidget> providers = [
    // Provider para el estado global de la app
    ChangeNotifierProvider<AppProvider>(
      create: (context) => AppProvider(),
    ),
    
    // Provider para el estado del usuario
    ChangeNotifierProvider<UserProvider>(
      create: (context) => UserProvider(),
    ),
  ];

  /// Método para obtener un provider específico
  static T of<T>(BuildContext context) {
    return Provider.of<T>(context, listen: false);
  }

  /// Método para escuchar cambios en un provider
  static T watch<T>(BuildContext context) {
    return Provider.of<T>(context);
  }
}
