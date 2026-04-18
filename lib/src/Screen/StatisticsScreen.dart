import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nofacezone/src/Custom/AppColors.dart';
import 'package:nofacezone/src/Custom/AppLocalizations.dart';
import 'package:nofacezone/src/Providers/AppProvider.dart';
import 'package:nofacezone/src/Services/PreferencesService.dart';
import 'package:nofacezone/src/Services/UsageLimitsService.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime _mondayOfWeek(DateTime d) {
  final day = _dateOnly(d);
  return day.subtract(Duration(days: day.weekday - DateTime.monday));
}

String _dateKey(DateTime d) => _dateOnly(d).toIso8601String().split('T')[0];

String _formatMinutesAsHm(AppLocalizations loc, int totalMinutes) {
  if (totalMinutes <= 0) return '0${loc.minutesShort}';
  final h = totalMinutes ~/ 60;
  final m = totalMinutes % 60;
  if (h <= 0) return '$m${loc.minutesShort}';
  if (m == 0) return '$h${loc.hoursShort}';
  return '$h${loc.hoursShort} $m${loc.minutesShort}';
}

Map<String, Map<String, dynamic>> _recordsByDate(List<Map<String, dynamic>> rows) {
  final map = <String, Map<String, dynamic>>{};
  for (final r in rows) {
    final k = r['fecha'] as String?;
    if (k != null) map[k] = r;
  }
  return map;
}

int _freeMinutesFromUsed(int usedMinutes) {
  const dayCap = 24 * 60;
  return (dayCap - usedMinutes).clamp(0, dayCap);
}

List<double> _hourlyFractionsFromSessions(
  List<Map<String, dynamic>> sessions,
  int totalUsedFallback,
) {
  final buckets = List<double>.filled(24, 0);
  final now = DateTime.now();

  for (final s in sessions) {
    final inicioStr = s['inicio_sesion'] as String?;
    if (inicioStr == null) continue;
    DateTime start;
    try {
      start = DateTime.parse(inicioStr);
    } catch (_) {
      continue;
    }
    DateTime end;
    final finStr = s['fin_sesion'] as String?;
    final estado = s['estado'] as String? ?? '';
    if (finStr != null) {
      try {
        end = DateTime.parse(finStr);
      } catch (_) {
        end = now;
      }
    } else if (estado == 'activa') {
      end = now;
    } else {
      continue;
    }
    if (!end.isAfter(start)) continue;

    final capEnd = end.difference(start).inHours > 24 ? start.add(const Duration(hours: 24)) : end;
    var cursor = start;
    while (cursor.isBefore(capEnd)) {
      final h = cursor.hour;
      final nextHourBoundary = DateTime(cursor.year, cursor.month, cursor.day, cursor.hour + 1);
      final segmentEnd = nextHourBoundary.isBefore(capEnd) ? nextHourBoundary : capEnd;
      final mins = segmentEnd.difference(cursor).inMinutes.clamp(0, 60);
      buckets[h] += mins.toDouble();
      cursor = segmentEnd;
    }
  }

  if (buckets.every((e) => e == 0) && totalUsedFallback > 0) {
    final per = totalUsedFallback / 24.0;
    for (var i = 0; i < 24; i++) {
      buckets[i] = per;
    }
  }

  final maxV = buckets.reduce((a, b) => a > b ? a : b);
  if (maxV <= 0) return List<double>.filled(7, 0.08);
  const sampleHours = [8, 10, 12, 14, 16, 18, 20];
  return sampleHours.map((h) => (buckets[h] / maxV).clamp(0.08, 1.0)).toList();
}

int _currentSuccessStreak(Map<String, Map<String, dynamic>> byDate, DateTime startDay, int fallbackLimit) {
  var streak = 0;
  var d = _dateOnly(startDay);
  for (var i = 0; i < 120; i++) {
    final key = _dateKey(d);
    final rec = byDate[key];
    if (rec == null) break;
    final used = rec['tiempo_usado_minutos'] as int? ?? 0;
    final lim = rec['limite_del_dia_minutos'] as int? ?? fallbackLimit;
    if (lim <= 0) break;
    if (used <= lim) {
      streak++;
    } else {
      break;
    }
    d = d.subtract(const Duration(days: 1));
  }
  return streak;
}

