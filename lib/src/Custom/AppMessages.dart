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
    'focus': [0, 1, 2, 3, 4, 5, 6, 7],
    'discipline': [0, 1, 2, 3, 4, 5, 6, 7],
    'mindfulness': [0, 1, 2, 3, 4, 5, 6, 7],
  };

  static final Map<String, Map<String, List<String>>> _customMessages = {
    'focus': {
      'es': [
        '🎯 Lo importante primero: hoy tú mandas sobre tu atención.',
        '🧠 Cada minuto de enfoque te devuelve claridad.',
        '📵 Menos ruido, más progreso real.',
        '🚀 El enfoque constante vence al talento disperso.',
        '🔒 Protege tu concentración como tu recurso más valioso.',
        '⏱️ Una sesión enfocada cambia todo tu día.',
        '🌱 La disciplina de hoy es la libertad de mañana.',
        '✨ Cuando eliges enfoque, eliges crecimiento.',
      ],
      'en': [
        '🎯 Prioritize what matters: your attention is yours today.',
        '🧠 Every focused minute gives you clarity back.',
        '📵 Less noise, more real progress.',
        '🚀 Consistent focus beats scattered talent.',
        '🔒 Guard your concentration as your top asset.',
        '⏱️ One focused session can transform your day.',
        '🌱 Today discipline becomes tomorrow freedom.',
        '✨ Choosing focus means choosing growth.',
      ],
    },
    'discipline': {
      'es': [
        '💪 Haz lo que dijiste, incluso cuando no tengas ganas.',
        '📈 El progreso silencioso también cuenta.',
        '🛡️ Tu constancia te protege de recaer.',
        '🔥 Repite el hábito, fortalece tu identidad.',
        '🏁 No busques perfección, busca continuidad.',
        '⚙️ Pequeñas acciones diarias, grandes resultados.',
        '🌟 Tú construyes tu mejor versión decisión por decisión.',
        '✅ Cumplir hoy te da confianza para mañana.',
      ],
      'en': [
        '💪 Do what you said, even without motivation.',
        '📈 Silent progress still counts.',
        '🛡️ Consistency protects you from relapse.',
        '🔥 Repeat the habit, strengthen your identity.',
        '🏁 Don’t chase perfection, chase consistency.',
        '⚙️ Small daily actions create massive results.',
        '🌟 You build your best self one decision at a time.',
        '✅ Keeping promises today builds confidence for tomorrow.',
      ],
    },
    'mindfulness': {
      'es': [
        '🌿 Respira: este momento también es parte del proceso.',
        '🧘 Tu paz vale más que cualquier scroll infinito.',
        '☀️ Presencia ahora, ansiedad menos después.',
        '💚 Tu mente también necesita descanso consciente.',
        '🌊 Observa el impulso, no tienes que obedecerlo.',
        '🔕 El silencio mental también se entrena.',
        '🍃 Vuelve al cuerpo, vuelve a ti.',
        '✨ Cada pausa consciente te devuelve poder.',
      ],
      'en': [
        '🌿 Breathe: this moment is part of your process.',
        '🧘 Your peace is worth more than endless scrolling.',
        '☀️ Presence now, less anxiety later.',
        '💚 Your mind needs intentional rest too.',
        '🌊 Notice the urge, you do not have to obey it.',
        '🔕 Mental silence can be trained.',
        '🍃 Return to your body, return to yourself.',
        '✨ Every mindful pause gives your power back.',
      ],
    },
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
    final languageCode = localizations.locale.languageCode;
    final customCollection = _customMessages[collectionId];
    if (customCollection != null) {
      final messages = customCollection[languageCode] ?? customCollection['en'] ?? const <String>[];
      if (messages.isNotEmpty) {
        return messages[index % messages.length];
      }
    }

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
      case 'focus':
        return localizations.locale.languageCode == 'es' ? 'Foco Profundo' : 'Deep Focus';
      case 'discipline':
        return localizations.locale.languageCode == 'es' ? 'Disciplina' : 'Discipline';
      case 'mindfulness':
        return localizations.locale.languageCode == 'es' ? 'Mindfulness' : 'Mindfulness';
      default:
        return collectionId;
    }
  }
}

