import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class Esp32Service {
  static const String mqttBroker = 'your-mqtt-broker.com'; // Replace with your MQTT broker
  static const int mqttPort = 1883; // Standard MQTT port
  static const String clientId = 'flameguard_mobile_app';

  MqttServerClient? _client;
  final StreamController<Map<String, dynamic>> _deviceDataController = StreamController.broadcast();
  final StreamController<String> _connectionStatusController = StreamController.broadcast();

  // Getters for streams
  Stream<Map<String, dynamic>> get deviceDataStream => _deviceDataController.stream;
  Stream<String> get connectionStatusStream => _connectionStatusController.stream;

  // ─── MQTT CONNECTION MANAGEMENT ───────────────────────────────────────────

  Future<bool> connect() async {
    try {
      if (kIsWeb) {
        // mqtt_client uses dart:io TLS primitives which are not available on Flutter Web.
        debugPrint('MQTT is not supported on web in this configuration.');
        _connectionStatusController.add('web_unavailable');
        return false;
      }

      _client = MqttServerClient(mqttBroker, clientId);
      _client!.port = mqttPort;
      _client!.logging(on: kDebugMode);
      _client!.keepAlivePeriod = 20;
      _client!.onDisconnected = _onDisconnected;
      _client!.onConnected = _onConnected;
      _client!.onSubscribed = _onSubscribed;

      final connMessage = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .withWillTopic('flameguard/status')
          .withWillMessage('disconnected')
          .startClean()
          .withWillQos(MqttQos.atLeastOnce);

      _client!.connectionMessage = connMessage;

      await _client!.connect();
      _connectionStatusController.add('connected');
      return true;
    } catch (e) {
      debugPrint('MQTT connection failed: $e');
      _connectionStatusController.add('disconnected');
      return false;
    }
  }

  void disconnect() {
    _client?.disconnect();
    _connectionStatusController.add('disconnected');
  }

  // ─── DEVICE COMMUNICATION METHODS ─────────────────────────────────────────

  // Subscribe to device topics
  Future<void> subscribeToDevice(String deviceId) async {
    if (_client?.connectionStatus?.state != MqttConnectionState.connected) {
      throw Exception('MQTT client not connected');
    }

    // Subscribe to device status updates
    final statusTopic = 'flameguard/devices/$deviceId/status';
    _client!.subscribe(statusTopic, MqttQos.atLeastOnce);

    // Subscribe to sensor data
    final sensorTopic = 'flameguard/devices/$deviceId/sensors';
    _client!.subscribe(sensorTopic, MqttQos.atLeastOnce);

    // Subscribe to alerts
    final alertTopic = 'flameguard/devices/$deviceId/alerts';
    _client!.subscribe(alertTopic, MqttQos.atLeastOnce);

    // Listen for incoming messages
    _client!.updates!.listen(_onMessageReceived);
  }

  // Unsubscribe from device topics
  void unsubscribeFromDevice(String deviceId) {
    final topics = [
      'flameguard/devices/$deviceId/status',
      'flameguard/devices/$deviceId/sensors',
      'flameguard/devices/$deviceId/alerts',
    ];

    for (final topic in topics) {
      _client?.unsubscribe(topic);
    }
  }

  // Send command to ESP32 device
  Future<void> sendCommand(String deviceId, String command, Map<String, dynamic>? params) async {
    if (_client?.connectionStatus?.state != MqttConnectionState.connected) {
      throw Exception('MQTT client not connected');
    }

    final topic = 'flameguard/devices/$deviceId/commands';
    final payload = {
      'command': command,
      'timestamp': DateTime.now().toIso8601String(),
      'params': params ?? {},
    };

    final message = MqttClientPayloadBuilder()
        .addString(jsonEncode(payload))
        .payload!;

    _client!.publishMessage(topic, MqttQos.atLeastOnce, message);
  }

  // Control device power
  Future<void> setDevicePower(String deviceId, bool on) async {
    await sendCommand(deviceId, 'power', {'state': on ? 'on' : 'off'});
  }

  // Set device settings
  Future<void> setDeviceSettings(String deviceId, Map<String, dynamic> settings) async {
    await sendCommand(deviceId, 'settings', settings);
  }

  // Request device status update
  Future<void> requestStatusUpdate(String deviceId) async {
    await sendCommand(deviceId, 'status_request', {});
  }

  // ─── MQTT EVENT HANDLERS ─────────────────────────────────────────────────

  void _onConnected() {
    debugPrint('MQTT Connected');
    _connectionStatusController.add('connected');
  }

  void _onDisconnected() {
    debugPrint('MQTT Disconnected');
    _connectionStatusController.add('disconnected');
  }

  void _onSubscribed(String topic) {
    debugPrint('Subscribed to: $topic');
  }

  void _onMessageReceived(List<MqttReceivedMessage<MqttMessage>> event) {
    final recMess = event[0].payload as MqttPublishMessage;
    final topic = event[0].topic;
    final payload = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      data['topic'] = topic;
      data['receivedAt'] = DateTime.now().toIso8601String();

      _deviceDataController.add(data);
    } catch (e) {
      debugPrint('Failed to parse MQTT message: $e');
    }
  }

  // ─── UTILITY METHODS ─────────────────────────────────────────────────────

  bool get isConnected => _client?.connectionStatus?.state == MqttConnectionState.connected;

  void dispose() {
    _client?.disconnect();
    _deviceDataController.close();
    _connectionStatusController.close();
  }
}

// ESP32 Command Types
class Esp32Commands {
  static const String power = 'power';
  static const String settings = 'settings';
  static const String statusRequest = 'status_request';
  static const String reset = 'reset';
  static const String updateFirmware = 'update_firmware';
}

// ESP32 Message Types
class Esp32Topics {
  static String deviceStatus(String deviceId) => 'flameguard/devices/$deviceId/status';
  static String deviceSensors(String deviceId) => 'flameguard/devices/$deviceId/sensors';
  static String deviceAlerts(String deviceId) => 'flameguard/devices/$deviceId/alerts';
  static String deviceCommands(String deviceId) => 'flameguard/devices/$deviceId/commands';
}