int _bestSuccessStreakForRecords(Iterable<Map<String, dynamic>> records, int fallbackLimit) {
  final sorted = records.where((r) => r['fecha'] != null).toList()
    ..sort((a, b) => (a['fecha'] as String).compareTo(b['fecha'] as String));

  var best = 0;
  var cur = 0;
  DateTime? lastDay;

  for (final r in sorted) {
    final used = r['tiempo_usado_minutos'] as int? ?? 0;
    final lim = r['limite_del_dia_minutos'] as int? ?? fallbackLimit;
    final ok = lim > 0 && used <= lim;
    DateTime day;
    try {
      day = _dateOnly(DateTime.parse(r['fecha'] as String));
    } catch (_) {
      continue;
    }

    if (!ok) {
      cur = 0;
      lastDay = null;
      continue;
    }

    if (lastDay == null) {
      cur = 1;
    } else {
      final diff = day.difference(lastDay).inDays;
      if (diff == 1) {
        cur++;
      } else if (diff == 0) {
        // mismo registro duplicado
      } else {
        cur = 1;
      }
    }
    lastDay = day;
    if (cur > best) best = cur;
  }
  return best;
}

class _StatisticsScreenState extends State<StatisticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _loading = true;
  String? _loadError;

  bool _loggedIn = false;
  int _todayUsed = 0;
  int _todayLimit = 60;
  int _blockedSessions = 0;

  List<double> _hourlyBarFractions = List<double>.filled(7, 0.12);

  List<int> _weekDayUsedMinutes = List<int>.filled(7, 0);
  int _weekMaxUsed = 1;

  int _thisWeekFreeTotal = 0;
  int _lastWeekFreeTotal = 0;
  int _improvementPct = 0;

  int _consecutiveSuccessDays = 0;
  int _weekAvgFreeDaily = 0;

  int _monthFreeTotal = 0;
  int _monthBestStreak = 0;
  int _monthSuccessPct = 0;
  List<double> _monthChunkProgress = List<double>.filled(4, 0.08);

  int _effectivenessPct = 0;
  String _motivationLabel = '';
  String _moodLabel = '';
  String _mentalLabel = '';

  bool _achStreak7 = false;
  bool _achWeeklyGoal = false;
  bool _ach100hFree = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadStatistics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      await PreferencesService.init();
      final blocked = PreferencesService.getBlockedSessionsCount();
      final uid = Supabase.instance.client.auth.currentUser?.id;

      if (uid == null) {
        if (!mounted) return;
        setState(() {
          _loggedIn = false;
          _blockedSessions = blocked;
          _todayUsed = 0;
          _todayLimit = 60;
          _hourlyBarFractions = List<double>.filled(7, 0.12);
          _weekDayUsedMinutes = List<int>.filled(7, 0);
          _weekMaxUsed = 1;
          _thisWeekFreeTotal = 0;
          _lastWeekFreeTotal = 0;
          _improvementPct = 0;
          _consecutiveSuccessDays = 0;
          _weekAvgFreeDaily = 0;
          _monthFreeTotal = 0;
          _monthBestStreak = 0;
          _monthSuccessPct = 0;
          _monthChunkProgress = List<double>.filled(4, 0.08);
          _effectivenessPct = 0;
          _motivationLabel = '';
          _moodLabel = '';
          _mentalLabel = '';
          _achStreak7 = false;
          _achWeeklyGoal = false;
          _ach100hFree = false;
          _loading = false;
        });
        return;
      }

      final today = DateTime.now();
      final monday = _mondayOfWeek(today);
      final lastMonday = monday.subtract(const Duration(days: 7));
      final lastSunday = monday.subtract(const Duration(days: 1));
      final historyStart = monday.subtract(const Duration(days: 7 * 10));

      final todayRec = await UsageLimitsService.getOrCreateTodayUsage();
      final sessions = await UsageLimitsService.getTodaySessions();
      final limits = await UsageLimitsService.getOrCreateUsageLimits();
      final history = await UsageLimitsService.getDailyUsageRecordsInRange(historyStart, today);

      final defaultLimit = limits?['limite_diario_minutos'] as int? ?? 60;
      final weeklyGoalHours = limits?['meta_semanal_horas'] as int? ?? 10;

      final usedToday = todayRec?['tiempo_usado_minutos'] as int? ?? 0;
      final limitToday = todayRec?['limite_del_dia_minutos'] as int? ?? defaultLimit;

      final byDate = _recordsByDate(history);

      final hourlyFr = _hourlyFractionsFromSessions(sessions, usedToday);

      final weekUsed = List<int>.generate(7, (i) {
        final d = monday.add(Duration(days: i));
        final rec = byDate[_dateKey(d)];
        return rec?['tiempo_usado_minutos'] as int? ?? 0;
      });
      final weekMax = weekUsed.fold<int>(1, (m, u) => u > m ? u : m);

      var thisWeekFree = 0;
      for (var i = 0; i < 7; i++) {
        final d = monday.add(Duration(days: i));
        final rec = byDate[_dateKey(d)];
        final u = rec?['tiempo_usado_minutos'] as int? ?? 0;
        thisWeekFree += _freeMinutesFromUsed(u);
      }

      var lastWeekFree = 0;
      for (var i = 0; i < 7; i++) {
        final d = lastMonday.add(Duration(days: i));
        if (d.isAfter(lastSunday)) break;
        final rec = byDate[_dateKey(d)];
        final u = rec?['tiempo_usado_minutos'] as int? ?? 0;
        lastWeekFree += _freeMinutesFromUsed(u);
      }

      var improvement = 0;
      if (lastWeekFree > 0) {
        improvement = (((thisWeekFree - lastWeekFree) / lastWeekFree) * 100).round();
      } else if (thisWeekFree > 0) {
        improvement = 100;
      }

      final streak = _currentSuccessStreak(byDate, today, defaultLimit);
      final avgFree = thisWeekFree ~/ 7;

      final monthRecs = history.where((r) {
        try {
          final fd = DateTime.parse(r['fecha'] as String);
          return fd.year == today.year && fd.month == today.month;
        } catch (_) {
          return false;
        }
      }).toList();

      var monthFree = 0;
      for (final r in monthRecs) {
        monthFree += _freeMinutesFromUsed(r['tiempo_usado_minutos'] as int? ?? 0);
      }

      var successes = 0;
      for (final r in monthRecs) {
        final used = r['tiempo_usado_minutos'] as int? ?? 0;
        final lim = r['limite_del_dia_minutos'] as int? ?? defaultLimit;
        if (lim > 0 && used <= lim) successes++;
      }
      final successPct = monthRecs.isEmpty ? 0 : ((100 * successes) ~/ monthRecs.length);

      final bestStreakMonth = _bestSuccessStreakForRecords(monthRecs, defaultLimit);

      final chunks = List<List<Map<String, dynamic>>>.generate(4, (_) => []);
      for (final r in monthRecs) {
        try {
          final dt = DateTime.parse(r['fecha'] as String);
          final idx = ((dt.day - 1) ~/ 7).clamp(0, 3);
          chunks[idx].add(r);
        } catch (_) {}
      }

      final chunkProgress = List<double>.generate(4, (cIdx) {
        final ch = chunks[cIdx];
        if (ch.isEmpty) return 0.08;
        var free = 0;
        for (final r in ch) {
          free += _freeMinutesFromUsed(r['tiempo_usado_minutos'] as int? ?? 0);
        }
        return (free / (7 * 24 * 60)).clamp(0.08, 1.0);
      });

      final eff = limitToday > 0
          ? ((100 * (limitToday - usedToday) / limitToday).round().clamp(0, 100))
          : 100;

      var sumUsedThisIsoWeek = 0;
      for (var i = 0; i < 7; i++) {
        final d = monday.add(Duration(days: i));
        final rec = byDate[_dateKey(d)];
        sumUsedThisIsoWeek += rec?['tiempo_usado_minutos'] as int? ?? 0;
      }

      if (!mounted) return;
      setState(() {
        _loggedIn = true;
        _blockedSessions = blocked;
        _todayUsed = usedToday;
        _todayLimit = limitToday;
        _hourlyBarFractions = hourlyFr;
        _weekDayUsedMinutes = weekUsed;
        _weekMaxUsed = weekMax;
        _thisWeekFreeTotal = thisWeekFree;
        _lastWeekFreeTotal = lastWeekFree;
        _improvementPct = improvement;
        _consecutiveSuccessDays = streak;
        _weekAvgFreeDaily = avgFree;
        _monthFreeTotal = monthFree;
        _monthBestStreak = bestStreakMonth;
        _monthSuccessPct = successPct;
        _monthChunkProgress = chunkProgress;
        _effectivenessPct = eff;
        _achStreak7 = streak >= 7;
        _achWeeklyGoal = sumUsedThisIsoWeek <= weeklyGoalHours * 60;
        _ach100hFree = monthFree >= 100 * 60;
        _loading = false;
      });

      final loc = AppLocalizations.of(context);
      if (loc != null && mounted) {
        _applyTierLabels(loc);
        setState(() {});
      }
    } catch (e, st) {
      debugPrint('StatisticsScreen load error: $e\n$st');
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _loading = false;
      });
    }
  }

  void _applyTierLabels(AppLocalizations loc) {
    final eff = _effectivenessPct;
    if (eff >= 75) {
      _motivationLabel = loc.high;
      _moodLabel = loc.good;
      _mentalLabel = loc.strong;
    } else if (eff >= 45) {
      _motivationLabel = loc.moderate;
      _moodLabel = loc.moderate;
      _mentalLabel = loc.regular;
    } else {
      _motivationLabel = loc.weak;
      _moodLabel = loc.weak;
      _mentalLabel = loc.weak;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        AppColors.setTheme(appProvider.colorTheme);
        final loc = AppLocalizations.of(context)!;
        if (_motivationLabel.isEmpty && _loggedIn) {
          _applyTierLabels(loc);
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(loc.statistics),
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                tooltip: loc.refresh,
                icon: const Icon(Icons.refresh),
                onPressed: _loading ? null : _loadStatistics,
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              labelColor: AppColors.textLight,
              unselectedLabelColor: AppColors.textLight.withValues(alpha: 0.6),
              indicatorColor: AppColors.accentBlue,
              indicatorWeight: 3,
              tabs: [
                Tab(text: loc.today),
                Tab(text: loc.week),
                Tab(text: loc.month),
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
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _loadError != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  loc.errorGettingInfo,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: AppColors.textLight),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _loadError!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.textLight.withValues(alpha: 0.8),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                FilledButton(
                                  onPressed: _loadStatistics,
                                  child: Text(loc.refresh),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            if (!_loggedIn)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                                child: Material(
                                  color: Colors.amber.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.info_outline, color: Colors.amber),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            loc.statisticsSignInHint,
                                            style: const TextStyle(
                                              color: AppColors.textLight,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            Expanded(
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  _wrapRefresh(_buildTodayTab(loc)),
                                  _wrapRefresh(_buildWeekTab(loc)),
                                  _wrapRefresh(_buildMonthTab(loc)),
                                ],
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

  Widget _wrapRefresh(Widget child) {
    return RefreshIndicator(
      color: AppColors.accentBlue,
      onRefresh: _loadStatistics,
      child: child,
    );
  }

  Widget _buildTodayTab(AppLocalizations loc) {
    final freeToday = _freeMinutesFromUsed(_todayUsed);
    final savedToday = _todayLimit > 0 ? (_todayLimit - _todayUsed).clamp(0, _todayLimit) : 0;
    final effLabel = !_loggedIn
        ? loc.effectivenessNoData
        : '${_effectivenessPct.clamp(0, 100)}%';

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        _buildSummaryCard(
          '📊 ${loc.daySummary}',
          [
            _buildStatItem(
              loc.freeTimeFromFacebook,
              _formatMinutesAsHm(loc, freeToday),
              Icons.access_time,
              Colors.blue,
            ),
            _buildStatItem(
              loc.blockedSessions,
              '$_blockedSessions',
              Icons.block,
              Colors.red,
            ),
            _buildStatItem(
              loc.timeSaved,
              _formatMinutesAsHm(loc, savedToday),
              Icons.savings,
              Colors.green,
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildActivityChart(loc),
        const SizedBox(height: 24),
        _buildMetricsGrid(loc, effLabel),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildWeekTab(AppLocalizations loc) {
    final labels = [loc.monday, loc.tuesday, loc.wednesday, loc.thursday, loc.friday, loc.saturday, loc.sunday];
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        _buildSummaryCard(
          '📈 ${loc.weeklySummary}',
          [
            _buildStatItem(
              loc.totalFreeTime,
              _formatMinutesAsHm(loc, _thisWeekFreeTotal),
              Icons.calendar_today,
              Colors.blue,
            ),
            _buildStatItem(
              loc.consecutiveDays,
              '$_consecutiveSuccessDays',
              Icons.calendar_view_week,
              Colors.orange,
            ),
            _buildStatItem(
              loc.dailyAverage,
              _formatMinutesAsHm(loc, _weekAvgFreeDaily),
              Icons.trending_up,
              Colors.green,
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildWeeklyBarChart(loc, labels),
        const SizedBox(height: 24),
        _buildWeeklyComparison(loc),
      ],
    );
  }

  Widget _buildMonthTab(AppLocalizations loc) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        _buildSummaryCard(
          '🏆 ${loc.monthlySummary}',
          [
            _buildStatItem(
              loc.totalFreeTime,
              _formatMinutesAsHm(loc, _monthFreeTotal),
              Icons.calendar_month,
              Colors.purple,
            ),
            _buildStatItem(
              loc.bestStreak,
              '$_monthBestStreak ${loc.days}',
              Icons.local_fire_department,
              Colors.orange,
            ),
            _buildStatItem(
              loc.successRate,
              '${_monthSuccessPct.clamp(0, 100)}%',
              Icons.check_circle,
              Colors.green,
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildMonthlyChart(loc),
        const SizedBox(height: 24),
        _buildAchievementsSection(loc),
      ],
    );
  }

  Widget _buildSummaryCard(String title, List<Widget> items) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.textLight.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textLight.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.textLight.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 16),
          ...items,
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.textLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textLight.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityChart(AppLocalizations loc) {
    const labels = ['8', '10', '12', '14', '16', '18', '20'];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.textLight.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textLight.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📅 ${loc.hourlyActivity}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (i) {
              final h = _hourlyBarFractions[i].clamp(0.08, 1.0);
              return _buildBar(labels[i], h, AppColors.accentBlue);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(String label, double height, Color color) {
    return Column(
      children: [
        Container(
          width: 30,
          height: 120 * height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [color, color.withValues(alpha: 0.6)],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textLight.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsGrid(AppLocalizations loc, String effectivenessValue) {
    final mot = _motivationLabel.isEmpty ? loc.moderate : _motivationLabel;
    final mood = _moodLabel.isEmpty ? loc.good : _moodLabel;
    final mental = _mentalLabel.isEmpty ? loc.strong : _mentalLabel;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _buildMetricCard('🎯 ${loc.effectiveness}', effectivenessValue, Icons.track_changes, Colors.orange),
        _buildMetricCard('💪 ${loc.motivation}', mot, Icons.emoji_events, Colors.yellow),
        _buildMetricCard('😊 ${loc.mood}', mood, Icons.mood, Colors.blue),
        _buildMetricCard('🧠 ${loc.mentalStrength}', mental, Icons.fitness_center, Colors.green),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.textLight.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textLight.withValues(alpha: 0.9),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyBarChart(AppLocalizations loc, List<String> dayLabels) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.textLight.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textLight.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📊 ${loc.weeklyActivity}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (i) {
              final used = _weekDayUsedMinutes[i];
              final frac = _weekMaxUsed > 0 ? (used / _weekMaxUsed).clamp(0.12, 1.0) : 0.12;
              return _buildDayBar(dayLabels[i], frac);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDayBar(String label, double height) {
    return Column(
      children: [
        Container(
          width: 35,
          height: 140 * height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [AppColors.accentPurple, AppColors.accentBlue],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textLight.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyComparison(AppLocalizations loc) {
    final sign = _improvementPct >= 0 ? '➕' : '➖';
    final pct = _improvementPct.abs();
    final color = _improvementPct >= 0 ? Colors.green : Colors.orange;

    final thisProgress = _normalizeProgress(_thisWeekFreeTotal);
    final lastProgress = _normalizeProgress(_lastWeekFreeTotal);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.textLight.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textLight.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📉 ${loc.weeklyComparison}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 16),
          _buildComparisonRow(
            loc.lastWeek,
            _formatMinutesAsHm(loc, _lastWeekFreeTotal),
            lastProgress,
            Colors.red,
          ),
          const SizedBox(height: 12),
          _buildComparisonRow(
            loc.thisWeek,
            _formatMinutesAsHm(loc, _thisWeekFreeTotal),
            thisProgress,
            Colors.green,
          ),
          const SizedBox(height: 8),
          Text(
            '$sign ${loc.improvement} $pct%',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  double _normalizeProgress(int freeMinutes) {
    const cap = 7 * 24 * 60;
    return (freeMinutes / cap).clamp(0.05, 1.0);
  }

  Widget _buildComparisonRow(String label, String value, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textLight,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.textLight.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyChart(AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.textLight.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textLight.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📅 ${loc.monthlyProgress}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 20),
          Column(
            children: List.generate(4, (i) {
              return _buildWeekRow('${loc.weekNumber} ${i + 1}', _monthChunkProgress[i]);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekRow(String label, double progress) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textLight,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 10,
            decoration: BoxDecoration(
              color: AppColors.textLight.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(5),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: AppColors.accentGradient),
                  borderRadius: const BorderRadius.all(Radius.circular(5)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection(AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.textLight.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textLight.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🏆 ${loc.monthlyAchievements}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 16),
          _buildAchievementBadge('🔥 ${loc.streak7Days}', Icons.local_fire_department, Colors.orange, _achStreak7),
          const SizedBox(height: 12),
          _buildAchievementBadge('🎯 ${loc.weeklyGoalAchieved}', Icons.flag, Colors.blue, _achWeeklyGoal),
          const SizedBox(height: 12),
          _buildAchievementBadge('⚡ ${loc.hours100Free}', Icons.bolt, Colors.yellow, _ach100hFree),
        ],
      ),
    );
  }

  Widget _buildAchievementBadge(String title, IconData icon, Color color, bool earned) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.textLight.withValues(alpha: earned ? 0.1 : 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: earned ? color : AppColors.textLight.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: earned ? color.withValues(alpha: 0.2) : AppColors.textLight.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: earned ? color : AppColors.textLight.withValues(alpha: 0.3),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: earned ? AppColors.textLight : AppColors.textLight.withValues(alpha: 0.5),
              ),
            ),
          ),
          if (earned)
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 24,
            ),
        ],
      ),
    );
  }
}
