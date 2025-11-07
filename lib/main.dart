import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'src/Screen/SplashScreen.dart';
import 'src/Providers/ProviderConfig.dart';
import 'src/Providers/AppProvider.dart';
import 'src/Custom/AppColors.dart';
import 'src/Custom/AppFonts.dart';
import 'src/Custom/Config.dart' as AppConfig;

Future<void> main() async {
  await Supabase.initialize(
    url: AppConfig.Config.mSupabaseUrl,
    anonKey: AppConfig.Config.mSupabaseKey,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: ProviderConfig.providers,
      child: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          // Actualizar el tema de colores cuando cambie el provider
          AppColors.setTheme(appProvider.colorTheme);
          
          // Actualizar la fuente cuando cambie el provider
          AppFonts.setFont(appProvider.fontFamily);
          
          // Obtener el nombre de la familia de fuente actual
          final fontFamily = AppFonts.currentFontFamily;
          
          // Crear TextTheme con la fuente seleccionada
          TextTheme? textTheme;
          if (fontFamily != null) {
            try {
              // Intentar cargar la fuente de Google Fonts
              switch (fontFamily) {
                case 'Playfair Display':
                  textTheme = GoogleFonts.playfairDisplayTextTheme();
                  break;
                case 'Poppins':
                  textTheme = GoogleFonts.poppinsTextTheme();
                  break;
                case 'Comfortaa':
                  textTheme = GoogleFonts.comfortaaTextTheme();
                  break;
                case 'Montserrat':
                  textTheme = GoogleFonts.montserratTextTheme();
                  break;
                default:
                  textTheme = null;
              }
            } catch (e) {
              // Si hay error, usar fuente predeterminada
              textTheme = null;
            }
          }
          
          return MaterialApp(
            title: 'NoFaceZone',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              fontFamily: fontFamily,
              textTheme: textTheme,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primaryPurple,
                brightness: Brightness.light,
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.transparent,
                elevation: 0,
                centerTitle: true,
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              fontFamily: fontFamily,
              textTheme: textTheme,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primaryPurple,
                brightness: Brightness.dark,
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.transparent,
                elevation: 0,
                centerTitle: true,
              ),
            ),
            themeMode: appProvider.themeMode,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
