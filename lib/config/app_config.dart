// Configuration for MQTT settings and device thresholds.
// API configuration removed — all data goes through Firebase directly.
class Config {
  // ─── MQTT CONFIGURATION ───────────────────────────────────────────────────
  static const String mqttBroker = String.fromEnvironment(
    'MQTT_BROKER',
    defaultValue: 'your-mqtt-broker.com',
  );

  static const int mqttPort = int.fromEnvironment('MQTT_PORT', defaultValue: 1883);
  static const String mqttUsername = String.fromEnvironment('MQTT_USERNAME', defaultValue: '');
  static const String mqttPassword = String.fromEnvironment('MQTT_PASSWORD', defaultValue: '');

  // MQTT topics
  static const String mqttBaseTopic = 'flameguard';
  static String deviceTopic(String deviceId) => '$mqttBaseTopic/$deviceId';
  static const String statusTopic = '$mqttBaseTopic/status';
  static const String commandTopic = '$mqttBaseTopic/commands';

  // ─── DEVICE CONFIGURATION ─────────────────────────────────────────────────
  static const Duration deviceStatusUpdateInterval = Duration(seconds: 30);
  static const Duration deviceHeartbeatTimeout = Duration(minutes: 5);

  // ─── SECURITY CONFIGURATION ───────────────────────────────────────────────
  static const bool enableMqttTls =
    String.fromEnvironment('MQTT_TLS') == 'true';

  // ─── DEVELOPMENT SETTINGS ─────────────────────────────────────────────────
  static const bool isDevelopment = bool.fromEnvironment('DEV_MODE', defaultValue: false);
  static const bool enableLogging = bool.fromEnvironment('ENABLE_LOGGING', defaultValue: true);

  // ─── ESP32 DEVICE TYPES ───────────────────────────────────────────────────
  static const Map<String, String> deviceTypes = {
    'fire_detector': 'Fire Detector',
    'smoke_sensor': 'Smoke Sensor',
    'temperature_monitor': 'Temperature Monitor',
    'gas_detector': 'Gas Detector',
    'multi_sensor': 'Multi-Sensor Hub',
  };

  // ─── ALERT THRESHOLDS ────────────────────────────────────────────────────
  static const Map<String, double> defaultThresholds = {
    'temperature_max': 60.0,
    'smoke_max': 500.0,
    'gas_max': 1000.0,
    'flame_intensity_max': 80.0,
  };
}