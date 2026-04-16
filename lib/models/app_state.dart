import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/esp32_service.dart';
import 'device_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:developer';


enum AppNotificationCategory { announcement, system, access }

class AppNotification {
  final int id;
  final String title;
  final String body;
  final String time;
  final bool isNew;
  final AppNotificationCategory category;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    this.isNew = false,
    this.category = AppNotificationCategory.announcement,
  });
}

class AppState extends ChangeNotifier {
  bool _isDark = false;
  List<DeviceModel> _devices = [];
  DeviceModel? _selectedDevice;
  int _nextId = 10;
  final Set<int> _dismissedAlerts = {};
  final List<String> _rooms = ['Living', 'Kitchen', 'Bedroom'];
  final List<String> _deviceTypes = ['Fan', 'TV', 'Router'];
  final List<dynamic> _alerts = [];
  bool _hasNewNotification = true;
  final List<AppNotification> _notifications = [
    AppNotification(
      id: 1,
      title: 'New Feature: Scheduling',
      body: 'You can now schedule your appliances to turn on/off automatically!',
      time: '2 hours ago',
      isNew: true,
    ),
    AppNotification(
      id: 2,
      title: 'Security Update',
      body: 'We\'ve enhanced our encryption protocols for better protection.',
      time: '1 day ago',
    ),
    AppNotification(
      id: 3,
      title: 'Welcome to FlameGuard',
      body: 'Thank you for choosing FlameGuard for your home safety.',
      time: '3 days ago',
    ),
  ];
  Timer? _timer;
  Timer? _webSensorSyncTimer;
  bool _webSyncInFlight = false;

  // ─── SERVICE INSTANCES ───────────────────────────────────────────────────
  final Esp32Service _esp32Service = Esp32Service();
  String? _authToken;
  bool _isAuthenticated = false;
  String? _userId;
  String? _userEmail;
  String? _userName;

  // ─── STREAM SUBSCRIPTIONS ────────────────────────────────────────────────
  StreamSubscription<Map<String, dynamic>>? _deviceDataSubscription;
  StreamSubscription<String>? _connectionStatusSubscription;

  AppState() {
    _init();
  }

  void _init() async {
    _devices = initialDevices; // Initialize with mock data
    await loadTheme();
    await loadAuthState();
    _startScheduleEnforcer();
    _setupEsp32Listeners();
  }

  void _setupEsp32Listeners() {
    // Listen to ESP32 device data updates
    _deviceDataSubscription = _esp32Service.deviceDataStream.listen(_handleDeviceData);

    // Listen to connection status changes
    _connectionStatusSubscription = _esp32Service.connectionStatusStream.listen(_handleConnectionStatus);
  }

  void _handleDeviceData(Map<String, dynamic> data) {
    final topic = data['topic'] as String;
    final payload = Map<String, dynamic>.from(data)..remove('topic');

    if (topic.contains('/status')) {
      _updateDeviceStatus(payload);
    } else if (topic.contains('/sensors')) {
      _updateSensorData(payload);
    } else if (topic.contains('/alerts')) {
      _handleDeviceAlert(payload);
    }
  }

  void _handleConnectionStatus(String status) {
    debugPrint('ESP32 Connection Status: $status');
    // Could add UI feedback for connection status
  }

  void _updateDeviceStatus(Map<String, dynamic> status) {
    final deviceId = status['deviceId'] as String?;
    if (deviceId == null) return;

    final deviceIndex = _devices.indexWhere((d) => d.id.toString() == deviceId);
    if (deviceIndex == -1) return;

    final isActive = status['active'] as bool? ?? false;
    final risk = status['risk'] as String? ?? 'Low';
    final riskScore = status['riskScore'] as int? ?? 0;

    _devices[deviceIndex] = _devices[deviceIndex].copyWith(
      active: isActive,
      risk: risk,
      riskScore: riskScore,
    );
    notifyListeners();
  }

