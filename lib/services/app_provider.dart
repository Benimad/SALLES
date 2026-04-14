import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/salle.dart';
import '../models/demande.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class AppProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();

  User? _currentUser;
  List<Salle> _salles = [];
  List<Demande> _demandes = [];
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  List<Salle> get salles => _salles;
  List<Demande> get demandes => _demandes;
  bool get isLoading => _isLoading;

  Future<void> loadCurrentUser() async {
    _currentUser = await _authService.getCurrentUser();
    notifyListeners();
  }

  Future<void> loadSalles() async {
    _isLoading = true;
    notifyListeners();
    
    _salles = await _apiService.getSalles();
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadDemandes({int? userId}) async {
    _isLoading = true;
    notifyListeners();
    
    _demandes = await _apiService.getDemandes(userId: userId);
    
    _isLoading = false;
    notifyListeners();
  }

  List<Salle> searchSalles(String query) {
    if (query.isEmpty) return _salles;
    
    return _salles.where((salle) {
      return salle.nom.toLowerCase().contains(query.toLowerCase()) ||
             salle.equipements.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  List<Salle> filterSallesByCapacity(int minCapacity) {
    return _salles.where((salle) => salle.capacite >= minCapacity).toList();
  }

  List<Demande> getDemandesByStatus(String status) {
    return _demandes.where((demande) => demande.statut == status).toList();
  }

  int get totalDemandes => _demandes.length;
  int get demandesEnAttente => getDemandesByStatus('en_attente').length;
  int get demandesApprouvees => getDemandesByStatus('approuvee').length;
  int get demandesRejetees => getDemandesByStatus('rejetee').length;
}
