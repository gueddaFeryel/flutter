enum CategorieMateriel {
  CHIRURGICAL,
  MEDICAL,
  DIAGNOSTIC,
  AUTRE
}

class Materiel {
  final int id;
  final String nom;
  final String description;
  final int quantiteDisponible;
  final CategorieMateriel categorie;

  Materiel({
    required this.id,
    required this.nom,
    required this.description,
    required this.quantiteDisponible,
    required this.categorie,
  });

  factory Materiel.fromJson(Map<String, dynamic> json) {
    return Materiel(
      id: json['id'] as int,
      nom: json['nom'] as String,
      description: json['description'] as String,
      quantiteDisponible: json['quantiteDisponible'] as int,
      categorie: _parseCategorie(json['categorie']),
    );
  }

  static CategorieMateriel _parseCategorie(String categorie) {
    switch (categorie) {
      case 'CHIRURGICAL':
        return CategorieMateriel.CHIRURGICAL;
      case 'MEDICAL':
        return CategorieMateriel.MEDICAL;
      case 'DIAGNOSTIC':
        return CategorieMateriel.DIAGNOSTIC;
      default:
        return CategorieMateriel.AUTRE;
    }
  }

  static String _categorieToString(CategorieMateriel categorie) {
    return categorie.toString().split('.').last;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'description': description,
      'quantiteDisponible': quantiteDisponible,
      'categorie': _categorieToString(categorie),
    };
  }

  @override
  String toString() {
    return 'Materiel{id: $id, nom: $nom, quantite: $quantiteDisponible}';
  }
}
