// lib/models/device_model.dart

class SharedUser {
  final int id;
  final String name;
  final String initial;

  SharedUser({required this.id, required this.name, required this.initial});
}

class DeviceModel {
  final List<SharedUser> sharedUsers;
  final int id;
  final String name;
  final String zone;
  final String icon;
  final int wattage;
  final double voltage;
  final double current;
  final double temperature; // °C — from sensor
  bool active;
  final String risk;
  final int riskScore;
  final String runtime;
  bool autoCutoff;
  String threshold;
  bool scheduleEnabled;
  int startHour;
  int startMinute;
  int endHour;
  int endMinute;

  DeviceModel({
    required this.id,
    required this.name,
    required this.zone,
    required this.icon,
    required this.wattage,
    required this.voltage,
    required this.current,
    required this.temperature,
    required this.active,
    required this.risk,
    required this.riskScore,
    required this.runtime,
    this.autoCutoff = true,
    this.threshold  = 'High',
    this.scheduleEnabled = false,
    this.startHour = 8,
    this.startMinute = 0,
    this.endHour = 22,
    this.endMinute = 0,
    this.sharedUsers = const [],
  });

  String get powerLabel {
    if (wattage >= 1000) return '${(wattage / 1000).toStringAsFixed(1)} kW';
    return '$wattage W';
  }

  /// Safe < 45°C · Warning 45–65°C · Critical > 65°C
  String get tempStatus {
    if (temperature >= 65) return 'Critical';
    if (temperature >= 45) return 'Warning';
    return 'Safe';
  }

  DeviceModel copyWith({
    bool?   active,
    bool?   autoCutoff,
    String? threshold,
    String? risk,
    int?    riskScore,
    String? name,
    String? zone,
    String? icon,
    int?    wattage,
    double? temperature,
    double? voltage,
    double? current,
    bool?   scheduleEnabled,
    int?    startHour,
    int?    startMinute,
    int?    endHour,
    int?    endMinute,
    List<SharedUser>? sharedUsers,
  }) => DeviceModel(
    id:          id,
    name:        name        ?? this.name,
    zone:        zone        ?? this.zone,
    icon:        icon        ?? this.icon,
    wattage:     wattage     ?? this.wattage,
    voltage:     voltage     ?? this.voltage,
    current:     current     ?? this.current,
    temperature: temperature ?? this.temperature,
    active:      active      ?? this.active,
    risk:        risk        ?? this.risk,
    riskScore:   riskScore   ?? this.riskScore,
    runtime:     runtime,
    autoCutoff:  autoCutoff  ?? this.autoCutoff,
    threshold:   threshold   ?? this.threshold,
    sharedUsers: sharedUsers ?? this.sharedUsers,
    scheduleEnabled: scheduleEnabled ?? this.scheduleEnabled,
    startHour:   startHour   ?? this.startHour,
    startMinute: startMinute ?? this.startMinute,
    endHour:     endHour     ?? this.endHour,
    endMinute:   endMinute   ?? this.endMinute,
  );

  // ─── JSON SERIALIZATION ───────────────────────────────────────────────────

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['id'] as int,
      name: json['name'] as String,
      zone: json['zone'] as String,
      icon: json['icon'] as String,
      wattage: json['wattage'] as int,
      voltage: (json['voltage'] as num).toDouble(),
      current: (json['current'] as num).toDouble(),
      temperature: (json['temperature'] as num).toDouble(),
      active: json['active'] as bool,
      risk: json['risk'] as String,
      riskScore: json['riskScore'] as int,
      runtime: json['runtime'] as String,
      autoCutoff: json['autoCutoff'] as bool? ?? true,
      threshold: json['threshold'] as String? ?? 'High',
      scheduleEnabled: json['scheduleEnabled'] as bool? ?? false,
      startHour: json['startHour'] as int? ?? 8,
      startMinute: json['startMinute'] as int? ?? 0,
      endHour: json['endHour'] as int? ?? 22,
      endMinute: json['endMinute'] as int? ?? 0,
      sharedUsers: (json['sharedUsers'] as List<dynamic>?)
          ?.map((u) => SharedUser.fromJson(u as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'zone': zone,
      'icon': icon,
      'wattage': wattage,
      'voltage': voltage,
      'current': current,
      'temperature': temperature,
      'active': active,
      'risk': risk,
      'riskScore': riskScore,
      'runtime': runtime,
      'autoCutoff': autoCutoff,
      'threshold': threshold,
      'scheduleEnabled': scheduleEnabled,
      'startHour': startHour,
      'startMinute': startMinute,
      'endHour': endHour,
      'endMinute': endMinute,
      'sharedUsers': sharedUsers.map((u) => u.toJson()).toList(),
    };
  }
}

// ─── SHARED USER JSON METHODS ──────────────────────────────────────────────

extension SharedUserJson on SharedUser {
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'initial': initial,
    };
  }

  factory SharedUser.fromJson(Map<String, dynamic> json) {
    return SharedUser(
      id: json['id'] as int,
      name: json['name'] as String,
      initial: json['initial'] as String,
    );
  }
}

// ─── SEED DATA ────────────────────────────────────────────────────────────────
final List<DeviceModel> initialDevices = [
  DeviceModel(
    id: 1, name: 'Master Fan', zone: 'Bedroom', icon: 'fan',
    wattage: 1200, voltage: 230, current: 5.22, temperature: 38.5,
    active: true, risk: 'Low', riskScore: 12, runtime: '3h 15m',
    autoCutoff: true, threshold: 'High',
    scheduleEnabled: true, startHour: 8, startMinute: 0, endHour: 13, endMinute: 0,
    sharedUsers: [
      SharedUser(id: 1, name: 'John Doe', initial: 'J'),
      SharedUser(id: 2, name: 'Jane Smith', initial: 'S'),
    ],
  ),
  DeviceModel(
    id: 2, name: 'Living Room TV', zone: 'Living', icon: 'tv',
    wattage: 125, voltage: 230, current: 0.54, temperature: 31.2,
    active: true, risk: 'Low', riskScore: 8, runtime: '1h 42m',
    autoCutoff: true, threshold: 'High',
    sharedUsers: [
      SharedUser(id: 3, name: 'Mark Wilson', initial: 'W'),
    ],
  ),
  DeviceModel(
    id: 3, name: 'Kitchen Fan', zone: 'Kitchen', icon: 'fan',
    wattage: 55, voltage: 230, current: 0.24, temperature: 35.8,
    active: false, risk: 'Medium', riskScore: 34, runtime: '0h 22m',
    autoCutoff: false, threshold: 'Medium',
    sharedUsers: [],
  ),
  DeviceModel(
    id: 4, name: 'Smart AC', zone: 'Bedroom', icon: 'fan',
    wattage: 1500, voltage: 230, current: 6.52, temperature: 42.0,
    active: false, risk: 'Low', riskScore: 15, runtime: '0h 45m',
    autoCutoff: true, threshold: 'High',
  ),
  DeviceModel(
    id: 5, name: 'Smart Lights', zone: 'Living', icon: 'zap',
    wattage: 60, voltage: 230, current: 0.26, temperature: 28.0,
    active: true, risk: 'Low', riskScore: 2, runtime: '5h 20m',
    autoCutoff: true, threshold: 'High',
  ),
];