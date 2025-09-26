import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'src/Screen/SplashScreen.dart';
import 'src/Providers/ProviderConfig.dart';
import 'src/Providers/AppProvider.dart';
import 'src/Custom/AppColors.dart';
import 'src/Custom/Config.dart';

Future<void> main() async {
  await Supabase.initialize(
    url: Config.mSupabaseUrl,
    anonKey: Config.mSupabaseKey,
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
          return MaterialApp(
            title: 'NoFaceZone',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
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
