import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:nofacezone/src/Custom/AppColors.dart';
import 'package:nofacezone/src/Custom/Library.dart';
import 'package:nofacezone/src/Custom/Config.dart';
import 'package:nofacezone/src/Custom/AppLocalizations.dart';
import 'package:nofacezone/src/Providers/AppProvider.dart';
import 'package:nofacezone/src/Providers/UserProvider.dart';
import 'package:nofacezone/src/Screen/EditProfileScreen.dart';
import 'package:nofacezone/src/Screen/ReportsScreen.dart';
import 'package:nofacezone/src/Services/PreferencesService.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  @override
  Widget build(BuildContext context) {
    // Escuchar cambios del AppProvider para actualizar el tema
    final appProvider = Provider.of<AppProvider>(context);
    AppColors.setTheme(appProvider.colorTheme);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.settings ?? 'Configuración'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
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
                // Perfil del usuario
                _buildProfileSection(),
                const SizedBox(height: 32),

                // Notificaciones
                _buildNotificationsSection(),
                const SizedBox(height: 24),

                // Límites de uso
                _buildUsageLimitsSection(),
                const SizedBox(height: 24),

                // Apariencia
                _buildAppearanceSection(),
                const SizedBox(height: 24),

                // Configuración avanzada
                _buildAdvancedSection(),
                const SizedBox(height: 24),

                // Información de la app
                _buildAboutSection(),
              ],
            ),
          ),
        ),
      ),
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
                      ? ClipOval(
                          child: Image.network(
                            user!.profileImage!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.person,
                                color: AppColors.textLight,
                                size: 32,
                              );
                            },
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
              '${appProvider.dailyUsageLimit} ${localizations.minutes}',
              () => _showDailyLimitDialog(appProvider),
            ),
            const SizedBox(height: 12),
            _buildSettingItemWithValue(
              localizations.weeklyGoalTitle,
              localizations.weeklyGoalDescription,
              Icons.track_changes,
              '${appProvider.weeklyGoal} ${localizations.hours}',
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: intervals.map((interval) {
            return RadioListTile<int>(
              title: Text(
                '$interval ${localizations.minutes}',
                style: const TextStyle(color: AppColors.textLight),
              ),
              value: interval,
              groupValue: appProvider.notificationInterval,
              onChanged: (value) {
                Navigator.pop(context, value);
              },
              activeColor: AppColors.accentBlue,
            );
          }).toList(),
        ),
      ),
    );

    if (selectedInterval != null) {
      appProvider.setNotificationInterval(selectedInterval);
      if (mounted) {
        final updatedLocalizations = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${updatedLocalizations.notificationIntervalTitle} ${updatedLocalizations.languageUpdated.toLowerCase()}: $selectedInterval ${updatedLocalizations.minutes}')),
        );
      }
    }
  }

  Future<void> _showDailyLimitDialog(AppProvider appProvider) async {
    final localizations = AppLocalizations.of(context)!;
    final limit = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: Text(
          localizations.dailyLimitDialogTitle,
          style: const TextStyle(color: AppColors.textLight),
        ),
        content: TextField(
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppColors.textLight),
          decoration: InputDecoration(
            hintText: localizations.enterMinutes,
            hintStyle: TextStyle(color: AppColors.textLight.withValues(alpha: 0.5)),
            filled: true,
            fillColor: AppColors.textLight.withValues(alpha: 0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.cancel),
          ),
          TextButton(
            onPressed: () {
              // Por simplicidad, usar un valor por defecto
              Navigator.pop(context, 60);
            },
            child: Text(localizations.save),
          ),
        ],
      ),
    );

    if (limit != null) {
      appProvider.setDailyUsageLimit(limit);
      if (mounted) {
        final updatedLocalizations = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${updatedLocalizations.dailyLimitUpdated}: $limit ${updatedLocalizations.minutes}')),
        );
      }
    }
  }

  Future<void> _showWeeklyGoalDialog(AppProvider appProvider) async {
    final localizations = AppLocalizations.of(context)!;
    final goal = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: Text(
          localizations.weeklyGoalDialogTitle,
          style: const TextStyle(color: AppColors.textLight),
        ),
        content: TextField(
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppColors.textLight),
          decoration: InputDecoration(
            hintText: localizations.enterHours,
            hintStyle: TextStyle(color: AppColors.textLight.withValues(alpha: 0.5)),
            filled: true,
            fillColor: AppColors.textLight.withValues(alpha: 0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, 10);
            },
            child: Text(localizations.save),
          ),
        ],
      ),
    );

    if (goal != null) {
      appProvider.setWeeklyGoal(goal);
      if (mounted) {
        final updatedLocalizations = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${updatedLocalizations.weeklyGoalUpdated}: $goal ${updatedLocalizations.hours}')),
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: Text(localizations.system, style: const TextStyle(color: AppColors.textLight)),
              value: ThemeMode.system,
              groupValue: appProvider.themeMode,
              onChanged: (value) => Navigator.pop(context, value),
              activeColor: AppColors.accentBlue,
            ),
            RadioListTile<ThemeMode>(
              title: Text(localizations.light, style: const TextStyle(color: AppColors.textLight)),
              value: ThemeMode.light,
              groupValue: appProvider.themeMode,
              onChanged: (value) => Navigator.pop(context, value),
              activeColor: AppColors.accentBlue,
            ),
            RadioListTile<ThemeMode>(
              title: Text(localizations.dark, style: const TextStyle(color: AppColors.textLight)),
              value: ThemeMode.dark,
              groupValue: appProvider.themeMode,
              onChanged: (value) => Navigator.pop(context, value),
              activeColor: AppColors.accentBlue,
            ),
          ],
        ),
      ),
    );

    if (theme != null) {
      appProvider.setThemeMode(theme);
      if (mounted) {
        final localizations = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${localizations.theme} ${localizations.languageUpdated.toLowerCase()}: ${_getThemeName(theme, localizations)}')),
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text(localizations.spanish, style: const TextStyle(color: AppColors.textLight)),
              value: 'es',
              groupValue: appProvider.language,
              onChanged: (value) => Navigator.pop(context, value),
              activeColor: AppColors.accentBlue,
            ),
            RadioListTile<String>(
              title: Text(localizations.english, style: const TextStyle(color: AppColors.textLight)),
              value: 'en',
              groupValue: appProvider.language,
              onChanged: (value) => Navigator.pop(context, value),
              activeColor: AppColors.accentBlue,
            ),
          ],
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${updatedLocalizations.languageUpdated}: ${_getLanguageName(language, updatedLocalizations)}')),
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No hay datos de usuario para exportar')),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(localizations.dataCopied)),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${localizations.exportError}: $e')),
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

      if (shouldImport == true && jsonController.text.isNotEmpty) {
        try {
          final importData = jsonDecode(jsonController.text) as Map<String, dynamic>;
          
          // Importar datos del usuario
          if (importData.containsKey('user')) {
            final userProvider = Provider.of<UserProvider>(context, listen: false);
            final userData = importData['user'] as Map<String, dynamic>;
            // Aquí podrías actualizar el usuario si tienes un método para eso
          }

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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(localizations.dataImportedSuccessfully)),
            );
          }
        } catch (e) {
          if (mounted) {
            final localizations = AppLocalizations.of(context)!;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(localizations.invalidJson)),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        final localizations = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${localizations.importError}: $e')),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuración reiniciada correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al reiniciar configuración: $e')),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${localizations.errorGettingInfo}: $e')),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(localizations.emailCopied)),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${localizations.helpCenter} ${localizations.loading}')),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gracias por tu interés en mejorar NoFaceZone')),
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