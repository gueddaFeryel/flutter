import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medical_intervention_app/models/notification.dart';

class NotificationService {
  // Adresse du backend - à adapter selon la plateforme
  static const String _baseUrl = 'http://10.0.2.2:8082/api/notifications';
  static const String _medicalStaffUrl = 'http://10.0.2.2:8089/api/medical-staff/by-firebase';

  Future<String?> _getFirebaseToken() async {
    try {
      return await FirebaseAuth.instance.currentUser?.getIdToken();
    } catch (e) {
      print('Error getting Firebase token: $e');
      return null;
    }
  }

  Future<String?> _getStaffId(String firebaseUid) async {
    final token = await _getFirebaseToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('$_medicalStaffUrl/$firebaseUid'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['id']?.toString();
    }
    return null;
  }

  Future<List<AppNotification>> getUserNotifications(String firebaseUid) async {
    try {
      final staffId = await _getStaffId(firebaseUid);
      if (staffId == null) throw Exception('Staff ID not found');

      final token = await _getFirebaseToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('$_baseUrl/user/$staffId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => AppNotification.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load notifications: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getUserNotifications: $e');
      rethrow;
    }
  }

  Future<void> markAllAsRead(String firebaseUid) async {
    try {
      final staffId = await _getStaffId(firebaseUid);
      if (staffId == null) throw Exception('Staff ID not found');

      final token = await _getFirebaseToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.post(
        Uri.parse('$_baseUrl/mark-all-read?userId=$staffId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark as read: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in markAllAsRead: $e');
      rethrow;
    }
  }
  Future<void> markNotificationAsRead(String notificationId) async {
  final response = await http.post(
    Uri.parse('$_baseUrl/mark-read'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'notificationId': notificationId}),
  );

  if (response.statusCode != 200) {
    throw Exception('Failed to mark notification as read');
  }
}
}