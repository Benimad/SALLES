import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../models/user.dart';
import '../models/demande.dart';
import '../utils/theme.dart';
import '../widgets/al_omrane_widgets.dart';
import 'salles_screen.dart';
import 'demandes_screen.dart';
import 'admin_screen.dart';
import 'login_screen.dart';
import 'calendar_screen.dart';
import 'statistics_screen.dart';
import 'profile_screen.dart';
import 'manage_salles_screen.dart';

class NewHomeScreen extends StatefulWidget {
  const NewHomeScreen({super.key});

  @override
  State<NewHomeScreen> createState() => _NewHomeScreenState();
}

class _NewHomeScreenState extends State<NewHomeScreen> {
  final _authService = AuthService();
  final _apiService = ApiService();
  User? _currentUser;
  List<Demande> _recentDemandes = [];
  bool _isLoading = true;
  
  int _enAttente = 0;
  int _acceptees = 0;
  int _refusees = 0;

  @override
  void initState() {
    super.initState();
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

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AlOmraneTheme.redAccent,
            ),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
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
          // Header avec gradient
          GradientHeader(
            title: 'Bonjour, ${_currentUser!.prenom}',
            subtitle: _currentUser!.role == 'admin' ? 'Administrateur' : 'Employé',
            trailing: IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Colors.white),
              onPressed: () {
                // TODO: Navigate to notifications
              },
            ),
          ),
          const RedAccentBar(),
          
          // Contenu
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Statistiques
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
                    
                    // Actions rapides
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Actions rapides',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AlOmraneTheme.darkNavy,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    Row(
                      children: [
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.add_circle_outline,
                            label: 'Nouvelle\ndemande',
                            color: AlOmraneTheme.redAccent,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SallesScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.calendar_today,
                            label: 'Calendrier',
                            color: AlOmraneTheme.navyBlue,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CalendarScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.list_alt,
                            label: 'Mes\ndemandes',
                            color: AlOmraneTheme.statusPending,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const DemandesScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Demandes récentes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Demandes récentes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AlOmraneTheme.darkNavy,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const DemandesScreen(),
                              ),
                            );
                          },
                          child: const Text('Voir tout'),
                        ),
                      ],
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
      
      // Bottom Navigation
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

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AlOmraneTheme.cardShadow,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AlOmraneTheme.darkNavy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
