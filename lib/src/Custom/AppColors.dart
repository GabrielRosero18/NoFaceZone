import 'package:flutter/material.dart';

/// Paleta de colores consistente para toda la aplicación NoFaceZone
class AppColors {
  // Colores principales del gradiente de fondo
  static const Color primaryPurple = Color(0xFF7F53AC);
  static const Color primaryBlue = Color(0xFF647DEE);
  static const Color lightLavender = Color(0xFFB8C1FF);
  
  // Gradientes
  static const List<Color> backgroundGradient = [
    primaryPurple,
    primaryBlue,
    lightLavender,
  ];
  
  static const List<Color> accentGradient = [
    Color(0xFF6A85FF),
    lightLavender,
  ];
  
  // Colores de superficie
  static const Color surfaceColor = Color(0xFFF8F9FF);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color darkSurface = Color(0x66121A3B);
  
  // Colores de texto
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF718096);
  static const Color textLight = Color(0xFFFFFFFF);
  
  // Colores de acento
  static const Color accentBlue = Color(0xFF6A85FF);
  static const Color accentPurple = Color(0xFF7F53AC);
  
  // Colores de estado
  static const Color success = Color(0xFF48BB78);
  static const Color warning = Color(0xFFED8936);
  static const Color error = Color(0xFFF56565);
  static const Color info = Color(0xFF4299E1);
  
  // Sombras
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];
  
  static const List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
  ];
}
