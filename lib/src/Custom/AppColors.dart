import 'package:flutter/material.dart';

/// Modelo de tema de colores
class ColorTheme {
  final String id;
  final String name;
  final List<Color> backgroundGradient;
  final List<Color> accentGradient;
  final Color primaryColor;
  final Color accentColor;

  const ColorTheme({
    required this.id,
    required this.name,
    required this.backgroundGradient,
    required this.accentGradient,
    required this.primaryColor,
    required this.accentColor,
  });
}

/// Paleta de colores consistente para toda la aplicación NoFaceZone
class AppColors {
  // Tema actual (se actualiza dinámicamente)
  static ColorTheme _currentTheme = _defaultTheme;
  
  // Tema predeterminado (Océano Azul - el tema actual de la app)
  static const ColorTheme _defaultTheme = ColorTheme(
    id: 'ocean',
    name: 'Océano Azul',
    backgroundGradient: [
      Color(0xFF7F53AC), // primaryPurple
      Color(0xFF647DEE), // primaryBlue
      Color(0xFFB8C1FF), // lightLavender
    ],
    accentGradient: [
      Color(0xFF6A85FF),
      Color(0xFFB8C1FF),
    ],
    primaryColor: Color(0xFF7F53AC),
    accentColor: Color(0xFF6A85FF),
  );

  // Todos los temas disponibles
  static final Map<String, ColorTheme> _themes = {
    'ocean': _defaultTheme,
    'sunset': const ColorTheme(
      id: 'sunset',
      name: 'Atardecer',
      backgroundGradient: [
        Color(0xFFE65100), // Colors.orange[800]!
        Color(0xFFEC407A), // Colors.pink[400]!
        Color(0xFFBA68C8), // Colors.purple[300]!
      ],
      accentGradient: [
        Color(0xFFEC407A),
        Color(0xFFBA68C8),
      ],
      primaryColor: Color(0xFFE65100),
      accentColor: Color(0xFFEC407A),
    ),
    'forest': const ColorTheme(
      id: 'forest',
      name: 'Bosque Verde',
      backgroundGradient: [
        Color(0xFF2E7D32), // Colors.green[800]!
        Color(0xFF66BB6A), // Colors.lightGreen[400]!
        Color(0xFFDCE775), // Colors.lime[300]!
      ],
      accentGradient: [
        Color(0xFF66BB6A),
        Color(0xFFDCE775),
      ],
      primaryColor: Color(0xFF2E7D32),
      accentColor: Color(0xFF66BB6A),
    ),
    'lavender': const ColorTheme(
      id: 'lavender',
      name: 'Lavanda',
      backgroundGradient: [
        Color(0xFF6A1B9A), // Colors.purple[800]!
        Color(0xFF7B1FA2), // Colors.deepPurple[400]!
        Color(0xFF7986CB), // Colors.indigo[300]!
      ],
      accentGradient: [
        Color(0xFF7B1FA2),
        Color(0xFF7986CB),
      ],
      primaryColor: Color(0xFF6A1B9A),
      accentColor: Color(0xFF7B1FA2),
    ),
    'coral': const ColorTheme(
      id: 'coral',
      name: 'Coral',
      backgroundGradient: [
        Color(0xFFC62828), // Colors.red[700]!
        Color(0xFFFF6F00), // Colors.orange[400]!
        Color(0xFFFFD54F), // Colors.yellow[300]!
      ],
      accentGradient: [
        Color(0xFFFF6F00),
        Color(0xFFFFD54F),
      ],
      primaryColor: Color(0xFFC62828),
      accentColor: Color(0xFFFF6F00),
    ),
    'midnight': const ColorTheme(
      id: 'midnight',
      name: 'Medianoche',
      backgroundGradient: [
        Color(0xFF212121), // Colors.grey[900]!
        Color(0xFF546E7A), // Colors.blueGrey[800]!
        Color(0xFF616161), // Colors.grey[700]!
      ],
      accentGradient: [
        Color(0xFF546E7A),
        Color(0xFF616161),
      ],
      primaryColor: Color(0xFF212121),
      accentColor: Color(0xFF546E7A),
    ),
  };

  /// Obtener el tema actual
  static ColorTheme get currentTheme => _currentTheme;

  /// Establecer el tema actual
  static void setTheme(String themeId) {
    _currentTheme = _themes[themeId] ?? _defaultTheme;
  }

  /// Obtener un tema por ID
  static ColorTheme? getTheme(String themeId) {
    return _themes[themeId];
  }

  /// Obtener todos los temas disponibles
  static Map<String, ColorTheme> get allThemes => _themes;

  // Colores principales del gradiente de fondo (dinámicos)
  static Color get primaryPurple => _currentTheme.primaryColor;
  static Color get primaryBlue => _currentTheme.backgroundGradient[1];
  static Color get lightLavender => _currentTheme.backgroundGradient[2];
  
  // Gradientes (dinámicos)
  static List<Color> get backgroundGradient => _currentTheme.backgroundGradient;
  static List<Color> get accentGradient => _currentTheme.accentGradient;
  
  // Colores de superficie (estáticos)
  static const Color surfaceColor = Color(0xFFF8F9FF);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color darkSurface = Color(0x66121A3B);
  
  // Colores de texto (estáticos)
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF718096);
  static const Color textLight = Color(0xFFFFFFFF);
  
  // Colores de acento (dinámicos)
  static Color get accentBlue => _currentTheme.accentColor;
  static Color get accentPurple => _currentTheme.primaryColor;
  
  // Colores de estado (estáticos)
  static const Color success = Color(0xFF48BB78);
  static const Color warning = Color(0xFFED8936);
  static const Color error = Color(0xFFF56565);
  static const Color info = Color(0xFF4299E1);
  
  // Sombras (estáticas)
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
