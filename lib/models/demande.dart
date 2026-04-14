class Demande {
  final int id;
  final int userId;
  final int salleId;
  final String dateDebut;
  final String dateFin;
  final String heureDebut;
  final String heureFin;
  final String motif;
  final String statut;
  final String? userName;
  final String? salleName;

  Demande({
    required this.id,
    required this.userId,
    required this.salleId,
    required this.dateDebut,
    required this.dateFin,
    required this.heureDebut,
    required this.heureFin,
    required this.motif,
    required this.statut,
    this.userName,
    this.salleName,
  });

  factory Demande.fromJson(Map<String, dynamic> json) {
    return Demande(
      id: int.parse(json['id'].toString()),
      userId: int.parse(json['user_id'].toString()),
      salleId: int.parse(json['salle_id'].toString()),
      dateDebut: json['date_debut'] ?? '',
      dateFin: json['date_fin'] ?? '',
      heureDebut: json['heure_debut'] ?? '',
      heureFin: json['heure_fin'] ?? '',
      motif: json['motif'] ?? '',
      statut: json['statut'] ?? 'en_attente',
      userName: json['user_name'],
      salleName: json['salle_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'salle_id': salleId,
      'date_debut': dateDebut,
      'date_fin': dateFin,
      'heure_debut': heureDebut,
      'heure_fin': heureFin,
      'motif': motif,
      'statut': statut,
    };
  }
}
