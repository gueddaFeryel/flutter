import 'document.dart';

class Patient {
  final int id;
  final String nom;
  final String prenom;
  final DateTime? dateNaissance;
  final String? telephone;
  final String? adresse;
  final List<Document>? documents;

  Patient({
    required this.id,
    required this.nom,
    required this.prenom,
    this.dateNaissance,
    this.telephone,
    this.adresse,
    this.documents,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'] as int,
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      dateNaissance: json['dateNaissance'] != null
          ? DateTime.parse(json['dateNaissance'])
          : null,
      telephone: json['telephone'],
      adresse: json['adresse'],
      documents: json['documents'] != null
          ? (json['documents'] as List)
              .map((e) => Document.fromJson(e))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'dateNaissance': dateNaissance?.toIso8601String(),
      'telephone': telephone,
      'adresse': adresse,
      'documents': documents?.map((e) => e.toJson()).toList(),
    };
  }
}
