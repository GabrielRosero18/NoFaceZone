import 'package:flutter/material.dart';
import 'package:nofacezone/src/Screen/SplashScreen.dart';
import 'package:nofacezone/src/Screen/WelcomeScreen.dart';
import 'package:nofacezone/src/Screen/OnboardingScreen.dart';
import 'package:nofacezone/src/Screen/HomeScreen.dart';
import 'package:nofacezone/src/Screen/StatisticsScreen.dart';
import 'package:nofacezone/src/Screen/Settings.dart';
import 'package:nofacezone/src/Screen/RewardsScreen.dart';
import 'package:nofacezone/src/Screen/LoginScreen.dart';
import 'package:nofacezone/src/Screen/RegisterScreen.dart';
import 'package:nofacezone/src/Screen/EmotionTrackingScreen.dart';
import 'package:nofacezone/src/Custom/Constans.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CustomScreen { //enumerancion para las pantallas
  splash, 
  onboarding,
  welcome,
  home,
  statistics,
  settings,
  rewards,
  login,
  register,
  emotionTracking
}

enum TypeAnimation { //enumeracion para los tipos de animacion
  transition,
}

enum Preference {
  onboarding,
}

// Navegación con transición personalizada
void navigate(BuildContext mContext, CustomScreen mScreen, {bool finishCurrent = false}) {
  late final Widget target;
  switch (mScreen) {
    case CustomScreen.splash:
      target = const SplashScreen();
      break;
    case CustomScreen.onboarding:
      target = const OnboardingScreen();
      break;
    case CustomScreen.welcome:
      target = const WelcomeScreen();
      break;
    case CustomScreen.home:
      target = const HomeScreen();
      break;
    case CustomScreen.statistics:
      target = const StatisticsScreen();
      break;
    case CustomScreen.settings:
      target = const Settings();
      break;
    case CustomScreen.rewards:
      target = const RewardsScreen();
      break;
    case CustomScreen.login:
      target = const LoginScreen();
      break;
    case CustomScreen.register:
      target = const RegisterScreen();
      break;
    case CustomScreen.emotionTracking:
      target = const EmotionTrackingScreen();
      break;
  }

  final route = _goScreen(target, TypeAnimation.transition);
  if (finishCurrent) {
    Navigator.of(mContext).pushReplacement(route);
  } else {
    Navigator.of(mContext).push(route);
  }
}

Route _goScreen(Widget screen, TypeAnimation animationType) {
  return PageRouteBuilder(
    pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) => screen,
    transitionDuration: const Duration(milliseconds: 450),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      switch (animationType) {
        case TypeAnimation.transition:
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(curved),
              child: child,
            ),
          );
      }
    },
  );
}

// Extensión para crear colores a partir de códigos hexadecimales
extension NHexColor on Color {
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('FF');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  String toHex({bool leadingHashSign = true}) => '${leadingHashSign ? '#' : ''}'
      '${((a * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0')}'
      '${((r * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0')}'
      '${((g * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0')}'
      '${((b * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0')}';
}

// Guardar una preferencia
Future<void> setOnePreference(Preference mAuxKey, String value) async {
  String mkey = '';
  switch (mAuxKey) {
    case Preference.onboarding:
      mkey = Constants.onboardingKey;
      break;
  }  
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString(mkey, value);
}

// Obtener una preferencia
Future<String> getOnePreference(Preference mAuxKey) async {
  String mkey = '';
  switch (mAuxKey) {
    case Preference.onboarding:
      mkey = Constants.onboardingKey;
      break;
  }
  
  String result = "";
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool checkValue = prefs.containsKey(mkey);
  if (checkValue) {
    result = prefs.getString(mkey) ?? "";
  }
  return result;
}






