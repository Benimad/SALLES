import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Demande {
  final String id;
  final String userId;
  final String salleId;
  final String dateDebut;
  final String dateFin;
  final String heureDebut;
  final String heureFin;
  final String motif;
  final String? description;
  final int participantsExternes;
  final String statut;
  final String? raisonRejet;
  final String? userName;
  final String? salleName;
  final String? createdAt;
  final DateTime? createdAtDateTime;

  Demande({
    required this.id,
    required this.userId,
    required this.salleId,
    required this.dateDebut,
    required this.dateFin,
    required this.heureDebut,
    required this.heureFin,
    required this.motif,
    this.description,
    this.participantsExternes = 0,
    required this.statut,
    this.raisonRejet,
    this.userName,
    this.salleName,
    this.createdAt,
    this.createdAtDateTime,
  });

  factory Demande.fromJson(Map<String, dynamic> json) {
    String formattedDate = '';
    if (json['created_at'] != null) {
      if (json['created_at'] is Timestamp) {
        final date = (json['created_at'] as Timestamp).toDate();
        formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(date);
      } else {
        formattedDate = json['created_at'].toString();
      }
    }

    return Demande(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      salleId: json['salle_id']?.toString() ?? '',
      dateDebut: json['date_debut'] ?? '',
      dateFin: json['date_fin'] ?? '',
      heureDebut: json['heure_debut'] ?? '',
      heureFin: json['heure_fin'] ?? '',
      motif: json['motif'] ?? '',
      description: json['description'],
      participantsExternes: int.tryParse(json['participants_externes']?.toString() ?? '0') ?? 0,
      statut: json['statut'] ?? 'en_attente',
      raisonRejet: json['raison_rejet'],
      userName: json['user_name'],
      salleName: json['salle_name'],
      createdAt: formattedDate,
      createdAtDateTime: json['created_at'] is Timestamp ? (json['created_at'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'salle_id': salleId,
      'date_debut': dateDebut,
      'date_fin': dateFin,
      'heure_debut': heureDebut,
      'heure_fin': heureFin,
      'motif': motif,
      'description': description,
      'participants_externes': participantsExternes,
      'statut': statut,
      'user_name': userName,
      'salle_name': salleName,
    };
  }
}
