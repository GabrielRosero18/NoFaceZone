/// Modelo de datos para las emociones registradas
class EmotionModel {
  final int? id;
  final String emotion; // 'feliz', 'triste', 'neutro', 'ansioso', 'enojado'
  final String? comment;
  final DateTime createdAt;
  final String? userId; // ID del usuario autenticado

  EmotionModel({
    this.id,
    required this.emotion,
    this.comment,
    required this.createdAt,
    this.userId,
  });

  /// Crear desde un mapa (desde Supabase)
  factory EmotionModel.fromJson(Map<String, dynamic> json) {
    return EmotionModel(
      id: json['id'] as int?,
      emotion: json['emotion'] as String,
      comment: json['comment'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      userId: json['user_id'] as String?,
    );
  }

  /// Convertir a mapa (para Supabase)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'emotion': emotion,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
      if (userId != null) 'user_id': userId,
    };
  }

  /// Obtener el nombre de la emoción en español
  String get emotionName {
    switch (emotion.toLowerCase()) {
      case 'feliz':
        return 'Feliz';
      case 'triste':
        return 'Triste';
      case 'neutro':
        return 'Neutro';
      case 'ansioso':
        return 'Ansioso';
      case 'enojado':
        return 'Enojado';
      default:
        return emotion;
    }
  }

  /// Obtener el color asociado a la emoción
  int get emotionColor {
    switch (emotion.toLowerCase()) {
      case 'feliz':
        return 0xFF48BB78; // Verde
      case 'triste':
        return 0xFFF56565; // Rojo claro
      case 'neutro':
        return 0xFF718096; // Gris
      case 'ansioso':
        return 0xFFED8936; // Naranja
      case 'enojado':
        return 0xFFE53E3E; // Rojo oscuro
      default:
        return 0xFF718096;
    }
  }

  /// Obtener el icono asociado a la emoción
  String get emotionIcon {
    switch (emotion.toLowerCase()) {
      case 'feliz':
        return '😊';
      case 'triste':
        return '😢';
      case 'neutro':
        return '😐';
      case 'ansioso':
        return '⚡';
      case 'enojado':
        return '😠';
      default:
        return '😐';
    }
  }

  /// Formatear fecha para mostrar
  String get formattedDate {
    final day = createdAt.day.toString().padLeft(2, '0');
    final month = createdAt.month.toString().padLeft(2, '0');
    final year = createdAt.year;
    final hour = createdAt.hour.toString().padLeft(2, '0');
    final minute = createdAt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year - $hour:$minute';
  }
}

