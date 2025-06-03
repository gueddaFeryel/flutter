

enum StatutRapport { BROUILLON, SOUMIS, VALIDE }

class Rapport {
  final int id;
  final int interventionId;
  final String diagnostic;
  final String? complications;
  final String recommandations;
  final String? notesInfirmier;
  final int medecinId;
  final int? infirmierId;
  final StatutRapport statut;
  final DateTime dateCreation;
  final DateTime? dateSoumission;

  Rapport({
    required this.id,
    required this.interventionId,
    required this.diagnostic,
    this.complications,
    required this.recommandations,
    this.notesInfirmier,
    required this.medecinId,
    this.infirmierId,
    required this.statut,
    required this.dateCreation,
    this.dateSoumission,
  });

  // models/rapport.dart
factory Rapport.fromJson(Map<String, dynamic> json) {
  return Rapport(
    id: json['id'] as int? ?? 0, // Valeur par défaut si null
    interventionId: json['interventionId'] as int? ?? 0,
    diagnostic: json['diagnostic'] as String? ?? '',
    complications: json['complications'] as String?,
    recommandations: json['recommandations'] as String? ?? '',
    notesInfirmier: json['notesInfirmier'] as String?,
    medecinId: json['medecinId'] as int? ?? 0,
    infirmierId: json['infirmierId'] as int?,
    statut: StatutRapport.values.firstWhere(
      (e) => e.toString().split('.').last == (json['statut'] as String? ?? 'BROUILLON'),
      orElse: () => StatutRapport.BROUILLON,
    ),
    dateCreation: DateTime.parse(json['dateCreation'] as String? ?? DateTime.now().toIso8601String()),
    dateSoumission: json['dateSoumission'] != null 
        ? DateTime.parse(json['dateSoumission'] as String)
        : null,
  );
}
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'interventionId': interventionId,
      'diagnostic': diagnostic,
      'complications': complications,
      'recommandations': recommandations,
      'notesInfirmier': notesInfirmier,
      'medecinId': medecinId,
      'infirmierId': infirmierId,
      'statut': statut.toString().split('.').last,
      'dateCreation': dateCreation.toIso8601String(),
      'dateSoumission': dateSoumission?.toIso8601String(),
    };
  }

  bool get isEditable {
    return statut == StatutRapport.BROUILLON &&
        dateCreation.add(const Duration(hours: 24)).isAfter(DateTime.now());
  }
   bool get canMedecinEdit {
    return statut == StatutRapport.BROUILLON &&
        dateCreation.add(Duration(hours: 24)).isAfter(DateTime.now());
  }

  bool get canInfirmierEdit {
    return statut == StatutRapport.BROUILLON;
  }
}