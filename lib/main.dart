import 'package:apex_push/ui/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'logic/workout_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => WorkoutProvider(),
      child: ApexPushApp(),
    ),
  );
}

class ApexPushApp extends StatefulWidget {
  const ApexPushApp({super.key});

  @override
  State<ApexPushApp> createState() => _ApexPushAppState();
}

class _ApexPushAppState extends State<ApexPushApp> {
  ThemeMode _themeMode = ThemeMode.dark; // Multiple theme support

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ApexPush',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: _themeMode,
      home: DashboardScreen(),
    );
  }
}
