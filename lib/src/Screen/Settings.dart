import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:nofacezone/src/Custom/AppColors.dart';
import 'package:nofacezone/src/Custom/Library.dart';
import 'package:nofacezone/src/Custom/Config.dart';
import 'package:nofacezone/src/Custom/AppLocalizations.dart';
import 'package:nofacezone/src/Custom/CustomSnackBar.dart';
import 'package:nofacezone/src/Custom/TimeLimitSlider.dart';
import 'package:nofacezone/src/Providers/AppProvider.dart';
import 'package:nofacezone/src/Providers/UserProvider.dart';
import 'package:nofacezone/src/Screen/EditProfileScreen.dart';
import 'package:nofacezone/src/Screen/ReportsScreen.dart';
import 'package:nofacezone/src/Services/PreferencesService.dart';
import 'package:nofacezone/src/Custom/AppImageProviders.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  @override
  Widget build(BuildContext context) {
    return Selector<AppProvider, String>(
      selector: (_, p) => '${p.colorTheme}|${p.language}',
      builder: (context, _, __) {
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        AppColors.setTheme(appProvider.colorTheme);
        final backLabel = MaterialLocalizations.of(context).backButtonTooltip;

        return Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.of(context)?.settings ?? 'Configuración'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              tooltip: backLabel,
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RepaintBoundary(child: _buildProfileSection()),
                    const SizedBox(height: 32),
                    RepaintBoundary(child: _buildNotificationsSection()),
                    const SizedBox(height: 24),
                    RepaintBoundary(child: _buildUsageLimitsSection()),
                    const SizedBox(height: 24),
                    RepaintBoundary(child: _buildAppearanceSection()),
                    const SizedBox(height: 24),
                    RepaintBoundary(child: _buildAdvancedSection()),
                    const SizedBox(height: 24),
                    RepaintBoundary(child: _buildAboutSection()),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileSection() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.user;
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
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
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
                      ? ExcludeSemantics(
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: networkAvatarProvider(user.profileImage!, logicalDiameter: 60),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.person,
                          color: AppColors.textLight,
                          size: 32,
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? 'Usuario',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? 'usuario@email.com',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textLight.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: AppLocalizations.of(context)?.editProfile ?? 'Editar perfil',
                icon: const Icon(Icons.edit, color: AppColors.textLight),
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const EditProfileScreen(),
                    ),
                  );
                  // Actualizar la pantalla cuando se regrese
                  if (mounted) {
                    setState(() {});
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationsSection() {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final localizations = AppLocalizations.of(context)!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🔔 ${localizations.notificationsTitle}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingItem(
              localizations.enableNotificationsTitle,
              localizations.receiveAlerts,
              Icons.notifications,
              appProvider.notificationsEnabled,
              (value) => appProvider.setNotificationsEnabled(value),
            ),
            const SizedBox(height: 12),
            _buildSettingItemWithValue(
              localizations.notificationIntervalTitle,
              localizations.reminderFrequency,
              Icons.timer,
              '${appProvider.notificationInterval} ${localizations.minutes}',
              () => _showNotificationIntervalDialog(appProvider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUsageLimitsSection() {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final localizations = AppLocalizations.of(context)!;
        
        // Función para formatear el límite diario en formato abreviado
        String formatDailyLimit(int minutes) {
          final hours = minutes ~/ 60;
          final mins = minutes % 60;
          
          if (hours == 0) {
            return '$mins ${localizations.minutesShort}';
          } else if (mins == 0) {
            return '$hours ${localizations.hoursShort}';
          } else {
            final connector = ' ${localizations.timeConnector} ';
            return '$hours ${localizations.hoursShort}$connector$mins ${localizations.minutesShort}';
          }
        }
        
        // Función para formatear la meta semanal (solo horas)
        String formatWeeklyGoal(int hours) {
          return '$hours ${localizations.hoursShort}';
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '⏱️ ${localizations.usageLimitsTitle}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingItemWithValue(
              localizations.dailyLimitTitle,
              localizations.dailyLimitDescription,
              Icons.access_time,
              formatDailyLimit(appProvider.dailyUsageLimit),
              () => _showDailyLimitDialog(appProvider),
            ),
            const SizedBox(height: 12),
            _buildSettingItemWithValue(
              localizations.weeklyGoalTitle,
              localizations.weeklyGoalDescription,
              Icons.track_changes,
              formatWeeklyGoal(appProvider.weeklyGoal),
              () => _showWeeklyGoalDialog(appProvider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAppearanceSection() {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final localizations = AppLocalizations.of(context)!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🎨 ${localizations.appearance}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingItemWithValue(
              localizations.theme,
              localizations.appearanceDescription,
              Icons.palette,
              _getThemeName(appProvider.themeMode, localizations),
              () => _showThemeDialog(appProvider),
            ),
            const SizedBox(height: 12),
            _buildSettingItemWithValue(
              localizations.language,
              localizations.selectLanguageDescription,
              Icons.language,
              _getLanguageName(appProvider.language, localizations),
              () => _showLanguageDialog(appProvider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAdvancedSection() {
    final localizations = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '⚙️ ${localizations.advancedSettingsTitle}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textLight,
          ),
        ),
        const SizedBox(height: 16),
        _buildSettingItemWithValue(
          localizations.reportsAndExportation,
          localizations.reportsAndExportationDescription,
          Icons.assessment,
          null,
          () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const ReportsScreen(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildSettingItemWithValue(
          localizations.exportDataTitle,
          localizations.exportDataDescription,
          Icons.file_download,
          null,
          () => _exportData(),
        ),
        const SizedBox(height: 12),
        _buildSettingItemWithValue(
          localizations.importDataTitle,
          localizations.importDataDescription,
          Icons.file_upload,
          null,
          () => _importData(),
        ),
        const SizedBox(height: 12),
        _buildSettingItemWithValue(
          localizations.resetSettingsTitle,
          localizations.resetSettingsDescription,
          Icons.restore,
          null,
          () => _showResetDialog(),
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    final localizations = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ℹ️ ${localizations.aboutTitle}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textLight,
          ),
        ),
        const SizedBox(height: 16),
        _buildSettingItemWithValue(
          localizations.versionTitle,
          localizations.appInfo,
          Icons.info,
          null,
          () => _showVersionInfo(),
        ),
        const SizedBox(height: 12),
        _buildSettingItemWithValue(
          localizations.termsAndConditions,
          localizations.readLegalDocuments,
          Icons.description,
          null,
          () => _showTermsAndConditions(),
        ),
        const SizedBox(height: 12),
        _buildSettingItemWithValue(
          localizations.privacyPolicy,
          localizations.howWeProtectData,
          Icons.privacy_tip,
          null,
          () => _showPrivacyPolicy(),
        ),
        const SizedBox(height: 12),
        _buildSettingItemWithValue(
          localizations.contact,
          localizations.supportAndSuggestions,
          Icons.support_agent,
          null,
          () => _showContactInfo(),
        ),
        const SizedBox(height: 24),
        _buildSettingItemWithValue(
          localizations.logout,
          localizations.exitApplication,
          Icons.logout,
          null,
          () => _logout(),
        ),
      ],
    );
  }

  Widget _buildSettingItem(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.textLight.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.textLight.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.textLight.withValues(alpha: 0.1),
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
            child: Icon(icon, color: AppColors.accentBlue, size: 20),
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
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textLight.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.accentBlue,
            activeTrackColor: AppColors.accentBlue.withValues(alpha: 0.3),
            inactiveThumbColor: AppColors.textLight.withValues(alpha: 0.5),
            inactiveTrackColor: AppColors.textLight.withValues(alpha: 0.2),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItemWithValue(
    String title,
    String subtitle,
    IconData icon,
    String? value,
    VoidCallback? onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.textLight.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.textLight.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.textLight.withValues(alpha: 0.1),
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
              child: Icon(icon, color: AppColors.accentBlue, size: 20),
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
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textLight.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            if (value != null)
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.accentBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textLight.withValues(alpha: 0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showNotificationIntervalDialog(AppProvider appProvider) async {
    final localizations = AppLocalizations.of(context)!;
    final intervals = [5, 10, 15, 30, 60];
    final selectedInterval = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: Text(
          localizations.notificationIntervalTitle,
          style: const TextStyle(color: AppColors.textLight),
        ),
        content: RadioGroup<int>(
          groupValue: appProvider.notificationInterval,
          onChanged: (value) {
            if (value != null) Navigator.pop(context, value);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: intervals.map((interval) {
              return RadioListTile<int>(
                title: Text(
                  '$interval ${localizations.minutes}',
                  style: const TextStyle(color: AppColors.textLight),
                ),
                value: interval,
                activeColor: AppColors.accentBlue,
              );
            }).toList(),
          ),
        ),
      ),
    );

    if (selectedInterval != null) {
      appProvider.setNotificationInterval(selectedInterval);
      if (mounted) {
        final updatedLocalizations = AppLocalizations.of(context)!;
        CustomSnackBar.showInfo(
          context,
          '${updatedLocalizations.notificationIntervalTitle} ${updatedLocalizations.languageUpdated.toLowerCase()}: $selectedInterval ${updatedLocalizations.minutes}',
          icon: Icons.notifications_active_rounded,
        );
      }
    }
  }

  Future<void> _showDailyLimitDialog(AppProvider appProvider) async {
    final localizations = AppLocalizations.of(context)!;
    
    // Convertir minutos a incrementos de 10 minutos
    // Redondear al incremento de 10 minutos más cercano
    final currentMinutes = appProvider.dailyUsageLimit;
    final currentTenMinBlocks = (currentMinutes / 10.0).round();
    double selectedTenMinBlocks = currentTenMinBlocks.clamp(1, 144).toDouble(); // 10 min a 24 horas (144 bloques de 10 min)
    
    // Función para formatear el tiempo (formato abreviado)
    String formatTime(double tenMinBlocks) {
      final totalMinutes = (tenMinBlocks * 10).round();
      final hours = totalMinutes ~/ 60;
      final minutes = totalMinutes % 60;
      
      // Usar formato abreviado (h/min) para que quepa en una línea
      if (hours == 0) {
        return '$minutes ${localizations.minutesShort}';
      } else if (minutes == 0) {
        return '$hours ${localizations.hoursShort}';
      } else {
        // Usar el conector localizado
        final connector = ' ${localizations.timeConnector} ';
        return '$hours ${localizations.hoursShort}$connector$minutes ${localizations.minutesShort}';
      }
    }
    
    final result = await showDialog<double>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1F3A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localizations.timeLimitsTitle,
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                localizations.timeLimitsSubtitle,
                style: TextStyle(
                  color: AppColors.textLight.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  '${localizations.dailyLimitTitle}: ${formatTime(selectedTenMinBlocks)}',
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 15, // Reducido para que quepa en una línea
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                TimeLimitSlider(
                  value: selectedTenMinBlocks,
                  minValue: 1.0, // 10 minutos
                  maxValue: 144.0, // 24 horas (144 bloques de 10 min)
                  divisions: 143, // 144 valores (10 min, 20 min, 30 min, ..., 24h)
                  leftLabel: localizations.workLimitLabel,
                  rightLabel: localizations.personalLimitLabel,
                  onChanged: (value) {
                    setState(() {
                      selectedTenMinBlocks = value.roundToDouble(); // Redondear al bloque de 10 min más cercano
                    });
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  localizations.alertMessage,
                  style: TextStyle(
                    color: AppColors.textLight.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                localizations.cancel,
                style: TextStyle(color: AppColors.textLight.withValues(alpha: 0.7)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, selectedTenMinBlocks),
              child: Text(
                localizations.save,
                style: TextStyle(
                  color: AppColors.accentBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      // Convertir bloques de 10 minutos a minutos
      final limitInMinutes = (result * 10).round();
      await appProvider.setDailyUsageLimit(limitInMinutes);
      if (mounted) {
        final updatedLocalizations = AppLocalizations.of(context)!;
        final totalMinutes = limitInMinutes;
        final hours = totalMinutes ~/ 60;
        final minutes = totalMinutes % 60;
        
        String timeText;
        // Usar formato abreviado para el mensaje también
        if (hours == 0) {
          timeText = '$minutes ${updatedLocalizations.minutesShort}';
        } else if (minutes == 0) {
          timeText = '$hours ${updatedLocalizations.hoursShort}';
        } else {
          final connector = ' ${updatedLocalizations.timeConnector} ';
          timeText = '$hours ${updatedLocalizations.hoursShort}$connector$minutes ${updatedLocalizations.minutesShort}';
        }
        
        CustomSnackBar.showInfo(
          context,
          '${updatedLocalizations.dailyLimitUpdated}: $timeText',
          icon: Icons.timer_rounded,
        );
      }
    }
  }

  Future<void> _showWeeklyGoalDialog(AppProvider appProvider) async {
    final localizations = AppLocalizations.of(context)!;
    
    // Obtener el valor actual de la meta semanal (en horas)
    int selectedHours = appProvider.weeklyGoal.clamp(1, 168); // 1 hora a 1 semana (168 horas)
    
    final result = await showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1F3A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localizations.weeklyGoalDialogTitle,
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                localizations.weeklyGoalDescription,
                style: TextStyle(
                  color: AppColors.textLight.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  '${localizations.weeklyGoalTitle}: $selectedHours ${localizations.hoursShort}',
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                TimeLimitSlider(
                  value: selectedHours.toDouble(),
                  minValue: 1.0, // 1 hora
                  maxValue: 168.0, // 1 semana (168 horas)
                  divisions: 167, // 168 valores (1, 2, 3, ..., 168 horas)
                  leftLabel: localizations.workLimitLabel,
                  rightLabel: localizations.personalLimitLabel,
                  onChanged: (value) {
                    setState(() {
                      selectedHours = value.round(); // Redondear al entero más cercano
                    });
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  localizations.alertMessage,
                  style: TextStyle(
                    color: AppColors.textLight.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                localizations.cancel,
                style: TextStyle(color: AppColors.textLight.withValues(alpha: 0.7)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, selectedHours),
              child: Text(
                localizations.save,
                style: TextStyle(
                  color: AppColors.accentBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      await appProvider.setWeeklyGoal(result);
      if (mounted) {
        final updatedLocalizations = AppLocalizations.of(context)!;
        CustomSnackBar.showInfo(
          context,
          '${updatedLocalizations.weeklyGoalUpdated}: $result ${updatedLocalizations.hoursShort}',
          icon: Icons.flag_rounded,
        );
      }
    }
  }

  Future<void> _showThemeDialog(AppProvider appProvider) async {
    final localizations = AppLocalizations.of(context)!;
    final theme = await showDialog<ThemeMode>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: Text(
          localizations.selectTheme,
          style: const TextStyle(color: AppColors.textLight),
        ),
        content: RadioGroup<ThemeMode>(
          groupValue: appProvider.themeMode,
          onChanged: (value) {
            if (value != null) Navigator.pop(context, value);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeMode>(
                title: Text(localizations.system, style: const TextStyle(color: AppColors.textLight)),
                value: ThemeMode.system,
                activeColor: AppColors.accentBlue,
              ),
              RadioListTile<ThemeMode>(
                title: Text(localizations.light, style: const TextStyle(color: AppColors.textLight)),
                value: ThemeMode.light,
                activeColor: AppColors.accentBlue,
              ),
              RadioListTile<ThemeMode>(
                title: Text(localizations.dark, style: const TextStyle(color: AppColors.textLight)),
                value: ThemeMode.dark,
                activeColor: AppColors.accentBlue,
              ),
            ],
          ),
        ),
      ),
    );

    if (theme != null) {
      appProvider.setThemeMode(theme);
      if (mounted) {
        final localizations = AppLocalizations.of(context)!;
        CustomSnackBar.showInfo(
          context,
          '${localizations.theme} ${localizations.languageUpdated.toLowerCase()}: ${_getThemeName(theme, localizations)}',
          icon: Icons.brightness_6_rounded,
        );
      }
    }
  }

  Future<void> _showLanguageDialog(AppProvider appProvider) async {
    final localizations = AppLocalizations.of(context)!;
    final language = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: Text(
          localizations.selectLanguage,
          style: const TextStyle(color: AppColors.textLight),
        ),
        content: RadioGroup<String>(
          groupValue: appProvider.language,
          onChanged: (value) {
            if (value != null) Navigator.pop(context, value);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: Text(localizations.spanish, style: const TextStyle(color: AppColors.textLight)),
                value: 'es',
                activeColor: AppColors.accentBlue,
              ),
              RadioListTile<String>(
                title: Text(localizations.english, style: const TextStyle(color: AppColors.textLight)),
                value: 'en',
                activeColor: AppColors.accentBlue,
              ),
            ],
          ),
        ),
      ),
    );

    if (language != null) {
      await appProvider.setLanguage(language);
      if (mounted) {
        // Forzar reconstrucción de esta pantalla para actualizar los textos sin navegar
        setState(() {});
        // Esperar un frame para que el MaterialApp se actualice
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          final updatedLocalizations = AppLocalizations.of(context)!;
          CustomSnackBar.showSuccess(
            context,
            '${updatedLocalizations.languageUpdated}: ${_getLanguageName(language, updatedLocalizations)}',
            icon: Icons.language_rounded,
          );
        }
      }
    }
  }

  Future<void> _showResetDialog() async {
    final localizations = AppLocalizations.of(context)!;
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: Text(
          localizations.resetSettingsTitle,
          style: const TextStyle(color: AppColors.textLight),
        ),
        content: Text(
          localizations.resetSettingsConfirm,
          style: const TextStyle(color: AppColors.textLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(localizations.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(localizations.resetApp, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (shouldReset == true && mounted) {
      await _resetSettings();
    }
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: const Text(
          'Cerrar sesión',
          style: TextStyle(color: AppColors.textLight),
        ),
        content: const Text(
          '¿Está seguro de que desea cerrar sesión?',
          style: TextStyle(color: AppColors.textLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.logout();
      
      if (mounted) {
        navigate(context, CustomScreen.welcome, finishCurrent: true);
      }
    }
  }

  String _getThemeName(ThemeMode theme, AppLocalizations localizations) {
    switch (theme) {
      case ThemeMode.system:
        return localizations.system;
      case ThemeMode.light:
        return localizations.light;
      case ThemeMode.dark:
        return localizations.dark;
    }
  }

  String _getLanguageName(String language, AppLocalizations localizations) {
    switch (language) {
      case 'es':
        return localizations.spanish;
      case 'en':
        return localizations.english;
      default:
        return language;
    }
  }

  // Exportar datos del usuario
  Future<void> _exportData() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      
      final user = userProvider.user;
      if (user == null) {
        if (mounted) {
          CustomSnackBar.showWarning(
            context,
            'No hay datos de usuario para exportar',
            icon: Icons.info_outline_rounded,
          );
        }
        return;
      }

      // Crear objeto con todos los datos
      final exportData = {
        'user': user.toJson(),
        'settings': {
          'notificationsEnabled': appProvider.notificationsEnabled,
          'notificationInterval': appProvider.notificationInterval,
          'dailyUsageLimit': appProvider.dailyUsageLimit,
          'weeklyGoal': appProvider.weeklyGoal,
          'themeMode': appProvider.themeMode.toString(),
          'colorTheme': appProvider.colorTheme,
          'language': appProvider.language,
        },
        'preferences': {
          'todayUsageTime': PreferencesService.getTodayUsageTime(),
          'lastUsageDate': PreferencesService.getLastUsageDate(),
          'recordTimeWithoutFacebook': PreferencesService.getRecordTimeWithoutFacebook(),
        },
        'exportDate': DateTime.now().toIso8601String(),
        'appVersion': await Config.getAppVersion(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      
      if (mounted) {
        final localizations = AppLocalizations.of(context)!;
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1F3A),
            title: Text(
              localizations.dataExportedTitle,
              style: const TextStyle(color: AppColors.textLight),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.dataPreparedForExport,
                    style: const TextStyle(color: AppColors.textLight),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.darkSurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.textLight.withValues(alpha: 0.3)),
                    ),
                    child: SelectableText(
                      jsonString,
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(localizations.close),
              ),
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: jsonString));
                  Navigator.pop(context);
                  CustomSnackBar.showSuccess(
                    context,
                    localizations.dataCopied,
                    icon: Icons.copy_rounded,
                  );
                },
                child: Text(localizations.copy, style: TextStyle(color: AppColors.accentBlue)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final localizations = AppLocalizations.of(context)!;
        CustomSnackBar.showError(
          context,
          '${localizations.exportError}: $e',
          icon: Icons.error_outline_rounded,
        );
      }
    }
  }

  // Importar datos del usuario
  Future<void> _importData() async {
    try {
      final TextEditingController jsonController = TextEditingController();
      
      final localizations = AppLocalizations.of(context)!;
      final shouldImport = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1F3A),
          title: Text(
            localizations.importDataTitleDialog,
            style: const TextStyle(color: AppColors.textLight),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations.pasteJson,
                  style: const TextStyle(color: AppColors.textLight),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: jsonController,
                  maxLines: 10,
                  style: const TextStyle(color: AppColors.textLight),
                  decoration: InputDecoration(
                    hintText: localizations.pasteJsonHere,
                    hintStyle: TextStyle(color: AppColors.textLight.withValues(alpha: 0.5)),
                    filled: true,
                    fillColor: AppColors.darkSurface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.textLight.withValues(alpha: 0.3)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(localizations.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(localizations.import, style: TextStyle(color: AppColors.accentBlue)),
            ),
          ],
        ),
      );

      if (!mounted) return;

      if (shouldImport == true && jsonController.text.isNotEmpty) {
        try {
          final importData = jsonDecode(jsonController.text) as Map<String, dynamic>;
          
          // Importar configuraciones
          if (importData.containsKey('settings')) {
            final appProvider = Provider.of<AppProvider>(context, listen: false);
            final settings = importData['settings'] as Map<String, dynamic>;
            
            if (settings.containsKey('notificationsEnabled')) {
              await appProvider.setNotificationsEnabled(settings['notificationsEnabled'] as bool);
            }
            if (settings.containsKey('notificationInterval')) {
              await appProvider.setNotificationInterval(settings['notificationInterval'] as int);
            }
            if (settings.containsKey('dailyUsageLimit')) {
              await appProvider.setDailyUsageLimit(settings['dailyUsageLimit'] as int);
            }
            if (settings.containsKey('weeklyGoal')) {
              await appProvider.setWeeklyGoal(settings['weeklyGoal'] as int);
            }
          }

          // Importar preferencias
          if (importData.containsKey('preferences')) {
            final prefs = importData['preferences'] as Map<String, dynamic>;
            if (prefs.containsKey('todayUsageTime')) {
              await PreferencesService.setTodayUsageTime(prefs['todayUsageTime'] as int);
            }
            if (prefs.containsKey('lastUsageDate')) {
              await PreferencesService.setLastUsageDate(prefs['lastUsageDate'] as String);
            }
            if (prefs.containsKey('recordTimeWithoutFacebook')) {
              await PreferencesService.setRecordTimeWithoutFacebook(prefs['recordTimeWithoutFacebook'] as int);
            }
          }

          if (mounted) {
            final localizations = AppLocalizations.of(context)!;
            CustomSnackBar.showSuccess(
              context,
              localizations.dataImportedSuccessfully,
              icon: Icons.download_done_rounded,
            );
          }
        } catch (e) {
          if (mounted) {
            final localizations = AppLocalizations.of(context)!;
            CustomSnackBar.showError(
              context,
              localizations.invalidJson,
              icon: Icons.error_outline_rounded,
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        final localizations = AppLocalizations.of(context)!;
        CustomSnackBar.showError(
          context,
          '${localizations.importError}: $e',
          icon: Icons.error_outline_rounded,
        );
      }
    }
  }

  // Reiniciar configuración
  Future<void> _resetSettings() async {
    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      
      // Resetear a valores por defecto
      await appProvider.setNotificationsEnabled(true);
      await appProvider.setNotificationInterval(15);
      await appProvider.setDailyUsageLimit(60);
      await appProvider.setWeeklyGoal(10);
      await appProvider.setThemeMode(ThemeMode.system);
      await appProvider.setColorTheme('ocean');
      await appProvider.setLanguage('es');
      
      // Limpiar preferencias de uso
      await PreferencesService.setTodayUsageTime(0);
      await PreferencesService.setLastUsageDate('');
      await PreferencesService.setRecordTimeWithoutFacebook(0);
      
      if (mounted) {
        CustomSnackBar.showSuccess(
          context,
          'Configuración reiniciada correctamente',
          icon: Icons.refresh_rounded,
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(
          context,
          'Error al reiniciar configuración: $e',
          icon: Icons.error_outline_rounded,
        );
      }
    }
  }

  // Mostrar información de versión
  Future<void> _showVersionInfo() async {
    try {
      final localizations = AppLocalizations.of(context)!;
      final version = await Config.getAppVersion();
      final packageInfo = await Config.getPackageInfo();
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1F3A),
            title: Text(
              localizations.appInfoTitle,
              style: const TextStyle(color: AppColors.textLight),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(localizations.nameLabel, Config.appName),
                const SizedBox(height: 8),
                _buildInfoRow(localizations.versionLabel, version),
                const SizedBox(height: 8),
                _buildInfoRow(localizations.buildLabel, packageInfo.buildNumber),
                const SizedBox(height: 8),
                _buildInfoRow(localizations.descriptionLabel, Config.appDescription),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(localizations.close),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final localizations = AppLocalizations.of(context)!;
        CustomSnackBar.showError(
          context,
          '${localizations.errorGettingInfo}: $e',
          icon: Icons.error_outline_rounded,
        );
      }
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: TextStyle(
              color: AppColors.textLight.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: AppColors.textLight),
          ),
        ),
      ],
    );
  }

  // Mostrar términos y condiciones
  Future<void> _showTermsAndConditions() async {
    if (mounted) {
      final localizations = AppLocalizations.of(context)!;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1F3A),
          title: Text(
            localizations.termsTitle,
            style: const TextStyle(color: AppColors.textLight),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${localizations.lastUpdate}: ${DateTime.now().toString().split(' ')[0]}',
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  localizations.termsSection1Title,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  localizations.termsSection1Text,
                  style: const TextStyle(color: AppColors.textLight),
                ),
                const SizedBox(height: 16),
                Text(
                  localizations.termsSection2Title,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  localizations.termsSection2Text,
                  style: const TextStyle(color: AppColors.textLight),
                ),
                const SizedBox(height: 16),
                Text(
                  localizations.termsSection3Title,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  localizations.termsSection3Text,
                  style: const TextStyle(color: AppColors.textLight),
                ),
                const SizedBox(height: 16),
                Text(
                  localizations.termsSection4Title,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  localizations.termsSection4Text,
                  style: const TextStyle(color: AppColors.textLight),
                ),
                const SizedBox(height: 16),
                Text(
                  localizations.termsSection5Title,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  localizations.termsSection5Text,
                  style: const TextStyle(color: AppColors.textLight),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(localizations.close),
            ),
          ],
        ),
      );
    }
  }

  // Mostrar política de privacidad
  Future<void> _showPrivacyPolicy() async {
    if (mounted) {
      final localizations = AppLocalizations.of(context)!;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1F3A),
          title: Text(
            localizations.privacyTitle,
            style: const TextStyle(color: AppColors.textLight),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${localizations.lastUpdate}: ${DateTime.now().toString().split(' ')[0]}',
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  localizations.privacySection1Title,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  localizations.privacySection1Text,
                  style: const TextStyle(color: AppColors.textLight),
                ),
                const SizedBox(height: 16),
                Text(
                  localizations.privacySection2Title,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  localizations.privacySection2Text,
                  style: const TextStyle(color: AppColors.textLight),
                ),
                const SizedBox(height: 16),
                Text(
                  localizations.privacySection3Title,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  localizations.privacySection3Text,
                  style: const TextStyle(color: AppColors.textLight),
                ),
                const SizedBox(height: 16),
                Text(
                  localizations.privacySection4Title,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  localizations.privacySection4Text,
                  style: const TextStyle(color: AppColors.textLight),
                ),
                const SizedBox(height: 16),
                Text(
                  localizations.privacySection5Title,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  localizations.privacySection5Text,
                  style: const TextStyle(color: AppColors.textLight),
                ),
                const SizedBox(height: 16),
                Text(
                  localizations.privacySection6Title,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  localizations.privacySection6Text,
                  style: const TextStyle(color: AppColors.textLight),
                ),
                const SizedBox(height: 16),
                Text(
                  localizations.privacySection7Title,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  localizations.privacySection7Text,
                  style: const TextStyle(color: AppColors.textLight),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(localizations.close),
            ),
          ],
        ),
      );
    }
  }

  // Mostrar información de contacto
  Future<void> _showContactInfo() async {
    if (mounted) {
      final localizations = AppLocalizations.of(context)!;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1F3A),
          title: Text(
            localizations.contactTitle,
            style: const TextStyle(color: AppColors.textLight),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localizations.needHelp,
                style: const TextStyle(color: AppColors.textLight),
              ),
              const SizedBox(height: 24),
              _buildContactRow(
                Icons.email,
                localizations.emailLabel,
                'soporte@nofacezone.com',
                () {
                  // Aquí podrías abrir el cliente de email si tienes url_launcher
                  Clipboard.setData(const ClipboardData(text: 'soporte@nofacezone.com'));
                  Navigator.pop(context);
                  CustomSnackBar.showSuccess(
                    context,
                    localizations.emailCopied,
                    icon: Icons.email_rounded,
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildContactRow(
                Icons.help_outline,
                localizations.supportLabel,
                localizations.helpCenter,
                () {
                  Navigator.pop(context);
                  CustomSnackBar.showInfo(
                    context,
                    '${localizations.helpCenter} ${localizations.loading}',
                    icon: Icons.help_outline_rounded,
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildContactRow(
                Icons.feedback,
                'Feedback',
                'Envíanos tus comentarios',
                () {
                  Navigator.pop(context);
                  CustomSnackBar.showSuccess(
                    context,
                    'Gracias por tu interés en mejorar NoFaceZone',
                    icon: Icons.favorite_rounded,
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildContactRow(IconData icon, String label, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.textLight.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.accentBlue, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: AppColors.textLight.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textLight.withValues(alpha: 0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}