import 'dart:async';
import 'dart:math';

import 'package:proximity_sensor/proximity_sensor.dart';
import 'package:sensors_plus/sensors_plus.dart';

class SensorService {
  final double impactThreshold;

  bool _isNear = false;
  double _maxGInWindow = 0.0;
  StreamSubscription? _proximitySub;
  StreamSubscription? _accelSub;

  SensorService({this.impactThreshold = 12.0});

  void init() {
    _proximitySub = ProximitySensor.events.listen(
      (event) => _isNear = (event > 0),
    );
    _accelSub = accelerometerEventStream().listen((AccelerometerEvent event) {
      final magnitude = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );
      if (magnitude > _maxGInWindow) _maxGInWindow = magnitude;
    });
  }

  ({bool verified, double peakG, bool isNear}) verifyPushUp() {
    final peak = _maxGInWindow;
    final near = _isNear;
    _maxGInWindow = 0.0;
    return (verified: near && peak > impactThreshold, peakG: peak, isNear: near);
  }

  void dispose() {
    _proximitySub?.cancel();
    _accelSub?.cancel();
  }
}
