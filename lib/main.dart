import 'package:apex_push/ui/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';

import 'logic/notification_service.dart';
import 'logic/settings_provider.dart';
import 'logic/workout_provider.dart';

void main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  // Keep splash visible while orientation lock and providers initialise.
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  await NotificationService.instance.init();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WorkoutProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()..load()),
      ],
      child: const ApexPushApp(),
    ),
  );
}

class ApexPushApp extends StatelessWidget {
  const ApexPushApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return MaterialApp(
      title: 'ApexPush',
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: settings.themeMode,
      home: const DashboardScreen(),
    );
  }

  static ThemeData _buildTheme(Brightness brightness) => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          brightness: brightness,
        ),
        useMaterial3: true,
      );
}
