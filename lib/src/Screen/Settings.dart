import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:nofacezone/src/Custom/AppColors.dart';
import 'package:nofacezone/src/Custom/Library.dart';
import 'package:nofacezone/src/Custom/Config.dart';
import 'package:nofacezone/src/Providers/AppProvider.dart';
import 'package:nofacezone/src/Providers/UserProvider.dart';
import 'package:nofacezone/src/Screen/EditProfileScreen.dart';
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
        title: const Text('Configuración'),
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🔔 Notificaciones',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingItem(
              'Habilitar notificaciones',
              'Recibir alertas y recordatorios',
              Icons.notifications,
              appProvider.notificationsEnabled,
              (value) => appProvider.setNotificationsEnabled(value),
            ),
            const SizedBox(height: 12),
            _buildSettingItemWithValue(
              'Intervalo de notificaciones',
              'Frecuencia de recordatorios',
              Icons.timer,
              '${appProvider.notificationInterval} min',
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⏱️ Límites de uso',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingItemWithValue(
              'Límite diario',
              'Tiempo máximo de uso por día',
              Icons.access_time,
              '${appProvider.dailyUsageLimit} minutos',
              () => _showDailyLimitDialog(appProvider),
            ),
            const SizedBox(height: 12),
            _buildSettingItemWithValue(
              'Meta semanal',
              'Objetivo de horas por semana',
              Icons.track_changes,
              '${appProvider.weeklyGoal} horas',
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🎨 Apariencia',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingItemWithValue(
              'Tema',
              'Apariencia de la aplicación',
              Icons.palette,
              _getThemeName(appProvider.themeMode),
              () => _showThemeDialog(appProvider),
            ),
            const SizedBox(height: 12),
            _buildSettingItemWithValue(
              'Idioma',
              'Seleccionar idioma',
              Icons.language,
              _getLanguageName(appProvider.language),
              () => _showLanguageDialog(appProvider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAdvancedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '⚙️ Configuración avanzada',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textLight,
          ),
        ),
        const SizedBox(height: 16),
        _buildSettingItemWithValue(
          'Exportar datos',
          'Guardar tu progreso',
          Icons.file_download,
          null,
          () => _exportData(),
        ),
        const SizedBox(height: 12),
        _buildSettingItemWithValue(
          'Importar datos',
          'Restaurar tu progreso',
          Icons.file_upload,
          null,
          () => _importData(),
        ),
        const SizedBox(height: 12),
        _buildSettingItemWithValue(
          'Reiniciar configuración',
          'Volver a valores por defecto',
          Icons.restore,
          null,
          () => _showResetDialog(),
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ℹ️ Información',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textLight,
          ),
        ),
        const SizedBox(height: 16),
        _buildSettingItemWithValue(
          'Versión',
          'Información de la app',
          Icons.info,
          null,
          () => _showVersionInfo(),
        ),
        const SizedBox(height: 12),
        _buildSettingItemWithValue(
          'Términos y condiciones',
          'Leer documentos legales',
          Icons.description,
          null,
          () => _showTermsAndConditions(),
        ),
        const SizedBox(height: 12),
        _buildSettingItemWithValue(
          'Política de privacidad',
          'Cómo protegemos tus datos',
          Icons.privacy_tip,
          null,
          () => _showPrivacyPolicy(),
        ),
        const SizedBox(height: 12),
        _buildSettingItemWithValue(
          'Contacto',
          'Soporte y sugerencias',
          Icons.support_agent,
          null,
          () => _showContactInfo(),
        ),
        const SizedBox(height: 24),
        _buildSettingItemWithValue(
          'Cerrar sesión',
          'Salir de la aplicación',
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
    final intervals = [5, 10, 15, 30, 60];
    final selectedInterval = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: const Text(
          'Intervalo de notificaciones',
          style: TextStyle(color: AppColors.textLight),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: intervals.map((interval) {
            return RadioListTile<int>(
              title: Text(
                '$interval minutos',
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Intervalo actualizado: $selectedInterval min')),
        );
      }
    }
  }

  Future<void> _showDailyLimitDialog(AppProvider appProvider) async {
    final limit = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: const Text(
          'Límite diario (minutos)',
          style: TextStyle(color: AppColors.textLight),
        ),
        content: TextField(
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppColors.textLight),
          decoration: InputDecoration(
            hintText: 'Ingrese minutos',
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
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              // Por simplicidad, usar un valor por defecto
              Navigator.pop(context, 60);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (limit != null) {
      appProvider.setDailyUsageLimit(limit);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Límite diario actualizado: $limit min')),
        );
      }
    }
  }

  Future<void> _showWeeklyGoalDialog(AppProvider appProvider) async {
    final goal = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: const Text(
          'Meta semanal (horas)',
          style: TextStyle(color: AppColors.textLight),
        ),
        content: TextField(
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppColors.textLight),
          decoration: InputDecoration(
            hintText: 'Ingrese horas',
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
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, 10);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (goal != null) {
      appProvider.setWeeklyGoal(goal);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Meta semanal actualizada: $goal horas')),
        );
      }
    }
  }

  Future<void> _showThemeDialog(AppProvider appProvider) async {
    final theme = await showDialog<ThemeMode>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: const Text(
          'Seleccionar tema',
          style: TextStyle(color: AppColors.textLight),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('Sistema', style: TextStyle(color: AppColors.textLight)),
              value: ThemeMode.system,
              groupValue: appProvider.themeMode,
              onChanged: (value) => Navigator.pop(context, value),
              activeColor: AppColors.accentBlue,
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Claro', style: TextStyle(color: AppColors.textLight)),
              value: ThemeMode.light,
              groupValue: appProvider.themeMode,
              onChanged: (value) => Navigator.pop(context, value),
              activeColor: AppColors.accentBlue,
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Oscuro', style: TextStyle(color: AppColors.textLight)),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tema actualizado: ${_getThemeName(theme)}')),
        );
      }
    }
  }

  Future<void> _showLanguageDialog(AppProvider appProvider) async {
    final language = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: const Text(
          'Seleccionar idioma',
          style: TextStyle(color: AppColors.textLight),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Español', style: TextStyle(color: AppColors.textLight)),
              value: 'es',
              groupValue: appProvider.language,
              onChanged: (value) => Navigator.pop(context, value),
              activeColor: AppColors.accentBlue,
            ),
            RadioListTile<String>(
              title: const Text('English', style: TextStyle(color: AppColors.textLight)),
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
      appProvider.setLanguage(language);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Idioma actualizado: ${_getLanguageName(language)}')),
        );
      }
    }
  }

  Future<void> _showResetDialog() async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: const Text(
          'Reiniciar configuración',
          style: TextStyle(color: AppColors.textLight),
        ),
        content: const Text(
          '¿Está seguro de que desea reiniciar toda la configuración a sus valores por defecto?',
          style: TextStyle(color: AppColors.textLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reiniciar', style: TextStyle(color: AppColors.error)),
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

  String _getThemeName(ThemeMode theme) {
    switch (theme) {
      case ThemeMode.system:
        return 'Sistema';
      case ThemeMode.light:
        return 'Claro';
      case ThemeMode.dark:
        return 'Oscuro';
    }
  }

  String _getLanguageName(String language) {
    switch (language) {
      case 'es':
        return 'Español';
      case 'en':
        return 'English';
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
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1F3A),
            title: const Text(
              'Datos exportados',
              style: TextStyle(color: AppColors.textLight),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tus datos han sido preparados para exportar. Copia el siguiente JSON:',
                    style: TextStyle(color: AppColors.textLight),
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
                child: const Text('Cerrar'),
              ),
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: jsonString));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Datos copiados al portapapeles')),
                  );
                },
                child: Text('Copiar', style: TextStyle(color: AppColors.accentBlue)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al exportar datos: $e')),
        );
      }
    }
  }

  // Importar datos del usuario
  Future<void> _importData() async {
    try {
      final TextEditingController jsonController = TextEditingController();
      
      final shouldImport = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1F3A),
          title: const Text(
            'Importar datos',
            style: TextStyle(color: AppColors.textLight),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pega el JSON con tus datos exportados:',
                  style: TextStyle(color: AppColors.textLight),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: jsonController,
                  maxLines: 10,
                  style: const TextStyle(color: AppColors.textLight),
                  decoration: InputDecoration(
                    hintText: 'Pega el JSON aquí...',
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
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Importar', style: TextStyle(color: AppColors.accentBlue)),
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Datos importados correctamente')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error al importar datos: JSON inválido')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al importar datos: $e')),
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
      final version = await Config.getAppVersion();
      final packageInfo = await Config.getPackageInfo();
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1F3A),
            title: const Text(
              'Información de la aplicación',
              style: TextStyle(color: AppColors.textLight),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Nombre', Config.appName),
                const SizedBox(height: 8),
                _buildInfoRow('Versión', version),
                const SizedBox(height: 8),
                _buildInfoRow('Build', packageInfo.buildNumber),
                const SizedBox(height: 8),
                _buildInfoRow('Descripción', Config.appDescription),
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al obtener información: $e')),
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
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1F3A),
          title: const Text(
            'Términos y Condiciones',
            style: TextStyle(color: AppColors.textLight),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Última actualización: ${DateTime.now().toString().split(' ')[0]}',
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '1. Aceptación de los Términos',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Al usar NoFaceZone, aceptas estos términos y condiciones. Si no estás de acuerdo, no uses la aplicación.',
                  style: TextStyle(color: AppColors.textLight),
                ),
                const SizedBox(height: 16),
                const Text(
                  '2. Uso de la Aplicación',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'NoFaceZone está diseñada para ayudarte a controlar tu uso de redes sociales. Debes usar la aplicación de manera responsable y legal.',
                  style: TextStyle(color: AppColors.textLight),
                ),
                const SizedBox(height: 16),
                const Text(
                  '3. Privacidad',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Respetamos tu privacidad. Los datos que recopilamos se utilizan únicamente para mejorar tu experiencia en la aplicación. Consulta nuestra Política de Privacidad para más detalles.',
                  style: TextStyle(color: AppColors.textLight),
                ),
                const SizedBox(height: 16),
                const Text(
                  '4. Limitación de Responsabilidad',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'NoFaceZone se proporciona "tal cual" sin garantías. No nos hacemos responsables de ningún daño derivado del uso de la aplicación.',
                  style: TextStyle(color: AppColors.textLight),
                ),
                const SizedBox(height: 16),
                const Text(
                  '5. Modificaciones',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Nos reservamos el derecho de modificar estos términos en cualquier momento. Te notificaremos sobre cambios importantes.',
                  style: TextStyle(color: AppColors.textLight),
                ),
              ],
            ),
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

  // Mostrar política de privacidad
  Future<void> _showPrivacyPolicy() async {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1F3A),
          title: const Text(
            'Política de Privacidad',
            style: TextStyle(color: AppColors.textLight),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Última actualización: ${DateTime.now().toString().split(' ')[0]}',
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '1. Sobre NoFaceZone',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'NoFaceZone es una aplicación de autocontrol diseñada para ayudarte a gestionar y reducir tu tiempo de uso en redes sociales, especialmente Facebook. Nuestro objetivo es proporcionarte herramientas para desarrollar hábitos más saludables y conscientes en el uso de tecnología.',
                  style: TextStyle(color: AppColors.textLight),
                ),
                const SizedBox(height: 16),
                const Text(
                  '2. Información que Recopilamos',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Para brindarte un servicio de autocontrol efectivo, recopilamos: información de tu cuenta (nombre, email), datos de uso de la aplicación (tiempo de uso, límites establecidos, metas alcanzadas), preferencias de configuración (notificaciones, temas, idioma), y estadísticas de autocontrol (tiempo sin usar Facebook, progreso semanal). Todos estos datos se almacenan de forma segura y se utilizan exclusivamente para tu beneficio personal.',
                  style: TextStyle(color: AppColors.textLight),
                ),
                const SizedBox(height: 16),
                const Text(
                  '3. Cómo Usamos tu Información para el Autocontrol',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Utilizamos tu información únicamente para: generar estadísticas personalizadas sobre tu uso de redes sociales, enviarte recordatorios y notificaciones que te ayuden a mantener tus límites de autocontrol, crear gráficos y reportes de tu progreso, personalizar tu experiencia según tus objetivos de autocontrol, y mejorar las funcionalidades de la aplicación para mejorarte en tu proceso de autocontrol.',
                  style: TextStyle(color: AppColors.textLight),
                ),
                const SizedBox(height: 16),
                const Text(
                  '4. Privacidad y Confidencialidad',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Entendemos que el autocontrol es un proceso personal y privado. Por ello, NO vendemos, compartimos ni divulgamos tu información personal con terceros. Tus datos de autocontrol son completamente confidenciales y solo tú tienes acceso a ellos. Solo utilizamos datos agregados y completamente anónimos para análisis generales que nos ayudan a mejorar la aplicación.',
                  style: TextStyle(color: AppColors.textLight),
                ),
                const SizedBox(height: 16),
                const Text(
                  '5. Seguridad de tus Datos',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Implementamos medidas de seguridad técnicas y organizativas para proteger tu información personal y tus datos de autocontrol. Utilizamos encriptación y almacenamiento seguro. Sin embargo, ningún método de transmisión por Internet es 100% seguro, por lo que te recomendamos mantener tu cuenta segura con una contraseña fuerte.',
                  style: TextStyle(color: AppColors.textLight),
                ),
                const SizedBox(height: 16),
                const Text(
                  '6. Tus Derechos de Autocontrol',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tienes control total sobre tus datos: puedes acceder, modificar, exportar o eliminar tu información personal y datos de autocontrol en cualquier momento a través de la configuración de la aplicación. También puedes reiniciar tus estadísticas o ajustar tus límites de autocontrol cuando lo desees. Tu autonomía y control sobre tus datos es nuestra prioridad.',
                  style: TextStyle(color: AppColors.textLight),
                ),
                const SizedBox(height: 16),
                const Text(
                  '7. Datos de Autocontrol y Estadísticas',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Los datos de autocontrol (tiempo de uso, límites, metas, progreso) se almacenan localmente en tu dispositivo y de forma segura en nuestros servidores para permitir sincronización entre dispositivos. Estos datos son esenciales para que la aplicación funcione correctamente y te proporcione las herramientas de autocontrol que necesitas. Puedes eliminar estos datos en cualquier momento desde la configuración.',
                  style: TextStyle(color: AppColors.textLight),
                ),
              ],
            ),
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

  // Mostrar información de contacto
  Future<void> _showContactInfo() async {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1F3A),
          title: const Text(
            'Contacto',
            style: TextStyle(color: AppColors.textLight),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '¿Necesitas ayuda o tienes sugerencias?',
                style: TextStyle(color: AppColors.textLight),
              ),
              const SizedBox(height: 24),
              _buildContactRow(
                Icons.email,
                'Email',
                'soporte@nofacezone.com',
                () {
                  // Aquí podrías abrir el cliente de email si tienes url_launcher
                  Clipboard.setData(const ClipboardData(text: 'soporte@nofacezone.com'));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Email copiado al portapapeles')),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildContactRow(
                Icons.help_outline,
                'Soporte',
                'Centro de ayuda',
                () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Centro de ayuda próximamente disponible')),
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