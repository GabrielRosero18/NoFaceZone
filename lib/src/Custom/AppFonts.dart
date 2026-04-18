/// Sistema de fuentes para la aplicación NoFaceZone
class AppFonts {
  // Mapeo de IDs de fuentes a nombres de familias de fuentes
  static final Map<String, String> _fontFamilies = {
    'default': 'Roboto', // Fuente predeterminada de Flutter (ya disponible)
    'elegant': 'Playfair Display', // Elegante y sofisticada
    'modern': 'Poppins', // Moderna y minimalista
    'friendly': 'Comfortaa', // Amigable y redondeada
    'bold': 'Montserrat', // Audaz y llamativa
  };

  // Fuente actual (se actualiza dinámicamente)
  static String _currentFontId = 'default';
  
  /// Obtener la fuente actual
  static String get currentFontId => _currentFontId;
  
  /// Obtener el nombre de la familia de fuente actual
  /// Si es 'default', retorna null para usar la fuente predeterminada del sistema (Roboto)
  static String? get currentFontFamily {
    if (_currentFontId == 'default') {
      return null; // null usa la fuente predeterminada del sistema (Roboto en Material)
    }
    return _fontFamilies[_currentFontId];
  }
  
  /// Obtener la fuente de Google Fonts si está disponible
  /// Retorna null si es 'default' para usar la fuente predeterminada
  static String? get currentGoogleFont {
    if (_currentFontId == 'default') {
      return null;
    }
    return _fontFamilies[_currentFontId];
  }
  
  /// Establecer la fuente actual
  static void setFont(String fontId) {
    _currentFontId = _fontFamilies.containsKey(fontId) ? fontId : 'default';
  }
  
  /// Obtener el nombre de la familia de fuente por ID
  static String? getFontFamily(String fontId) {
    if (fontId == 'default') {
      return null; // null usa la fuente predeterminada
    }
    return _fontFamilies[fontId];
  }
  
  /// Obtener todos los IDs de fuentes disponibles
  static List<String> get allFontIds => _fontFamilies.keys.toList();
  
  /// Obtener todos los nombres de fuentes disponibles
  static Map<String, String> get allFontFamilies => Map.from(_fontFamilies);
  
  /// Obtener la fuente de Google Fonts para usar en TextTheme
  static String? getGoogleFontFamily(String fontId) {
    if (fontId == 'default') {
      return null;
    }
    return _fontFamilies[fontId];
  }
}

