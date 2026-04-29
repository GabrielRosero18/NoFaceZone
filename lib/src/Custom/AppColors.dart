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
  
  // Tema predeterminado (Neon Soft)
  static const ColorTheme _defaultTheme = ColorTheme(
    id: 'ocean',
    name: 'Neon Soft',
    backgroundGradient: [
      Color(0xFF111731),
      Color(0xFF182247),
      Color(0xFF223063),
    ],
    accentGradient: [
      Color(0xFF6F8DFF),
      Color(0xFF9AB0FF),
    ],
    primaryColor: Color(0xFF4E70DA),
    accentColor: Color(0xFF6F8DFF),
  );

  // Todos los temas disponibles
  static final Map<String, ColorTheme> _themes = {
    'ocean': _defaultTheme,
    'sunset': const ColorTheme(
      id: 'sunset',
      name: 'Atardecer',
      backgroundGradient: [
        Color(0xFF271821),
        Color(0xFF332032),
        Color(0xFF40293F),
      ],
      accentGradient: [
        Color(0xFFFF8A78),
        Color(0xFFD47EA6),
      ],
      primaryColor: Color(0xFFD26C5D),
      accentColor: Color(0xFFD47EA6),
    ),
    'forest': const ColorTheme(
      id: 'forest',
      name: 'Bosque Verde',
      backgroundGradient: [
        Color(0xFF13221D),
        Color(0xFF1B2E27),
        Color(0xFF253C32),
      ],
      accentGradient: [
        Color(0xFF6EC4A1),
        Color(0xFF8BD3B1),
      ],
      primaryColor: Color(0xFF4B9A7D),
      accentColor: Color(0xFF6EC4A1),
    ),
    'lavender': const ColorTheme(
      id: 'lavender',
      name: 'Lavanda',
      backgroundGradient: [
        Color(0xFF201A32),
        Color(0xFF2A2141),
        Color(0xFF362B54),
      ],
      accentGradient: [
        Color(0xFFA285FF),
        Color(0xFFBC9BFF),
      ],
      primaryColor: Color(0xFF8169CC),
      accentColor: Color(0xFFA285FF),
    ),
    'coral': const ColorTheme(
      id: 'coral',
      name: 'Coral',
      backgroundGradient: [
        Color(0xFF28171A),
        Color(0xFF342025),
        Color(0xFF412930),
      ],
      accentGradient: [
        Color(0xFFF08B69),
        Color(0xFFFFAF85),
      ],
      primaryColor: Color(0xFFCB6E57),
      accentColor: Color(0xFFF08B69),
    ),
    'midnight': const ColorTheme(
      id: 'midnight',
      name: 'Medianoche',
      backgroundGradient: [
        Color(0xFF0F1320),
        Color(0xFF161E31),
        Color(0xFF212B43),
      ],
      accentGradient: [
        Color(0xFF6E82B0),
        Color(0xFF8EA3D1),
      ],
      primaryColor: Color(0xFF5A6F99),
      accentColor: Color(0xFF6E82B0),
    ),
    'aurora': const ColorTheme(
      id: 'aurora',
      name: 'Aurora',
      backgroundGradient: [
        Color(0xFF111E2A),
        Color(0xFF173445),
        Color(0xFF1E4A61),
      ],
      accentGradient: [
        Color(0xFF45E0C5),
        Color(0xFF7DFFE3),
      ],
      primaryColor: Color(0xFF2EA18D),
      accentColor: Color(0xFF45E0C5),
    ),
    'neon': const ColorTheme(
      id: 'neon',
      name: 'Neon Pulse',
      backgroundGradient: [
        Color(0xFF1A102B),
        Color(0xFF241743),
        Color(0xFF2F1F5B),
      ],
      accentGradient: [
        Color(0xFFFF5FDB),
        Color(0xFF8E74FF),
      ],
      primaryColor: Color(0xFFB65FFF),
      accentColor: Color(0xFFFF5FDB),
    ),
    'ember': const ColorTheme(
      id: 'ember',
      name: 'Ember Glow',
      backgroundGradient: [
        Color(0xFF231711),
        Color(0xFF3A2218),
        Color(0xFF4D2E1F),
      ],
      accentGradient: [
        Color(0xFFFF9259),
        Color(0xFFFFC16E),
      ],
      primaryColor: Color(0xFFD46A3F),
      accentColor: Color(0xFFFF9259),
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
  static const Color darkSurface = Color(0xCC101827);
  
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
      color: Color(0x14000000),
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
  ];
  
  static const List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Color(0x26000000),
      blurRadius: 12,
      offset: Offset(0, 6),
    ),
  ];
}
