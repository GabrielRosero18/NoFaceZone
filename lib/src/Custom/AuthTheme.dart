import 'package:flutter/material.dart';
import 'package:nofacezone/src/Custom/AppColors.dart';

class AuthTheme {
  static const double fieldRadius = 16;
  static const double cardRadius = 26;
  static const double buttonRadius = 16;

  static BoxDecoration backgroundDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: AppColors.backgroundGradient,
      ),
    );
  }

  static List<Widget> buildBackgroundOrbs() {
    return [
      Positioned(
        top: -90,
        right: -40,
        child: Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accentBlue.withValues(alpha: 0.16),
          ),
        ),
      ),
      Positioned(
        bottom: -80,
        left: -40,
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accentBlue.withValues(alpha: 0.1),
          ),
        ),
      ),
    ];
  }

  static BoxDecoration glassCardDecoration() {
    return BoxDecoration(
      color: AppColors.darkSurface.withValues(alpha: 0.56),
      borderRadius: BorderRadius.circular(cardRadius),
      border: Border.all(color: AppColors.textLight.withValues(alpha: 0.13)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 18,
          offset: const Offset(0, 12),
        ),
      ],
    );
  }

  static InputDecoration inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: AppColors.textLight.withValues(alpha: 0.72),
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Icon(icon, color: AppColors.textLight.withValues(alpha: 0.8)),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(fieldRadius),
        borderSide: BorderSide(color: AppColors.textLight.withValues(alpha: 0.24)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(fieldRadius),
        borderSide: BorderSide(color: AppColors.textLight.withValues(alpha: 0.24)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(fieldRadius),
        borderSide: BorderSide(color: AppColors.accentBlue, width: 2),
      ),
      filled: true,
      fillColor: AppColors.textLight.withValues(alpha: 0.08),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    );
  }
}
