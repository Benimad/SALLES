import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/salle.dart';
import '../models/demande.dart';
import '../models/attachment.dart';
import '../utils/constants.dart';
import 'auth_service.dart';

class ApiService {
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${token ?? ''}',
    };
  }

  Future<List<Salle>> getSalles() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.getSalles),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return (data['salles'] as List)
              .map((json) => Salle.fromJson(json))
              .toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Phase 3 - CRUD Salles
  Future<Map<String, dynamic>> addSalle(Salle salle) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.addSalle),
        headers: await _getHeaders(),
        body: jsonEncode(salle.toJson()),
      );

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  Future<Map<String, dynamic>> updateSalle(Salle salle) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.updateSalle),
        headers: await _getHeaders(),
        body: jsonEncode(salle.toJson()),
      );

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteSalle(int salleId) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.deleteSalle),
        headers: await _getHeaders(),
        body: jsonEncode({'id': salleId}),
      );

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  Future<Map<String, dynamic>> createDemande(Demande demande) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.createDemande),
        headers: await _getHeaders(),
        body: jsonEncode(demande.toJson()),
      );

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  Future<List<Demande>> getDemandes({int? userId}) async {
    try {
      String url = ApiConstants.getDemandes;
      if (userId != null) {
        url += '?user_id=$userId';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return (data['demandes'] as List)
              .map((json) => Demande.fromJson(json))
              .toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> updateDemandeStatut(int demandeId, String statut) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.updateDemande),
        headers: await _getHeaders(),
        body: jsonEncode({'demande_id': demandeId, 'statut': statut}),
      );

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  Future<Map<String, dynamic>> updateDemandeStatutWithReason(
      int demandeId, String statut, String raison) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.updateDemande),
        headers: await _getHeaders(),
        body: jsonEncode({
          'demande_id': demandeId,
          'statut': statut,
          'raison_rejet': raison,
        }),
      );

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/get_statistics.php'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? {};
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, dynamic>> updateProfile(
      int userId, String nom, String prenom, String? phone, String? department) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/update_profile.php'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'user_id': userId,
          'nom': nom,
          'prenom': prenom,
          'phone': phone,
          'department': department,
        }),
      );
      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  Future<Map<String, dynamic>> changePassword(
      int userId, String currentPassword, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/change_password.php'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'user_id': userId,
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      );
      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  // Phase 3 - Pièces jointes
  Future<List<Attachment>> getAttachments(int demandeId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.getAttachments}?demande_id=$demandeId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return (data['attachments'] as List)
              .map((json) => Attachment.fromJson(json))
              .toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Phase 3 - Notifications
  Future<Map<String, dynamic>> updateFcmToken(int userId, String token) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.updateFcmToken),
        headers: await _getHeaders(),
        body: jsonEncode({'user_id': userId, 'fcm_token': token}),
      );

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  Future<Map<String, dynamic>> checkAvailability(int salleId, String dateDebut, String heureDebut, String heureFin) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.checkAvailability),
        headers: await _getHeaders(),
        body: jsonEncode({
          'salle_id': salleId,
          'date_debut': dateDebut,
          'heure_debut': heureDebut,
          'heure_fin': heureFin,
        }),
      );
      final data = jsonDecode(response.body);
      return data['data'] ?? {'available': false};
    } catch (e) {
      return {'available': false};
    }
  }
}
