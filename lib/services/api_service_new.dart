import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/salle.dart';
import '../models/demande.dart';
import '../models/attachment.dart';
import '../models/user.dart';
import '../utils/constants.dart';
import 'auth_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  late Dio _dio;
  final AuthService _authService = AuthService();

  ApiService._internal() {
    _initializeDio();
  }

  factory ApiService() {
    return _instance;
  }

  void _initializeDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: Duration(milliseconds: ApiConstants.connectTimeout),
        receiveTimeout: Duration(milliseconds: ApiConstants.receiveTimeout),
        contentType: 'application/json',
        responseType: ResponseType.json,
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _authService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          debugPrint('API Request: ${options.method} ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint('API Response: ${response.statusCode} ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (error, handler) {
          debugPrint('API Error: ${error.message}');
          return handler.next(error);
        },
      ),
    );
  }

  // ===== AUTHENTICATION =====
  Future<Map<String, dynamic>> login(String email, String password, {String? fcmToken}) async {
    try {
      final response = await _dio.post(
        '/login.php',
        data: {
          'email': email,
          'password': password,
          'fcm_token': fcmToken,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data;
      }
      return {
        'success': false,
        'message': response.data['message'] ?? 'Erreur de connexion',
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _getErrorMessage(e),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur: $e',
      };
    }
  }

  Future<Map<String, dynamic>> register(String nom, String prenom, String email, String password) async {
    try {
      final response = await _dio.post(
        '/register.php',
        data: {
          'nom': nom,
          'prenom': prenom,
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data;
      }
      return {
        'success': false,
        'message': response.data['message'] ?? 'Erreur d\'inscription',
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _getErrorMessage(e),
      };
    }
  }

  Future<User?> getUser(int userId) async {
    try {
      final response = await _dio.get(
        '/get_user.php',
        queryParameters: {'id': userId},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return User.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user: $e');
      return null;
    }
  }

  Future<bool> updateFcmToken(int userId, String token) async {
    try {
      final response = await _dio.post(
        '/update_fcm_token.php',
        data: {
          'user_id': userId,
          'fcm_token': token,
        },
      );

      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
      return false;
    }
  }

  // ===== ROOM (SALLE) OPERATIONS =====
  Future<List<Salle>> getSalles({String? date}) async {
    try {
      final response = await _dio.get(
        '/get_salles.php',
        queryParameters: {
          if (date != null) 'date': date,
          'sort': 'nom',
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return (response.data['data'] as List)
            .map((json) => Salle.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting salles: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> checkAvailability(
    int salleId,
    String dateDebut,
    String heureDebut,
    String heureFin,
  ) async {
    try {
      final response = await _dio.post(
        '/check_availability.php',
        data: {
          'salle_id': salleId,
          'date_debut': dateDebut,
          'heure_debut': heureDebut,
          'heure_fin': heureFin,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }
      return {'available': false, 'conflicts': -1};
    } catch (e) {
      debugPrint('Error checking availability: $e');
      return {'available': false, 'conflicts': -1};
    }
  }

  Future<Map<String, dynamic>> addSalle({
    required String nom,
    required int capacite,
    String? etage,
    String? localisation,
    String? equipements,
    String? description,
    String? contactResponsable,
  }) async {
    try {
      final response = await _dio.post(
        '/add_salle.php',
        data: {
          'nom': nom,
          'capacite': capacite,
          'etage': etage,
          'localisation': localisation,
          'equipements': equipements,
          'description': description,
          'contact_responsable': contactResponsable,
        },
      );

      return response.data;
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _getErrorMessage(e),
      };
    }
  }

  Future<Map<String, dynamic>> updateSalle({
    required int id,
    required String nom,
    required int capacite,
    String? etage,
    String? localisation,
    String? equipements,
    String? description,
    String? contactResponsable,
  }) async {
    try {
      final response = await _dio.post(
        '/update_salle.php',
        data: {
          'id': id,
          'nom': nom,
          'capacite': capacite,
          'etage': etage,
          'localisation': localisation,
          'equipements': equipements,
          'description': description,
          'contact_responsable': contactResponsable,
        },
      );

      return response.data;
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _getErrorMessage(e),
      };
    }
  }

  Future<Map<String, dynamic>> deleteSalle(int salleId) async {
    try {
      final response = await _dio.post(
        '/delete_salle.php',
        data: {'id': salleId},
      );

      return response.data;
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _getErrorMessage(e),
      };
    }
  }

  // ===== BOOKING (DEMANDE) OPERATIONS =====
  Future<Map<String, dynamic>> createDemande({
    required int userId,
    required int salleId,
    required String dateDebut,
    required String dateFin,
    required String heureDebut,
    required String heureFin,
    required String motif,
    String? description,
  }) async {
    try {
      final response = await _dio.post(
        '/create_demande.php',
        data: {
          'user_id': userId,
          'salle_id': salleId,
          'date_debut': dateDebut,
          'date_fin': dateFin,
          'heure_debut': heureDebut,
          'heure_fin': heureFin,
          'motif': motif,
          'description': description,
        },
      );

      return response.data;
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _getErrorMessage(e),
      };
    }
  }

  Future<List<Demande>> getDemandes({
    int? userId,
    String? status,
    int limit = 50,
    int offset = 0,
    bool admin = false,
  }) async {
    try {
      final response = await _dio.get(
        '/get_demandes.php',
        queryParameters: {
          if (userId != null) 'user_id': userId,
          if (status != null) 'status': status,
          'limit': limit,
          'offset': offset,
          if (admin) 'admin': '1',
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return (response.data['data'] as List)
            .map((json) => Demande.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting demandes: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> updateDemandeStatus({
    required int demandeId,
    required String statut,
    String? raisonRejet,
    int? approveParId,
  }) async {
    try {
      final response = await _dio.post(
        '/update_demande.php',
        data: {
          'demande_id': demandeId,
          'statut': statut,
          'raison_rejet': raisonRejet,
          'approuve_par': approveParId,
        },
      );

      return response.data;
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _getErrorMessage(e),
      };
    }
  }

  // ===== FILE ATTACHMENTS =====
  Future<List<Attachment>> getAttachments(int demandeId) async {
    try {
      final response = await _dio.get(
        '/get_attachments.php',
        queryParameters: {'demande_id': demandeId},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return (response.data['data'] as List)
            .map((json) => Attachment.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting attachments: $e');
      return [];
    }
  }

  // ===== HELPER METHODS =====
  String _getErrorMessage(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Délai de connexion dépassé';
      case DioExceptionType.receiveTimeout:
        return 'Délai de réception dépassé';
      case DioExceptionType.badResponse:
        if (error.response?.statusCode == 401) {
          return 'Non autorisé - Veuillez vous reconnecter';
        } else if (error.response?.statusCode == 422) {
          return 'Données invalides';
        } else if (error.response?.statusCode == 500) {
          return 'Erreur serveur';
        }
        return error.response?.data['message'] ?? 'Erreur serveur';
      case DioExceptionType.unknown:
        return 'Erreur de connexion';
      default:
        return 'Une erreur est survenue';
    }
  }
}
