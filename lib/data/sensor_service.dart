// data/sensor_service.dart
import 'dart:async';
import 'dart:math';

import 'package:proximity_sensor/proximity_sensor.dart';
import 'package:sensors_plus/sensors_plus.dart';

class SensorService {
  bool _isNear = false;
  double _maxGInWindow = 0.0;
  StreamSubscription? _accelSub;

  void init() {
    // 1. Proximity: Is the body physically over the phone?
    ProximitySensor.events.listen((event) => _isNear = (event > 0));

    // 2. Accelerometer: Monitor for 'thud' vibrations
    _accelSub = accelerometerEvents.listen((AccelerometerEvent event) {
      // Calculate total magnitude of movement (sqrt(x²+y²+z²))
      double magnitude = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );
      // Keep track of the hardest 'hit' in the current window
      if (magnitude > _maxGInWindow) _maxGInWindow = magnitude;
    });
  }

  bool verifyPushUp() {
    // A 'Verified' push up requires:
    // A) The proximity sensor was triggered (Near)
    // B) The impact magnitude was significant (e.g., > 12.0 m/s², where gravity is ~9.8)
    bool hasImpact = _maxGInWindow > 12.0;

    bool isValid = _isNear && hasImpact;

    // Reset impact for the next rep
    _maxGInWindow = 0.0;
    return isValid;
  }

  void dispose() {
    _accelSub?.cancel();
  }
}
