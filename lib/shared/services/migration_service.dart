import 'package:cloud_firestore/cloud_firestore.dart';

class MigrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> migrateSalles() async {
    final List<Map<String, dynamic>> salles = [
      {
        "nom": "Salle de Réunion A",
        "capacite": 10,
        "etage": 1,
        "localisation": "Aile Ouest",
        "equipements": "Projecteur, Tableau blanc, Wifi, Climatisation",
        "disponible": true,
        "description": "Salle idéale pour réunions de petits groupes",
      },
      {
        "nom": "Salle de Conférence B",
        "capacite": 50,
        "etage": 2,
        "localisation": "Aile Est",
        "equipements": "Projecteur HD, Système audio, Wifi, Climatisation, Visioconférence",
        "disponible": true,
        "description": "Grande salle de conférence avec équipement complet",
      },
      {
        "nom": "Salle de Formation C",
        "capacite": 20,
        "etage": 3,
        "localisation": "Aile Nord",
        "equipements": "Ordinateurs, Projecteur, Wifi, Tableau blanc",
        "disponible": true,
        "description": "Salle informatique avec 15 postes de travail",
      },
      {
        "nom": "Salle de Réunion D",
        "capacite": 8,
        "etage": 1,
        "localisation": "Aile Sud",
        "equipements": "Écran TV, Wifi, Tableau blanc",
        "disponible": true,
        "description": "Salle intime pour réunions confidentielles",
      }
    ];

    final batch = _firestore.batch();
    final collection = _firestore.collection('salles');

    for (var salle in salles) {
      final docRef = collection.doc();
      batch.set(docRef, {
        ...salle,
        'created_at': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  Future<void> createAdminUser({
    required String email,
    required String nom,
    required String prenom,
    required String userId,
  }) async {
    await _firestore.collection('users').doc(userId).set({
      'email': email,
      'nom': nom,
      'prenom': prenom,
      'role': 'admin',
      'created_at': FieldValue.serverTimestamp(),
    });
  }
}
