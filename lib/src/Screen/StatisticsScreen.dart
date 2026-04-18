import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nofacezone/src/Custom/AppColors.dart';
import 'package:nofacezone/src/Custom/AppLocalizations.dart';
import 'package:nofacezone/src/Providers/AppProvider.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Escuchar cambios del AppProvider para actualizar el tema e idioma
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        AppColors.setTheme(appProvider.colorTheme);
        
        return Scaffold(
      appBar: AppBar(
        title: Builder(
          builder: (context) => Text(AppLocalizations.of(context)!.statistics),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.textLight,
          unselectedLabelColor: AppColors.textLight.withValues(alpha: 0.6),
          indicatorColor: AppColors.accentBlue,
          indicatorWeight: 3,
          tabs: [
            Builder(
              builder: (context) => Tab(text: AppLocalizations.of(context)!.today),
            ),
            Builder(
              builder: (context) => Tab(text: AppLocalizations.of(context)!.week),
            ),
            Builder(
              builder: (context) => Tab(text: AppLocalizations.of(context)!.month),
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
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildTodayTab(),
              _buildWeekTab(),
              _buildMonthTab(),
            ],
          ),
        ),
      ),
    );
      },
    );
  }

  Widget _buildTodayTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resumen del día
          Builder(
            builder: (context) {
              final localizations = AppLocalizations.of(context)!;
              return _buildSummaryCard(
                '📊 ${localizations.daySummary}',
                [
                  _buildStatItem(localizations.freeTimeFromFacebook, '4h 32m', Icons.access_time, Colors.blue),
                  _buildStatItem(localizations.blockedSessions, '7', Icons.block, Colors.red),
                  _buildStatItem(localizations.timeSaved, '2h 15m', Icons.savings, Colors.green),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          
          // Gráfico de actividad horaria
          _buildActivityChart(),
          const SizedBox(height: 24),
          
          // Métricas adicionales
          _buildMetricsGrid(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildWeekTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resumen semanal
          Builder(
            builder: (context) {
              final localizations = AppLocalizations.of(context)!;
              return _buildSummaryCard(
                '📈 ${localizations.weeklySummary}',
                [
                  _buildStatItem(localizations.totalFreeTime, '28h 45m', Icons.calendar_today, Colors.blue),
                  _buildStatItem(localizations.consecutiveDays, '7', Icons.calendar_view_week, Colors.orange),
                  _buildStatItem(localizations.dailyAverage, '4h 6m', Icons.trending_up, Colors.green),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          
          // Gráfico de barras semanal
          _buildWeeklyBarChart(),
          const SizedBox(height: 24),
          
          // Comparación semanal
          _buildWeeklyComparison(),
        ],
      ),
    );
  }

  Widget _buildMonthTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resumen mensual
          Builder(
            builder: (context) {
              final localizations = AppLocalizations.of(context)!;
              return _buildSummaryCard(
                '🏆 ${localizations.monthlySummary}',
                [
                  _buildStatItem(localizations.totalFreeTime, '124h 32m', Icons.calendar_month, Colors.purple),
                  _buildStatItem(localizations.bestStreak, '15 días', Icons.local_fire_department, Colors.orange),
                  _buildStatItem(localizations.successRate, '87%', Icons.check_circle, Colors.green),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          
          // Gráfico mensual
          _buildMonthlyChart(),
          const SizedBox(height: 24),
          
          // Logros del mes
          _buildAchievementsSection(),
        ],
      ),
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
                  style: TextStyle(
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

  Widget _buildActivityChart() {
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
          Builder(
            builder: (context) => Text(
              '📅 ${AppLocalizations.of(context)!.hourlyActivity}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textLight,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildBar('8', 0.3, AppColors.accentBlue),
              _buildBar('10', 0.6, AppColors.accentBlue),
              _buildBar('12', 0.4, AppColors.accentBlue),
              _buildBar('14', 0.7, AppColors.accentBlue),
              _buildBar('16', 0.5, AppColors.accentBlue),
              _buildBar('18', 0.3, AppColors.accentBlue),
              _buildBar('20', 0.2, AppColors.accentBlue),
            ],
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

  Widget _buildMetricsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        Builder(
          builder: (context) {
            final localizations = AppLocalizations.of(context)!;
            return _buildMetricCard('🎯 ${localizations.effectiveness}', '85%', Icons.track_changes, Colors.orange);
          },
        ),
        Builder(
          builder: (context) {
            final localizations = AppLocalizations.of(context)!;
            return _buildMetricCard('💪 ${localizations.motivation}', localizations.high, Icons.emoji_events, Colors.yellow);
          },
        ),
        Builder(
          builder: (context) {
            final localizations = AppLocalizations.of(context)!;
            return _buildMetricCard('😊 ${localizations.mood}', localizations.good, Icons.mood, Colors.blue);
          },
        ),
        Builder(
          builder: (context) {
            final localizations = AppLocalizations.of(context)!;
            return _buildMetricCard('🧠 ${localizations.mentalStrength}', localizations.strong, Icons.fitness_center, Colors.green);
          },
        ),
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
            style: TextStyle(
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

  Widget _buildWeeklyBarChart() {
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
          Builder(
            builder: (context) {
              final localizations = AppLocalizations.of(context)!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📊 ${localizations.weeklyActivity}',
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
                    children: [
                      _buildDayBar(localizations.monday, 0.6),
                      _buildDayBar(localizations.tuesday, 0.8),
                      _buildDayBar(localizations.wednesday, 0.7),
                      _buildDayBar(localizations.thursday, 0.9),
                      _buildDayBar(localizations.friday, 0.5),
                      _buildDayBar(localizations.saturday, 0.4),
                      _buildDayBar(localizations.sunday, 0.6),
                    ],
                  ),
                ],
              );
            },
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

  Widget _buildWeeklyComparison() {
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
          Builder(
            builder: (context) {
              final localizations = AppLocalizations.of(context)!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📉 ${localizations.weeklyComparison}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildComparisonRow(localizations.lastWeek, '22h 30m', 0.75, Colors.red),
                  const SizedBox(height: 12),
                  _buildComparisonRow(localizations.thisWeek, '28h 45m', 0.95, Colors.green),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          Builder(
            builder: (context) {
              final localizations = AppLocalizations.of(context)!;
              return Text(
                '➕ ${localizations.improvement} 27%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              );
            },
          ),
        ],
      ),
    );
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

  Widget _buildMonthlyChart() {
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
          Builder(
            builder: (context) => Text(
              '📅 ${AppLocalizations.of(context)!.monthlyProgress}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textLight,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Builder(
            builder: (context) {
              final localizations = AppLocalizations.of(context)!;
              return Column(
                children: [
                  _buildWeekRow('${localizations.weekNumber} 1', 0.6),
                  _buildWeekRow('${localizations.weekNumber} 2', 0.7),
                  _buildWeekRow('${localizations.weekNumber} 3', 0.9),
                  _buildWeekRow('${localizations.weekNumber} 4', 0.85),
                ],
              );
            },
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
              widthFactor: progress,
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

  Widget _buildAchievementsSection() {
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
          Builder(
            builder: (context) {
              final localizations = AppLocalizations.of(context)!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🏆 ${localizations.monthlyAchievements}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildAchievementBadge('🔥 ${localizations.streak7Days}', Icons.local_fire_department, Colors.orange, true),
                  const SizedBox(height: 12),
                  _buildAchievementBadge('🎯 ${localizations.weeklyGoalAchieved}', Icons.flag, Colors.blue, true),
                  const SizedBox(height: 12),
                  _buildAchievementBadge('⚡ ${localizations.hours100Free}', Icons.bolt, Colors.yellow, true),
                ],
              );
            },
          ),
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