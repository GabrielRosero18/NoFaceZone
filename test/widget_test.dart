import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:nofacezone/src/Custom/AppLocalizations.dart';
import 'package:nofacezone/src/Providers/ProviderConfig.dart';

/// Smoke test sin timers de animación (evita ProEntrance / Future.delayed).
void main() {
  testWidgets('MaterialApp + Provider + i18n EN', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: ProviderConfig.providers,
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: const [Locale('es'), Locale('en')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Builder(
            builder: (context) {
              final loc = AppLocalizations.of(context)!;
              return Scaffold(
                body: Text('${loc.signIn}|${loc.welcomeChip}', textDirection: TextDirection.ltr),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sign in|Less scrolling, more control'), findsOneWidget);
  });

  testWidgets('MaterialApp + Provider + i18n ES', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: ProviderConfig.providers,
        child: MaterialApp(
          locale: const Locale('es'),
          supportedLocales: const [Locale('es'), Locale('en')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Builder(
            builder: (context) {
              final loc = AppLocalizations.of(context)!;
              return Scaffold(
                body: Text('${loc.signIn}|${loc.welcomeChip}', textDirection: TextDirection.ltr),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Iniciar sesión|Menos scroll, más control'), findsOneWidget);
  });
}
