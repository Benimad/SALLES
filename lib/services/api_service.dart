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
}
