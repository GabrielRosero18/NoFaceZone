import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nofacezone/src/Custom/AppColors.dart';
import 'package:nofacezone/src/Custom/AppLocalizations.dart';
import 'package:nofacezone/src/Custom/AppMessages.dart';
import 'package:nofacezone/src/Custom/CustomSnackBar.dart';
import 'package:nofacezone/src/Custom/ProAnimations.dart';
import 'package:nofacezone/src/Providers/AppProvider.dart';
import 'package:nofacezone/src/Services/RewardService.dart';
import 'package:nofacezone/src/Services/PointsService.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int userPoints = 0; // Puntos del usuario
  bool _isLoading = true;
  List<Map<String, dynamic>> _allRewards = [];
  List<Map<String, dynamic>> _userRewards = [];
  int _lastTabIndex = 0;

  void _hapticTap() => HapticFeedback.selectionClick();
  void _hapticSuccess() => HapticFeedback.mediumImpact();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _lastTabIndex = _tabController.index;
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && _lastTabIndex != _tabController.index) {
        _lastTabIndex = _tabController.index;
        _hapticTap();
      }
    });
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Cargar puntos del usuario
      final pointsData = await RewardService.getUserPoints();
      if (pointsData != null) {
        userPoints = pointsData['puntos_actuales'] ?? 0;
      }

      // Cargar todas las recompensas
      _allRewards = await RewardService.getAllRewards();

      // Cargar recompensas del usuario
      _userRewards = await RewardService.getUserRewards();

      // Verificar si el usuario tiene recompensas por defecto
      // Si no tiene ninguna, desbloquearlas automáticamente
      final defaultRewards = _allRewards.where((r) => r['is_default'] == true).toList();
      bool hasAnyDefaultReward = false;
      
      for (final defaultReward in defaultRewards) {
        final rewardId = defaultReward['id'] as String;
        if (_isRewardUnlocked(rewardId)) {
          hasAnyDefaultReward = true;
          debugPrint('✅ Usuario ya tiene recompensa por defecto: $rewardId');
          break;
        }
      }

      // Si no tiene ninguna recompensa por defecto, desbloquearlas
      if (!hasAnyDefaultReward && defaultRewards.isNotEmpty) {
        debugPrint('🔓 Usuario no tiene recompensas por defecto, desbloqueando...');
        // Obtener el usuario actual
        final supabase = Supabase.instance.client;
        final currentUser = supabase.auth.currentUser;
        if (currentUser != null) {
          await RewardService.unlockDefaultRewards(currentUser.id);
          // Recargar recompensas después de desbloquear
          _userRewards = await RewardService.getUserRewards();
          debugPrint('✅ Recompensas por defecto desbloqueadas');
        }
      } else {
        debugPrint('ℹ️ Usuario ya tiene recompensas por defecto o no hay recompensas por defecto');
      }
    } catch (e) {
      debugPrint('Error al cargar datos de recompensas: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        AppColors.setTheme(appProvider.colorTheme);
        
        return Scaffold(
      appBar: AppBar(
        title: Builder(
          builder: (context) => Text(AppLocalizations.of(context)!.rewards),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _hapticTap();
            Navigator.of(context).pop();
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          onTap: (_) => _hapticTap(),
          labelColor: AppColors.textLight,
          unselectedLabelColor: AppColors.textLight.withValues(alpha: 0.6),
          indicatorColor: AppColors.accentBlue,
          indicatorWeight: 3,
          isScrollable: true,
          tabs: [
            Builder(
              builder: (context) => Tab(text: AppLocalizations.of(context)!.themes),
            ),
            Builder(
              builder: (context) => Tab(text: AppLocalizations.of(context)!.fonts),
            ),
            Builder(
              builder: (context) => Tab(text: AppLocalizations.of(context)!.messages),
            ),
            Builder(
              builder: (context) => Tab(text: AppLocalizations.of(context)!.badges),
            ),
          ],
        ),
      ),
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
          child: Column(
            children: [
              // Barra de puntos
              ProEntrance(
                delayMs: 60,
                child: _buildPointsBar(),
              ),
              // Contenido de las pestañas
              Expanded(
                child: ProEntrance(
                  delayMs: 120,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildThemesTab(),
                      _buildFontsTab(),
                      _buildMessagesTab(),
                      _buildBadgesTab(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
      },
    );
  }

  Widget _buildPointsBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.textLight.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textLight.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(
          children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.stars, color: Colors.amber, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Builder(
                  builder: (context) {
                    final localizations = AppLocalizations.of(context)!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizations.yourPoints,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textLight,
                          ),
                        ),
                        Text(
                          '$userPoints ${localizations.pointsText}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textLight,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            minHeight: 7,
                            value: (userPoints % 1000) / 1000,
                            backgroundColor: AppColors.textLight.withValues(alpha: 0.16),
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentBlue),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Función auxiliar para verificar si una recompensa está desbloqueada
  bool _isRewardUnlocked(String rewardId) {
    // La función obtener_recompensas_usuario devuelve todas las recompensas
    // con un campo esta_desbloqueada que indica si las tiene
    try {
      final userReward = _userRewards.firstWhere(
        (ur) => ur['recompensa_id'] == rewardId,
        orElse: () => {},
      );
      
      // Si no está en la lista, no está desbloqueada
      if (userReward.isEmpty) {
        debugPrint('🔒 Recompensa $rewardId NO encontrada en recompensas del usuario');
        return false;
      }
      
      // Verificar si está desbloqueada
      final isUnlocked = userReward['esta_desbloqueada'] == true;
      debugPrint('${isUnlocked ? '✅' : '🔒'} Recompensa $rewardId: ${isUnlocked ? 'DESBLOQUEADA' : 'BLOQUEADA'}');
      return isUnlocked;
    } catch (e) {
      debugPrint('❌ Error al verificar recompensa $rewardId: $e');
      return false;
    }
  }

  // Función auxiliar para obtener colores desde metadata
  List<Color> _getColorsFromMetadata(Map<String, dynamic>? metadata) {
    if (metadata == null) return [Colors.blue, Colors.purple];
    
    final colorsJson = metadata['colors'] as List?;
    if (colorsJson == null) return [Colors.blue, Colors.purple];
    
    return colorsJson.map((c) {
      final colorStr = c.toString().replaceAll('#', '');
      return Color(int.parse('FF$colorStr', radix: 16));
    }).toList();
  }

  // Función auxiliar para obtener icono desde icon_name
  IconData _getIconFromName(String? iconName) {
    if (iconName == null) return Icons.star;
    
    switch (iconName) {
      case 'water_drop': return Icons.water_drop;
      case 'wb_twilight': return Icons.wb_twilight;
      case 'park': return Icons.park;
      case 'local_florist': return Icons.local_florist;
      case 'whatshot': return Icons.whatshot;
      case 'nights_stay': return Icons.nights_stay;
      case 'text_fields': return Icons.text_fields;
      case 'message': return Icons.message;
      case 'directions_walk': return Icons.directions_walk;
      case 'calendar_today': return Icons.calendar_today;
      case 'star': return Icons.star;
      case 'access_time': return Icons.access_time;
      case 'wb_sunny': return Icons.wb_sunny;
      case 'local_fire_department': return Icons.local_fire_department;
      case 'flag': return Icons.flag;
      case 'spa': return Icons.spa;
      case 'speed': return Icons.speed;
      case 'emoji_events': return Icons.emoji_events;
      default: return Icons.star;
    }
  }

  // Función auxiliar para mapear ID de fuente de BD a ID de AppFonts
  String _mapFontId(String dbFontId) {
    // font_default -> default, font_elegant -> elegant, etc.
    if (dbFontId.startsWith('font_')) {
      return dbFontId.substring(5); // Remover 'font_' del inicio
    }
    return dbFontId;
  }

  // Función auxiliar para mapear ID de mensaje de BD a ID de AppMessages
  String _mapMessageId(String dbMessageId) {
    // message_daily -> daily, message_achievements -> achievements, etc.
    if (dbMessageId.startsWith('message_')) {
      return dbMessageId.substring(8); // Remover 'message_' del inicio
    }
    return dbMessageId;
  }

  // Función auxiliar para obtener mensajes reales desde AppMessages
  List<String> _getMessagesFromCollection(String collectionId, AppLocalizations localizations) {
    try {
      final messages = AppMessages.getMessagesByCollection(collectionId, localizations);
      if (messages != null && messages.isNotEmpty) {
        // Tomar solo los primeros 3 mensajes como ejemplos
        return messages.take(3).toList();
      }
    } catch (e) {
      debugPrint('Error al obtener mensajes de la colección $collectionId: $e');
    }
    return [];
  }

  // Función auxiliar para calcular el progreso real de un badge basado en días consecutivos
  Future<double> _calculateBadgeProgress(String badgeId, int consecutiveDays) async {
    // Mapeo de badges a sus objetivos en días (según las descripciones en la BD)
    final badgeGoals = {
      'badge_first_steps': 3,        // Completa 3 días consecutivos
      'badge_week_warrior': 7,       // Completa 7 días consecutivos
      'badge_month_master': 30,       // Completa 30 días consecutivos
      'badge_streak_master': 30,     // Mantén 30 días consecutivos
      'badge_unstoppable': 50,       // Completa 50 días consecutivos
      'badge_legend': 100,          // Completa 100 días consecutivos
    };

    final goal = badgeGoals[badgeId];
    if (goal == null) {
      // Si no es un badge de días consecutivos, retornar 0
      return 0.0;
    }

    // Calcular progreso: min(1.0, días_consecutivos / objetivo)
    final progress = (consecutiveDays / goal).clamp(0.0, 1.0);
    debugPrint('📊 Badge $badgeId: $consecutiveDays días / $goal objetivo = ${(progress * 100).toStringAsFixed(1)}%');
    return progress;
  }

  // Función auxiliar para obtener días consecutivos del usuario
  Future<int> _getUserConsecutiveDays() async {
    try {
      return await PointsService.getConsecutiveDays();
    } catch (e) {
      debugPrint('Error al obtener días consecutivos: $e');
      return 0;
    }
  }

  Widget _buildLoadingPlaceholder({bool grid = false}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSkeletonBlock(height: 24, widthFactor: 0.45),
          const SizedBox(height: 10),
          _buildSkeletonBlock(height: 14, widthFactor: 0.7),
          const SizedBox(height: 22),
          if (grid)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: 4,
              itemBuilder: (context, index) => _buildSkeletonCard(height: 180, delayMs: index * 60),
            )
          else
            ...List.generate(
              5,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildSkeletonCard(height: 108, delayMs: index * 50),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSkeletonCard({required double height, int delayMs = 0}) {
    return ProEntrance(
      delayMs: delayMs,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 1100),
        tween: Tween<double>(begin: 0.45, end: 0.75),
        curve: Curves.easeInOut,
        builder: (context, value, child) => Opacity(opacity: value, child: child),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: AppColors.textLight.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.textLight.withValues(alpha: 0.16)),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonBlock({required double height, required double widthFactor}) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.textLight.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, {IconData icon = Icons.hourglass_empty_rounded}) {
    return Center(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 340),
        child: Container(
          key: ValueKey<String>(message),
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.textLight.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.textLight.withValues(alpha: 0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.textLight.withValues(alpha: 0.85), size: 28),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemesTab() {
    if (_isLoading) {
      return _buildLoadingPlaceholder(grid: true);
    }

    return Builder(
      builder: (context) {
        final localizations = AppLocalizations.of(context)!;
        
        // Filtrar solo temas
        final themeRewards = _allRewards.where((r) => r['tipo_recompensa_id'] == 'theme').toList();
        
        final themes = themeRewards.map((reward) {
          final rewardId = reward['id'] as String;
          // Solo desbloqueado si realmente lo tiene en recompensas_usuario
          final isUnlocked = _isRewardUnlocked(rewardId);
          final colors = _getColorsFromMetadata(reward['metadata']);
          
          return _RewardTheme(
            id: rewardId,
            name: reward['name_es'] ?? reward['name'] ?? '',
            description: reward['description_es'] ?? reward['description'] ?? '',
            colors: colors.isNotEmpty ? colors : [Colors.blue, Colors.purple],
            price: reward['price'] ?? 0,
            unlocked: isUnlocked, // Solo desbloqueado si está en recompensas_usuario
            icon: _getIconFromName(reward['icon_name']),
          );
        }).toList();
        
        if (themes.isEmpty) {
          return _buildEmptyState('No hay temas disponibles', icon: Icons.palette_outlined);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localizations.colorThemes,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                localizations.unlockThemesDescription,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textLight.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 20),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: themes.length,
                itemBuilder: (context, index) {
                  return ProEntrance(
                    delayMs: 60 + (index * 45),
                    child: _buildThemeCard(themes[index]),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeCard(_RewardTheme theme) {
    return Builder(
      builder: (context) {
        final localizations = AppLocalizations.of(context)!;
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        final currentTheme = Provider.of<AppProvider>(context).colorTheme;
        final isSelected = currentTheme == theme.id;

        return ProPressable(
          onTap: () async {
            _hapticTap();
            // Verificar si está desbloqueada (actualizar verificación en tiempo real)
            final isUnlocked = _isRewardUnlocked(theme.id);
            
            // Si no está desbloqueada, intentar comprarla
            if (!isUnlocked && !theme.unlocked) {
              // Si tiene puntos suficientes, comprarla
              if (userPoints >= theme.price) {
                final result = await RewardService.purchaseReward(theme.id);
                if (result['success'] == true) {
                  _hapticSuccess();
                  // Actualizar puntos inmediatamente
                  userPoints = (result['puntos_restantes'] ?? userPoints - theme.price) as int;
                  
                  // Recargar datos para actualizar el estado de recompensas
                  await _loadData();
                  
                  // Mapear el ID de la base de datos (theme_ocean) al ID de AppColors (ocean)
                  final themeId = theme.id.startsWith('theme_') 
                      ? theme.id.substring(6) // Remover 'theme_' del inicio
                      : theme.id;
                  
                  debugPrint('🎨 Aplicando tema comprado: ${theme.id} -> $themeId');
                  
                  // Aplicar el tema inmediatamente después de comprarlo
                  await appProvider.setColorTheme(themeId);
                  
                  // Forzar reconstrucción del widget
                  if (mounted) {
                    setState(() {});
                  }
                  
                  if (context.mounted) {
                    CustomSnackBar.showTheme(
                      context,
                      localizations.themeApplied(theme.name),
                      icon: Icons.palette_rounded,
                      gradientColors: theme.colors,
                      duration: const Duration(milliseconds: 1000),
                    );
                  }
                } else {
                  if (context.mounted) {
                    CustomSnackBar.showError(
                      context,
                      result['error'] ?? 'Error al comprar recompensa',
                    );
                  }
                }
              } else {
                // No tiene puntos suficientes
                if (context.mounted) {
                  CustomSnackBar.showWarning(
                    context,
                    'Necesitas ${theme.price} puntos para desbloquear este tema',
                    icon: Icons.lock_rounded,
                  );
                }
              }
              return;
            }
            
            // Si está desbloqueada, aplicarla directamente
            if (isUnlocked || theme.unlocked) {
              // Mapear el ID de la base de datos (theme_ocean) al ID de AppColors (ocean)
              final themeId = theme.id.startsWith('theme_') 
                  ? theme.id.substring(6) // Remover 'theme_' del inicio
                  : theme.id;
              
              debugPrint('🎨 Aplicando tema: ${theme.id} -> $themeId');
              await appProvider.setColorTheme(themeId);
              
              if (context.mounted) {
                CustomSnackBar.showTheme(
                  context,
                  localizations.themeApplied(theme.name),
                  icon: Icons.palette_rounded,
                  gradientColors: theme.colors,
                  duration: const Duration(milliseconds: 1000),
                );
              }
            }
          },
          child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: theme.colors,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AppColors.textLight
                  : theme.unlocked
                      ? AppColors.textLight.withValues(alpha: 0.3)
                      : AppColors.textLight.withValues(alpha: 0.1),
              width: isSelected ? 3 : 2,
            ),
          boxShadow: [
            BoxShadow(
              color: theme.colors[0].withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(theme.icon, color: Colors.white, size: 28),
                      if (isSelected)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.check_circle, color: Colors.white, size: 20),
                        )
                      else if (!theme.unlocked)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.lock, color: Colors.white, size: 16),
                        ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        theme.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        theme.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  if (!theme.unlocked)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.stars, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${theme.price}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                    else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.4)
                            : Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSelected ? Icons.star : Icons.check_circle,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isSelected ? localizations.active : localizations.available,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
      },
    );
  }

  Widget _buildFontsTab() {
    if (_isLoading) {
      return _buildLoadingPlaceholder();
    }

    return Builder(
      builder: (context) {
        final localizations = AppLocalizations.of(context)!;
        
        // Filtrar solo fuentes
        final fontRewards = _allRewards.where((r) => r['tipo_recompensa_id'] == 'font').toList();
        
        final fonts = fontRewards.map((reward) {
          final rewardId = reward['id'] as String;
          final isUnlocked = _isRewardUnlocked(rewardId);
          final fontId = _mapFontId(rewardId); // Mapear font_default -> default
          
          return _RewardFont(
            id: fontId, // Usar el ID mapeado para AppFonts
            name: reward['name_es'] ?? reward['name'] ?? '',
            description: reward['description_es'] ?? reward['description'] ?? '',
            unlocked: isUnlocked,
            price: reward['price'] ?? 0,
          );
        }).toList();
        
        if (fonts.isEmpty) {
          return _buildEmptyState('No hay fuentes disponibles', icon: Icons.text_fields_rounded);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localizations.fontTypes,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                localizations.customizeFontsDescription,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textLight.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 20),
              ...fonts.asMap().entries.map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ProEntrance(
                      delayMs: 60 + (entry.key * 40),
                      child: _buildFontCard(entry.value),
                    ),
                  )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFontCard(_RewardFont font) {
    return Builder(
      builder: (context) {
        final localizations = AppLocalizations.of(context)!;
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        final currentFont = Provider.of<AppProvider>(context).fontFamily;
        final isSelected = currentFont == font.id;

        return ProPressable(
          onTap: () async {
            _hapticTap();
            // Obtener el ID de la BD para verificar/comprar
            final fontReward = _allRewards.firstWhere(
              (r) => r['tipo_recompensa_id'] == 'font' && _mapFontId(r['id'] as String) == font.id,
              orElse: () => <String, dynamic>{},
            );
            
            if (fontReward.isEmpty) return;
            
            final dbFontId = fontReward['id'] as String;
            final isUnlocked = _isRewardUnlocked(dbFontId);
            
            // Si no está desbloqueada, intentar comprarla
            if (!isUnlocked && !font.unlocked) {
              // Si tiene puntos suficientes, comprarla
              if (userPoints >= font.price) {
                final result = await RewardService.purchaseReward(dbFontId);
                if (result['success'] == true) {
                  _hapticSuccess();
                  // Actualizar puntos inmediatamente
                  userPoints = (result['puntos_restantes'] ?? userPoints - font.price) as int;
                  
                  // Recargar datos para actualizar el estado
                  await _loadData();
                  
                  // Aplicar la fuente inmediatamente después de comprarla
                  await appProvider.setFontFamily(font.id);
                  
                  // Forzar reconstrucción del widget
                  if (mounted) {
                    setState(() {});
                  }
                  
                  if (context.mounted) {
                    CustomSnackBar.showSuccess(
                      context,
                      localizations.fontApplied(font.name),
                      icon: Icons.text_fields_rounded,
                      duration: const Duration(milliseconds: 1000),
                    );
                  }
                } else {
                  if (context.mounted) {
                    CustomSnackBar.showError(
                      context,
                      result['error'] ?? 'Error al comprar fuente',
                    );
                  }
                }
              } else {
                // No tiene puntos suficientes
                if (context.mounted) {
                  CustomSnackBar.showWarning(
                    context,
                    'Necesitas ${font.price} puntos para desbloquear esta fuente',
                    icon: Icons.lock_rounded,
                  );
                }
              }
              return;
            }
            
            // Si está desbloqueada, aplicarla directamente
            if (isUnlocked || font.unlocked) {
              await appProvider.setFontFamily(font.id);
              if (context.mounted) {
                CustomSnackBar.showSuccess(
                  context,
                  localizations.fontApplied(font.name),
                  icon: Icons.text_fields_rounded,
                  duration: const Duration(milliseconds: 1000),
                );
              }
            }
          },
          child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.textLight.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.textLight
                : font.unlocked
                    ? AppColors.accentBlue.withValues(alpha: 0.5)
                    : AppColors.textLight.withValues(alpha: 0.2),
            width: isSelected ? 2.5 : 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: font.unlocked
                    ? LinearGradient(colors: AppColors.accentGradient)
                    : null,
                color: font.unlocked ? null : AppColors.textLight.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                font.unlocked ? Icons.text_fields : Icons.lock,
                color: AppColors.textLight,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    font.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textLight,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    font.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textLight.withValues(alpha: 0.8),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (!font.unlocked)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stars, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${font.price}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.3)
                      : Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSelected ? Icons.star : Icons.check_circle,
                      color: isSelected ? Colors.white : Colors.green,
                      size: 18,
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 4),
                      Text(
                        localizations.active,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
        );
      },
    );
  }

  Widget _buildMessagesTab() {
    if (_isLoading) {
      return _buildLoadingPlaceholder();
    }

    return Builder(
      builder: (context) {
        final localizations = AppLocalizations.of(context)!;
        
        // Filtrar solo mensajes
        final messageRewards = _allRewards.where((r) => r['tipo_recompensa_id'] == 'message').toList();
        
        final messages = messageRewards.map((reward) {
          final rewardId = reward['id'] as String;
          final isUnlocked = _isRewardUnlocked(rewardId);
          final messageId = _mapMessageId(rewardId); // Mapear message_daily -> daily
          // Obtener mensajes reales desde AppMessages en lugar de metadata
          final examples = _getMessagesFromCollection(messageId, localizations);
          
          return _MotivationalMessage(
            id: messageId, // Usar el ID mapeado para AppMessages
            title: reward['name_es'] ?? reward['name'] ?? '',
            description: reward['description_es'] ?? reward['description'] ?? '',
            unlocked: isUnlocked,
            price: reward['price'] ?? 0,
            examples: examples.isNotEmpty ? examples : [
              localizations.messageExample1,
              localizations.messageExample2,
              localizations.messageExample3,
            ],
          );
        }).toList();
        
        if (messages.isEmpty) {
          return _buildEmptyState(
            'No hay colecciones de mensajes disponibles',
            icon: Icons.mark_email_unread_outlined,
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localizations.motivationalMessages,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                localizations.unlockMessagesDescription,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textLight.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 20),
              ...messages.asMap().entries.map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: ProEntrance(
                      delayMs: 60 + (entry.key * 35),
                      child: _buildMessageCard(entry.value),
                    ),
                  )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageCard(_MotivationalMessage message) {
    return Builder(
      builder: (context) {
        final localizations = AppLocalizations.of(context)!;
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        final activeCollections = Provider.of<AppProvider>(context).activeMessageCollections;
        final isActive = activeCollections.contains(message.id);

        return ProPressable(
          onTap: () async {
            _hapticTap();
            // Obtener el ID de la BD para verificar/comprar
            final messageReward = _allRewards.firstWhere(
              (r) => r['tipo_recompensa_id'] == 'message' && _mapMessageId(r['id'] as String) == message.id,
              orElse: () => <String, dynamic>{},
            );
            
            if (messageReward.isEmpty) return;
            
            final dbMessageId = messageReward['id'] as String;
            
            final isUnlocked = _isRewardUnlocked(dbMessageId);
            
            // Si no está desbloqueada, intentar comprarla
            if (!isUnlocked && !message.unlocked) {
              // Si tiene puntos suficientes, comprarla
              if (userPoints >= message.price) {
                final result = await RewardService.purchaseReward(dbMessageId);
                if (result['success'] == true) {
                  _hapticSuccess();
                  // Actualizar puntos inmediatamente
                  userPoints = (result['puntos_restantes'] ?? userPoints - message.price) as int;
                  
                  // Recargar datos para actualizar el estado
                  await _loadData();
                  
                  // Activar la colección después de comprarla
                  await appProvider.addMessageCollection(message.id);
                  
                  // Forzar reconstrucción del widget
                  if (mounted) {
                    setState(() {});
                  }
                  
                  if (context.mounted) {
                    CustomSnackBar.showSuccess(
                      context,
                      localizations.collectionActivated(message.title),
                      icon: Icons.toggle_on_rounded,
                    );
                  }
                } else {
                  if (context.mounted) {
                    CustomSnackBar.showError(
                      context,
                      result['error'] ?? 'Error al comprar colección',
                    );
                  }
                }
              } else {
                // No tiene puntos suficientes
                if (context.mounted) {
                  CustomSnackBar.showWarning(
                    context,
                    'Necesitas ${message.price} puntos para desbloquear esta colección',
                    icon: Icons.lock_rounded,
                  );
                }
              }
              return;
            }
            
            // Si está desbloqueada, activar/desactivar
            if (isUnlocked || message.unlocked) {
              await appProvider.toggleMessageCollection(message.id);
              if (context.mounted) {
                if (isActive) {
                  CustomSnackBar.showWarning(
                    context,
                    localizations.collectionDeactivated(message.title),
                    icon: Icons.toggle_off_rounded,
                  );
                } else {
                  CustomSnackBar.showSuccess(
                    context,
                    localizations.collectionActivated(message.title),
                    icon: Icons.toggle_on_rounded,
                  );
                }
              }
            }
          },
          child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.textLight.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? AppColors.textLight
                : message.unlocked
                    ? AppColors.accentPurple.withValues(alpha: 0.5)
                    : AppColors.textLight.withValues(alpha: 0.2),
            width: isActive ? 2.5 : 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: message.unlocked
                      ? LinearGradient(colors: AppColors.accentGradient)
                      : null,
                  color: message.unlocked ? null : AppColors.textLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  message.unlocked ? Icons.message : Icons.lock,
                  color: AppColors.textLight,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textLight,
                      ),
                    ),
                    Text(
                      message.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textLight.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              if (!message.unlocked)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.stars, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${message.price}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.white.withValues(alpha: 0.3)
                        : Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isActive ? Icons.star : Icons.check_circle,
                        color: isActive ? Colors.white : Colors.green,
                        size: 18,
                      ),
                      if (isActive) ...[
                        const SizedBox(width: 4),
                        Text(
                          localizations.active,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
          if (message.unlocked) ...[
            const SizedBox(height: 16),
            ...message.examples.map((example) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.textLight.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      example,
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textLight.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                )),
          ],
        ],
        ),
      ),
        );
      },
    );
  }

  Widget _buildBadgesTab() {
    if (_isLoading) {
      return _buildLoadingPlaceholder();
    }

    return FutureBuilder<int>(
      future: _getUserConsecutiveDays(),
      builder: (context, snapshot) {
        final consecutiveDays = snapshot.data ?? 0;
        final localizations = AppLocalizations.of(context)!;
        
        // Filtrar solo badges
        final badgeRewards = _allRewards.where((r) => r['tipo_recompensa_id'] == 'badge').toList();
        
        return FutureBuilder<List<_RewardBadge>>(
          future: Future.wait(badgeRewards.map((reward) async {
          final rewardId = reward['id'] as String;
          // Solo desbloqueado si realmente lo tiene en recompensas_usuario
          final isUnlocked = _isRewardUnlocked(rewardId);
          final metadata = reward['metadata'] as Map<String, dynamic>?;
          final colorHex = metadata?['color'] as String? ?? '#2196F3';
          
          // Calcular progreso real basado en días consecutivos
          double progress;
          if (isUnlocked) {
            // Si está desbloqueado, mostrar 100%
            progress = 1.0;
          } else {
            // Calcular progreso real basado en días consecutivos
            progress = await _calculateBadgeProgress(rewardId, consecutiveDays);
          }
          
          // Convertir color hex a Color
          Color badgeColor;
          try {
            final colorStr = colorHex.toString().replaceAll('#', '');
            badgeColor = Color(int.parse('FF$colorStr', radix: 16));
          } catch (e) {
            badgeColor = Colors.blue;
          }
          
            return _RewardBadge(
              id: rewardId,
              name: reward['name_es'] ?? reward['name'] ?? '',
              description: reward['description_es'] ?? reward['description'] ?? '',
              icon: _getIconFromName(reward['icon_name']),
              color: badgeColor,
              unlocked: isUnlocked, // Solo desbloqueado si está en recompensas_usuario
              progress: progress,
            );
          })),
          builder: (context, badgesSnapshot) {
            if (!badgesSnapshot.hasData) {
              return _buildLoadingPlaceholder();
            }
            
            final badges = badgesSnapshot.data!;
            
            if (badges.isEmpty) {
              return _buildEmptyState('No hay badges disponibles', icon: Icons.workspace_premium_outlined);
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.badgesAndAchievements,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    localizations.unlockBadgesDescription,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textLight.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ...badges.asMap().entries.map((entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: ProEntrance(
                          delayMs: 60 + (entry.key * 35),
                          child: _buildBadgeCard(entry.value),
                        ),
                      )),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBadgeCard(_RewardBadge badge) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.textLight.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: badge.unlocked
              ? badge.color.withValues(alpha: 0.5)
              : AppColors.textLight.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: badge.unlocked
                  ? badge.color.withValues(alpha: 0.2)
                  : AppColors.textLight.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: badge.unlocked ? badge.color : AppColors.textLight.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: Icon(
              badge.unlocked ? badge.icon : Icons.lock,
              color: badge.unlocked ? badge.color : AppColors.textLight.withValues(alpha: 0.5),
              size: 36,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  badge.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  badge.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textLight.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 8),
                if (!badge.unlocked)
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.textLight.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: badge.progress,
                      child: Container(
                        decoration: BoxDecoration(
                          color: badge.color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (badge.unlocked)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.check_circle, color: Colors.green, size: 28),
            )
          else
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.textLight.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${(badge.progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textLight.withValues(alpha: 0.7),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Modelos de datos
class _RewardTheme {
  final String id;
  final String name;
  final String description;
  final List<Color> colors;
  final int price;
  final bool unlocked;
  final IconData icon;

  _RewardTheme({
    required this.id,
    required this.name,
    required this.description,
    required this.colors,
    required this.price,
    required this.unlocked,
    required this.icon,
  });
}

class _RewardFont {
  final String id;
  final String name;
  final String description;
  final int price;
  final bool unlocked;

  _RewardFont({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.unlocked,
  });
}

class _MotivationalMessage {
  final String id;
  final String title;
  final String description;
  final List<String> examples;
  final int price;
  final bool unlocked;

  _MotivationalMessage({
    required this.id,
    required this.title,
    required this.description,
    required this.examples,
    required this.price,
    required this.unlocked,
  });
}

class _RewardBadge {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final bool unlocked;
  final double progress;

  _RewardBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.unlocked,
    required this.progress,
  });
}
