import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nofacezone/src/Custom/AppColors.dart';
import 'package:nofacezone/src/Custom/AppLocalizations.dart';
import 'package:nofacezone/src/Custom/CustomSnackBar.dart';
import 'package:nofacezone/src/Providers/AppProvider.dart';
import 'package:nofacezone/src/Services/EmotionService.dart';
import 'package:nofacezone/src/Models/EmotionModel.dart';

class EmotionTrackingScreen extends StatefulWidget {
  const EmotionTrackingScreen({super.key});

  @override
  State<EmotionTrackingScreen> createState() => _EmotionTrackingScreenState();
}

class _EmotionTrackingScreenState extends State<EmotionTrackingScreen> {
  String? _selectedEmotion;
  final TextEditingController _commentController = TextEditingController();
  List<EmotionModel> _recentEmotions = [];
  bool _isLoading = false;
  bool _isSaving = false;

  // Emociones disponibles - usando IconData con colores más vibrantes
  List<Map<String, dynamic>> _getEmotions(AppLocalizations? localizations) {
    // Si no hay localizations, usar valores por defecto en español
    final happy = localizations?.emotionHappy ?? 'Feliz';
    final sad = localizations?.emotionSad ?? 'Triste';
    final neutral = localizations?.emotionNeutral ?? 'Neutro';
    final anxious = localizations?.emotionAnxious ?? 'Ansioso';
    final angry = localizations?.emotionAngry ?? 'Enojado';
    
    return [
      {
        'id': 'feliz',
        'name': happy,
        'icon': Icons.sentiment_very_satisfied,
        'color': const Color(0xFF48BB78),
        'bgColor': const Color(0xFF48BB78).withValues(alpha: 0.2),
      },
      {
        'id': 'triste',
        'name': sad,
        'icon': Icons.sentiment_very_dissatisfied,
        'color': const Color(0xFFF56565),
        'bgColor': const Color(0xFFF56565).withValues(alpha: 0.2),
      },
      {
        'id': 'neutro',
        'name': neutral,
        'icon': Icons.sentiment_neutral,
        'color': const Color(0xFFA0AEC0),
        'bgColor': const Color(0xFFA0AEC0).withValues(alpha: 0.2),
      },
      {
        'id': 'ansioso',
        'name': anxious,
        'icon': Icons.bolt,
        'color': const Color(0xFFED8936),
        'bgColor': const Color(0xFFED8936).withValues(alpha: 0.2),
      },
      {
        'id': 'enojado',
        'name': angry,
        'icon': Icons.sentiment_dissatisfied,
        'color': const Color(0xFFE53E3E),
        'bgColor': const Color(0xFFE53E3E).withValues(alpha: 0.2),
      },
    ];
  }

  @override
  void initState() {
    super.initState();
    _loadRecentEmotions();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentEmotions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final emotions = await EmotionService.getRecentEmotions(limit: 5);
      setState(() {
        _recentEmotions = emotions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        final localizations = AppLocalizations.of(context);
        CustomSnackBar.showError(
          context,
          localizations?.errorLoadingEmotions ?? 'Error al cargar emociones: $e',
          icon: Icons.error_outline_rounded,
        );
      }
    }
  }

