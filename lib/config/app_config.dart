// Configuration for API endpoints and MQTT settings
class Config {
  // ─── API CONFIGURATION ────────────────────────────────────────────────────
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://flameguard.onrender.com',
  );

  // API timeout settings
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration apiConnectTimeout = Duration(seconds: 10);

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
  static const String statusTopic = '$mqttBaseTopic/status';
  static const String commandTopic = '$mqttBaseTopic/commands';

  // ─── DEVICE CONFIGURATION ─────────────────────────────────────────────────
  static const Duration deviceStatusUpdateInterval = Duration(seconds: 30);
  static const Duration deviceHeartbeatTimeout = Duration(minutes: 5);

  // ─── SECURITY CONFIGURATION ───────────────────────────────────────────────
  static const bool enableHttpsOnly = bool.fromEnvironment('HTTPS_ONLY', defaultValue: true);
  static const bool enableMqttTls = bool.fromEnvironment('MQTT_TLS', defaultValue: false);

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
  static const Map<String, double> alertThresholds = {
    'temperature_max': 60.0,  // Celsius
    'smoke_max': 500.0,       // PPM
    'gas_max': 1000.0,        // PPM
    'flame_intensity_max': 80.0, // %
  };
}

// Environment-specific configurations
class DevConfig extends Config {
  static const String apiBaseUrl = '  ';
  static const String mqttBroker = 'localhost';
  static const bool isDevelopment = true;
}

class StagingConfig extends Config {
  static const String apiBaseUrl = 'https://flameguard-staging.onrender.com/api';
  static const String mqttBroker = 'mqtt-staging.yourdomain.com';
}

class ProdConfig extends Config {
  static const String apiBaseUrl = 'https://flameguard-api.onrender.com/api';
  static const String mqttBroker = 'mqtt.yourdomain.com';
  static const bool enableMqttTls = true;
}