// data/sensor_service.dart
import 'package:proximity_sensor/proximity_sensor.dart';

class SensorService {
  bool _isNear = false;

  void init() {
    ProximitySensor.events.listen((event) => _isNear = (event > 0));
  }

  bool verifyPushUp() {
    // Return true only if proximity sensor detects something (chest/nose)
    // In a real app, you'd also check accelerometer spikes here
    return _isNear;
  }
}
