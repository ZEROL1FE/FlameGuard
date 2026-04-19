import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Direct Firestore service — replaces the old Express/MongoDB API layer.
/// Every CRUD operation goes straight to Cloud Firestore.
class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── COLLECTION REFERENCES ──────────────────────────────────────────────────
  static CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  static CollectionReference<Map<String, dynamic>> get _devices =>
      _db.collection('devices');

  // ─── USER METHODS ───────────────────────────────────────────────────────────

  /// Create or update a user document in Firestore (called on every login/signup).
  static Future<void> createOrUpdateUser({
    required String uid,
    required String email,
    required String name,
    String? profilePicture,
    String provider = 'email',
  }) async {
    final userRef = _users.doc(uid);
    final doc = await userRef.get();

    if (doc.exists) {
      // Update last login
      await userRef.update({
        'lastLogin': FieldValue.serverTimestamp(),
        'name': name,
        if (profilePicture != null) 'profilePicture': profilePicture,
      });
    } else {
      // Create new user doc
      await userRef.set({
        'email': email,
        'name': name,
        'profilePicture': profilePicture ?? '',
        'provider': provider,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Get user data by uid.
  static Future<Map<String, dynamic>?> getUser(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return {'id': doc.id, ...doc.data()!};
  }

  /// Lookup a user by email (for sharing devices).
  static Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final query = await _users
        .where('email', isEqualTo: email.trim().toLowerCase())
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    final doc = query.docs.first;
    return {'id': doc.id, ...doc.data()};
  }

  // ─── DEVICE METHODS ─────────────────────────────────────────────────────────

  /// Get all devices owned by or shared with the user.
  static Future<List<Map<String, dynamic>>> getDevices(String uid) async {
    // Get owned devices
    final ownedQuery = await _devices
        .where('owner', isEqualTo: uid)
        .get();

    // Get shared devices
    final sharedQuery = await _devices
        .where('sharedWith', arrayContains: uid)
        .get();

    // Merge and deduplicate
    final Map<String, Map<String, dynamic>> deviceMap = {};

    for (final doc in ownedQuery.docs) {
      deviceMap[doc.id] = {'id': doc.id, 'deviceId': doc.id, ...doc.data()};
    }
    for (final doc in sharedQuery.docs) {
      if (!deviceMap.containsKey(doc.id)) {
        deviceMap[doc.id] = {'id': doc.id, 'deviceId': doc.id, ...doc.data()};
      }
    }

    return deviceMap.values.toList();
  }

  /// Add a new device.
  static Future<Map<String, dynamic>> addDevice(
    String uid,
    Map<String, dynamic> deviceData,
  ) async {
    final data = {
      ...deviceData,
      'owner': uid,
      'sharedWith': <String>[],
      'sharedAccess': <Map<String, dynamic>>[],
      'active': false,
      'sensorData': {
        'temperature': 25.0,
        'voltage': 230.0,
        'current': 0.0,
        'humidity': null,
        'flameDetected': false,
        'smokeDetected': false,
        'batteryLevel': 100,
      },
      'createdAt': FieldValue.serverTimestamp(),
    };

    final docRef = await _devices.add(data);
    final doc = await docRef.get();

    return {'id': doc.id, 'deviceId': doc.id, ...doc.data()!};
  }

  /// Update a device document.
  static Future<void> updateDevice(
    String deviceId,
    Map<String, dynamic> updates,
  ) async {
    // Remove fields that shouldn't be overwritten
    final clean = Map<String, dynamic>.from(updates)
      ..remove('id')
      ..remove('deviceId')
      ..remove('createdAt')
      ..remove('owner');

    await _devices.doc(deviceId).update(clean);
  }

  /// Delete a device document.
  static Future<void> deleteDevice(String deviceId) async {
    await _devices.doc(deviceId).delete();
  }

  // ─── ACCESS SHARING ─────────────────────────────────────────────────────────

  /// Share device access with another user by email.
  /// Returns the shared user info if successful.
  static Future<Map<String, dynamic>?> shareDeviceAccess(
    String deviceId,
    String email, {
    String permission = 'view',
  }) async {
    // Find the target user by email
    final targetUser = await getUserByEmail(email);
    if (targetUser == null) return null;

    final targetUid = targetUser['id'] as String;

    final deviceRef = _devices.doc(deviceId);
    final deviceDoc = await deviceRef.get();
    if (!deviceDoc.exists) return null;

    final data = deviceDoc.data()!;
    final sharedAccess = List<Map<String, dynamic>>.from(
      (data['sharedAccess'] as List<dynamic>?) ?? [],
    );
    final sharedWith = List<String>.from(
      (data['sharedWith'] as List<dynamic>?) ?? [],
    );

    // Check if already shared, update permission
    final existingIndex = sharedAccess.indexWhere(
      (entry) => entry['userId'] == targetUid,
    );

    if (existingIndex >= 0) {
      sharedAccess[existingIndex] = {
        'userId': targetUid,
        'email': targetUser['email'],
        'name': targetUser['name'],
        'permission': permission,
        'sharedAt': DateTime.now().toIso8601String(),
      };
    } else {
      sharedAccess.add({
        'userId': targetUid,
        'email': targetUser['email'],
        'name': targetUser['name'],
        'permission': permission,
        'sharedAt': DateTime.now().toIso8601String(),
      });
    }

    // Add to sharedWith array for querying
    if (!sharedWith.contains(targetUid)) {
      sharedWith.add(targetUid);
    }

    await deviceRef.update({
      'sharedAccess': sharedAccess,
      'sharedWith': sharedWith,
    });

    return {
      'id': targetUid,
      'name': targetUser['name'] ?? 'User',
      'email': targetUser['email'] ?? '',
      'permission': permission,
    };
  }

  /// Get shared access list for a device.
  static Future<List<Map<String, dynamic>>> getSharedAccess(
    String deviceId,
  ) async {
    final doc = await _devices.doc(deviceId).get();
    if (!doc.exists) return [];

    final data = doc.data()!;
    final sharedAccess = (data['sharedAccess'] as List<dynamic>?) ?? [];
    return sharedAccess
        .map((entry) => Map<String, dynamic>.from(entry as Map))
        .toList();
  }

  /// Remove shared access for a user.
  static Future<void> removeSharedAccess(
    String deviceId,
    String userId,
  ) async {
    final deviceRef = _devices.doc(deviceId);
    final deviceDoc = await deviceRef.get();
    if (!deviceDoc.exists) return;

    final data = deviceDoc.data()!;
    final sharedAccess = List<Map<String, dynamic>>.from(
      (data['sharedAccess'] as List<dynamic>?) ?? [],
    );
    final sharedWith = List<String>.from(
      (data['sharedWith'] as List<dynamic>?) ?? [],
    );

    sharedAccess.removeWhere((entry) => entry['userId'] == userId);
    sharedWith.remove(userId);

    await deviceRef.update({
      'sharedAccess': sharedAccess,
      'sharedWith': sharedWith,
    });
  }

  // ─── SENSOR HISTORY ─────────────────────────────────────────────────────────

  /// Get sensor history for a device.
  static Future<List<Map<String, dynamic>>> getDeviceHistory(
    String deviceId, {
    int limit = 100,
    int sinceHours = 24,
  }) async {
    final since = DateTime.now().subtract(Duration(hours: sinceHours));

    final query = await _devices
        .doc(deviceId)
        .collection('sensorHistory')
        .where('recordedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
        .orderBy('recordedAt', descending: true)
        .limit(limit)
        .get();

    return query.docs.map((doc) {
      final data = doc.data();
      // Convert Timestamp to ISO string for compatibility
      if (data['recordedAt'] is Timestamp) {
        data['recordedAt'] =
            (data['recordedAt'] as Timestamp).toDate().toIso8601String();
      }
      return data;
    }).toList();
  }

  /// Add a sensor history entry for a device.
  static Future<void> addSensorHistory(
    String deviceId,
    Map<String, dynamic> sensorData,
  ) async {
    await _devices.doc(deviceId).collection('sensorHistory').add({
      ...sensorData,
      'recordedAt': FieldValue.serverTimestamp(),
    });
  }

  // ─── FORGOT PASSWORD ───────────────────────────────────────────────────────

  /// Send a password reset email via Firebase Auth.
  static Future<void> sendPasswordResetEmail(String email) async {
    await FirebaseAuth.instance.sendPasswordResetEmail(
      email: email.trim(),
    );
  }
}