  Future<void> _registerEmotion() async {
    final localizations = AppLocalizations.of(context);
    if (_selectedEmotion == null) {
      CustomSnackBar.showWarning(
        context,
        localizations?.pleaseSelectEmotion ?? 'Por favor selecciona una emoción',
        icon: Icons.emoji_emotions_outlined,
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final result = await EmotionService.registerEmotion(
        emotion: _selectedEmotion!,
        comment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
      );

      if (result['success'] == true) {
        // Limpiar formulario
        setState(() {
          _selectedEmotion = null;
          _commentController.clear();
        });

        // Recargar emociones recientes
        await _loadRecentEmotions();

        if (mounted) {
          CustomSnackBar.showSuccess(
            context,
            localizations?.emotionRegisteredSuccessfully ?? 'Emoción registrada exitosamente',
            icon: Icons.mood_rounded,
          );
        }
      } else {
        if (mounted) {
          CustomSnackBar.showError(
            context,
            result['error'] ?? (localizations?.errorRegisteringEmotion ?? 'Error al registrar emoción'),
            icon: Icons.error_outline_rounded,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(
          context,
          '${localizations?.errorRegisteringEmotion ?? 'Error inesperado'}: $e',
          icon: Icons.error_outline_rounded,
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        AppColors.setTheme(appProvider.colorTheme);
        final localizations = AppLocalizations.of(context);

        return Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppColors.backgroundGradient,
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header con botón de regreso
                    _buildHeader(context),
                    const SizedBox(height: 32),
                    
                    // Layout principal: formulario a la izquierda, registro a la derecha
                    LayoutBuilder(
                      builder: (context, constraints) {
                        // En pantallas pequeñas, mostrar verticalmente
                        if (constraints.maxWidth < 800) {
                          return Column(
                            children: [
                              _buildEmotionForm(localizations),
                              const SizedBox(height: 24),
                              _buildRecentLog(localizations),
                            ],
                          );
                        }
                        // En pantallas grandes, mostrar horizontalmente
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 1,
                              child: _buildEmotionForm(localizations),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 1,
                              child: _buildRecentLog(localizations),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textLight),
          onPressed: () => Navigator.of(context).pop(),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Consumer<AppProvider>(
            builder: (context, appProvider, child) {
              final localizations = AppLocalizations.of(context);
              return Text(
                localizations?.emotionTrackingTitle ?? 'Seguimiento de Emociones',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textLight,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmotionForm(AppLocalizations? localizations) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.textLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.textLight.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations?.howDoYouFeelToday ?? '¿Cómo te sientes hoy?',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            localizations?.selectEmotionDescription ?? 'Selecciona la emoción que mejor describe tu estado actual',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textLight.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 24),
          
          // Grid de emociones
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.0, // Aumentado para dar más espacio vertical
            ),
            itemCount: _getEmotions(localizations).length,
            itemBuilder: (context, index) {
              final emotion = _getEmotions(localizations)[index];
              final isSelected = _selectedEmotion == emotion['id'];
              final icon = emotion['icon'] as IconData;
              final color = emotion['color'] as Color;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedEmotion = emotion['id'] as String;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? color.withValues(alpha: 0.12)
                        : AppColors.textLight.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected 
                          ? color
                          : color.withValues(alpha: 0.4),
                      width: isSelected ? 3 : 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                              spreadRadius: 0,
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: color.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        padding: EdgeInsets.all(isSelected ? 6 : 5),
                        decoration: BoxDecoration(
                          color: AppColors.textLight.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected
                              ? Border.all(
                                  color: color,
                                  width: 2.5,
                                )
                              : null,
                        ),
                        child: Icon(
                          icon,
                          size: isSelected ? 26 : 24,
                          color: color,
                        ),
                      ),
                      SizedBox(height: isSelected ? 3 : 4),
                      Flexible(
                        child: Text(
                          emotion['name'] as String,
                          style: TextStyle(
                            fontSize: isSelected ? 11 : 10,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: AppColors.textLight,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(height: 1),
                        Icon(
                          Icons.check_circle,
                          size: 11,
                          color: color,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          
          // Campo de comentario
          Text(
            localizations?.commentOptional ?? 'Comentario (Opcional)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: localizations?.commentPlaceholder ?? 'Describe brevemente lo que sientes o el contexto...',
              hintStyle: TextStyle(color: AppColors.textLight.withValues(alpha: 0.6)),
              filled: true,
              fillColor: AppColors.textLight.withValues(alpha: 0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.textSecondary.withValues(alpha: 0.2),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.textSecondary.withValues(alpha: 0.2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.primaryPurple,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.error.withValues(alpha: 0.5),
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.error,
                  width: 2,
                ),
              ),
            ),
            style: TextStyle(color: AppColors.textLight),
          ),
          const SizedBox(height: 24),
          
          // Botón de registrar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _registerEmotion,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      localizations?.registerEmotion ?? 'Registrar Emoción',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentLog(AppLocalizations? localizations) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.textLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.textLight.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations?.recentLog ?? 'Registro Reciente',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            localizations?.recentEmotionsSubtitle ?? 'Tus últimas emociones registradas',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textLight.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 24),
          
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_recentEmotions.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.sentiment_neutral,
                      size: 64,
                      color: AppColors.textLight.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      localizations?.noEmotionsRegistered ?? 'No hay emociones registradas aún',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textLight.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._recentEmotions.map((emotion) => _buildEmotionCard(emotion)),
        ],
      ),
    );
  }

  Widget _buildEmotionCard(EmotionModel emotion) {
    final localizations = AppLocalizations.of(context);
    final emotions = _getEmotions(localizations);
    final emotionData = emotions.firstWhere(
      (e) => e['id'] == emotion.emotion,
      orElse: () => emotions[2], // Default a neutro
    );
    
    final icon = emotionData['icon'] as IconData;
    final color = emotionData['color'] as Color;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.textLight.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.textLight.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 24,
              color: color,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  emotionData['name'] as String,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textLight,
                  ),
                ),
                if (emotion.comment != null && emotion.comment!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    emotion.comment!,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textLight.withValues(alpha: 0.9),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  emotion.formattedDate,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          // Botón de eliminar
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: AppColors.error.withValues(alpha: 0.8),
              size: 20,
            ),
            onPressed: () => _showDeleteConfirmation(emotion, localizations),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmation(EmotionModel emotion, AppLocalizations? localizations) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppColors.backgroundGradient,
            ),
          ),
          child: AlertDialog(
            backgroundColor: AppColors.darkSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: AppColors.error.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.error.withValues(alpha: 0.2),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    localizations?.deleteEmotion ?? 'Eliminar emoción',
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '⚠️ ${localizations?.deleteEmotionConfirmation ?? '¿Estás seguro de que deseas eliminar esta emoción?'}',
                  style: TextStyle(
                    color: AppColors.textLight.withValues(alpha: 0.8),
                    fontSize: 14,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              // Botón Cancelar
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.textLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.textLight.withValues(alpha: 0.3),
                  ),
                ),
                child: FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    localizations?.cancel ?? 'Cancelar',
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              // Botón Eliminar
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3),
                  ),
                ),
                child: FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    localizations?.delete ?? 'Eliminar',
                    style: const TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed == true && emotion.id != null) {
      await _deleteEmotion(emotion.id!, localizations);
    }
  }

  Future<void> _deleteEmotion(int emotionId, AppLocalizations? localizations) async {
    try {
      final result = await EmotionService.deleteEmotion(emotionId);

      if (result['success'] == true) {
        // Recargar emociones recientes
        await _loadRecentEmotions();

        if (mounted) {
          CustomSnackBar.showSuccess(
            context,
            localizations?.emotionDeletedSuccessfully ?? 'Emoción eliminada exitosamente',
            icon: Icons.delete_sweep_rounded,
          );
        }
      } else {
        if (mounted) {
          CustomSnackBar.showError(
            context,
            result['error'] ?? (localizations?.errorDeletingEmotion ?? 'Error al eliminar emoción'),
            icon: Icons.error_outline_rounded,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(
          context,
          '${localizations?.errorDeletingEmotion ?? 'Error inesperado'}: $e',
          icon: Icons.error_outline_rounded,
        );
      }
    }
  }
}

