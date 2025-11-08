import 'package:flutter/material.dart';
import 'package:nofacezone/src/Custom/AppColors.dart';

/// Widget de notificación personalizado con diseño moderno y profesional
class CustomSnackBar extends StatelessWidget {
  final String message;
  final IconData? icon;
  final Color? backgroundColor;
  final List<Color>? gradientColors;
  final Duration duration;
  final bool showIcon;

  const CustomSnackBar({
    super.key,
    required this.message,
    this.icon,
    this.backgroundColor,
    this.gradientColors,
    this.duration = const Duration(milliseconds: 1500),
    this.showIcon = true,
  });

  /// Muestra un SnackBar de éxito
  static void showSuccess(
    BuildContext context,
    String message, {
    IconData icon = Icons.check_circle_rounded,
    Duration duration = const Duration(milliseconds: 1500),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: CustomSnackBar(
          message: message,
          icon: icon,
          gradientColors: [
            const Color(0xFF10B981), // Verde esmeralda
            const Color(0xFF059669), // Verde más oscuro
          ],
          showIcon: true,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: duration,
        padding: EdgeInsets.zero,
      ),
    );
  }

  /// Muestra un SnackBar de información
  static void showInfo(
    BuildContext context,
    String message, {
    IconData icon = Icons.info_rounded,
    Duration duration = const Duration(milliseconds: 1500),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: CustomSnackBar(
          message: message,
          icon: icon,
          gradientColors: [
            AppColors.accentBlue,
            AppColors.accentBlue.withValues(alpha: 0.8),
          ],
          showIcon: true,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: duration,
        padding: EdgeInsets.zero,
      ),
    );
  }

  /// Muestra un SnackBar de advertencia
  static void showWarning(
    BuildContext context,
    String message, {
    IconData icon = Icons.warning_rounded,
    Duration duration = const Duration(milliseconds: 1500),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: CustomSnackBar(
          message: message,
          icon: icon,
          gradientColors: [
            const Color(0xFFF59E0B), // Ámbar
            const Color(0xFFD97706), // Ámbar oscuro
          ],
          showIcon: true,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: duration,
        padding: EdgeInsets.zero,
      ),
    );
  }

  /// Muestra un SnackBar de error
  static void showError(
    BuildContext context,
    String message, {
    IconData icon = Icons.error_rounded,
    Duration duration = const Duration(milliseconds: 1500),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: CustomSnackBar(
          message: message,
          icon: icon,
          gradientColors: [
            const Color(0xFFEF4444), // Rojo
            const Color(0xFFDC2626), // Rojo oscuro
          ],
          showIcon: true,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: duration,
        padding: EdgeInsets.zero,
      ),
    );
  }

  /// Muestra un SnackBar personalizado con gradiente del tema
  static void showTheme(
    BuildContext context,
    String message, {
    IconData icon = Icons.auto_awesome_rounded,
    List<Color>? gradientColors,
    Duration duration = const Duration(milliseconds: 1500),
  }) {
    final colors = gradientColors ?? [
      AppColors.accentGradient[0],
      AppColors.accentGradient[1],
    ];

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: CustomSnackBar(
          message: message,
          icon: icon,
          gradientColors: colors,
          showIcon: true,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: duration,
        padding: EdgeInsets.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = gradientColors ?? [
      backgroundColor ?? AppColors.accentGradient[0],
      (backgroundColor ?? AppColors.accentGradient[0]).withValues(alpha: 0.8),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors[0].withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          if (showIcon && icon != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Iconos decorativos de brillo
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome,
                color: Colors.white.withValues(alpha: 0.7),
                size: 16,
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.auto_awesome,
                color: Colors.white.withValues(alpha: 0.5),
                size: 14,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

