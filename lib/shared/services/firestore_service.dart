import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../../models/salle.dart';
import '../../models/demande.dart';
import '../../core/constants/constants.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ===== SALLES =====
  Future<List<Salle>> getSalles() async {
    try {
      final snapshot = await _firestore
          .collection('salles')
          .where('disponible', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => Salle.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> addSalle(Map<String, dynamic> salleData) async {
    try {
      await _firestore.collection('salles').add({
        ...salleData,
        'disponible': true,
        'created_at': FieldValue.serverTimestamp(),
      });
      return {'success': true, 'message': 'Salle ajoutée'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  Future<Map<String, dynamic>> updateSalle(Salle salle) async {
    try {
      await _firestore
          .collection('salles')
          .doc(salle.id)
          .update(salle.toJson());
      return {'success': true, 'message': 'Salle modifiée'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteSalle(String salleId) async {
    try {
      await _firestore.collection('salles').doc(salleId).delete();
      return {'success': true, 'message': 'Salle supprimée'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  // ===== DEMANDES =====
  Future<Map<String, dynamic>> createDemande(Demande demande) async {
    try {
      final availability = await checkAvailability(
        demande.salleId,
        demande.dateDebut,
        demande.heureDebut,
        demande.heureFin,
        requestedSlots: demande.participantsExternes,
      );

      if (!availability['available']) {
        final slots = availability['slots'] ?? 0;
        return {
          'success': false,
          'message': 'Capacité insuffisante. $slots places restantes pour ce créneau.'
        };
      }

      final docRef = await _firestore.collection('demandes').add({
        ...demande.toJson(),
        'statut': AppConstants.statusPending,
        'created_at': FieldValue.serverTimestamp(),
      });

      return {'success': true, 'message': 'Demande créée', 'id': docRef.id};
    } catch (e) {
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  Future<List<Demande>> getDemandes({String? userId, bool admin = false}) async {
    try {
      Query query = _firestore.collection('demandes');

      if (!admin && userId != null) {
        query = query.where('user_id', isEqualTo: userId);
      }

      final snapshot = await query.get();

      final list = snapshot.docs
          .map((doc) => Demande.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id}))
          .toList();
      list.sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
      return list;
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> updateDemandeStatus({
    required String demandeId,
    required String statut,
    String? raisonRejet,
  }) async {
    try {
      final data = {
        'statut': statut,
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (raisonRejet != null) {
        data['raison_rejet'] = raisonRejet;
      }

      await _firestore.collection('demandes').doc(demandeId).update(data);

      return {'success': true, 'message': 'Statut mis à jour'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  Future<Map<String, dynamic>> checkAvailability(
    String salleId,
    String dateDebut,
    String heureDebut,
    String heureFin,
    {int requestedSlots = 1}
  ) async {
    try {
      // 1. Get Room Capacity
      final salleDoc = await _firestore.collection('salles').doc(salleId).get();
      if (!salleDoc.exists) return {'available': false, 'message': 'Salle introuvable', 'slots': 0};
      
      final capacity = int.tryParse(salleDoc.data()?['capacite']?.toString() ?? '0') ?? 0;

      // 2. Get all approved reservations for this room and date
      final snapshot = await _firestore
          .collection('demandes')
          .where('salle_id', isEqualTo: salleId)
          .where('date_debut', isEqualTo: dateDebut)
          .where('statut', isEqualTo: AppConstants.statusApproved)
          .get();

      int maxOverlappingParticipants = 0;

      // We need to check the occupancy at the specific requested time
      // A more robust way is to check all time points, but for a simple "slots" system,
      // we check how many participants are already booked for any interval overlapping with the requested one.
      
      int currentOccupancy = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final existingStart = data['heure_debut'];
        final existingEnd = data['heure_fin'];
        final participants = int.tryParse(data['participants_externes']?.toString() ?? '1') ?? 1;

        if (_timeOverlaps(heureDebut, heureFin, existingStart, existingEnd)) {
          currentOccupancy += participants;
        }
      }

      final remainingSlots = capacity - currentOccupancy;
      
      return {
        'available': remainingSlots >= requestedSlots,
        'slots': remainingSlots,
        'capacity': capacity,
        'current': currentOccupancy
      };
    } catch (e) {
      return {'available': false, 'message': 'Erreur: $e', 'slots': -1};
    }
  }

  bool _timeOverlaps(
      String start1, String end1, String start2, String end2) {
    return (start1.compareTo(end2) < 0 && end1.compareTo(start2) > 0);
  }

  // ===== STATISTICS =====
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final sallesCount = await _firestore.collection('salles').count().get();
      final demandesCount = await _firestore.collection('demandes').count().get();
      final pendingCount = await _firestore
          .collection('demandes')
          .where('statut', isEqualTo: AppConstants.statusPending)
          .count()
          .get();
      
      // Calculate live occupancy for right now
      final now = DateTime.now();
      final dateStr = DateFormat('yyyy-MM-dd').format(now);
      final timeStr = DateFormat('HH:mm').format(now);

      final activeDemandes = await _firestore
          .collection('demandes')
          .where('date_debut', isEqualTo: dateStr)
          .where('statut', isEqualTo: AppConstants.statusApproved)
          .get();

      int currentOccupancy = 0;
      for (final doc in activeDemandes.docs) {
        final data = doc.data();
        if (_isTimeWithin(timeStr, data['heure_debut'], data['heure_fin'])) {
          currentOccupancy += int.tryParse(data['participants_externes']?.toString() ?? '1') ?? 1;
        }
      }

      return {
        'total_salles': sallesCount.count,
        'total_demandes': demandesCount.count,
        'demandes_en_attente': pendingCount.count,
        'current_occupancy': currentOccupancy,
      };
    } catch (e) {
      return {};
    }
  }

  bool _isTimeWithin(String target, String start, String end) {
    return (target.compareTo(start) >= 0 && target.compareTo(end) <= 0);
  }

  // ===== REAL-TIME LISTENERS =====
  Stream<List<Demande>> watchDemandes({String? userId, bool admin = false}) {
    Query query = _firestore.collection('demandes');

    // Security: If not admin, force filter by current user UID if userId is missing
    if (!admin) {
      final effectiveUserId = userId ?? FirebaseAuth.instance.currentUser?.uid;
      if (effectiveUserId != null) {
        query = query.where('user_id', isEqualTo: effectiveUserId);
      } else {
        // Return empty stream if no user ID available to avoid permission error
        return Stream.value([]);
      }
    }

    return query.snapshots(includeMetadataChanges: true).map(
      (snapshot) {
        final list = snapshot.docs
            .map((doc) => Demande.fromJson(
                {...doc.data() as Map<String, dynamic>, 'id': doc.id}))
            .toList();
        
        // Better sorting: If we have multiple documents, we should try to use the raw created_at for sorting
        // but for now, we'll keep the client-side sort but use the document data if possible.
        try {
          list.sort((a, b) {
            if (a.createdAtDateTime == null) return 1;
            if (b.createdAtDateTime == null) return -1;
            return b.createdAtDateTime!.compareTo(a.createdAtDateTime!);
          });
        } catch (e) {
          debugPrint('Sort error: $e');
        }
        
        return list;
      },
    ).handleError((error) {
      debugPrint('Firestore Error in watchDemandes: $error');
    });
  }

  Stream<List<Demande>> watchApprovedDemandes() {
    return _firestore
        .collection('demandes')
        .where('statut', isEqualTo: AppConstants.statusApproved)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Demande.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id}))
              .toList(),
        );
  }

  Stream<List<Salle>> watchSalles() {
    return _firestore
        .collection('salles')
        .where('disponible', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Salle.fromJson({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }

  // Profile management
  Future<Map<String, dynamic>> updateProfile(
      String userId, String nom, String prenom, String? phone, String? department) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'nom': nom,
        'prenom': prenom,
        'phone': phone,
        'department': department,
        'updated_at': FieldValue.serverTimestamp(),
      });
      return {'success': true, 'message': 'Profil mis à jour'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  Future<Map<String, dynamic>> changePassword(String userId, String current, String next) async {
    // Note: Password changes are usually handled by Firebase Auth.
    // This is a stub to satisfy the UI controller.
    return {'success': false, 'message': 'Veuillez utiliser la fonction de récupération de mot de passe.'};
  }
}
