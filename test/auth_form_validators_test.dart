import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nofacezone/src/Custom/AppLocalizations.dart';
import 'package:nofacezone/src/auth/auth_form_validators.dart';

void main() {
  group('AuthFormValidators.loginEmail', () {
    test('EN: empty and invalid messages', () {
      final loc = AppLocalizations(const Locale('en'));
      expect(AuthFormValidators.loginEmail('', loc), loc.emailRequired);
      expect(AuthFormValidators.loginEmail('x', loc), loc.emailInvalid);
      expect(AuthFormValidators.loginEmail('a@b', loc), loc.emailInvalid);
      expect(AuthFormValidators.loginEmail('user@domain.com', loc), isNull);
    });

    test('ES: formato inválido', () {
      final loc = AppLocalizations(const Locale('es'));
      expect(AuthFormValidators.loginEmail(null, loc), loc.emailRequired);
      expect(AuthFormValidators.loginEmail('   ', loc), loc.emailRequired);
      expect(AuthFormValidators.loginEmail('sinarroba.com', loc), loc.emailInvalid);
    });
  });

  group('AuthFormValidators.loginPassword', () {
    test('required in both locales', () {
      final en = AppLocalizations(const Locale('en'));
      final es = AppLocalizations(const Locale('es'));
      expect(AuthFormValidators.loginPassword('', en), en.passwordRequired);
      expect(AuthFormValidators.loginPassword('  ', es), es.passwordRequired);
      expect(AuthFormValidators.loginPassword('secret', en), isNull);
    });
  });
}
