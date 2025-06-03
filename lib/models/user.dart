import 'package:firebase_auth/firebase_auth.dart';

class AppUser {
  final int id;
  final String firebaseUid;
  final String email;
  final String? firstName;
  final String? lastName;
  final String role;
  final bool isAdmin;
  final bool isApproved;

  AppUser({
    required this.id,
    required this.firebaseUid,
    required this.email,
    this.firstName,
    this.lastName,
    required this.role,
    this.isAdmin = false,
    this.isApproved = false,
  });

  factory AppUser.fromFirebase(User user, Map<String, dynamic> data) {
    return AppUser(
      id: _parseId(data['id']),
      firebaseUid: user.uid,
      email: user.email ?? '',
      firstName: data['prenom'],
      lastName: data['nom'],
      role: data['role']?.toString().toUpperCase() ?? 'USER',
      isAdmin: data['is_admin'] == true,
      isApproved: data['isApproved'] == true,
    );
  }

  static int _parseId(dynamic id) {
    if (id is int) return id;
    if (id is String) return int.tryParse(id) ?? 0;
    return 0;
  }

  String get fullName {
    final parts = [firstName, lastName].where((part) => part?.isNotEmpty ?? false);
    return parts.join(' ').trim();
  }

  String get displayName {
    if (fullName.isNotEmpty) return fullName;
    if (email.contains('@')) return email.split('@')[0];
    return email;
  }

  bool get isMedecin => role == 'MEDECIN';
  bool get isInfirmier => role == 'INFIRMIER';
  bool get isAdministratif => role == 'ADMINISTRATIF';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firebase_uid': firebaseUid,
      'email': email,
      'prenom': firstName,
      'nom': lastName,
      'role': role,
      'is_admin': isAdmin,
      'isApproved': isApproved,
    };
  }
}