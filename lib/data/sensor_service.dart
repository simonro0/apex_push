import 'dart:async';
import 'dart:math';

import 'package:proximity_sensor/proximity_sensor.dart';
import 'package:sensors_plus/sensors_plus.dart';

class SensorService {
  final double impactThreshold;

  /// Called on the main thread each time the proximity sensor transitions
  /// from FAR → NEAR (i.e. the user's nose/chest approaches the screen).
  /// Set before calling [init]; may be updated at any time.
  void Function()? proximityRepCallback;

  bool   _wasNear = false;
  bool   _isNear  = false;
  double _maxGInWindow = 0.0;
  double _lastProximityRaw = 0.0;
  bool   _inCooldown = false;

  /// Automatisch ermittelte Polarität: true wenn das Gerät 0 = NEAR meldet
  /// (invertiert gegenüber dem Standard event > 0 = NEAR).
  bool _invertProximity    = false;
  bool _proximityCalibrated = false;
  StreamSubscription? _proximitySub;
  StreamSubscription? _accelSub;

  SensorService({this.impactThreshold = 6.0});

  void init() {
    _wasNear              = false;
    _invertProximity      = false;
    _proximityCalibrated  = false;
    _proximitySub = ProximitySensor.events.listen((event) {
      // Auto-Kalibrierung: erstes Ereignis im Ruhezustand (Telefon liegt flach)
      // sollte "fern" sein. Normale Geräte: 0 = fern → event == 0 → nicht invertiert.
      // Invertierte Geräte: liefern z.B. 5 im Ruhezustand → event > 0 → invertiert.
      if (!_proximityCalibrated) {
        _invertProximity     = event > 0;
        _proximityCalibrated = true;
      }
      final nowNear = _invertProximity ? event == 0 : event > 0;
      if (nowNear && !_wasNear) {
        // Transition to NEAR fires before physical touch — the primary rep trigger.
        proximityRepCallback?.call();
      }
      _wasNear          = nowNear;
      _isNear           = nowNear;
      _lastProximityRaw = event.toDouble();
    });
    // userAccelerometerEventStream removes gravity so magnitude at rest ≈ 0.
    _accelSub = userAccelerometerEventStream().listen((UserAccelerometerEvent event) {
      if (_inCooldown) return;
      final magnitude = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );
      if (magnitude > _maxGInWindow) _maxGInWindow = magnitude;
    });
  }

  ({bool verified, double peakG, bool isNear, double proximityRaw}) verifyPushUp() {
    final peak    = _maxGInWindow;
    final near    = _isNear;
    final proxRaw = _lastProximityRaw;

    // 200 ms cooldown: ignore accelerometer spikes caused by the tap itself.
    _maxGInWindow = 0.0;
    _inCooldown   = true;
    Timer(const Duration(milliseconds: 200), () {
      _maxGInWindow = 0.0;
      _inCooldown   = false;
    });

    return (verified: near && peak > impactThreshold, peakG: peak, isNear: near, proximityRaw: proxRaw);
  }

  void dispose() {
    _proximitySub?.cancel();
    _accelSub?.cancel();
  }
}
