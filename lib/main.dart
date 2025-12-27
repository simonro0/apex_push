import 'dart:async';

import 'package:flutter/material.dart';

void main() => runApp(ApexPushApp());

class ApexPushApp extends StatelessWidget {
  const ApexPushApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(), // Easy to swap for other themes
      home: PushUpCounterPage(),
    );
  }
}

class PushUpCounterPage extends StatefulWidget {
  const PushUpCounterPage({super.key});

  @override
  _PushUpCounterPageState createState() => _PushUpCounterPageState();
}

class _PushUpCounterPageState extends State<PushUpCounterPage> {
  int _counter = 0;
  DateTime? _lastTapTime;
  final List<double> _intervals = [];
  bool _isCheating = false;

  void _handleTap() {
    final now = DateTime.now();

    if (_lastTapTime != null) {
      final difference = now.difference(_lastTapTime!).inMilliseconds;

      // ANTI-CHEAT: If tap is faster than 400ms, it's likely a finger-tap/cheat
      if (difference < 400) {
        setState(() => _isCheating = true);
        // Reset cheat warning after 1 second
        Timer(Duration(seconds: 1), () => setState(() => _isCheating = false));
        return;
      }
      _intervals.add(difference.toDouble());
    }

    setState(() {
      _counter++;
      _lastTapTime = now;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: double.infinity,
          // Updated to use withValues as withOpacity is deprecated
          color: _isCheating
              ? Colors.red.withValues(alpha: 0.5)
              : Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isCheating ? "TOO FAST! FORM CHECK" : "PUSH DOWN",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 40),
              Text(
                '$_counter',
                // FontWeight.black might not be available in all versions, w900 is equivalent
                style: TextStyle(fontSize: 120, fontWeight: FontWeight.w900),
              ),
              if (_lastTapTime != null)
                Text(
                  "Last rep: ${(_intervals.isNotEmpty ? (60000 / _intervals.last).toStringAsFixed(1) : '0')} RPM",
                ),
            ],
          ),
        ),
      ),
    );
  }
}
