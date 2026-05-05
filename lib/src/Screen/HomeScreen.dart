import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:nofacezone/src/Custom/AppColors.dart';
import 'package:nofacezone/src/Custom/AppLocalizations.dart';
import 'package:nofacezone/src/Custom/AppMessages.dart';
import 'package:nofacezone/src/Custom/CustomSnackBar.dart';
import 'package:nofacezone/src/Custom/ProAnimations.dart';
import 'package:nofacezone/src/Providers/UserProvider.dart';
import 'package:nofacezone/src/Providers/AppProvider.dart';
import 'package:nofacezone/src/Services/PointsService.dart';
import 'package:nofacezone/src/Services/UsageLimitsService.dart';
import 'package:nofacezone/src/Services/PreferencesService.dart';
import 'package:nofacezone/src/Services/NearbyRecommendationsService.dart';
import 'package:nofacezone/src/Screen/UsageLimitBlockedScreen.dart';
import 'package:nofacezone/src/Screen/EditProfileScreen.dart';
import 'package:nofacezone/src/Custom/Library.dart';
import 'package:nofacezone/src/Custom/AppImageProviders.dart';
import 'package:nofacezone/src/Custom/time_remaining_clock_painters.dart';

enum _BlockReason { dailyLimit, nightBlock, mandatoryBreak }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _animationController;
  late AnimationController _ambientGlowController;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideAnimation;
  Timer? _usageTimer;
  int _remainingMinutes = 0;
  int _dailyLimitMinutes = 60;
  int? _currentSessionId;
  DateTime? _localSessionStartAt;
  bool _isBlockedScreenShown = false;
  bool _isLoadingUsageData = false;
  bool _hasLoadedUsageData = false;
  DateTime? _blockDismissedTime; // Ventana de gracia temporal para bloqueo diario
  DateTime? _dailyBlockDismissedUntil; // "Quitar bloqueo por hoy" (hasta fin del día)
  DateTime? _nightBlockDismissedTime;
  DateTime? _mandatoryBreakDismissedTime;
  /// Última carga completa de uso (para espaciar llamadas a red desde el timer periódico).
  DateTime? _lastUsageDataFetchAt;

  int _consecutiveDaysWithEmotions = 0;
  double _weeklyProgressFactor = 0.0;
  int _weeklyDaysWithUsage = 0;
  String _nightWindowLabel = '—';
  String _pauseIntervalLabel = '—';
  int? _minutesToNextMandatoryPause;
  int _mandatoryPauseIntervalMinutes = 30;
  bool _isInNightBlockWindow = false;
  String _dailyMotivationMessage = '';
  /// Incluye día e idioma para que el mensaje se regenere al cambiar locale.
  String _dailyMotivationCacheKey = '';
  List<_ActivityRecommendation> _activeActivityRecommendations = [];
  Set<String> _completedActivityIds = <String>{};
  int _activityShuffleSeed = 0;
  String _activityStateDateKey = '';
  Map<String, int> _activityCompletionByDay = <String, int>{};
  bool _isLoadingNearbyPlaces = false;
  String? _nearbyPlacesError;
  List<NearbyPlace> _nearbyPlaces = <NearbyPlace>[];
  bool _nearbyPermissionDeniedForever = false;
  bool _nearbyLocationServiceDisabled = false;
  String _nearbyCategoryFilter = 'all';
  bool _nearbyShowExtendedList = false;
  Set<String> _favoriteNearbyPlaceIds = <String>{};

  static const String _activityDatePrefKey = 'activity_recommendations_date_v1';
  static const String _activityCompletedPrefKey = 'activity_recommendations_completed_v1';
  static const String _activitySeedPrefKey = 'activity_recommendations_seed_v1';
  static const String _activityHistoryPrefKey = 'activity_recommendations_history_v1';
  static const String _nearbyFavoritesPrefKey = 'nearby_places_favorites_v1';

  void _hapticLight() => HapticFeedback.selectionClick();
  void _hapticMedium() => HapticFeedback.mediumImpact();

  bool _useLiteEffects() {
    final media = MediaQuery.maybeOf(context);
    if (media == null) return false;
    return media.disableAnimations || media.size.width < 390;
  }

  String _todayDateKey() {
    final now = DateTime.now();
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    return '${now.year}-$mm-$dd';
  }

  String _resolveDailyMotivation(BuildContext context, AppLocalizations localizations) {
    final todayKey = _todayDateKey();
    final lang = Localizations.localeOf(context).languageCode;
    final cacheKey = '$todayKey|$lang';
    if (_dailyMotivationCacheKey != cacheKey || _dailyMotivationMessage.isEmpty) {
      _dailyMotivationCacheKey = cacheKey;
      _dailyMotivationMessage = AppMessages.getRandomMessage(localizations);
    }
    return _dailyMotivationMessage;
  }

  List<_ActivityRecommendation> _getRecommendedActivities(
    AppLocalizations loc,
    AppProvider app,
  ) {
    final riskRatio = app.dailyUsageLimit > 0
        ? (app.todayUsageMinutes / app.dailyUsageLimit)
        : 0.0;

    final highRisk = <_ActivityRecommendation>[
      _ActivityRecommendation(
        id: 'breathing',
        title: loc.activityBreathingTitle,
        subtitle: loc.activityBreathingSubtitle,
        minutes: 3,
        icon: Icons.self_improvement,
        color: Colors.purpleAccent,
      ),
      _ActivityRecommendation(
        id: 'walk',
        title: loc.activityWalkTitle,
        subtitle: loc.activityWalkSubtitle,
        minutes: 10,
        icon: Icons.directions_walk,
        color: Colors.green,
      ),
      _ActivityRecommendation(
        id: 'hydrate',
        title: loc.activityHydrateTitle,
        subtitle: loc.activityHydrateSubtitle,
        minutes: 2,
        icon: Icons.local_drink,
        color: Colors.blueAccent,
      ),
    ];

    final mediumRisk = <_ActivityRecommendation>[
      _ActivityRecommendation(
        id: 'stretch',
        title: loc.activityStretchTitle,
        subtitle: loc.activityStretchSubtitle,
        minutes: 7,
        icon: Icons.accessibility_new,
        color: Colors.orange,
      ),
      _ActivityRecommendation(
        id: 'read',
        title: loc.activityReadTitle,
        subtitle: loc.activityReadSubtitle,
        minutes: 12,
        icon: Icons.menu_book,
        color: Colors.teal,
      ),
      _ActivityRecommendation(
        id: 'journal',
        title: loc.activityJournalTitle,
        subtitle: loc.activityJournalSubtitle,
        minutes: 8,
        icon: Icons.edit_note,
        color: Colors.pinkAccent,
      ),
    ];

    final lowRisk = <_ActivityRecommendation>[
      _ActivityRecommendation(
        id: 'plan_day',
        title: loc.activityPlanDayTitle,
        subtitle: loc.activityPlanDaySubtitle,
        minutes: 10,
        icon: Icons.event_note,
        color: Colors.indigo,
      ),
      _ActivityRecommendation(
        id: 'tidy',
        title: loc.activityTidyTitle,
        subtitle: loc.activityTidySubtitle,
        minutes: 15,
        icon: Icons.cleaning_services,
        color: Colors.cyan,
      ),
      _ActivityRecommendation(
        id: 'learn',
        title: loc.activityLearnTitle,
        subtitle: loc.activityLearnSubtitle,
        minutes: 20,
        icon: Icons.lightbulb,
        color: Colors.amber,
      ),
    ];

    final source = riskRatio >= 0.9
        ? highRisk
        : (riskRatio >= 0.6 ? mediumRisk : lowRisk);
    final offset = DateTime.now().day % source.length;
    return List<_ActivityRecommendation>.generate(
      source.length,
      (i) => source[(i + offset) % source.length],
    );
  }

  String _todayActivityKey() {
    final now = DateTime.now();
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    return '${now.year}-$mm-$dd';
  }

  Future<void> _loadActivityState(AppLocalizations loc, AppProvider app) async {
    await PreferencesService.init();
    final todayKey = _todayActivityKey();
    final savedDate = PreferencesService.getString(_activityDatePrefKey) ?? '';
    final savedSeed = int.tryParse(PreferencesService.getString(_activitySeedPrefKey) ?? '0') ?? 0;
    final completedJson = PreferencesService.getString(_activityCompletedPrefKey);
    final historyJson = PreferencesService.getString(_activityHistoryPrefKey);
    final completed = <String>{};
    final history = <String, int>{};
    if (completedJson != null && completedJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(completedJson);
        if (decoded is List) {
          completed.addAll(decoded.map((e) => e.toString()));
        }
      } catch (_) {}
    }
    if (historyJson != null && historyJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(historyJson);
        if (decoded is Map) {
          decoded.forEach((k, v) {
            history[k.toString()] = (v as num).toInt();
          });
        }
      } catch (_) {}
    }

    if (savedDate != todayKey) {
      _activityShuffleSeed = DateTime.now().hour;
      _completedActivityIds = <String>{};
      _activityCompletionByDay = history;
      _activityStateDateKey = todayKey;
      _activeActivityRecommendations = _rotateRecommendations(
        _getRecommendedActivities(loc, app),
        _activityShuffleSeed,
      );
      await _saveActivityState();
      return;
    }

    _activityShuffleSeed = savedSeed;
    _completedActivityIds = completed;
    _activityCompletionByDay = history;
    _activityStateDateKey = todayKey;
    _activeActivityRecommendations = _rotateRecommendations(
      _getRecommendedActivities(loc, app),
      _activityShuffleSeed,
    );
  }

  Future<void> _saveActivityState() async {
    await PreferencesService.setString(_activityDatePrefKey, _activityStateDateKey);
    await PreferencesService.setString(_activitySeedPrefKey, _activityShuffleSeed.toString());
    await PreferencesService.setString(
      _activityCompletedPrefKey,
      jsonEncode(_completedActivityIds.toList()),
    );
    await PreferencesService.setString(
      _activityHistoryPrefKey,
      jsonEncode(_activityCompletionByDay),
    );
  }

  List<_ActivityRecommendation> _rotateRecommendations(
    List<_ActivityRecommendation> source,
    int seed,
  ) {
    if (source.isEmpty) return source;
    final offset = seed % source.length;
    return List<_ActivityRecommendation>.generate(
      source.length,
      (i) => source[(i + offset) % source.length],
    );
  }

  Future<void> _refreshActivities(AppLocalizations loc, AppProvider app) async {
    setState(() {
      _activityShuffleSeed += 1;
      _activeActivityRecommendations = _rotateRecommendations(
        _getRecommendedActivities(loc, app),
        _activityShuffleSeed,
      );
    });
    await _saveActivityState();
  }

  Future<void> _toggleActivityCompleted(_ActivityRecommendation rec, AppLocalizations loc) async {
    final isDone = _completedActivityIds.contains(rec.id);
    final dayKey = _todayActivityKey();
    setState(() {
      if (isDone) {
        _completedActivityIds.remove(rec.id);
        final current = _activityCompletionByDay[dayKey] ?? 0;
        _activityCompletionByDay[dayKey] = (current - 1).clamp(0, 99);
      } else {
        _completedActivityIds.add(rec.id);
        final current = _activityCompletionByDay[dayKey] ?? 0;
        _activityCompletionByDay[dayKey] = current + 1;
      }
    });
    await _saveActivityState();
    if (!isDone) {
      await PointsService.awardActivityCompletionPoints(
        activityId: rec.id,
        activityMinutes: rec.minutes,
      );
    }
    if (!mounted) return;
    CustomSnackBar.showTheme(
      context,
      isDone ? loc.activityMarkedPending : loc.activityCompletedMessage,
      icon: isDone ? Icons.undo : Icons.task_alt,
    );
  }

  Future<void> _syncActivityRecommendations(AppLocalizations loc, AppProvider app) async {
    final next = _rotateRecommendations(
      _getRecommendedActivities(loc, app),
      _activityShuffleSeed,
    );
    final validIds = next.map((e) => e.id).toSet();
    _completedActivityIds = _completedActivityIds.where(validIds.contains).toSet();
    if (mounted) {
      setState(() {
        _activeActivityRecommendations = next;
      });
    } else {
      _activeActivityRecommendations = next;
    }
    await _saveActivityState();
  }

  Future<void> _loadNearbyRecommendations({bool forceRefresh = false}) async {
    if (_isLoadingNearbyPlaces) return;
    setState(() {
      _isLoadingNearbyPlaces = true;
      _nearbyPlacesError = null;
    });

    try {
      final result = await NearbyRecommendationsService.fetchNearbyWellbeingPlaces(
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        _nearbyPlaces = result.places;
        _nearbyPlacesError = result.errorMessage;
        _nearbyPermissionDeniedForever = result.isPermissionDeniedForever;
        _nearbyLocationServiceDisabled = result.isLocationServiceDisabled;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _nearbyPlacesError = 'No se pudieron cargar lugares cercanos.';
        _nearbyPermissionDeniedForever = false;
        _nearbyLocationServiceDisabled = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingNearbyPlaces = false;
        });
      } else {
        _isLoadingNearbyPlaces = false;
      }
    }
  }

  Future<void> _loadNearbyFavorites() async {
    await PreferencesService.init();
    final raw = PreferencesService.getString(_nearbyFavoritesPrefKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        final ids = decoded.map((e) => e.toString()).toSet();
        if (!mounted) {
          _favoriteNearbyPlaceIds = ids;
          return;
        }
        setState(() {
          _favoriteNearbyPlaceIds = ids;
        });
      }
    } catch (_) {}
  }

  String _nearbyPlaceId(NearbyPlace place) {
    return '${place.name}|${place.lat.toStringAsFixed(5)}|${place.lng.toStringAsFixed(5)}';
  }

  Future<void> _toggleNearbyFavorite(NearbyPlace place) async {
    final placeId = _nearbyPlaceId(place);
    final updated = Set<String>.from(_favoriteNearbyPlaceIds);
    if (updated.contains(placeId)) {
      updated.remove(placeId);
    } else {
      updated.add(placeId);
    }
    if (mounted) {
      setState(() {
        _favoriteNearbyPlaceIds = updated;
      });
    } else {
      _favoriteNearbyPlaceIds = updated;
    }
    await PreferencesService.setString(
      _nearbyFavoritesPrefKey,
      jsonEncode(_favoriteNearbyPlaceIds.toList()),
    );
  }

  Future<void> _clearNearbyFavorites() async {
    if (mounted) {
      setState(() {
        _favoriteNearbyPlaceIds = <String>{};
      });
    } else {
      _favoriteNearbyPlaceIds = <String>{};
    }
    await PreferencesService.setString(_nearbyFavoritesPrefKey, jsonEncode(<String>[]));
  }

  Future<void> _openPlaceInMaps(NearbyPlace place) async {
    final lat = place.lat.toStringAsFixed(6);
    final lng = place.lng.toStringAsFixed(6);
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      CustomSnackBar.showWarning(
        context,
        'No se pudo abrir el mapa en este momento.',
        icon: Icons.map_outlined,
      );
    }
  }

  Widget _buildActivityRecommendations() {
    final loc = AppLocalizations.of(context)!;
    final app = Provider.of<AppProvider>(context, listen: false);
    final recs = _activeActivityRecommendations.isEmpty
        ? _getRecommendedActivities(loc, app)
        : _activeActivityRecommendations;
    final riskRatio = app.dailyUsageLimit > 0
        ? (app.todayUsageMinutes / app.dailyUsageLimit)
        : 0.0;

    final reason = riskRatio >= 0.9
        ? loc.activityReasonHighRisk
        : (riskRatio >= 0.6 ? loc.activityReasonMediumRisk : loc.activityReasonLowRisk);
    final doneCount = recs.where((r) => _completedActivityIds.contains(r.id)).length;
    final progress = recs.isEmpty ? 0.0 : (doneCount / recs.length).clamp(0.0, 1.0);
    final nowRec = recs.isEmpty ? null : recs[DateTime.now().hour % recs.length];
    final weekStats = _last7DaysActivityStats();
    final weekTotal = weekStats.fold<int>(0, (a, b) => a + b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.textLight.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textLight.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🧩 ${loc.activityRecommendationsTitle}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            reason,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textLight.withValues(alpha: 0.85),
            ),
          ),
          if (nowRec != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.textLight.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: nowRec.color.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Icon(Icons.flash_on, color: nowRec.color, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${loc.activityNowSuggestion}: ${nowRec.title} (${nowRec.minutes}${loc.minutesShort})',
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    minHeight: 8,
                    value: progress,
                    backgroundColor: AppColors.textLight.withValues(alpha: 0.2),
                    color: Colors.green,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$doneCount/${recs.length}',
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Column(
            children: recs.take(3).map((rec) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildActivityTile(rec, loc),
              );
            }).toList(),
          ),
          const SizedBox(height: 4),
          Text(
            '${loc.activityWeeklyDone}: $weekTotal',
            style: TextStyle(
              color: AppColors.textLight.withValues(alpha: 0.82),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          _buildActivityHistoryBars(weekStats),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _refreshActivities(loc, app),
              icon: const Icon(Icons.shuffle),
              label: Text(loc.activityRefresh),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyRecommendations() {
    final app = Provider.of<AppProvider>(context, listen: false);
    final filtered = _nearbyCategoryFilter == 'all'
        ? _nearbyPlaces
        : _nearbyPlaces.where((p) => p.category == _nearbyCategoryFilter).toList();
    final favorites = filtered.where((p) => _favoriteNearbyPlaceIds.contains(_nearbyPlaceId(p))).toList();
    final nonFavorites = filtered.where((p) => !_favoriteNearbyPlaceIds.contains(_nearbyPlaceId(p))).toList();
    final ordered = <NearbyPlace>[...favorites, ...nonFavorites];
    final visible = _nearbyShowExtendedList ? ordered.take(12).toList() : ordered.take(6).toList();
    final hasNoResultsForFilter = !_isLoadingNearbyPlaces && _nearbyPlaces.isNotEmpty && ordered.isEmpty;
    final usageRatio = app.dailyUsageLimit > 0
        ? (app.todayUsageMinutes / app.dailyUsageLimit)
        : 0.0;
    final nearbyMotivation = _buildNearbyMotivationalCopy(
      filter: _nearbyCategoryFilter,
      usageRatio: usageRatio,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.textLight.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textLight.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📍 Lugares cercanos para reemplazar el hábito',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _nearbyPlacesError ?? 'Parques, bibliotecas y espacios saludables cerca de ti.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textLight.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            nearbyMotivation,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textLight.withValues(alpha: 0.72),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (favorites.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.pinkAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.32)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.favorite, color: Colors.pinkAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Favoritos cercanos: ${favorites.length}',
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _clearNearbyFavorites,
                    child: const Text('Limpiar favoritos'),
                  ),
                ],
              ),
            ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildNearbyFilterChip('all', 'Todo'),
              _buildNearbyFilterChip('park', 'Parques'),
              _buildNearbyFilterChip('library', 'Bibliotecas'),
              _buildNearbyFilterChip('gym', 'Deporte'),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoadingNearbyPlaces)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (_nearbyPlaces.isEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextButton.icon(
                  onPressed: _loadNearbyRecommendations,
                  icon: const Icon(Icons.my_location),
                  label: const Text('Activar ubicación y recomendar lugares'),
                ),
                if (_nearbyPermissionDeniedForever) ...[
                  const SizedBox(height: 6),
                  FilledButton.icon(
                    onPressed: Geolocator.openAppSettings,
                    icon: const Icon(Icons.settings),
                    label: const Text('Abrir configuración de permisos'),
                  ),
                ] else if (_nearbyLocationServiceDisabled) ...[
                  const SizedBox(height: 6),
                  FilledButton.icon(
                    onPressed: Geolocator.openLocationSettings,
                    icon: const Icon(Icons.location_off),
                    label: const Text('Abrir ajustes de ubicación'),
                  ),
                ],
              ],
            )
          else
            ...visible.map((place) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.textLight.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      NearbyRecommendationsService.iconForCategory(place.category),
                      color: AppColors.accentBlue,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            place.name,
                            style: const TextStyle(
                              color: AppColors.textLight,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            place.address,
                            style: TextStyle(
                              color: AppColors.textLight.withValues(alpha: 0.75),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.accentBlue.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  NearbyRecommendationsService.categoryLabel(place.category),
                                  style: const TextStyle(
                                    color: AppColors.textLight,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                NearbyRecommendationsService.distanceLabel(place.distanceMeters),
                                style: TextStyle(
                                  color: AppColors.textLight.withValues(alpha: 0.78),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Favorito',
                      onPressed: () => _toggleNearbyFavorite(place),
                      icon: Icon(
                        _favoriteNearbyPlaceIds.contains(_nearbyPlaceId(place))
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: _favoriteNearbyPlaceIds.contains(_nearbyPlaceId(place))
                            ? Colors.pinkAccent
                            : AppColors.textLight,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Abrir en mapa',
                      onPressed: () => _openPlaceInMaps(place),
                      icon: const Icon(Icons.open_in_new, color: AppColors.textLight),
                    ),
                  ],
                ),
              );
            }),
          if (hasNoResultsForFilter)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.textLight.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'No hay resultados en este filtro para tu zona. Prueba "Todo" o recarga.',
                style: TextStyle(color: AppColors.textLight),
              ),
            ),
          if (!_isLoadingNearbyPlaces && _nearbyCategoryFilter != 'all')
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _loadNearbyRecommendations(forceRefresh: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Recargar esta categoría'),
              ),
            ),
          if (!_isLoadingNearbyPlaces && ordered.length > 6)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _nearbyShowExtendedList = !_nearbyShowExtendedList;
                  });
                },
                icon: Icon(_nearbyShowExtendedList ? Icons.expand_less : Icons.expand_more),
                label: Text(_nearbyShowExtendedList ? 'Ver menos' : 'Ver más lugares'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNearbyFilterChip(String value, String label) {
    final selected = _nearbyCategoryFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() {
          _nearbyCategoryFilter = value;
          _nearbyShowExtendedList = false;
        });
      },
      selectedColor: AppColors.textLight,
      backgroundColor: AppColors.textLight.withValues(alpha: 0.12),
      visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      labelStyle: TextStyle(
        color: selected ? AppColors.primaryBlue : AppColors.textLight,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  String _buildNearbyMotivationalCopy({
    required String filter,
    required double usageRatio,
  }) {
    final highUsage = usageRatio >= 0.85;
    final mediumUsage = usageRatio >= 0.6;

    switch (filter) {
      case 'park':
        if (highUsage) {
          return 'Has usado mucho Facebook hoy; salir a este parque puede romper el impulso y recargar tu enfoque.';
        }
        if (mediumUsage) {
          return 'Un paseo corto por un parque puede ayudarte a mantener el control del día.';
        }
        return 'Excelente ritmo: parque + aire libre para sostener tu progreso.';
      case 'library':
        if (highUsage) {
          return 'Si hoy te consumió Facebook, una biblioteca cercana puede darte un reset mental potente.';
        }
        if (mediumUsage) {
          return 'Biblioteca = entorno sin ruido digital para volver a lo importante.';
        }
        return 'Buen momento para invertir ese tiempo en lectura o estudio.';
      case 'gym':
        if (highUsage) {
          return 'Cuando sube el uso de Facebook, mover el cuerpo corta el ciclo rápido. Dale a deporte.';
        }
        if (mediumUsage) {
          return 'Una sesión corta de deporte puede bajar ansiedad y evitar recaídas.';
        }
        return 'Sigue así: actividad física para reforzar el hábito saludable.';
      default:
        if (highUsage) {
          return 'Has usado bastante Facebook hoy; elegir un lugar cercano ahora puede salvar tu día.';
        }
        if (mediumUsage) {
          return 'Vas a tiempo: elige un lugar cercano y cambia el impulso por una acción real.';
        }
        return 'Buen control hoy. Mantén la racha con una salida corta y consciente.';
    }
  }

  List<int> _last7DaysActivityStats() {
    final now = DateTime.now();
    final result = <int>[];
    for (var i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final key =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      result.add(_activityCompletionByDay[key] ?? 0);
    }
    return result;
  }

  Widget _buildActivityHistoryBars(List<int> values) {
    final maxV = values.fold<int>(1, (m, v) => v > m ? v : m);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(values.length, (i) {
        final v = values[i];
        final h = ((v / maxV).clamp(0.08, 1.0)) * 26;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$v',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textLight.withValues(alpha: 0.72),
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  height: h,
                  decoration: BoxDecoration(
                    color: AppColors.accentBlue.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildActivityTile(_ActivityRecommendation rec, AppLocalizations loc) {
    final done = _completedActivityIds.contains(rec.id);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.textLight.withValues(alpha: done ? 0.18 : 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (done ? Colors.green : rec.color).withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: rec.color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(rec.icon, color: rec.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rec.title,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${rec.subtitle} • ${rec.minutes}${loc.minutesShort}',
                  style: TextStyle(
                    color: AppColors.textLight.withValues(alpha: 0.82),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () => _toggleActivityCompleted(rec, loc),
            icon: Icon(done ? Icons.undo : Icons.task_alt, size: 18),
            label: Text(done ? loc.activityUndo : loc.activityDoIt),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 420),
      vsync: this,
    );
    _ambientGlowController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    
    _fadeInAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _animationController.value = 1.0;
        _ambientGlowController.value = 0.35;
      } else {
        _animationController.forward();
        _ambientGlowController.forward();
      }
    });
    
    // Registrar observer para detectar cambios en el ciclo de vida de la app
    WidgetsBinding.instance.addObserver(this);
    
    // Iniciar sesión de uso cuando se abre la app
    _startAppSession();
    
    // Cargar límites y tiempo restante después de iniciar sesión (con delay para evitar múltiples llamadas)
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _loadUsageData().then((_) {
          // Verificar límite después de cargar datos iniciales
          if (mounted && _remainingMinutes <= 0) {
            _showBlockedScreen(_BlockReason.dailyLimit);
          }
        });
      }
    });
    
    // Iniciar timer para actualizar cada 10 segundos (más frecuente)
    _startUsageTimer();
    
    // Mostrar mensaje motivacional después de que la pantalla se construya
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showWelcomeMessage();
      // Otorgar puntos por inicio de sesión diario
      PointsService.awardDailyLoginPoints();
      final loc = AppLocalizations.of(context);
      final app = Provider.of<AppProvider>(context, listen: false);
      if (loc != null) {
        _loadActivityState(loc, app).then((_) {
          if (mounted) setState(() {});
        });
      }
      _loadNearbyFavorites();
      _loadNearbyRecommendations();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        // App volvió a primer plano - iniciar nueva sesión
        _startAppSession();
        // Cargar datos después de un pequeño delay para evitar múltiples llamadas
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _loadUsageData();
            unawaited(
              Provider.of<AppProvider>(context, listen: false).syncLocalNotificationSchedule(),
            );
          }
        });
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // App fue a segundo plano - finalizar sesión actual
        _endAppSession();
        break;
      case AppLifecycleState.detached:
        // App está siendo cerrada - finalizar sesión
        _endAppSession();
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  /// Iniciar sesión de uso cuando se abre la app
  Future<void> _startAppSession() async {
    try {
      // Finalizar cualquier sesión activa anterior (por si acaso)
      final activeSessions = await UsageLimitsService.getActiveSessions();
      for (var session in activeSessions) {
        final sessionId = session['id'] as int;
        await UsageLimitsService.finishUsageSession(sessionId);
      }
      
      // Iniciar nueva sesión
      final sessionId = await UsageLimitsService.startUsageSession();
      if (sessionId != null) {
        _currentSessionId = sessionId;
        _localSessionStartAt = DateTime.now();
        
        if (!mounted) return;
        // Actualizar AppProvider
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        await appProvider.startUsageSession();
      }
    } catch (e) {
      debugPrint('Error starting app session: $e');
    }
  }

  /// Finalizar sesión cuando la app se cierra o va a segundo plano
  Future<void> _endAppSession() async {
    try {
      if (_currentSessionId != null) {
        await UsageLimitsService.finishUsageSession(_currentSessionId!);
        
        if (!mounted) return;
        // Actualizar AppProvider
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        await appProvider.finishUsageSession();
        
        _currentSessionId = null;
        _localSessionStartAt = null;
      }
    } catch (e) {
      debugPrint('Error ending app session: $e');
    }
  }

  /// Cargar datos de uso desde Supabase (optimizado)
  Future<void> _loadUsageData({bool fromPeriodicTimer = false}) async {
    if (fromPeriodicTimer && _lastUsageDataFetchAt != null) {
      final since = DateTime.now().difference(_lastUsageDataFetchAt!);
      if (since < const Duration(seconds: 8)) {
        return;
      }
    }
    // Prevenir múltiples llamadas simultáneas
    if (_isLoadingUsageData) {
      return;
    }

    if (mounted) {
      setState(() {
        _isLoadingUsageData = true;
      });
    } else {
      _isLoadingUsageData = true;
    }
    
    try {
      // Obtener datos de uso de manera más eficiente
      // Primero obtener el registro del día que ya contiene toda la información
      final todayUsage = await UsageLimitsService.getOrCreateTodayUsage();
      
      if (todayUsage == null) {
        if (mounted) {
          await _refreshHomeSummaryMetrics();
          setState(() {
            _hasLoadedUsageData = true;
          });
        } else {
          _hasLoadedUsageData = true;
        }
        return;
      }
      
      final limit = todayUsage['limite_del_dia_minutos'] as int? ?? 
                    await UsageLimitsService.getCurrentDailyLimit();
      final used = todayUsage['tiempo_usado_minutos'] as int? ?? 0;
      
      // Calcular tiempo restante considerando sesiones activas
      final remainingFromService = await UsageLimitsService.getRemainingTimeToday();

      // Fallback local: sumar minutos de sesión activa en vivo para evitar
      // depender totalmente de la sincronización de Supabase.
      int localActiveMinutes = 0;
      if (_localSessionStartAt != null) {
        final elapsed = DateTime.now().difference(_localSessionStartAt!).inMinutes;
        localActiveMinutes = elapsed.clamp(0, 24 * 60);
      }
      final localRemaining = (limit - (used + localActiveMinutes)).clamp(0, limit);
      final remaining = remainingFromService < localRemaining
          ? remainingFromService
          : localRemaining;
      
      if (mounted) {
        // Solo loggear si hay cambios significativos para mejorar rendimiento
        if ((_dailyLimitMinutes != limit || _remainingMinutes != remaining) && 
            (_remainingMinutes - remaining).abs() > 1) {
          debugPrint('📊 Datos de uso actualizados:');
          debugPrint('   Límite: $limit minutos');
          debugPrint('   Usado: $used minutos');
          debugPrint('   Sesión local activa: $localActiveMinutes minutos');
          debugPrint('   Restante (servicio): $remainingFromService minutos');
          debugPrint('   Restante (local): $localRemaining minutos');
          debugPrint('   Restante: $remaining minutos');
        }
        
        setState(() {
          _dailyLimitMinutes = limit;
          _remainingMinutes = remaining;
        });
        
        // Actualizar AppProvider de manera más eficiente (solo cuando es necesario)
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        // No actualizar cada vez, solo cuando hay cambios significativos
        if (appProvider.dailyUsageLimit != limit) {
          await appProvider.refreshUsageLimits();
        }
        if (!mounted) return;
        if (appProvider.todayUsageMinutes != used) {
          await appProvider.updateTodayUsage();
        }
        if (!mounted) return;
        
        // Verificar si se alcanzó el límite y mostrar pantalla de bloqueo.
        // Respeta "quitar bloqueo por hoy" y una gracia corta después de sumar tiempo.
        final now = DateTime.now();
        final isDailySnoozedForToday = _dailyBlockDismissedUntil != null &&
            now.isBefore(_dailyBlockDismissedUntil!);
        final isInDailyGraceWindow = _blockDismissedTime != null &&
            now.difference(_blockDismissedTime!).inMinutes < 3;
        final canShowBlock = !isDailySnoozedForToday && !isInDailyGraceWindow;
        
        // Solo loggear si hay cambios significativos
        if (remaining <= 0 || (remaining != _remainingMinutes && _remainingMinutes > 0)) {
          debugPrint('🔍 Verificación de bloqueo:');
          debugPrint('   Tiempo restante: $remaining minutos');
          debugPrint('   Bloqueo mostrado: $_isBlockedScreenShown');
          debugPrint('   Puede mostrar bloqueo: $canShowBlock');
        }
        
        // Verificar si el tiempo se acabó
        if (remaining <= 0 && !_isBlockedScreenShown && canShowBlock) {
          debugPrint('🚨 Tiempo agotado. Mostrando pantalla de bloqueo');
          _showBlockedScreen(_BlockReason.dailyLimit);
        } else if (remaining > 0 && _isBlockedScreenShown) {
          // Si hay tiempo restante y la pantalla está mostrada, cerrarla
          debugPrint('✅ Hay tiempo restante ($remaining min), cerrando bloqueo');
          _isBlockedScreenShown = false;
          _blockDismissedTime = null;
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        }

        // Bloqueo automático por horario nocturno (con cooldown de 5 min al quitar)
        final isInNightBlock = await UsageLimitsService.isInNightBlockTime();
        final canShowNightBlock = _nightBlockDismissedTime == null ||
            DateTime.now().difference(_nightBlockDismissedTime!).inMinutes >= 5;

        if (isInNightBlock && !_isBlockedScreenShown && remaining > 0 && canShowNightBlock) {
          debugPrint('🌙 Bloqueo nocturno activo. Mostrando pantalla de bloqueo.');
          _showBlockedScreen(_BlockReason.nightBlock);
        }

        // Bloqueo automático por pausas obligatorias (cuando llegue a 0 min al próximo descanso)
        final minutesToBreak = await UsageLimitsService.getTimeUntilNextBreak();
        final shouldShowBreakBlock = appProvider.mandatoryBreaksActive &&
            minutesToBreak != null &&
            minutesToBreak <= 0;
        final canShowBreakBlock = _mandatoryBreakDismissedTime == null ||
            DateTime.now().difference(_mandatoryBreakDismissedTime!).inMinutes >= 5;

        if (shouldShowBreakBlock &&
            !_isBlockedScreenShown &&
            remaining > 0 &&
            !isInNightBlock &&
            canShowBreakBlock) {
          debugPrint('⏸️ Pausa obligatoria alcanzada. Mostrando pantalla de bloqueo.');
          _showBlockedScreen(_BlockReason.mandatoryBreak);
        }

        await _refreshHomeSummaryMetrics();
        if (!mounted) return;
        final loc = AppLocalizations.of(context);
        if (loc != null) {
          await _syncActivityRecommendations(loc, appProvider);
        }

        _lastUsageDataFetchAt = DateTime.now();
      }
    } catch (e) {
      debugPrint('Error loading usage data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingUsageData = false;
          _hasLoadedUsageData = true;
        });
      } else {
        _isLoadingUsageData = false;
        _hasLoadedUsageData = true;
      }
    }
  }

  Future<void> _handlePullToRefresh() async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final localizations = AppLocalizations.of(context);

    await _loadUsageData();

    if (localizations != null) {
      await _syncActivityRecommendations(localizations, appProvider);
    }
    await _loadNearbyRecommendations();
  }

  /// Mostrar pantalla de bloqueo cuando se alcanza el límite
  void _showBlockedScreen(_BlockReason reason) {
    if (!mounted || _isBlockedScreenShown) return;
    
    _isBlockedScreenShown = true;
    PreferencesService.incrementBlockedSessionsCount();

    final isDailyLimit = reason == _BlockReason.dailyLimit;
    final title = switch (reason) {
      _BlockReason.dailyLimit => '⏰ Límite Alcanzado',
      _BlockReason.nightBlock => '🌙 Bloqueo Nocturno',
      _BlockReason.mandatoryBreak => '⏸️ Pausa Obligatoria',
    };
    final message = switch (reason) {
      _BlockReason.dailyLimit => '¡Has alcanzado tu límite diario de uso! 🌟',
      _BlockReason.nightBlock => 'Estás dentro del horario de descanso nocturno configurado. Es momento de desconectarte.',
      _BlockReason.mandatoryBreak => 'Llegó la pausa obligatoria. Toma un descanso breve para cuidar tu bienestar.',
    };
    
    // Mostrar como overlay/modal
    showDialog(
      context: context,
      barrierDismissible: false, // No se puede cerrar tocando fuera
      barrierColor: Colors.black.withValues(alpha: 0.95),
      builder: (context) => PopScope(
        canPop: false, // Prevenir cierre con botón atrás
        child: UsageLimitBlockedScreen(
          title: title,
          message: message,
          showAddTimeButton: isDailyLimit,
          showDismissButton: true,
          onTimeAdded: () async {
            if (!isDailyLimit) return;
            // Al sumar tiempo, dar una ventana de gracia para evitar reaparición inmediata
            // mientras se sincronizan los datos.
            _isBlockedScreenShown = false;
            _blockDismissedTime = DateTime.now();
            _dailyBlockDismissedUntil = null;

            await Future.delayed(const Duration(milliseconds: 1200));
            await _loadUsageData();

            final remaining = await UsageLimitsService.getRemainingTimeToday();
            if (mounted) {
              setState(() {
                _remainingMinutes = remaining;
              });
            }

            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                _loadUsageData();
              }
            });
          },
          onBlockRemoved: () {
            _isBlockedScreenShown = false;
            switch (reason) {
              case _BlockReason.dailyLimit:
                // "Quitar bloqueo por hoy": no volver a mostrar hasta fin del día.
                final now = DateTime.now();
                _dailyBlockDismissedUntil =
                    DateTime(now.year, now.month, now.day, 23, 59, 59);
                _blockDismissedTime = now;
                debugPrint('🚫 Bloqueo diario quitado por hoy.');
                break;
              case _BlockReason.nightBlock:
                _nightBlockDismissedTime = DateTime.now();
                debugPrint('🚫 Bloqueo nocturno quitado manualmente por el usuario.');
                break;
              case _BlockReason.mandatoryBreak:
                _mandatoryBreakDismissedTime = DateTime.now();
                debugPrint('🚫 Pausa obligatoria omitida manualmente por el usuario.');
                break;
            }
          },
        ),
      ),
    ).then((_) {
      // Cuando se cierra el diálogo
      _isBlockedScreenShown = false;
    });
  }

  /// Iniciar timer para actualizar el contador cada 10 segundos (optimizado)
  void _startUsageTimer() {
    _usageTimer?.cancel(); // Cancelar timer anterior si existe
    _usageTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      // Actualizar datos de uso solo una vez por ciclo
      // No actualizar si ya se está cargando para evitar múltiples llamadas
      if (!_isLoadingUsageData) {
        try {
          await _loadUsageData(fromPeriodicTimer: true);
        } catch (e) {
          debugPrint('❌ Error en timer de actualización de uso: $e');
        }
      }
    });
  }

  /// Mostrar mensaje motivacional al entrar a la app
  void _showWelcomeMessage() {
    if (!mounted) return;
    
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return;
    
    // Lista de mensajes motivacionales para cuando entra a la app
    final welcomeMessages = [
      '¡Sigue así! Cada día es una nueva oportunidad 🌟',
      'Estás haciendo un gran trabajo 💪',
      'Tu progreso es increíble, ¡continúa! 🎯',
      'Cada momento sin redes sociales te hace más fuerte ⚡',
      'Estás construyendo hábitos increíbles 🚀',
      'Tu futuro yo te lo agradecerá 🌈',
      '¡Eres más fuerte de lo que piensas! 💎',
      'Cada paso cuenta, sigue adelante 🎉',
      'Tu bienestar es tu prioridad ✨',
      'Estás tomando el control de tu vida 🎊',
    ];
    
    final random = Random();
    final message = welcomeMessages[random.nextInt(welcomeMessages.length)];
    
    // Esperar un poco para que la animación termine
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        CustomSnackBar.showTheme(
          context,
          message,
          icon: Icons.auto_awesome_rounded,
          duration: const Duration(milliseconds: 2500),
        );
      }
    });
  }

  @override
  void dispose() {
    // Finalizar sesión al cerrar la app
    _endAppSession();
    
    // Remover observer
    WidgetsBinding.instance.removeObserver(this);
    
    _animationController.dispose();
    _ambientGlowController.dispose();
    _usageTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Solo reconstruir el shell cuando cambian tema o idioma (menos trabajo que Consumer completo).
    return Selector<AppProvider, String>(
      selector: (_, p) =>
          '${p.colorTheme}|${p.language}|${p.nightBlockActive}|${p.mandatoryBreaksActive}|${p.dailyUsageLimit}|${p.todayUsageMinutes}',
      builder: (context, _, __) {
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        AppColors.setTheme(appProvider.colorTheme);
        
        final liteEffects = _useLiteEffects();
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
              child: RefreshIndicator(
                onRefresh: _handlePullToRefresh,
                child: (liteEffects)
                    ? SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStaggeredSection(index: 0, child: _buildHeader()),
                            const SizedBox(height: 24),
                            _buildStaggeredSection(index: 1, child: _buildMotivationalMessage()),
                            const SizedBox(height: 24),
                            _buildStaggeredSection(index: 2, child: _buildDailyDashboard()),
                            const SizedBox(height: 24),
                            _buildStaggeredSection(index: 3, child: _buildActivityRecommendations()),
                            const SizedBox(height: 24),
                            _buildStaggeredSection(index: 4, child: _buildNearbyRecommendations()),
                            const SizedBox(height: 24),
                          ],
                        ),
                      )
                    : FadeTransition(
                        opacity: _fadeInAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header con saludo y perfil
                                _buildStaggeredSection(index: 0, child: _buildHeader()),
                                const SizedBox(height: 24),

                                // Mensaje motivacional
                                _buildStaggeredSection(index: 1, child: _buildMotivationalMessage()),
                                const SizedBox(height: 24),

                                // Dashboard unificado (resumen + límites)
                                _buildStaggeredSection(index: 2, child: _buildDailyDashboard()),
                                const SizedBox(height: 24),

                                // Recomendaciones de actividad
                                _buildStaggeredSection(index: 3, child: _buildActivityRecommendations()),
                                const SizedBox(height: 24),
                                _buildStaggeredSection(index: 4, child: _buildNearbyRecommendations()),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                      ),
              ),
        ),
      ),
    );
      },
    );
  }

  Widget _buildStaggeredSection({
    required int index,
    required Widget child,
  }) {
    if (MediaQuery.disableAnimationsOf(context) || _useLiteEffects()) {
      return child;
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, _) {
        final start = (index * 0.12).clamp(0.0, 0.7);
        final curve = Interval(start, 1.0, curve: Curves.easeOutCubic);
        final t = curve.transform(_animationController.value.clamp(0.0, 1.0));
        final dy = (1 - t) * 10;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, dy),
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final localizations = AppLocalizations.of(context)!;
        final user = userProvider.user;
        final userName = user?.name ?? localizations.user;
        final currentHour = DateTime.now().hour;
        String greeting = localizations.goodMorning;

        if (currentHour >= 12 && currentHour < 18) {
          greeting = localizations.goodAfternoon;
        } else if (currentHour >= 18) {
          greeting = localizations.goodEvening;
        }

        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textLight.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
            Semantics(
              button: true,
              label: localizations.settings,
              child: Tooltip(
                message: localizations.settings,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      _hapticLight();
                      navigate(context, CustomScreen.settings);
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.textLight.withValues(alpha: 0.14),
                        border: Border.all(
                          color: AppColors.textLight.withValues(alpha: 0.28),
                          width: 1.2,
                        ),
                      ),
                      child: Icon(
                        Icons.settings_rounded,
                        color: AppColors.textLight,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Semantics(
              button: true,
              label: localizations.editProfile,
              child: GestureDetector(
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                  );
                  if (mounted) {
                    setState(() {});
                  }
                },
                child: ExcludeSemantics(
                  child: Hero(
                    tag: 'profile_avatar_hero',
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: AppColors.accentGradient),
                          boxShadow: AppColors.cardShadow,
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.darkSurface,
                          ),
                          child: user?.profileImage != null && user!.profileImage!.isNotEmpty
                              ? Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    image: DecorationImage(
                                      image: networkAvatarProvider(user.profileImage!, logicalDiameter: 52),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.person,
                                  color: AppColors.textLight,
                                  size: 28,
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMotivationalMessage() {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final localizations = AppLocalizations.of(context)!;
        // Mantener el mismo mensaje durante todo el día para evitar cambios bruscos.
        final message = _resolveDailyMotivation(context, localizations);
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.accentPurple.withValues(alpha: 0.24),
                AppColors.accentBlue.withValues(alpha: 0.18),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.textLight.withValues(alpha: 0.22),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentPurple.withValues(alpha: 0.16),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.textLight.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: AppColors.textLight,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      localizations.messageOfDay,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textLight.withValues(alpha: 0.84),
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textLight,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDailyDashboard() {
    final localizations = AppLocalizations.of(context)!;
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final liteEffects = _useLiteEffects();
    final today = DateTime.now();
    final todayLabel =
        '${today.day.toString().padLeft(2, '0')}/${today.month.toString().padLeft(2, '0')}';
    // Usar estado en vivo para reflejar descuento continuo del tiempo
    // (incluye sesión activa) y evitar que la UI se "congele" hasta persistir en BD.
    final limitMinutes = _dailyLimitMinutes.clamp(1, 24 * 60);
    final remainingMinutes = _remainingMinutes.clamp(0, limitMinutes);
    final usedMinutes = (limitMinutes - remainingMinutes).clamp(0, limitMinutes);
    final progress = (usedMinutes / limitMinutes).clamp(0.0, 1.0);
    final recordHours = PreferencesService.getRecordTimeWithoutFacebook();
    final blockedSessions = PreferencesService.getBlockedSessionsCount();

    final bool isDailyBlocked = remainingMinutes <= 0;
    final bool isNightBlocked = appProvider.nightBlockActive && _isInNightBlockWindow;
    final bool isBreakBlocked =
        appProvider.mandatoryBreaksActive &&
        _minutesToNextMandatoryPause != null &&
        _minutesToNextMandatoryPause! <= 0;

    final bool isBlocked = isDailyBlocked || isNightBlocked || isBreakBlocked;
    final bool isNearLimit = !isBlocked && progress >= 0.8;
    final statusColor = isBlocked
        ? Colors.redAccent
        : (isNearLimit ? Colors.orange : Colors.green);
    final statusText = isDailyBlocked
        ? localizations.homeStatusBlockedDaily
        : (isNightBlocked
            ? localizations.homeStatusNightBlockActive
            : (isBreakBlocked
                ? localizations.homeStatusMandatoryBreakActive
                : (isNearLimit ? localizations.homeStatusNearLimit : localizations.homeStatusWithinLimit)));

    return AnimatedBuilder(
      animation: _ambientGlowController,
      builder: (context, _) {
        final glowT = liteEffects ? 0.2 : Curves.easeInOut.transform(_ambientGlowController.value);
        return ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: liteEffects ? 0 : 7,
              sigmaY: liteEffects ? 0 : 7,
            ),
            child: AnimatedContainer(
              duration: Duration(milliseconds: liteEffects ? 120 : 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.darkSurface.withValues(alpha: 0.92),
                    AppColors.primaryBlue.withValues(alpha: 0.38),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.textLight.withValues(alpha: 0.22), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.24 + (0.08 * glowT)),
                    blurRadius: 14 + (8 * glowT),
                    spreadRadius: 0.2 + (0.8 * glowT),
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  localizations.homeDashboardTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textLight,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.textLight.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.textLight.withValues(alpha: 0.22)),
                ),
                child: Text(
                  todayLabel,
                  style: TextStyle(
                    color: AppColors.textLight.withValues(alpha: 0.85),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.28),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: liteEffects ? 260 : 500),
                  curve: Curves.easeOutCubic,
                  tween: Tween<double>(begin: 0, end: progress),
                  builder: (context, animatedProgress, _) => Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 92,
                        height: 92,
                        child: CircularProgressIndicator(
                          value: animatedProgress,
                          strokeWidth: 8,
                          backgroundColor: AppColors.textLight.withValues(alpha: 0.16),
                          valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                        ),
                      ),
                      Text(
                        '${(animatedProgress * 100).round()}%',
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isBlocked ? Icons.block : Icons.verified_rounded,
                          size: 18,
                          color: statusColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: statusColor.withValues(alpha: 0.35)),
                      ),
                      child: Text(
                        localizations.homeDashboardPerformancePercent(
                          (100 - (progress * 100)).round().clamp(0, 100),
                        ),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(
            height: 1,
            thickness: 1,
            color: AppColors.textLight.withValues(alpha: 0.14),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _showTimeRemainingDialog(localizations),
            child: TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: liteEffects ? 180 : 380),
              curve: Curves.easeOutCubic,
              tween: Tween<double>(begin: 0, end: progress),
              builder: (context, animatedProgress, _) => ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: LinearProgressIndicator(
                  minHeight: 10,
                  value: animatedProgress,
                  backgroundColor: AppColors.textLight.withValues(alpha: 0.2),
                  color: statusColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildUsageStatMini(
                  localizations.homeUsedLabel,
                  _formatMinutesHm(usedMinutes),
                  Icons.schedule,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildUsageStatMini(
                  localizations.remaining,
                  _formatMinutesHm(remainingMinutes),
                  Icons.hourglass_bottom_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => _showTimeRemainingDialog(localizations),
                  child: _buildUsageStatMini(
                    localizations.dailyLimitHome,
                    _formatMinutesHm(limitMinutes),
                    Icons.timer_outlined,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatusIndicator(
                  icon: Icons.bedtime,
                  label: localizations.nightBlock,
                  value: appProvider.nightBlockActive
                      ? (_isInNightBlockWindow ? localizations.active : localizations.usageStatusStandby)
                      : localizations.featureOff,
                  color: _isInNightBlockWindow ? Colors.purpleAccent : AppColors.textLight,
                  isOn: appProvider.nightBlockActive,
                  onTap: _showNightBlockQuickConfig,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatusIndicator(
                  icon: Icons.pause_circle_outline,
                  label: localizations.mandatoryBreaks,
                  value: appProvider.mandatoryBreaksActive
                      ? (_minutesToNextMandatoryPause != null
                          ? (_minutesToNextMandatoryPause! <= 0
                              ? localizations.homeMandatoryBreakNow
                              : '${localizations.nextIn} ${_formatMinutesHm(_minutesToNextMandatoryPause!)}')
                          : localizations.usageStatusStandby)
                      : localizations.featureOff,
                  color: isBreakBlocked ? Colors.orange : AppColors.textLight,
                  isOn: appProvider.mandatoryBreaksActive,
                  onTap: _showMandatoryBreakQuickConfig,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatusIndicator(
                  icon: Icons.block,
                  label: localizations.dailyLimitHome,
                  value: isDailyBlocked ? localizations.active : localizations.featureOff,
                  color: isDailyBlocked ? Colors.redAccent : AppColors.textLight,
                  isOn: isDailyBlocked,
                  onTap: _showDailyLimitQuickConfig,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            localizations.homeQuickImpact,
            style: TextStyle(
              color: AppColors.textLight.withValues(alpha: 0.86),
              fontWeight: FontWeight.w600,
              fontSize: 13,
              letterSpacing: 0.15,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildImpactMiniCard(
                  icon: Icons.military_tech_outlined,
                  label: localizations.timeWithoutFacebook,
                  value: _formatRecordHours(recordHours),
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildImpactMiniCard(
                  icon: Icons.block,
                  label: localizations.blockedSessions,
                  value: '$blockedSessions',
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildImpactMiniCard(
                  icon: Icons.local_fire_department_outlined,
                  label: localizations.consecutiveDays,
                  value: '$_consecutiveDaysWithEmotions',
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildDashboardActionPill(
                      icon: Icons.timer_outlined,
                      label: localizations.homeSeeTimer,
                      color: Colors.teal,
                      fullWidth: true,
                      onTap: () => _showTimeRemainingDialog(localizations),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildDashboardActionPill(
                      icon: Icons.sentiment_satisfied_alt,
                      label: localizations.emotionTracking,
                      color: Colors.pinkAccent,
                      fullWidth: true,
                      onTap: () => navigate(context, CustomScreen.emotionTracking),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildDashboardActionPill(
                      icon: Icons.analytics_outlined,
                      label: localizations.statistics,
                      color: AppColors.accentBlue,
                      fullWidth: true,
                      onTap: () => navigate(context, CustomScreen.statistics),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildDashboardActionPill(
                      icon: Icons.card_giftcard,
                      label: localizations.rewards,
                      color: Colors.orange,
                      fullWidth: true,
                      onTap: () => navigate(context, CustomScreen.rewards),
                    ),
                  ),
                ],
              ),
            ],
          ),
              ],
            ),
          ),
        ),
      );
      },
    );
  }

  Widget _buildUsageStatMini(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.textLight.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.textLight.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: AppColors.textLight.withValues(alpha: 0.82)),
          const SizedBox(height: 4),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: Text(
              value,
              key: ValueKey<String>(value),
              style: const TextStyle(
                color: AppColors.textLight,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textLight.withValues(alpha: 0.72),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isOn,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.textLight.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: (isOn ? color : AppColors.textLight).withValues(alpha: 0.28),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedRotation(
                  turns: isOn ? 0.04 : 0.0,
                  duration: const Duration(milliseconds: 260),
                  child: Icon(icon, size: 13, color: isOn ? color : AppColors.textLight),
                ),
                const SizedBox(width: 5),
                SizedBox(
                  width: 8,
                  height: 8,
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 220),
                    scale: isOn ? 1.15 : 1.0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isOn ? color : Colors.grey,
                        boxShadow: isOn
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.5),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textLight.withValues(alpha: 0.7),
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isOn ? color : AppColors.textLight,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImpactMiniCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.textLight.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(height: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: Text(
              value,
              key: ValueKey<String>(value),
              style: const TextStyle(
                color: AppColors.textLight,
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textLight.withValues(alpha: 0.68),
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardActionPill({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool fullWidth = false,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () {
        _hapticLight();
        onTap();
      },
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.textLight.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment:
              fullWidth ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: AppColors.textLight.withValues(alpha: 0.95),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshHomeSummaryMetrics() async {
    try {
      final consecutive = await PointsService.getConsecutiveDays();
      final weekly = await UsageLimitsService.getWeeklyStats();
      final limits = await UsageLimitsService.getOrCreateUsageLimits();
      final nextBreak = await UsageLimitsService.getTimeUntilNextBreak();
      final inNight = await UsageLimitsService.isInNightBlockTime();

      if (!mounted) return;
      final app = Provider.of<AppProvider>(context, listen: false);
      final goalHours = app.weeklyGoal.clamp(1, 200);
      final totalMin = weekly['total_minutos'] as int? ?? 0;
      final usedHours = totalMin / 60.0;
      final factor = (usedHours / goalHours).clamp(0.0, 1.0);
      final diasUso = weekly['dias_con_uso'] as int? ?? 0;

      String nightLbl = '—';
      int pauseInterval = 30;
      if (limits != null) {
        final s = limits['bloqueo_nocturno_inicio'] as String?;
        final e = limits['bloqueo_nocturno_fin'] as String?;
        nightLbl = _compactTimeRange(s, e);
        pauseInterval = limits['intervalo_pausa_minutos'] as int? ?? 30;
      }

      setState(() {
        _consecutiveDaysWithEmotions = consecutive;
        _weeklyProgressFactor = factor;
        _weeklyDaysWithUsage = diasUso;
        _nightWindowLabel = nightLbl;
        _pauseIntervalLabel = '$pauseInterval min';
        _minutesToNextMandatoryPause = nextBreak;
        _mandatoryPauseIntervalMinutes = pauseInterval;
        _isInNightBlockWindow = inNight;
      });
    } catch (e) {
      debugPrint('Error refrescando métricas del home: $e');
    }
  }

  String _compactTimeRange(String? start, String? end) {
    if (start == null || end == null) return '—';
    String short(String t) {
      final p = t.split(':');
      if (p.length >= 2) return '${p[0]}:${p[1]}';
      return t;
    }
    return '${short(start)} – ${short(end)}';
  }

  String _formatRecordHours(int hours) {
    if (hours <= 0) return '0 h';
    return '$hours h';
  }

  String _formatMinutesHm(int minutes) {
    if (minutes <= 0) return '0m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  double _mandatoryBreakProgress(bool mandatoryActive) {
    if (!mandatoryActive) return 0.05;
    final interval = _mandatoryPauseIntervalMinutes.clamp(1, 9999);
    final next = _minutesToNextMandatoryPause;
    if (next == null) return 0.35;
    return (1.0 - (next / interval)).clamp(0.0, 1.0);
  }

  // ignore: unused_element
  Widget _buildUsageSummary() {
    final localizations = AppLocalizations.of(context)!;
    if (_isLoadingUsageData && !_hasLoadedUsageData) {
      return _buildUsageSectionSkeleton(titleEmoji: '📱');
    }
    final recordHours = PreferencesService.getRecordTimeWithoutFacebook();
    final blocked = PreferencesService.getBlockedSessionsCount();
    final app = Provider.of<AppProvider>(context, listen: false);
    final savedToday = (app.dailyUsageLimit - app.todayUsageMinutes).clamp(0, app.dailyUsageLimit);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.textLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textLight.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📱 ${localizations.usageSummary}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildUsageCard(
                  localizations.timeWithoutFacebook,
                  _formatRecordHours(recordHours),
                  Icons.access_time,
                  AppColors.accentBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildUsageCard(
                  localizations.blockedSessions,
                  '$blocked',
                  Icons.block,
                  AppColors.accentPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildUsageCard(
                  localizations.timeSaved,
                  _formatMinutesHm(savedToday),
                  Icons.savings,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildUsageCard(
                  localizations.consecutiveDays,
                  '$_consecutiveDaysWithEmotions',
                  Icons.calendar_today,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsageCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.textLight.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.textLight.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textLight,
              shadows: [
                Shadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textLight.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildUsageLimits() {
    final localizations = AppLocalizations.of(context)!;
    if (_isLoadingUsageData && !_hasLoadedUsageData) {
      return _buildUsageSectionSkeleton(titleEmoji: '⏰');
    }
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final limitMinutes = _dailyLimitMinutes.clamp(1, 24 * 60);
    final remainingMinutes = _remainingMinutes.clamp(0, limitMinutes);
    final usedMinutes = (limitMinutes - remainingMinutes).clamp(0, limitMinutes);

    String limitText;
    if (limitMinutes >= 60) {
      final hours = limitMinutes ~/ 60;
      final mins = limitMinutes % 60;
      if (mins > 0) {
        limitText = '${hours}h ${mins}m';
      } else {
        limitText = '$hours ${localizations.hours}';
      }
    } else {
      limitText = '$limitMinutes ${localizations.minutesShort}';
    }

    String remainingText;
    if (remainingMinutes >= 60) {
      final hours = remainingMinutes ~/ 60;
      final mins = remainingMinutes % 60;
      if (mins > 0) {
        remainingText = '${hours}h ${mins}m';
      } else {
        remainingText = '${hours}h';
      }
    } else {
      remainingText = '${remainingMinutes}m';
    }

    final progress = limitMinutes > 0 ? usedMinutes / limitMinutes : 0.0;

    final nightStatus = !appProvider.nightBlockActive
        ? localizations.featureOff
        : (_isInNightBlockWindow ? localizations.active : localizations.usageStatusStandby);
    final nightProgress = !appProvider.nightBlockActive
        ? 0.05
        : (_isInNightBlockWindow ? 0.95 : 0.35);

    final mandatoryStatus = !appProvider.mandatoryBreaksActive
        ? localizations.featureOff
        : (_minutesToNextMandatoryPause != null
            ? '${localizations.nextIn} $_minutesToNextMandatoryPause ${localizations.minutesShort}'
            : localizations.usageStatusStandby);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.textLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textLight.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '⏰ ${localizations.usageLimitsTitleHome}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _showTimeRemainingDialog(localizations),
            child: _buildLimitItem(
              localizations.dailyLimitHome,
              limitText,
              '$remainingText ${localizations.remaining}',
              Icons.access_time,
              AppColors.accentBlue,
              progress.clamp(0.0, 1.0),
            ),
          ),
          const SizedBox(height: 12),
          _buildLimitItem(
            localizations.nightBlock,
            appProvider.nightBlockActive ? _nightWindowLabel : '—',
            nightStatus,
            Icons.bedtime,
            AppColors.accentPurple,
            nightProgress,
          ),
          const SizedBox(height: 12),
          _buildLimitItem(
            localizations.mandatoryBreaks,
            appProvider.mandatoryBreaksActive ? _pauseIntervalLabel : '—',
            mandatoryStatus,
            Icons.pause,
            Colors.orange,
            _mandatoryBreakProgress(appProvider.mandatoryBreaksActive),
          ),
        ],
      ),
    );
  }


  /// Mostrar diálogo con reloj de tiempo restante
  Future<void> _showTimeRemainingDialog(AppLocalizations localizations) async {
    if (!_isLoadingUsageData) {
      await _loadUsageData();
    }

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return _TimeRemainingDialog(
          remainingMinutes: _remainingMinutes,
          dailyLimitMinutes: _dailyLimitMinutes,
          fetchSnapshot: _fetchTimeRemainingSnapshot,
        );
      },
    );
  }

  Future<({int remainingMinutes, int dailyLimitMinutes})> _fetchTimeRemainingSnapshot() async {
    try {
      final remainingFromService = await UsageLimitsService.getRemainingTimeToday();
      final limits = await UsageLimitsService.getOrCreateUsageLimits();
      final limitMinutes = limits?['limite_diario_minutos'] as int? ?? _dailyLimitMinutes;
      return (
        remainingMinutes: remainingFromService,
        dailyLimitMinutes: limitMinutes,
      );
    } catch (_) {
      return (
        remainingMinutes: _remainingMinutes,
        dailyLimitMinutes: _dailyLimitMinutes,
      );
    }
  }

  Future<void> _showNightBlockQuickConfig() async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    bool enabled = appProvider.nightBlockActive;
    String start = _nightWindowLabel.contains('–')
        ? _nightWindowLabel.split('–').first.trim()
        : '22:00';
    String end = _nightWindowLabel.contains('–')
        ? _nightWindowLabel.split('–').last.trim()
        : '07:00';

    String normalize(String t) {
      final parts = t.split(':');
      if (parts.length < 2) return '22:00:00';
      return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}:00';
    }

    final saved = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          tween: Tween<double>(begin: 0.96, end: 1.0),
          builder: (context, v, child) => Opacity(
            opacity: ((v - 0.96) / 0.04).clamp(0.0, 1.0),
            child: Transform.scale(scale: v, child: child),
          ),
          child: StatefulBuilder(
            builder: (ctx, setModalState) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textLight.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: AppColors.accentGradient),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.bedtime, color: AppColors.textLight, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Configurar bloqueo nocturno',
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.textLight.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.textLight.withValues(alpha: 0.2)),
                  ),
                  child: SwitchListTile(
                    value: enabled,
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Activar',
                      style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.w600),
                    ),
                    onChanged: (v) => setModalState(() => enabled = v),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.accentBlue.withValues(alpha: 0.45)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () async {
                          final now = TimeOfDay.now();
                          final picked = await showTimePicker(context: context, initialTime: now);
                          if (picked != null) {
                            setModalState(() {
                              start =
                                  '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                            });
                          }
                        },
                        child: Text('Inicio  $start'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.accentBlue.withValues(alpha: 0.45)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () async {
                          final now = TimeOfDay.now();
                          final picked = await showTimePicker(context: context, initialTime: now);
                          if (picked != null) {
                            setModalState(() {
                              end =
                                  '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                            });
                          }
                        },
                        child: Text('Fin  $end'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Guardar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ),
        );
      },
    );

    if (saved != true || !mounted) return;

    if (enabled && start == end) {
      _hapticLight();
      CustomSnackBar.showWarning(
        context,
        'La hora de inicio y fin no pueden ser iguales.',
      );
      return;
    }

    final success = await UsageLimitsService.updateNightBlock(
      active: enabled,
      startTime: normalize(start),
      endTime: normalize(end),
    );
    if (!success || !mounted) return;
    _hapticMedium();
    await appProvider.refreshUsageLimits();
    await _loadUsageData();
    if (!mounted) return;
    CustomSnackBar.showSuccess(context, 'Bloqueo nocturno guardado');
  }

  Future<void> _showMandatoryBreakQuickConfig() async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    bool enabled = appProvider.mandatoryBreaksActive;
    int interval = _mandatoryPauseIntervalMinutes;
    int duration = 5;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          tween: Tween<double>(begin: 0.96, end: 1.0),
          builder: (context, v, child) => Opacity(
            opacity: ((v - 0.96) / 0.04).clamp(0.0, 1.0),
            child: Transform.scale(scale: v, child: child),
          ),
          child: StatefulBuilder(
            builder: (ctx, setModalState) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textLight.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: AppColors.accentGradient),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.pause_circle, color: AppColors.textLight, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Configurar pausas obligatorias',
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.textLight.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.textLight.withValues(alpha: 0.2)),
                  ),
                  child: SwitchListTile(
                    value: enabled,
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Activar',
                      style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.w600),
                    ),
                    onChanged: (v) => setModalState(() => enabled = v),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: interval,
                        dropdownColor: AppColors.darkSurface,
                        style: const TextStyle(color: AppColors.textLight),
                        items: const [15, 20, 30, 45, 60]
                            .map((e) => DropdownMenuItem(value: e, child: Text('$e min')))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setModalState(() => interval = v);
                        },
                        decoration: const InputDecoration(labelText: 'Intervalo'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: duration,
                        dropdownColor: AppColors.darkSurface,
                        style: const TextStyle(color: AppColors.textLight),
                        items: const [3, 5, 10, 15]
                            .map((e) => DropdownMenuItem(value: e, child: Text('$e min')))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setModalState(() => duration = v);
                        },
                        decoration: const InputDecoration(labelText: 'Duración'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Guardar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ),
        );
      },
    );

    if (saved != true || !mounted) return;
    if (enabled && duration >= interval) {
      _hapticLight();
      CustomSnackBar.showWarning(
        context,
        'La duración debe ser menor al intervalo.',
      );
      return;
    }
    final success = await UsageLimitsService.updateMandatoryBreaks(
      active: enabled,
      intervalMinutes: interval,
      durationMinutes: duration,
    );
    if (!success || !mounted) return;
    _hapticMedium();
    await appProvider.refreshUsageLimits();
    await _loadUsageData();
    if (!mounted) return;
    CustomSnackBar.showSuccess(context, 'Pausas obligatorias guardadas');
  }

  Future<void> _showDailyLimitQuickConfig() async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final localizations = AppLocalizations.of(context)!;
    int selectedMinutes = appProvider.dailyUsageLimit.clamp(10, 24 * 60);

    String formatMinutes(int minutes) {
      final h = minutes ~/ 60;
      final m = minutes % 60;
      if (h == 0) return '$m ${localizations.minutesShort}';
      if (m == 0) return '$h ${localizations.hoursShort}';
      return '${h}h ${m}m';
    }

    final saved = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          tween: Tween<double>(begin: 0.96, end: 1.0),
          builder: (context, v, child) => Opacity(
            opacity: ((v - 0.96) / 0.04).clamp(0.0, 1.0),
            child: Transform.scale(scale: v, child: child),
          ),
          child: StatefulBuilder(
            builder: (ctx, setModalState) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textLight.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: AppColors.accentGradient),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.timer_outlined, color: AppColors.textLight, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        localizations.dailyLimitHome,
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${localizations.dailyLimitTitle}: ${formatMinutes(selectedMinutes)}',
                  style: TextStyle(
                    color: AppColors.textLight.withValues(alpha: 0.9),
                    fontSize: 13,
                  ),
                ),
                Slider(
                  value: selectedMinutes.toDouble(),
                  min: 10,
                  max: 24 * 60,
                  divisions: ((24 * 60) - 10) ~/ 10,
                  onChanged: (v) {
                    setModalState(() => selectedMinutes = (v ~/ 10) * 10);
                  },
                ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Guardar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ),
        );
      },
    );

    if (saved != true || !mounted) return;
    _hapticMedium();
    await appProvider.setDailyUsageLimit(selectedMinutes);
    await _loadUsageData();
    if (!mounted) return;
    CustomSnackBar.showSuccess(
      context,
      'Límite diario actualizado a ${formatMinutes(selectedMinutes)}',
    );
  }

  Widget _buildLimitItem(String title, String value, String status, IconData icon, Color color, double progress) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.textLight.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 6,
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
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                // Barra de progreso mejorada
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.textLight.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color, color.withValues(alpha: 0.8)],
                        ),
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageSectionSkeleton({required String titleEmoji}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.textLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textLight.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHomeSkeletonLine(widthFactor: 0.45, height: 20),
          const SizedBox(height: 14),
          Text(
            titleEmoji,
            style: TextStyle(
              color: AppColors.textLight.withValues(alpha: 0.6),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(
            3,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ProEntrance(
                delayMs: 40 + (index * 45),
                child: Container(
                  height: 86,
                  decoration: BoxDecoration(
                    color: AppColors.textLight.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeSkeletonLine({required double widthFactor, required double height}) {
    return AnimatedBuilder(
      animation: _ambientGlowController,
      builder: (context, _) {
        final t = _ambientGlowController.value;
        return FractionallySizedBox(
          widthFactor: widthFactor,
          child: Container(
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-1.0 + (2.0 * t), 0),
                end: Alignment(1.0 + (2.0 * t), 0),
                colors: [
                  AppColors.textLight.withValues(alpha: 0.12),
                  AppColors.textLight.withValues(alpha: 0.24),
                  AppColors.textLight.withValues(alpha: 0.12),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      },
    );
  }

  // ignore: unused_element
  Widget _buildWeeklyProgress() {
    final localizations = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.textLight.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textLight.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentPurple.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.textLight.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.trending_up,
                  color: AppColors.accentPurple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                localizations.weeklyProgress,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textLight,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Barra de progreso mejorada
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.textLight.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: _weeklyProgressFactor.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: AppColors.accentGradient),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentPurple.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$_weeklyDaysWithUsage/7 ${localizations.days}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textLight.withValues(alpha: 0.9),
                ),
              ),
              Text(
                '${(_weeklyProgressFactor * 100).round()}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentPurple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

}

class _ActivityRecommendation {
  final String id;
  final String title;
  final String subtitle;
  final int minutes;
  final IconData icon;
  final Color color;

  const _ActivityRecommendation({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.minutes,
    required this.icon,
    required this.color,
  });
}

/// Diálogo con reloj que muestra el tiempo restante
class _TimeRemainingDialog extends StatefulWidget {
  final int remainingMinutes;
  final int dailyLimitMinutes;
  final Future<({int remainingMinutes, int dailyLimitMinutes})> Function() fetchSnapshot;

  const _TimeRemainingDialog({
    required this.remainingMinutes,
    required this.dailyLimitMinutes,
    required this.fetchSnapshot,
  });

  @override
  State<_TimeRemainingDialog> createState() => _TimeRemainingDialogState();
}

class _TimeRemainingDialogState extends State<_TimeRemainingDialog> with SingleTickerProviderStateMixin {
  Timer? _updateTimer;
  Timer? _syncTimer;
  int _currentRemainingSeconds = 0;
  int _currentLimitSeconds = 60;
  final ValueNotifier<int> _remainingSecondsNotifier = ValueNotifier<int>(0);
  DateTime _dialogStartTime = DateTime.now();
  int _initialRemainingSeconds = 0;
  bool _isSyncing = false;
  bool _criticalPulsePhase = false;
  DateTime? _lastSyncAt;
  int _syncIntervalSeconds = 15;
  late final AnimationController _entryController;
  String _clockStyle = 'pro';
  static const String _clockStylePrefKey = 'time_clock_style_v1';

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..forward();
    _currentLimitSeconds = (widget.dailyLimitMinutes * 60).clamp(60, 24 * 60 * 60).toInt();
    _initialRemainingSeconds = (widget.remainingMinutes * 60).clamp(0, _currentLimitSeconds).toInt();
    _currentRemainingSeconds = _initialRemainingSeconds;
    _remainingSecondsNotifier.value = _currentRemainingSeconds;
    _dialogStartTime = DateTime.now();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_loadClockStyle());
      unawaited(_refreshFromService());
    });
  }

  Future<void> _loadClockStyle() async {
    await PreferencesService.init();
    final saved = PreferencesService.getString(_clockStylePrefKey) ?? 'pro';
    if (!mounted) return;
    setState(() {
      _clockStyle = saved;
    });
  }

  void _startTimer() {
    // Timer principal que cuenta hacia atrás cada segundo
    // Calcula el tiempo restante basado en el tiempo transcurrido desde que se abrió el diálogo
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      final now = DateTime.now();
      final elapsed = now.difference(_dialogStartTime).inSeconds;
      final calculatedRemaining = _initialRemainingSeconds - elapsed;

      final boundedRemaining = calculatedRemaining > 0 ? calculatedRemaining : 0;
      if (_currentRemainingSeconds != boundedRemaining) {
        _currentRemainingSeconds = boundedRemaining;
        _remainingSecondsNotifier.value = boundedRemaining;
      }
      if (boundedRemaining == 0) {
        // Si llegó a 0, sincronizar con backend para evitar desfases.
        unawaited(_refreshFromService());
      }

      final shouldPulse = boundedRemaining > 0 && boundedRemaining <= 5 * 60;
      final desiredSync = _desiredSyncIntervalSeconds(boundedRemaining);
      final nextPulsePhase = shouldPulse ? !_criticalPulsePhase : false;
      if (nextPulsePhase != _criticalPulsePhase) {
        setState(() {
          _criticalPulsePhase = nextPulsePhase;
        });
      }

      if (desiredSync != _syncIntervalSeconds) {
        _syncIntervalSeconds = desiredSync;
        _restartSyncTimer();
      }
    });

    _restartSyncTimer();
  }

  int _desiredSyncIntervalSeconds(int remainingSeconds) {
    if (remainingSeconds <= 60) return 5;
    if (remainingSeconds <= 5 * 60) return 10;
    return 20;
  }

  void _restartSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(Duration(seconds: _syncIntervalSeconds), (timer) {
      if (!mounted) return;
      unawaited(_refreshFromService());
    });
  }

  Future<void> _refreshFromService() async {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      final snapshot = await widget.fetchSnapshot();
      final remainingFromService = snapshot.remainingMinutes;
      final limitMinutes = snapshot.dailyLimitMinutes;

      final updatedLimitSeconds = (limitMinutes * 60).clamp(60, 24 * 60 * 60).toInt();
      final updatedRemainingSeconds = (remainingFromService * 60)
          .clamp(0, updatedLimitSeconds)
          .toInt();

      final now = DateTime.now();
      final elapsed = now.difference(_dialogStartTime).inSeconds;
      final currentCalculated = (_initialRemainingSeconds - elapsed).clamp(0, _currentLimitSeconds);

      // El servicio suele venir en minutos enteros; eso puede "subir" 1-59s artificialmente.
      // Solo aceptamos subidas si son >= 60s (p.ej. se agregó tiempo real).
      final diff = updatedRemainingSeconds - currentCalculated;
      final shouldIgnoreSmallUpwardCorrection = diff > 0 && diff < 60;
      final targetRemainingSeconds =
          shouldIgnoreSmallUpwardCorrection ? currentCalculated.toInt() : updatedRemainingSeconds;

      if (!mounted) return;
      setState(() {
        _currentLimitSeconds = updatedLimitSeconds;
        _initialRemainingSeconds = targetRemainingSeconds;
        _currentRemainingSeconds = targetRemainingSeconds;
        _remainingSecondsNotifier.value = targetRemainingSeconds;
        _dialogStartTime = now;
        _lastSyncAt = now;
      });
    } finally {
      _isSyncing = false;
    }
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _syncTimer?.cancel();
    _entryController.dispose();
    _remainingSecondsNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ValueListenableBuilder<int>(
        valueListenable: _remainingSecondsNotifier,
        builder: (context, remainingSeconds, _) {
          final hours = remainingSeconds ~/ 3600;
          final minutes = (remainingSeconds % 3600) ~/ 60;
          final seconds = remainingSeconds % 60;

          Color clockColor;
          if (remainingSeconds <= 0) {
            clockColor = Colors.red;
          } else if (remainingSeconds <= _currentLimitSeconds * 0.25) {
            final dangerZone = (_currentLimitSeconds * 0.25).clamp(1, _currentLimitSeconds);
            final t = ((dangerZone - remainingSeconds) / dangerZone).clamp(0.0, 1.0);
            clockColor = Color.lerp(Colors.orange, Colors.red, t) ?? Colors.orange;
          } else {
            clockColor = Colors.green;
          }

          final totalSeconds = _currentLimitSeconds;
          final progress = totalSeconds > 0
              ? (remainingSeconds / totalSeconds).clamp(0.0, 1.0)
              : 0.0;
          final isCritical = remainingSeconds > 0 && remainingSeconds <= 5 * 60;
          final pulseFactor = isCritical && _criticalPulsePhase ? 1.0 : 0.0;
          final loc = AppLocalizations.of(context);
          final usedProgress = (1.0 - progress).clamp(0.0, 1.0);
          final dialogWidth = MediaQuery.sizeOf(context).width;
          final dialSize = dialogWidth < 380 ? 220.0 : 240.0;
          final outerRingSize = dialSize - 16;
          final innerRingSize = outerRingSize - 22;
          final centerPadding = dialogWidth < 380 ? 6.0 : 8.0;
          final remainingMinutesLabel = (remainingSeconds / 60).ceil().clamp(0, 24 * 60);
          final contextualStatus = remainingSeconds <= 0
              ? 'Tiempo agotado'
              : 'Te quedan $remainingMinutesLabel min';
          final riskLevel = (1.0 - progress).clamp(0.0, 1.0);
          final isClassic = _clockStyle == 'classic';
          final isNeon = _clockStyle == 'neon';
          final isAurora = _clockStyle == 'aurora';
          final isQuantum = _clockStyle == 'quantum';
          final topBg = isClassic
              ? Color.lerp(AppColors.darkSurface, const Color(0xFF2A3440), 0.35 + 0.2 * riskLevel)!
              : isNeon
                  ? Color.lerp(AppColors.darkSurface, const Color(0xFF1A0D2E), 0.5 + 0.15 * riskLevel)!
                  : isAurora
                      ? Color.lerp(AppColors.darkSurface, const Color(0xFF0D2830), 0.45 + 0.15 * riskLevel)!
                      : isQuantum
                          ? Color.lerp(AppColors.darkSurface, const Color(0xFF051018), 0.55 + 0.12 * riskLevel)!
                          : Color.lerp(AppColors.darkSurface, clockColor, 0.10 + (0.12 * riskLevel)) ??
                              AppColors.darkSurface;
          final bottomBg = isClassic
              ? Color.lerp(
                  AppColors.darkSurface.withValues(alpha: 0.95),
                  const Color(0xFF1E2630),
                  0.4 + 0.15 * riskLevel,
                )!
              : isNeon
                  ? Color.lerp(
                      AppColors.darkSurface.withValues(alpha: 0.95),
                      const Color(0xFF12082A),
                      0.5 + 0.1 * riskLevel,
                    )!
                  : isAurora
                      ? Color.lerp(
                          AppColors.darkSurface.withValues(alpha: 0.95),
                          const Color(0xFF082220),
                          0.45 + 0.12 * riskLevel,
                        )!
                      : isQuantum
                          ? Color.lerp(
                              AppColors.darkSurface.withValues(alpha: 0.95),
                              const Color(0xFF020810),
                              0.55 + 0.1 * riskLevel,
                            )!
                          : Color.lerp(
                                AppColors.darkSurface.withValues(alpha: 0.95),
                                clockColor,
                                0.05 + (0.10 * riskLevel),
                              ) ??
                              AppColors.darkSurface.withValues(alpha: 0.95);

          return AnimatedBuilder(
            animation: _entryController,
            builder: (context, _) {
              final entryProgress = Curves.easeOutCubic.transform(_entryController.value);
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [topBg, bottomBg],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: clockColor.withValues(alpha: 0.5),
                    width: isCritical ? (2.0 + pulseFactor) : 2.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: clockColor.withValues(alpha: isCritical ? (0.3 + (0.2 * pulseFactor)) : 0.3),
                      blurRadius: isCritical ? (20 + (8 * pulseFactor)) : 20,
                      spreadRadius: isCritical ? (5 + (2 * pulseFactor)) : 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
            // Título
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  loc?.remaining ?? 'Remaining',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textLight,
                  ),
                ),
                IconButton(
                  tooltip: loc?.refresh ?? 'Refresh',
                  icon: Icon(
                    _isSyncing ? Icons.sync : Icons.refresh,
                    color: AppColors.textLight,
                  ),
                  onPressed: _isSyncing ? null : () => unawaited(_refreshFromService()),
                ),
                IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  icon: const Icon(Icons.close, color: AppColors.textLight),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            _buildTimerClockVisual(
              hours: hours,
              minutes: minutes,
              seconds: seconds,
              progress: progress,
              usedProgress: usedProgress,
              clockColor: clockColor,
              entryProgress: entryProgress,
              isCritical: isCritical,
              pulseFactor: pulseFactor,
              dialSize: dialSize,
              outerRingSize: outerRingSize,
              innerRingSize: innerRingSize,
              centerPadding: centerPadding,
              loc: loc,
            ),
            const SizedBox(height: 14),
            Text(
              contextualStatus,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textLight.withValues(alpha: 0.82),
              ),
            ),
            const SizedBox(height: 16),
            
            // Información adicional
            Builder(
              builder: (context) {
                // Calcular valores basados en el tiempo actual del contador
                final currentRemainingMinutes = (_currentRemainingSeconds / 60).ceil();
                final totalLimitMinutes = (totalSeconds / 60).round();
                final usedMinutes = totalLimitMinutes - currentRemainingMinutes;
                
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildInfoItem(
                      loc?.dailyLimitHome ?? 'Limit',
                      '${totalLimitMinutes.clamp(0, 24 * 60)}m',
                      Icons.timer_outlined,
                    ),
                    _buildInfoItem(
                      loc?.homeUsedLabel ?? 'Used',
                      '${usedMinutes.clamp(0, totalLimitMinutes)}m',
                      Icons.access_time,
                    ),
                    _buildInfoItem(
                      loc?.remaining ?? 'Remaining',
                      '${currentRemainingMinutes.clamp(0, totalLimitMinutes)}m',
                      Icons.hourglass_empty,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              _lastSyncAt == null
                  ? (loc?.refresh ?? 'Refresh')
                  : '${loc?.refresh ?? 'Refresh'}: ${DateTime.now().difference(_lastSyncAt!).inSeconds}s',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textLight.withValues(alpha: 0.6),
              ),
            ),
          ],
                ),
              );
            },
      );
        },
      ),
    );
  }

  Widget _buildTimerClockVisual({
    required int hours,
    required int minutes,
    required int seconds,
    required double progress,
    required double usedProgress,
    required Color clockColor,
    required double entryProgress,
    required bool isCritical,
    required double pulseFactor,
    required double dialSize,
    required double outerRingSize,
    required double innerRingSize,
    required double centerPadding,
    required AppLocalizations? loc,
  }) {
    switch (_clockStyle) {
      case 'classic':
        return _buildClassicSquareClock(
          hours: hours,
          minutes: minutes,
          seconds: seconds,
          progress: progress,
          usedProgress: usedProgress,
          clockColor: clockColor,
          entryProgress: entryProgress,
          isCritical: isCritical,
          pulseFactor: pulseFactor,
          dialSize: dialSize,
          outerRingSize: outerRingSize,
          innerRingSize: innerRingSize,
          centerPadding: centerPadding,
          loc: loc,
        );
      case 'neon':
        return _buildNeonHexClock(
          hours: hours,
          minutes: minutes,
          seconds: seconds,
          progress: progress,
          usedProgress: usedProgress,
          clockColor: clockColor,
          entryProgress: entryProgress,
          isCritical: isCritical,
          pulseFactor: pulseFactor,
          dialSize: dialSize,
          outerRingSize: outerRingSize,
          innerRingSize: innerRingSize,
          centerPadding: centerPadding,
          loc: loc,
        );
      case 'aurora':
        return _buildAuroraEllipseClock(
          hours: hours,
          minutes: minutes,
          seconds: seconds,
          progress: progress,
          usedProgress: usedProgress,
          clockColor: clockColor,
          entryProgress: entryProgress,
          isCritical: isCritical,
          pulseFactor: pulseFactor,
          dialSize: dialSize,
          outerRingSize: outerRingSize,
          innerRingSize: innerRingSize,
          centerPadding: centerPadding,
          loc: loc,
        );
      case 'quantum':
        return _buildQuantumDiamondClock(
          hours: hours,
          minutes: minutes,
          seconds: seconds,
          progress: progress,
          usedProgress: usedProgress,
          clockColor: clockColor,
          entryProgress: entryProgress,
          isCritical: isCritical,
          pulseFactor: pulseFactor,
          dialSize: dialSize,
          outerRingSize: outerRingSize,
          innerRingSize: innerRingSize,
          centerPadding: centerPadding,
          loc: loc,
        );
      default:
        return _buildProCircularClock(
          hours: hours,
          minutes: minutes,
          seconds: seconds,
          progress: progress,
          usedProgress: usedProgress,
          clockColor: clockColor,
          entryProgress: entryProgress,
          isCritical: isCritical,
          pulseFactor: pulseFactor,
          dialSize: dialSize,
          outerRingSize: outerRingSize,
          innerRingSize: innerRingSize,
          centerPadding: centerPadding,
          loc: loc,
        );
    }
  }

  Widget _buildTimeDigitsColumn({
    required int hours,
    required int minutes,
    required int seconds,
    required double centerPadding,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: centerPadding, vertical: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hours > 0) ...[
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                hours.toString().padLeft(2, '0'),
                style: const TextStyle(
                  fontSize: 46,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.2,
                  color: AppColors.textLight,
                  height: 1.0,
                ),
              ),
            ),
            const SizedBox(height: 1),
            Text(
              'Horas',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.1,
                height: 0.95,
                color: AppColors.textLight.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 1),
          ],
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              minutes.toString().padLeft(2, '0'),
              style: TextStyle(
                fontSize: hours > 0 ? 36 : 42,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.2,
                color: AppColors.textLight,
                height: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            'Minutos',
            style: TextStyle(
              fontSize: hours > 0 ? 13 : 15,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.1,
              height: 0.95,
              color: AppColors.textLight.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 1),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              seconds.toString().padLeft(2, '0'),
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.1,
                color: AppColors.textLight.withValues(alpha: 0.92),
                height: 1.0,
              ),
            ),
          ),
          Text(
            'Segundos',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.05,
              height: 0.95,
              color: AppColors.textLight.withValues(alpha: 0.62),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProCircularClock({
    required int hours,
    required int minutes,
    required int seconds,
    required double progress,
    required double usedProgress,
    required Color clockColor,
    required double entryProgress,
    required bool isCritical,
    required double pulseFactor,
    required double dialSize,
    required double outerRingSize,
    required double innerRingSize,
    required double centerPadding,
    required AppLocalizations? loc,
  }) {
    return SizedBox(
      width: dialSize,
      height: dialSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.textLight.withValues(alpha: 0.08),
                  AppColors.darkSurface.withValues(alpha: 0.05),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: clockColor.withValues(alpha: 0.28),
                  blurRadius: 22,
                  spreadRadius: 3,
                ),
              ],
            ),
          ),
          Semantics(
            label: loc?.remaining ?? 'Remaining',
            value: '${(progress * 100).round()}%',
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              tween: Tween<double>(end: progress),
              builder: (context, animatedProgress, _) {
                return CustomPaint(
                  size: Size.square(outerRingSize),
                  painter: TimeRemainingClockProPainter(
                    remainingProgress: animatedProgress,
                    usedProgress: usedProgress,
                    mainColor: clockColor,
                    tickColor: AppColors.textLight.withValues(alpha: 0.26),
                    entryProgress: entryProgress,
                    showCriticalParticles: isCritical,
                    particlePhase: pulseFactor,
                  ),
                );
              },
            ),
          ),
          Container(
            width: innerRingSize - 8,
            height: innerRingSize - 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.textLight.withValues(alpha: 0.10),
                  AppColors.textLight.withValues(alpha: 0.04),
                ],
              ),
              border: Border.all(
                color: AppColors.textLight.withValues(alpha: 0.20),
                width: 1.2,
              ),
            ),
            child: _buildTimeDigitsColumn(
              hours: hours,
              minutes: minutes,
              seconds: seconds,
              centerPadding: centerPadding,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassicSquareClock({
    required int hours,
    required int minutes,
    required int seconds,
    required double progress,
    required double usedProgress,
    required Color clockColor,
    required double entryProgress,
    required bool isCritical,
    required double pulseFactor,
    required double dialSize,
    required double outerRingSize,
    required double innerRingSize,
    required double centerPadding,
    required AppLocalizations? loc,
  }) {
    return SizedBox(
      width: dialSize,
      height: dialSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.textLight.withValues(alpha: 0.07),
                  const Color(0xFF1A222C).withValues(alpha: 0.85),
                ],
              ),
              border: Border.all(
                color: AppColors.textLight.withValues(alpha: 0.12),
              ),
              boxShadow: [
                BoxShadow(
                  color: clockColor.withValues(alpha: 0.12),
                  blurRadius: 16,
                ),
              ],
            ),
          ),
          Semantics(
            label: loc?.remaining ?? 'Remaining',
            value: '${(progress * 100).round()}%',
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              tween: Tween<double>(end: progress),
              builder: (context, animatedProgress, _) {
                return CustomPaint(
                  size: Size.square(outerRingSize),
                  painter: TimeRemainingClockSquarePainter(
                    remainingProgress: animatedProgress,
                    usedProgress: usedProgress,
                    mainColor: clockColor,
                    tickColor: AppColors.textLight.withValues(alpha: 0.22),
                    entryProgress: 1.0,
                    showCriticalParticles: isCritical,
                    particlePhase: pulseFactor,
                  ),
                );
              },
            ),
          ),
          Container(
            width: innerRingSize - 4,
            height: innerRingSize - 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  AppColors.textLight.withValues(alpha: 0.06),
                  AppColors.textLight.withValues(alpha: 0.02),
                ],
              ),
              border: Border.all(
                color: AppColors.textLight.withValues(alpha: 0.16),
                width: 1.2,
              ),
            ),
            child: _buildTimeDigitsColumn(
              hours: hours,
              minutes: minutes,
              seconds: seconds,
              centerPadding: centerPadding,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeonHexClock({
    required int hours,
    required int minutes,
    required int seconds,
    required double progress,
    required double usedProgress,
    required Color clockColor,
    required double entryProgress,
    required bool isCritical,
    required double pulseFactor,
    required double dialSize,
    required double outerRingSize,
    required double innerRingSize,
    required double centerPadding,
    required AppLocalizations? loc,
  }) {
    final accent = Color.lerp(AppColors.accentPurple, const Color(0xFF7A5CFF), 0.5)!;
    return SizedBox(
      width: dialSize,
      height: dialSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  accent.withValues(alpha: 0.22),
                  const Color(0xFF12081E).withValues(alpha: 0.9),
                ],
              ),
              boxShadow: [
                BoxShadow(color: accent.withValues(alpha: 0.45), blurRadius: 32, spreadRadius: 2),
                BoxShadow(color: AppColors.accentBlue.withValues(alpha: 0.25), blurRadius: 24),
              ],
            ),
          ),
          Semantics(
            label: loc?.remaining ?? 'Remaining',
            value: '${(progress * 100).round()}%',
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              tween: Tween<double>(end: progress),
              builder: (context, animatedProgress, _) {
                return CustomPaint(
                  size: Size.square(outerRingSize),
                  painter: TimeRemainingClockHexPainter(
                    remainingProgress: animatedProgress,
                    usedProgress: usedProgress,
                    mainColor: clockColor,
                    accentColor: accent,
                    entryProgress: entryProgress,
                    showCriticalParticles: isCritical,
                    particlePhase: pulseFactor,
                  ),
                );
              },
            ),
          ),
          Container(
            width: innerRingSize - 14,
            height: innerRingSize - 14,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1E1035).withValues(alpha: 0.95),
                  const Color(0xFF0D0618).withValues(alpha: 0.98),
                ],
              ),
              border: Border.all(
                color: accent.withValues(alpha: 0.55),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentBlue.withValues(alpha: 0.2),
                  blurRadius: 12,
                ),
              ],
            ),
            child: _buildTimeDigitsColumn(
              hours: hours,
              minutes: minutes,
              seconds: seconds,
              centerPadding: centerPadding,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuroraEllipseClock({
    required int hours,
    required int minutes,
    required int seconds,
    required double progress,
    required double usedProgress,
    required Color clockColor,
    required double entryProgress,
    required bool isCritical,
    required double pulseFactor,
    required double dialSize,
    required double outerRingSize,
    required double innerRingSize,
    required double centerPadding,
    required AppLocalizations? loc,
  }) {
    const mint = Color(0xFF2BD6B4);
    const deep = Color(0xFF0A3D36);
    return SizedBox(
      width: dialSize,
      height: dialSize * 0.94,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  mint.withValues(alpha: 0.12),
                  deep.withValues(alpha: 0.5),
                ],
              ),
            ),
          ),
          Semantics(
            label: loc?.remaining ?? 'Remaining',
            value: '${(progress * 100).round()}%',
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              tween: Tween<double>(end: progress),
              builder: (context, animatedProgress, _) {
                return CustomPaint(
                  size: Size(outerRingSize, outerRingSize * 0.88),
                  painter: TimeRemainingClockEllipsePainter(
                    remainingProgress: animatedProgress,
                    usedProgress: usedProgress,
                    mainColor: clockColor,
                    auraMint: mint,
                    auraDeep: deep,
                    entryProgress: entryProgress,
                    showCriticalParticles: isCritical,
                    particlePhase: pulseFactor,
                  ),
                );
              },
            ),
          ),
          Container(
            width: innerRingSize - 12,
            height: (innerRingSize - 12) * 0.88,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: LinearGradient(
                colors: [
                  AppColors.textLight.withValues(alpha: 0.11),
                  mint.withValues(alpha: 0.06),
                ],
              ),
              border: Border.all(
                color: mint.withValues(alpha: 0.35),
                width: 1.2,
              ),
            ),
            child: _buildTimeDigitsColumn(
              hours: hours,
              minutes: minutes,
              seconds: seconds,
              centerPadding: centerPadding,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantumDiamondClock({
    required int hours,
    required int minutes,
    required int seconds,
    required double progress,
    required double usedProgress,
    required Color clockColor,
    required double entryProgress,
    required bool isCritical,
    required double pulseFactor,
    required double dialSize,
    required double outerRingSize,
    required double innerRingSize,
    required double centerPadding,
    required AppLocalizations? loc,
  }) {
    const cyan = Color(0xFF1DEBFF);
    return SizedBox(
      width: dialSize,
      height: dialSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  cyan.withValues(alpha: 0.08),
                  const Color(0xFF020810).withValues(alpha: 0.95),
                ],
              ),
            ),
          ),
          Semantics(
            label: loc?.remaining ?? 'Remaining',
            value: '${(progress * 100).round()}%',
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              tween: Tween<double>(end: progress),
              builder: (context, animatedProgress, _) {
                return CustomPaint(
                  size: Size.square(outerRingSize),
                  painter: TimeRemainingClockDiamondPainter(
                    remainingProgress: animatedProgress,
                    usedProgress: usedProgress,
                    mainColor: clockColor,
                    hudColor: cyan,
                    entryProgress: entryProgress,
                    showCriticalParticles: isCritical,
                    particlePhase: pulseFactor,
                  ),
                );
              },
            ),
          ),
          Container(
            width: innerRingSize - 10,
            height: innerRingSize - 10,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: const Color(0xFF050C12).withValues(alpha: 0.92),
              border: Border.all(color: cyan.withValues(alpha: 0.4)),
              boxShadow: [
                BoxShadow(color: cyan.withValues(alpha: 0.15), blurRadius: 14),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 6,
                  top: 6,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: cyan.withValues(alpha: 0.7), width: 2),
                        left: BorderSide(color: cyan.withValues(alpha: 0.7), width: 2),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: cyan.withValues(alpha: 0.7), width: 2),
                        right: BorderSide(color: cyan.withValues(alpha: 0.7), width: 2),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 6,
                  bottom: 6,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: cyan.withValues(alpha: 0.7), width: 2),
                        left: BorderSide(color: cyan.withValues(alpha: 0.7), width: 2),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: cyan.withValues(alpha: 0.7), width: 2),
                        right: BorderSide(color: cyan.withValues(alpha: 0.7), width: 2),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: _buildTimeDigitsColumn(
                    hours: hours,
                    minutes: minutes,
                    seconds: seconds,
                    centerPadding: centerPadding,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.textLight.withValues(alpha: 0.7), size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textLight,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textLight.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
