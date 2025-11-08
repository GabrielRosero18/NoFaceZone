import 'dart:math';
import 'package:nofacezone/src/Custom/AppLocalizations.dart';

/// Sistema de mensajes motivacionales para la aplicación NoFaceZone
class AppMessages {
  // Índices de mensajes para mapear entre idiomas
  static final Map<String, List<int>> _messageIndices = {
    'daily': [0, 1, 2, 3, 4, 5, 6, 7],
    'achievements': [0, 1, 2, 3, 4, 5, 6, 7],
    'encouragement': [0, 1, 2, 3, 4, 5, 6, 7],
    'wisdom': [0, 1, 2, 3, 4, 5, 6, 7],
  };

  // Colecciones activas (se actualiza dinámicamente)
  static List<String> _activeCollections = ['daily'];

  /// Establecer las colecciones activas
  static void setActiveCollections(List<String> collectionIds) {
    _activeCollections = collectionIds.where((id) => _messageIndices.containsKey(id)).toList();
    // Si no hay colecciones activas, usar la predeterminada
    if (_activeCollections.isEmpty) {
      _activeCollections = ['daily'];
    }
  }

  /// Obtener las colecciones activas
  static List<String> get activeCollections => List.from(_activeCollections);

  /// Obtener un mensaje aleatorio de las colecciones activas traducido
  static String getRandomMessage(AppLocalizations localizations) {
    if (_activeCollections.isEmpty) {
      _activeCollections = ['daily'];
    }

    // Recopilar todos los mensajes de todas las colecciones activas
    final allMessages = <String>[];
    for (final collectionId in _activeCollections) {
      if (_messageIndices.containsKey(collectionId)) {
        final indices = _messageIndices[collectionId]!;
        for (final index in indices) {
          allMessages.add(_getMessageByIndex(collectionId, index, localizations));
        }
      }
    }

    if (allMessages.isEmpty) {
      return localizations.messageExample1; // Mensaje predeterminado
    }

    final random = Random();
    return allMessages[random.nextInt(allMessages.length)];
  }
  
  /// Obtener un mensaje traducido por índice y colección
  static String _getMessageByIndex(String collectionId, int index, AppLocalizations localizations) {
    switch (collectionId) {
      case 'daily':
        switch (index) {
          case 0: return localizations.messageExample1;
          case 1: return localizations.messageExample2;
          case 2: return localizations.messageExample3;
          default: return localizations.messageExample1;
        }
      case 'achievements':
        switch (index) {
          case 0: return localizations.messageExample4;
          case 1: return localizations.messageExample5;
          case 2: return localizations.messageExample6;
          default: return localizations.messageExample4;
        }
      case 'encouragement':
        switch (index) {
          case 0: return localizations.messageExample7;
          case 1: return localizations.messageExample8;
          case 2: return localizations.messageExample9;
          default: return localizations.messageExample7;
        }
      case 'wisdom':
        switch (index) {
          case 0: return localizations.messageExample10;
          case 1: return localizations.messageExample11;
          case 2: return localizations.messageExample12;
          default: return localizations.messageExample10;
        }
      default:
        return localizations.messageExample1;
    }
  }

  /// Obtener todos los mensajes de una colección específica traducidos
  static List<String>? getMessagesByCollection(String collectionId, AppLocalizations localizations) {
    final indices = _messageIndices[collectionId];
    if (indices == null) return null;
    
    return indices.map((index) => _getMessageByIndex(collectionId, index, localizations)).toList();
  }

  /// Obtener todas las colecciones disponibles
  static Map<String, List<int>> get allCollections => _messageIndices;

  /// Verificar si una colección está activa
  static bool isCollectionActive(String collectionId) {
    return _activeCollections.contains(collectionId);
  }

  /// Obtener el nombre de la colección traducido
  static String getCollectionName(String collectionId, AppLocalizations localizations) {
    switch (collectionId) {
      case 'daily':
        return localizations.dailyMessages;
      case 'achievements':
        return localizations.achievementMessages;
      case 'encouragement':
        return localizations.encouragementMessages;
      case 'wisdom':
        return localizations.wisdomDaily;
      default:
        return collectionId;
    }
  }
}

