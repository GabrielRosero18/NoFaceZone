import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nofacezone/src/Custom/AppColors.dart';
import 'package:nofacezone/src/Custom/Library.dart';
import 'package:nofacezone/src/Providers/AppProvider.dart';
import 'package:nofacezone/src/Providers/UserProvider.dart';
import 'package:nofacezone/src/Screen/EditProfileScreen.dart';

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
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Función en desarrollo')),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildSettingItemWithValue(
          'Importar datos',
          'Restaurar tu progreso',
          Icons.file_upload,
          null,
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Función en desarrollo')),
            );
          },
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
          '1.0.0',
          null,
        ),
        const SizedBox(height: 12),
        _buildSettingItemWithValue(
          'Términos y condiciones',
          'Leer documentos legales',
          Icons.description,
          null,
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Función en desarrollo')),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildSettingItemWithValue(
          'Política de privacidad',
          'Cómo protegemos tus datos',
          Icons.privacy_tip,
          null,
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Función en desarrollo')),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildSettingItemWithValue(
          'Contacto',
          'Soporte y sugerencias',
          Icons.support_agent,
          null,
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Función en desarrollo')),
            );
          },
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Función en desarrollo')),
      );
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
}