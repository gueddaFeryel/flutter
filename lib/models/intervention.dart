import 'operating_room.dart';
import 'medical_staff.dart';
import 'materiel.dart';
import 'patient.dart';
class Intervention {
  final int id;
  final String type;
  final DateTime date;
  final DateTime? startTime;
  final DateTime? endTime;
  final String status;
  final OperatingRoom? room;
  final Set<MedicalStaff>? medicalTeam;
  final List<Materiel>? materiels;
  final String? notes;
  final String? roomId;
  final Patient? patient;
  Intervention({
    required this.id,
    required this.type,
    required this.date,
    this.startTime,
    this.endTime,
    required this.status,
    this.room,
    this.medicalTeam,
    this.materiels,
    this.notes,
    this.roomId,
     this.patient,
  });

  factory Intervention.fromJson(Map<String, dynamic> json) {
    return Intervention(
      id: json['id'] as int,
      type: json['type'].toString(),
      date: DateTime.parse(json['date']),
      startTime: json['startTime'] != null ? DateTime.parse(json['startTime']) : null,
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      status: json['statut']?.toString() ?? 'DEMANDE',
      room: json['room'] != null ? OperatingRoom.fromJson(json['room']) : null,
      roomId: json['roomId']?.toString(),
      medicalTeam: json['equipeMedicale'] != null
          ? (json['equipeMedicale'] as List)
              .map((e) => MedicalStaff.fromJson(e))
              .toSet()
          : null,
      materiels: json['materiels'] != null
          ? (json['materiels'] as List)
              .map((e) => Materiel.fromJson(e))
              .toList()
          : null,
      notes: json['notes'],
      patient: json['patient'] != null ? Patient.fromJson(json['patient']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'date': date.toIso8601String(),
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'statut': status,
      'room': room?.toJson(),
      'roomId': roomId,
      'equipeMedicale': medicalTeam?.map((e) => e.toJson()).toList(),
      'materiels': materiels?.map((e) => e.toJson()).toList(),
      'notes': notes,
      'patient': patient?.toJson(),
    };
  }
}