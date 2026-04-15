import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';
import '../models/user.dart';
import '../models/demande.dart';
import '../utils/theme.dart';
import '../widgets/al_omrane_widgets.dart';
import 'salles_screen.dart';
import 'demandes_screen.dart';
import 'login_screen.dart';
import 'calendar_screen.dart';
import 'profile_screen.dart';

class HomeScreenWithWebSocket extends StatefulWidget {
  const HomeScreenWithWebSocket({super.key});

  @override
  State<HomeScreenWithWebSocket> createState() => _HomeScreenWithWebSocketState();
}

class _HomeScreenWithWebSocketState extends State<HomeScreenWithWebSocket> {
  final _authService = AuthService();
  final _apiService = ApiService();
  final _wsService = WebSocketService();
  
  User? _currentUser;
  List<Demande> _recentDemandes = [];
  bool _isLoading = true;
  int _notificationCount = 0;
  
  int _enAttente = 0;
  int _acceptees = 0;
  int _refusees = 0;

  @override
  void initState() {
    super.initState();
    _initializeWebSocket();
    _loadData();
  }

  Future<void> _initializeWebSocket() async {
    final userId = await _authService.getUserId();
    if (userId != null) {
      _wsService.connect(userId);
      
      // Écouter les messages WebSocket
      _wsService.stream.listen((data) {
        if (data['type'] == 'new_demande') {
          _handleNewDemande(data);
        } else if (data['type'] == 'demande_update') {
          _handleDemandeUpdate(data);
        }
      });
    }
  }

  void _handleNewDemande(Map<String, dynamic> data) {
    setState(() => _notificationCount++);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.notifications_active, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Nouvelle demande: ${data['data']['salle']}'),
            ),
          ],
        ),
        backgroundColor: AlOmraneTheme.navyBlue,
        action: SnackBarAction(
          label: 'Voir',
          textColor: Colors.white,
          onPressed: () => _loadData(),
        ),
      ),
    );
    
    _loadData();
  }

  void _handleDemandeUpdate(Map<String, dynamic> data) {
    final status = data['status'];
    final statusText = status == 'approuvee' ? 'approuvée' : 'rejetée';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Demande $statusText'),
        backgroundColor: status == 'approuvee' 
          ? AlOmraneTheme.statusAccepted 
          : AlOmraneTheme.statusRefused,
      ),
    );
    
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final user = await _authService.getCurrentUser();
    if (user != null) {
      final demandes = await _apiService.getDemandes(userId: user.id);
      
      setState(() {
        _currentUser = user;
        _recentDemandes = demandes.take(5).toList();
        _enAttente = demandes.where((d) => d.statut == 'en_attente').length;
        _acceptees = demandes.where((d) => d.statut == 'approuvee').length;
        _refusees = demandes.where((d) => d.statut == 'rejetee').length;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _wsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null || _isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            title: 'Bonjour, ${_currentUser!.prenom}',
            subtitle: _currentUser!.role == 'admin' ? 'Administrateur' : 'Employé',
            trailing: Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                  onPressed: () => setState(() => _notificationCount = 0),
                ),
                if (_notificationCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AlOmraneTheme.redAccent,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        '$_notificationCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const RedAccentBar(),
          
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Connection status indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _wsService.isConnected 
                          ? AlOmraneTheme.statusAccepted.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _wsService.isConnected 
                                ? AlOmraneTheme.statusAccepted 
                                : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _wsService.isConnected ? 'Connecté' : 'Déconnecté',
                            style: TextStyle(
                              fontSize: 12,
                              color: _wsService.isConnected 
                                ? AlOmraneTheme.statusAccepted 
                                : Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Statistics
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            title: 'En attente',
                            value: _enAttente.toString(),
                            icon: Icons.schedule,
                            color: AlOmraneTheme.statusPending,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            title: 'Acceptées',
                            value: _acceptees.toString(),
                            icon: Icons.check_circle,
                            color: AlOmraneTheme.statusAccepted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    StatCard(
                      title: 'Refusées',
                      value: _refusees.toString(),
                      icon: Icons.cancel,
                      color: AlOmraneTheme.statusRefused,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    const Text(
                      'Demandes récentes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AlOmraneTheme.darkNavy,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    if (_recentDemandes.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Aucune demande',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...(_recentDemandes.map((demande) => DemandeCard(
                        salleName: demande.salleName ?? 'Salle #${demande.salleId}',
                        date: DateFormat('dd/MM/yyyy').format(
                          DateTime.parse(demande.dateDebut),
                        ),
                        timeRange: '${demande.heureDebut} - ${demande.heureFin}',
                        status: demande.statut,
                        motif: demande.motif,
                      ))),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: AlOmraneTheme.navyBlue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.meeting_room),
            label: 'Salles',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SallesScreen()),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          }
        },
      ),
    );
  }
}
