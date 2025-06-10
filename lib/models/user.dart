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
  final String? image; // Nouveau champ pour l'URL de l'image
  final String? specialty;

  AppUser({
    required this.id,
    required this.firebaseUid,
    required this.email,
    this.firstName,
    this.lastName,
    required this.role,
    this.isAdmin = false,
    this.isApproved = false,
    this.image, // Initialisation optionnelle
     this.specialty, // Ajouté
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
      image: data['image'], // Récupération de l'URL de l'image depuis les données
        specialty: data['specialty'] as String?, // Ajouté
      
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
      'image': image, // Ajout de l'image dans la sérialisation
    };
  }

  // Méthode pour créer une copie avec des valeurs modifiées
  AppUser copyWith({
    int? id,
    String? firebaseUid,
    String? email,
    String? firstName,
    String? lastName,
    String? role,
    bool? isAdmin,
    bool? isApproved,
    String? image,
  }) {
    return AppUser(
      id: id ?? this.id,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role ?? this.role,
      isAdmin: isAdmin ?? this.isAdmin,
      isApproved: isApproved ?? this.isApproved,
      image: image ?? this.image,
    );
  }
}