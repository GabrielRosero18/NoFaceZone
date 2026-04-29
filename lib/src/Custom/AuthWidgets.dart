import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nofacezone/src/Custom/AppColors.dart';
import 'package:nofacezone/src/Custom/AuthTheme.dart';

class AuthScaffold extends StatelessWidget {
  final String title;
  final String backTooltip;
  final VoidCallback onBackPressed;
  final Widget child;

  const AuthScaffold({
    super.key,
    required this.title,
    required this.backTooltip,
    required this.onBackPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: backTooltip,
          icon: const Icon(Icons.arrow_back, color: AppColors.textLight),
          onPressed: onBackPressed,
        ),
        title: Text(
          title,
          style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: AuthTheme.backgroundDecoration(),
        child: Stack(
          children: [
            ...AuthTheme.buildBackgroundOrbs(),
            SafeArea(child: child),
          ],
        ),
      ),
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  final String text;
  final bool isLoading;
  final VoidCallback? onPressed;

  const AuthPrimaryButton({
    super.key,
    required this.text,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: AppColors.accentGradient),
        borderRadius: BorderRadius.circular(AuthTheme.buttonRadius),
        boxShadow: AppColors.cardShadow,
      ),
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AuthTheme.buttonRadius),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.textLight),
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textLight,
                ),
              ),
      ),
    );
  }
}

class AuthHeaderChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const AuthHeaderChip({
    super.key,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.textLight.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.textLight.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.textLight.withValues(alpha: 0.95)),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const AuthGlassCard({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: AuthTheme.glassCardDecoration(),
      child: child,
    );
  }
}

class AuthInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextStyle? style;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? inputFormatters;

  const AuthInputField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.style,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      style: style ?? const TextStyle(color: AppColors.textLight),
      decoration: AuthTheme.inputDecoration(
        label: label,
        icon: icon,
        suffixIcon: suffixIcon,
      ),
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      validator: validator,
      onChanged: onChanged,
      inputFormatters: inputFormatters,
    );
  }
}

class AuthSelectField<T> extends StatelessWidget {
  final T? value;
  final String label;
  final IconData icon;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? Function(T?)? validator;
  final Color? dropdownColor;
  final TextStyle? style;

  const AuthSelectField({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.items,
    this.onChanged,
    this.validator,
    this.dropdownColor,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      dropdownColor: dropdownColor ?? AppColors.darkSurface,
      style: style ?? const TextStyle(color: AppColors.textLight),
      items: items,
      onChanged: onChanged,
      decoration: AuthTheme.inputDecoration(
        label: label,
        icon: icon,
      ),
      validator: validator,
    );
  }
}
