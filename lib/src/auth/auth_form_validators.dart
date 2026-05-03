import 'package:nofacezone/src/Custom/AppLocalizations.dart';

/// Validaciones reutilizables para formularios de autenticación (i18n).
class AuthFormValidators {
  AuthFormValidators._();

  static final RegExp _emailRegex = RegExp(
    r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
  );

  static String? loginEmail(String? value, AppLocalizations loc) {
    final String v = (value ?? '').trim();
    if (v.isEmpty) return loc.emailRequired;
    if (!v.contains('@')) return loc.emailInvalid;
    if (!_emailRegex.hasMatch(v)) return loc.emailInvalid;
    return null;
  }

  static String? loginPassword(String? value, AppLocalizations loc) {
    final String v = (value ?? '').trim();
    if (v.isEmpty) return loc.passwordRequired;
    return null;
  }
}
