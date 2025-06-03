class MedicalStaff {
  final int id;
  final String? firebaseUid;
  final String firstName;
  final String lastName;
  final String email;
  final String role;
  final String? phone;
  final bool isAdmin;
  final String? specialty; // Ajouté

  MedicalStaff({
    required this.id,
    this.firebaseUid,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    this.phone,
    this.isAdmin = false,
    this.specialty, // Ajouté
  });

  factory MedicalStaff.fromJson(Map<String, dynamic> json) {
    return MedicalStaff(
      id: json['id'] as int,
      firebaseUid: json['firebaseUid'] as String?,
      firstName: json['prenom'] as String,
      lastName: json['nom'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      phone: json['telephone'] as String?,
      isAdmin: json['isAdmin'] ?? false,
      specialty: json['specialty'] as String?, // Ajouté
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firebaseUid': firebaseUid,
      'prenom': firstName,
      'nom': lastName,
      'email': email,
      'role': role,
      'telephone': phone,
      'isAdmin': isAdmin,
    };
  }

  String get fullName => '$firstName $lastName';
}