class Document {
  final int id;
  final String nomFichier;
  final String typeMime;
  final int? taille;
  final String donnees; // Encodé en base64 côté backend
  final DateTime? dateCreation;

  Document({
    required this.id,
    required this.nomFichier,
    required this.typeMime,
    this.taille,
    required this.donnees,
    this.dateCreation,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'] as int,
      nomFichier: json['nomFichier'] ?? '',
      typeMime: json['typeMime'] ?? '',
      taille: json['taille'],
      donnees: json['donnees'] ?? '',
      dateCreation: json['dateCreation'] != null
          ? DateTime.parse(json['dateCreation'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nomFichier': nomFichier,
      'typeMime': typeMime,
      'taille': taille,
      'donnees': donnees,
      'dateCreation': dateCreation?.toIso8601String(),
    };
  }
}