  void _updateSensorData(Map<String, dynamic> sensorData) {
    final deviceId = sensorData['deviceId'] as String?;
    if (deviceId == null) return;

    final deviceIndex = _devices.indexWhere((d) => d.id.toString() == deviceId);
    if (deviceIndex == -1) return;

    _devices[deviceIndex] = _devices[deviceIndex].copyWith(
      voltage: sensorData['voltage'] as double?,
      current: sensorData['current'] as double?,
      temperature: sensorData['temperature'] as double?,
    );
    notifyListeners();
  }

  void _handleDeviceAlert(Map<String, dynamic> alert) {
    // Add alert to alerts list
    _alerts.add({
      'id': DateTime.now().millisecondsSinceEpoch,
      'deviceId': alert['deviceId'],
      'type': alert['type'] ?? 'unknown',
      'message': alert['message'] ?? 'Device alert',
      'timestamp': DateTime.now().toIso8601String(),
      'severity': alert['severity'] ?? 'medium',
    });
    notifyListeners();
  }

  void _startScheduleEnforcer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _checkSchedules());
  }

  void _startWebSensorPolling() {
    _webSensorSyncTimer?.cancel();
    if (!kIsWeb) return;
    if (!_isAuthenticated) return;

    _webSensorSyncTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) async {
        if (_webSyncInFlight) return;
        _webSyncInFlight = true;
        try {
          await syncDevicesFromServer();
        } finally {
          _webSyncInFlight = false;
        }
      },
    );
  }

  void _checkSchedules() {
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    bool hasChanged = false;

    _devices = _devices.map((d) {
      if (!d.scheduleEnabled) return d;

      final startMinutes = d.startHour * 60 + d.startMinute;
      final endMinutes = d.endHour * 60 + d.endMinute;

      bool isInside;
      if (startMinutes < endMinutes) {
        isInside = currentMinutes >= startMinutes && currentMinutes < endMinutes;
      } else {
        // Overnight: e.g. 22:00 to 06:00
        isInside = currentMinutes >= startMinutes || currentMinutes < endMinutes;
      }

      bool shouldBeActive = isInside;
      bool shouldStillBeEnabled = d.scheduleEnabled;

      // Disable the schedule (one-time behavior) if we are PAST the end time
      if (!isInside) {
        if (startMinutes < endMinutes && currentMinutes >= endMinutes) {
          shouldStillBeEnabled = false;
        } else if (startMinutes > endMinutes && currentMinutes >= endMinutes && currentMinutes < startMinutes) {
          shouldStillBeEnabled = false;
        }
      }

      if (d.active != shouldBeActive || d.scheduleEnabled != shouldStillBeEnabled) {
        hasChanged = true;
        return d.copyWith(active: shouldBeActive, scheduleEnabled: shouldStillBeEnabled);
      }
      return d;
    }).toList();

    if (hasChanged) notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _webSensorSyncTimer?.cancel();
    _deviceDataSubscription?.cancel();
    _connectionStatusSubscription?.cancel();
    _esp32Service.dispose();
    super.dispose();
  }

  // ─── AUTHENTICATION METHODS ──────────────────────────────────────────────

  bool get isAuthenticated => _isAuthenticated;
  String? get userId => _userId;
  String? get userEmail => _userEmail;
  String? get userName => _userName;
  String? get authToken => _authToken;

  Future<void> loadAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('authToken');
    _userId = prefs.getString('userId');
    _userEmail = prefs.getString('userEmail');
    _userName = prefs.getString('userName');
    _isAuthenticated = _authToken != null && _userId != null;

    if (_isAuthenticated) {
      await connectToEsp32();
      await syncDevicesFromServer();
      _startWebSensorPolling();
    }

    notifyListeners();
  }

  Future<void> saveAuthState(String token, String id, String email, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('authToken', token);
    await prefs.setString('userId', id);
    await prefs.setString('userEmail', email);
    await prefs.setString('userName', name);

    _authToken = token;
    _userId = id;
    _userEmail = email;
    _userName = name;
    _isAuthenticated = true;

    await connectToEsp32();
    await syncDevicesFromServer();
    _startWebSensorPolling();
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
    await prefs.remove('userId');
    await prefs.remove('userEmail');
    await prefs.remove('userName');

    _authToken = null;
    _userId = null;
    _userEmail = null;
    _userName = null;
    _isAuthenticated = false;

    _esp32Service.disconnect();
    notifyListeners();
  }

  // ─── API AUTHENTICATION METHODS ──────────────────────────────────────────

  Future<bool> loginWithGoogle() async {
    try {
      UserCredential userCredential;

      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        userCredential =
            await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        final googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) return false;

        final googleAuth = await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);
      }

      final user = userCredential.user;

      if (user == null) return false;

      // 🔥 IMPORTANT: connect to your backend
      final idToken = await user.getIdToken();

      if (idToken == null) return false;

      final response = await ApiService.firebaseLogin(idToken);

      final token = response['token'];
      final userData = response['user'];

      await saveAuthState(
        token,
        userData['id'],
        userData['email'],
        userData['name'],
      );

      return true;
    } catch (e) {
      log("Google login error: $e");
      return false;
    }
  }

  Future<bool> loginWithFacebook(String accessToken) async {
    try {
      final credential = FacebookAuthProvider.credential(accessToken);
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final idToken = await userCredential.user?.getIdToken();
      if (idToken == null) return false;

      final response = await ApiService.firebaseLogin(idToken);
      final token = response['token'] as String;
      final user = response['user'] as Map<String, dynamic>;

      await saveAuthState(
        token,
        user['id'] as String,
        user['email'] as String,
        user['name'] as String,
      );
      return true;
    } catch (e) {
      debugPrint('Facebook login failed: $e');
      return false;
    }
  }

  Future<bool> loginWithApple(String identityToken, String userIdentifier) async {
    try {
      final response = await ApiService.appleLogin(identityToken, userIdentifier);
      final token = response['token'] as String;
      final user = response['user'] as Map<String, dynamic>;

      await saveAuthState(
        token,
        user['id'] as String,
        user['email'] as String,
        user['name'] as String,
      );
      return true;
    } catch (e) {
      debugPrint('Apple login failed: $e');
      return false;
    }
  }

  Future<bool> loginWithEmail(String email, String password) async {
    try {
      final response = await ApiService.emailLogin(email, password);
      final token = response['token'] as String;
      final user = response['user'] as Map<String, dynamic>;

      await saveAuthState(
        token,
        user['id'] as String,
        user['email'] as String,
        user['name'] as String,
      );
      return true;
    } catch (e) {
      debugPrint('Email login failed: $e');
      return false;
    }
  }

  Future<bool> signupWithEmail(String name, String email, String password) async {
    try {
      final response = await ApiService.emailSignup(name, email, password);
      final token = response['token'] as String;
      final user = response['user'] as Map<String, dynamic>;

      await saveAuthState(
        token,
        user['id'] as String,
        user['email'] as String,
        user['name'] as String,
      );
      return true;
    } catch (e) {
      debugPrint('Email signup failed: $e');
      return false;
    }
  }

  // ─── ESP32 CONNECTION METHODS ────────────────────────────────────────────

  Future<bool> connectToEsp32() async {
    if (kIsWeb) {
      // Avoid dart:io TLS primitives on Flutter Web.
      return false;
    }
    if (!_isAuthenticated) return false;
    return await _esp32Service.connect();
  }

  bool get isEsp32Connected => _esp32Service.isConnected;

  // ─── DEVICE MANAGEMENT METHODS ───────────────────────────────────────────

  Future<void> syncDevicesFromServer() async {
    if (!_isAuthenticated || _authToken == null) return;

    try {
      final serverDevices = await ApiService.getDevices(_authToken!);
      // Convert server devices to local DeviceModel format
      _devices = serverDevices.map((d) => DeviceModel.fromJson(d)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to sync devices: $e');
      // Keep local devices if sync fails
    }
  }

  Future<bool> addDeviceToServer({
    required String name,
    required String zone,
    required String icon,
    required int wattage,
  }) async {
    if (!_isAuthenticated || _authToken == null) return false;

    try {
      final generatedDeviceId =
          'fg-${DateTime.now().millisecondsSinceEpoch}-${name.hashCode.abs()}';
      final deviceData = {
        'deviceId': generatedDeviceId,
        'name': name,
        'location': zone,
        'icon': icon,
        'wattage': wattage,
        'type': icon,
      };

      final response = await ApiService.addDevice(_authToken!, deviceData);
      final newDevice = DeviceModel.fromJson(response);

      _devices = [..._devices, newDevice];
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Failed to add device: $e');
      return false;
    }
  }

  Future<bool> updateDeviceOnServer(DeviceModel device) async {
    if (!_isAuthenticated || _authToken == null) return false;

    try {
      final updates = device.toJson();
      await ApiService.updateDevice(_authToken!, device.deviceId, updates);

      final index = _devices.indexWhere((d) => d.id == device.id);
      if (index != -1) {
        _devices[index] = device;
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('Failed to update device: $e');
      return false;
    }
  }

  Future<bool> deleteDeviceFromServer(int deviceId) async {
    if (!_isAuthenticated || _authToken == null) return false;

    try {
      final device = getDevice(deviceId);
      if (device == null) return false;
      await ApiService.deleteDevice(_authToken!, device.deviceId);
      _devices.removeWhere((d) => d.id == deviceId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Failed to delete device: $e');
      return false;
    }
  }

  Future<bool> shareDeviceAccess({
    required int deviceId,
    required String email,
    required String permission,
  }) async {
    if (!_isAuthenticated || _authToken == null) return false;

    final device = getDevice(deviceId);
    if (device == null) return false;

    try {
      final shared = await ApiService.shareDeviceAccess(
        _authToken!,
        device.deviceId,
        email,
        permission: permission,
      );

      final sharedUser = SharedUser.fromJson(
        Map<String, dynamic>.from(shared['shared'] ?? {}),
      );

      final index = _devices.indexWhere((d) => d.id == deviceId);
      if (index != -1) {
        final updated = List<SharedUser>.from(_devices[index].sharedUsers);
        final existingIndex =
            updated.indexWhere((u) => u.backendId == sharedUser.backendId);
        if (existingIndex != -1) {
          updated[existingIndex] = sharedUser;
        } else {
          updated.add(sharedUser);
        }
        _devices[index] = _devices[index].copyWith(sharedUsers: updated);
        notifyListeners();
      }

      return true;
    } catch (e) {
      debugPrint('Failed to share device access: $e');
      return false;
    }
  }

  Future<void> loadSharedAccessForDevice(int deviceId) async {
    if (!_isAuthenticated || _authToken == null) return;
    final device = getDevice(deviceId);
    if (device == null) return;

    try {
      final shared = await ApiService.getSharedAccess(
        _authToken!,
        device.deviceId,
      );
      final mapped = shared
          .map((entry) =>
              SharedUser.fromJson(Map<String, dynamic>.from(entry)))
          .toList();
      final index = _devices.indexWhere((d) => d.id == deviceId);
      if (index != -1) {
        _devices[index] = _devices[index].copyWith(sharedUsers: mapped);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to load shared access: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getDeviceHistory(
    int deviceId, {
    int limit = 100,
    int sinceHours = 24,
  }) async {
    if (!_isAuthenticated || _authToken == null) return [];
    final device = getDevice(deviceId);
    if (device == null) return [];

    try {
      final rows = await ApiService.getDeviceHistory(
        _authToken!,
        device.deviceId,
        limit: limit,
        sinceHours: sinceHours,
      );
      return rows
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();
    } catch (e) {
      debugPrint('Failed to fetch history: $e');
      return [];
    }
  }

  // ─── DEVICE CONTROL METHODS ──────────────────────────────────────────────

  Future<bool> toggleDevicePower(int deviceId) async {
    final device = getDevice(deviceId);
    if (device == null) return false;

    final newState = !device.active;

    // Update locally first for immediate UI feedback
    toggleDevice(deviceId);

    // Send command to ESP32
    try {
      await _esp32Service.setDevicePower(deviceId.toString(), newState);
      return true;
    } catch (e) {
      // Revert local change if ESP32 command fails
      toggleDevice(deviceId);
      debugPrint('Failed to toggle device power: $e');
      return false;
    }
  }

  Future<bool> sendDeviceCommand(int deviceId, String command, Map<String, dynamic>? params) async {
    try {
      await _esp32Service.sendCommand(deviceId.toString(), command, params);
      return true;
    } catch (e) {
      debugPrint('Failed to send device command: $e');
      return false;
    }
  }

  bool get isDark => _isDark;
  List<DeviceModel> get devices => List.unmodifiable(_devices);
  DeviceModel? get selectedDevice => _selectedDevice;

  // ── Load saved theme on app start ─────────────────────────────────
  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool('isDark') ?? false;
    notifyListeners();
  }

  // ── Toggle and persist theme ───────────────────────────────────────
  Future<void> toggleTheme() async {
    _isDark = !_isDark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', _isDark);
    notifyListeners();
  }

  void toggleDevice(int id) {
    _devices = _devices.map((d) =>
      d.id == id ? d.copyWith(active: !d.active) : d
    ).toList();
    notifyListeners();
  }

  void toggleAutoCutoff(int id) {
    _devices = _devices.map((d) =>
      d.id == id ? d.copyWith(autoCutoff: !d.autoCutoff) : d
    ).toList();
    notifyListeners();
  }

  void setThreshold(int id, String threshold) {
    _devices = _devices.map((d) =>
      d.id == id ? d.copyWith(threshold: threshold) : d
    ).toList();
    notifyListeners();
  }

  void updateSchedule(int id, bool enabled, int startH, int startM, int endH, int endM) {
    _devices = _devices.map((d) =>
      d.id == id ? d.copyWith(
        scheduleEnabled: enabled,
        startHour: startH,
        startMinute: startM,
        endHour: endH,
        endMinute: endM,
      ) : d
    ).toList();
    notifyListeners();
  }

  void selectDevice(DeviceModel device) {
    _selectedDevice = device;
    notifyListeners();
  }

  void updateSensorData(int id, {
    double? voltage,
    double? current,
    double? temperature,
  }) {
    _devices = _devices.map((d) => d.id == id
        ? d.copyWith(
            voltage:     voltage,
            current:     current,
            temperature: temperature,
          )
        : d).toList();
    notifyListeners();
  }

  void addDevice({
    required String name,
    required String zone,
    required String icon,
    required int wattage,
  }) {
    _devices = [
      ..._devices,
      DeviceModel(
        id: _nextId++,
        deviceId: 'local-${DateTime.now().millisecondsSinceEpoch}',
        name: name, zone: zone, icon: icon,
        wattage: wattage, voltage: 230,
        current: wattage / 230,
        temperature: 25.0,
        active: false, risk: 'Low', riskScore: 5,
        runtime: '0h 00m', autoCutoff: true, threshold: 'High',
      ),
    ];
    notifyListeners();
  }

  DeviceModel? getDevice(int id) {
    try { return _devices.firstWhere((d) => d.id == id); }
    catch (_) { return null; }
  }

  int get totalWatts =>
      _devices.where((d) => d.active).fold(0, (s, d) => s + d.wattage);

  bool get isSafe => totalWatts < 3500;

  double get maxActiveTemp {
    final active = _devices.where((d) => d.active);
    if (active.isEmpty) return 0;
    return active.map((d) => d.temperature).reduce((a, b) => a > b ? a : b);
  }

  int get totalSharedUsersCount {
    final allUsers = <int>{};
    for (final d in _devices) {
      for (final u in d.sharedUsers) {
        allUsers.add(u.id);
      }
    }
    return allUsers.length;
  }

  // ── Alerts Management ──────────────────────────────────────────────
  bool get hasNewNotification => _hasNewNotification;
  void clearNewNotification() {
    _hasNewNotification = false;
    notifyListeners();
  }

  bool _announcementsEnabled = true;
  bool _accessEnabled = true;

  List<AppNotification> get notifications => _notifications
      .where((n) => (n.category == AppNotificationCategory.announcement && _announcementsEnabled) ||
                    (n.category == AppNotificationCategory.access && _accessEnabled) ||
                    (n.category == AppNotificationCategory.system))
      .toList();

  void toggleCategory(AppNotificationCategory category, bool enabled) {
    if (category == AppNotificationCategory.announcement) _announcementsEnabled = enabled;
    if (category == AppNotificationCategory.access) _accessEnabled = enabled;
    notifyListeners();
  }

  void deleteNotification(int id) {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  Future<bool> deleteSharedUser(int deviceId, SharedUser user) async {
    if (!_isAuthenticated || _authToken == null) return false;
    final device = getDevice(deviceId);
    if (device == null || user.backendId.isEmpty) return false;

    try {
      await ApiService.removeSharedAccess(
        _authToken!,
        device.deviceId,
        user.backendId,
      );

      final i = _devices.indexWhere((d) => d.id == deviceId);
      if (i != -1) {
        final shared = List<SharedUser>.from(_devices[i].sharedUsers);
        shared.removeWhere(
            (u) => u.backendId == user.backendId || u.id == user.id);
        _devices[i] = _devices[i].copyWith(sharedUsers: shared);
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('Failed to delete shared user: $e');
      return false;
    }
  }

  List<dynamic> get alerts => _alerts;
  List<dynamic> get activeAlerts => _alerts.where((a) => !_dismissedAlerts.contains(a.id)).toList();
  int get activeAlertCount => activeAlerts.length;

  void dismissAlert(int id) {
    _dismissedAlerts.add(id);
    notifyListeners();
  }

  int getDeviceCountInRoom(String room) {
    return _devices.where((d) => d.zone == room).length;
  }

  int getDeviceCountByType(String type) {
    return _devices.where((d) => d.icon.toLowerCase() == type.toLowerCase()).length;
  }

  // ── Room Management ────────────────────────────────────────────────
  List<String> get rooms => List.unmodifiable(_rooms);

  void addRoom(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final exists = _rooms.any((r) => r.toLowerCase() == trimmed.toLowerCase());
    if (!exists) {
      _rooms.add(trimmed);
      notifyListeners();
    }
  }

  void addType(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final exists = _deviceTypes.any((t) => t.toLowerCase() == trimmed.toLowerCase());
    if (!exists) {
      _deviceTypes.add(trimmed);
      notifyListeners();
    }
  }

  List<String> get deviceTypes => List.unmodifiable(_deviceTypes);

  void removeRoom(String name) {
    if (_rooms.length <= 1) return; 
    _rooms.remove(name);
    _devices = _devices.map((d) =>
      d.zone == name ? d.copyWith(zone: 'Unknown Area') : d
    ).toList();
    notifyListeners();
  }

  void updateDevice(DeviceModel device) {
    final i = _devices.indexWhere((d) => d.id == device.id);
    if (i != -1) {
      _devices[i] = device;
      notifyListeners();
    }
  }

  void renameRoom(String oldName, String newName) {
    final index = _rooms.indexOf(oldName);
    if (index != -1) {
      _rooms[index] = newName;
      // Update devices in this room
      _devices = _devices.map((d) =>
        d.zone == oldName ? d.copyWith(zone: newName) : d
      ).toList();
      notifyListeners();
    }
  }
}