import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart' as client;
import '../models/medical_staff.dart';
import 'dart:convert';
import '../models/intervention.dart';
import '../models/rapport.dart';

class InterventionService {
  static const String _baseUrl = 'http://10.0.2.2:8089/api';

  // In InterventionService
// In your InterventionService class
Future<List<Intervention>> getInterventionsByStaff(String firebaseUid) async {
  try {
    // 1. Obtenir le staffId numérique à partir du firebaseUid
    final staffResponse = await http.get(
      Uri.parse('$_baseUrl/medical-staff/by-firebase/$firebaseUid'),
      headers: {'Content-Type': 'application/json'},
    );

    if (staffResponse.statusCode != 200) {
      throw Exception('Échec de récupération du staff ID: ${staffResponse.statusCode}');
    }

    final staffData = json.decode(staffResponse.body);
    final staffId = staffData['id'] as int?;

    if (staffId == null) {
      return [];
    }

    // 2. Maintenant utiliser le staffId numérique pour obtenir les interventions
    final interventionsResponse = await http.get(
      Uri.parse('$_baseUrl/interventions/by-staff/$staffId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (interventionsResponse.statusCode == 200) {
      final List<dynamic> data = json.decode(interventionsResponse.body);
      return data.map((json) => Intervention.fromJson(json)).toList();
    } else {
      throw Exception('Échec du chargement: ${interventionsResponse.statusCode}');
    }
  } catch (e) {
    debugPrint('Erreur dans getInterventionsByStaff: $e');
    rethrow;
  }
}
Future<void> createInterventionWithRoomAndUser(Map<String, dynamic> intervention) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/interventions/with-room-and-user'),
      headers: {
        'Content-Type': 'application/json',
        // Add your authentication headers here
      },
      body: json.encode(intervention),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create intervention: ${response.body}');
    }
  }

Future<List<String>> getInterventionTypes() async {
  final response = await http.get(Uri.parse('$_baseUrl/intervention-types'));
  if (response.statusCode == 200) {
    return List<String>.from(json.decode(response.body));
  }
  throw Exception('Failed to load intervention types');
}

Future<List<MedicalStaff>> getMedicalStaffByRole(String role) async {
  final response = await http.get(Uri.parse('$_baseUrl/medical-staff/role/$role'));
  if (response.statusCode == 200) {
    return (json.decode(response.body) as List)
        .map((json) => MedicalStaff.fromJson(json))
        .toList();
  }
  throw Exception('Failed to load medical staff');
}
  Future<Intervention> createIntervention(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/interventions'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    
    if (response.statusCode == 201) {
      return Intervention.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create intervention');
    }
  }
 // services/intervention_service.dart
Future<Rapport?> getRapportByIntervention(int interventionId) async {
  try {
    final response = await http.get(
      Uri.parse('$_baseUrl/rapports-postoperatoires/intervention/$interventionId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      if (jsonData == null) return null;
      return Rapport.fromJson(jsonData);
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('Failed to load report: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('Error in getRapportByIntervention: $e');
    throw Exception('Error fetching report: ${e.toString()}');
  }
}

  Future<Rapport> createRapport(
  int interventionId,
  int userId,
  Map<String, dynamic> rapportData,
  String userRole,
) async {
  try {
    // Vérifier d'abord si un rapport existe déjà
    final existingRapport = await getRapportByIntervention(interventionId);
    if (existingRapport != null) {
      throw Exception('Un rapport existe déjà pour cette intervention');
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/rapports-postoperatoires/intervention/$interventionId'),
      headers: {
        'Content-Type': 'application/json',
        'X-User-Id': userId.toString(),
        'X-User-Role': userRole,
      },
      body: json.encode(rapportData),
    );

    if (response.statusCode == 201) {
      return Rapport.fromJson(json.decode(response.body));
    } else if (response.statusCode == 409) {
      throw Exception('Un rapport existe déjà pour cette intervention');
    } else {
      final errorData = json.decode(response.body);
      final errorMessage = errorData['message'] ?? 
          errorData['error'] ??
          'Failed to create report: ${response.statusCode}';
      throw Exception(errorMessage);
    }
  } catch (e) {
    throw Exception('Error creating report: $e');
  }
}
  Future<Rapport> updateRapport(
  int rapportId,
  Map<String, dynamic> rapportData,
  int userId,
  String userRole,
) async {
  try {
    final url = userRole == 'INFIRMIER'
        ? '$_baseUrl/rapports-postoperatoires/$rapportId/notes-infirmier'
        : '$_baseUrl/rapports-postoperatoires/$rapportId';

    final response = await http.put(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'X-User-Id': userId.toString(),
        'X-User-Role': userRole,
      },
      body: json.encode(rapportData),
    );

    if (response.statusCode == 200) {
      return Rapport.fromJson(json.decode(response.body));
    } else {
      throw Exception('Échec de la mise à jour: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Erreur lors de la mise à jour: $e');
  }
}
}