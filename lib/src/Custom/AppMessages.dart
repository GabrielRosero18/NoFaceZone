import 'dart:math';

/// Sistema de mensajes motivacionales para la aplicación NoFaceZone
class AppMessages {
  // Colecciones de mensajes disponibles
  static final Map<String, List<String>> _messageCollections = {
    'daily': [
      '✨ Cada día es una nueva oportunidad',
      '💪 Eres más fuerte de lo que crees',
      '🌟 Tus pequeños pasos llevan a grandes cambios',
      '🌱 El crecimiento viene de la constancia',
      '💫 Hoy es el mejor día para empezar',
      '🌈 Cada esfuerzo cuenta',
      '🎯 La disciplina te llevará lejos',
      '🔥 Tu determinación es tu superpoder',
    ],
    'achievements': [
      '🎉 ¡Increíble! Lograste tu meta',
      '🏆 Has superado tus expectativas',
      '⭐ Eres un ejemplo de perseverancia',
      '🎊 Cada logro es un paso hacia tu mejor versión',
      '💎 Tu dedicación brilla',
      '👑 Eres un verdadero campeón',
      '🚀 Sigues rompiendo barreras',
      '💪 Tu fuerza de voluntad es admirable',
    ],
    'encouragement': [
      '🌱 Todo crecimiento requiere tiempo',
      '💫 Tus esfuerzos no pasan desapercibidos',
      '🌺 Eres capaz de superar cualquier obstáculo',
      '🌊 Las olas más grandes forman los mejores surfistas',
      '🦋 La transformación toma tiempo, pero vale la pena',
      '🌳 Los árboles más altos tienen las raíces más profundas',
      '💎 La presión crea diamantes',
      '🌟 Incluso las estrellas necesitan oscuridad para brillar',
    ],
    'wisdom': [
      '🧘 La paz viene de dentro',
      '🎯 El éxito es la suma de pequeños esfuerzos',
      '🌈 La persistencia supera la resistencia',
      '🌅 Cada amanecer trae nuevas posibilidades',
      '🦉 La sabiduría viene de la experiencia',
      '🌿 La paciencia es una virtud poderosa',
      '🕊️ La serenidad está en aceptar lo que no puedes cambiar',
      '🎭 La vida es un viaje, no un destino',
    ],
  };

  // Colecciones activas (se actualiza dinámicamente)
  static List<String> _activeCollections = ['daily'];

  /// Establecer las colecciones activas
  static void setActiveCollections(List<String> collectionIds) {
    _activeCollections = collectionIds.where((id) => _messageCollections.containsKey(id)).toList();
    // Si no hay colecciones activas, usar la predeterminada
    if (_activeCollections.isEmpty) {
      _activeCollections = ['daily'];
    }
  }

  /// Obtener las colecciones activas
  static List<String> get activeCollections => List.from(_activeCollections);

  /// Obtener un mensaje aleatorio de las colecciones activas
  static String getRandomMessage() {
    if (_activeCollections.isEmpty) {
      _activeCollections = ['daily'];
    }

    // Recopilar todos los mensajes de las colecciones activas
    final allMessages = <String>[];
    for (final collectionId in _activeCollections) {
      if (_messageCollections.containsKey(collectionId)) {
        allMessages.addAll(_messageCollections[collectionId]!);
      }
    }

    if (allMessages.isEmpty) {
      return '✨ Cada día es una nueva oportunidad'; // Mensaje predeterminado
    }

    final random = Random();
    return allMessages[random.nextInt(allMessages.length)];
  }

  /// Obtener todos los mensajes de una colección específica
  static List<String>? getMessagesByCollection(String collectionId) {
    return _messageCollections[collectionId];
  }

  /// Obtener todas las colecciones disponibles
  static Map<String, List<String>> get allCollections => Map.from(_messageCollections);

  /// Verificar si una colección está activa
  static bool isCollectionActive(String collectionId) {
    return _activeCollections.contains(collectionId);
  }

  /// Obtener el nombre de la colección
  static String getCollectionName(String collectionId) {
    final names = {
      'daily': 'Mensajes diarios',
      'achievements': 'Mensajes de logros',
      'encouragement': 'Mensajes de aliento',
      'wisdom': 'Sabiduría diaria',
    };
    return names[collectionId] ?? collectionId;
  }
}

