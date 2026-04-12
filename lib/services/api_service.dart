import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

class ApiService {
  static const String baseUrl = 'https://flameguard.onrender.com/api';

  // Headers for authenticated requests
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Add auth token to headers
  static Map<String, String> authHeaders(String token) => {
    ..._headers,
    'Authorization': 'Bearer $token',
  };

  // ─── AUTHENTICATION ENDPOINTS ──────────────────────────────────────────────

  // Google OAuth login
  static Future<Map<String, dynamic>> googleLogin(String idToken) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/google-login'),
      headers: _headers,
      body: jsonEncode({'idToken': idToken}),
    );
    return _handleResponse(response);
  }

  // Facebook OAuth login
  static Future<Map<String, dynamic>> facebookLogin(String accessToken) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/facebook-login'),
      headers: _headers,
      body: jsonEncode({'accessToken': accessToken}),
    );
    return _handleResponse(response);
  }

  // Apple Sign In
  static Future<Map<String, dynamic>> appleLogin(String identityToken, String userIdentifier) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/apple-login'),
      headers: _headers,
      body: jsonEncode({
        'identityToken': identityToken,
        'userIdentifier': userIdentifier,
      }),
    );
    return _handleResponse(response);
  }

  // Email/password login
  static Future<Map<String, dynamic>> emailLogin(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _handleResponse(response);
  }

  // Email/password signup
  static Future<Map<String, dynamic>> emailSignup(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/signup'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
      }),
    );
    return _handleResponse(response);
  }

  // ─── DEVICE MANAGEMENT ENDPOINTS ───────────────────────────────────────────

  // Get all user devices
  static Future<List<dynamic>> getDevices(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/devices'),
      headers: authHeaders(token),
    );
    final data = _handleResponse(response);
    return data['devices'] ?? [];
  }

  // Add new device
  static Future<Map<String, dynamic>> addDevice(String token, Map<String, dynamic> deviceData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/devices'),
      headers: authHeaders(token),
      body: jsonEncode(deviceData),
    );
    return _handleResponse(response);
  }

  // Update device
  static Future<Map<String, dynamic>> updateDevice(String token, String deviceId, Map<String, dynamic> updates) async {
    final response = await http.put(
      Uri.parse('$baseUrl/devices/$deviceId'),
      headers: authHeaders(token),
      body: jsonEncode(updates),
    );
    return _handleResponse(response);
  }

  // Delete device
  static Future<void> deleteDevice(String token, String deviceId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/devices/$deviceId'),
      headers: authHeaders(token),
    );
    _handleResponse(response);
  }

  // ─── ESP32 COMMUNICATION ENDPOINTS ─────────────────────────────────────────

  // Send command to ESP32 device
  static Future<Map<String, dynamic>> sendDeviceCommand(String token, String deviceId, String command, Map<String, dynamic>? params) async {
    final response = await http.post(
      Uri.parse('$baseUrl/devices/$deviceId/command'),
      headers: authHeaders(token),
      body: jsonEncode({
        'command': command,
        'params': params ?? {},
      }),
    );
    return _handleResponse(response);
  }

  // Get device status from ESP32
  static Future<Map<String, dynamic>> getDeviceStatus(String token, String deviceId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/devices/$deviceId/status'),
      headers: authHeaders(token),
    );
    return _handleResponse(response);
  }

  // ─── ACCESS SHARING ENDPOINTS ─────────────────────────────────────────────

  // Share device access
  static Future<Map<String, dynamic>> shareDeviceAccess(String token, String deviceId, String email, List<String> permissions) async {
    final response = await http.post(
      Uri.parse('$baseUrl/devices/$deviceId/share'),
      headers: authHeaders(token),
      body: jsonEncode({
        'email': email,
        'permissions': permissions,
      }),
    );
    return _handleResponse(response);
  }

  // Get shared access list
  static Future<List<dynamic>> getSharedAccess(String token, String deviceId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/devices/$deviceId/shared'),
      headers: authHeaders(token),
    );
    final data = _handleResponse(response);
    return data['shared'] ?? [];
  }

  // ─── UTILITY METHODS ──────────────────────────────────────────────────────

  // Handle HTTP response
  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw ApiException(
        statusCode: response.statusCode,
        message: error['message'] ?? 'API request failed',
        details: error,
      );
    }
  }
}

// Custom exception for API errors
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? details;

  ApiException({
    required this.statusCode,
    required this.message,
    this.details,
  });

  @override
  String toString() => 'ApiException: $statusCode - $message';
}