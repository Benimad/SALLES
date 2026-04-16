import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../models/demande.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';
import '../utils/theme.dart';
import '../widgets/al_omrane_widgets.dart';
import 'login_screen.dart';
import 'salles_screen.dart';
import 'demandes_screen.dart';
import 'admin_screen.dart';
import 'profile_screen.dart';
import 'manage_salles_screen.dart';
import 'statistics_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _apiService = ApiService();

  User? _user;
  List<Demande> _recentDemandes = [];
  bool _isLoading = true;
  int _enAttente = 0;
  int _approuvees = 0;
  int _rejetees = 0;
  int _pendingAdminCount = 0;

  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    WebSocketService().dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final user = await _authService.getCurrentUser();
    if (user == null) return;

    WebSocketService().connect(user.id.toString(), user.role);
    WebSocketService().stream.listen(_onWsMessage);

    final demandes = await _apiService.getDemandes(
      userId: user.role == 'employe' ? user.id : null,
    );

    if (mounted) {
      setState(() {
        _user = user;
        _recentDemandes = demandes.take(5).toList();
        _enAttente = demandes.where((d) => d.statut == 'en_attente').length;
        _approuvees = demandes.where((d) => d.statut == 'approuvee').length;
        _rejetees = demandes.where((d) => d.statut == 'rejetee').length;
        _pendingAdminCount = _enAttente;
        _isLoading = false;
      });
    }
  }

  void _onWsMessage(Map<String, dynamic> data) {
    if (!mounted) return;
    final type = data['type'] as String?;

    if (type == 'new_demande') {
      _loadData();
      _showToast(
        'Nouvelle demande reçue',
        Icons.notification_add_rounded,
        AppColors.secondary,
      );
    } else if (type == 'demande_update') {
      _loadData();
      final status = data['status'] as String?;
      _showToast(
        status == 'approuvee'
            ? 'Votre demande a été approuvée ✓'
            : 'Votre demande a été rejetée',
        status == 'approuvee'
            ? Icons.check_circle_rounded
            : Icons.cancel_rounded,
        status == 'approuvee' ? AppColors.secondary : AppColors.error,
      );
    }
  }

  void _showToast(String message, IconData icon, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 14)),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppColors.surfaceContainerLowest,
        title: const Text('Déconnexion',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface)),
        content: const Text(
            'Êtes-vous sûr de vouloir vous déconnecter?',
            style: TextStyle(
                fontSize: 14,
                color: AppColors.onSurfaceVariant,
                height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    }
  }

  bool get _isAdmin => _user?.role == 'admin';

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _user == null) {
      return const Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _navIndex == 0 && !_isAdmin
          ? FloatingActionButton.extended(
              onPressed: () async {
                final salles = await _apiService.getSalles();
                if (mounted && salles.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SallesScreen()),
                  );
                }
              },
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Réserver',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isAdmin) {
      switch (_navIndex) {
        case 0:
          return _buildDashboard();
        case 1:
          return const AdminScreen();
        case 2:
          return const ManageSallesScreen();
        case 3:
          return const StatisticsScreen();
        case 4:
          return const ProfileScreen();
      }
    } else {
      switch (_navIndex) {
        case 0:
          return _buildDashboard();
        case 1:
          return const SallesScreen();
        case 2:
          return const DemandesScreen();
        case 3:
          return const ProfileScreen();
      }
    }
    return _buildDashboard();
  }

  Widget _buildBottomNav() {
    if (_isAdmin) {
      return _BottomNav(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
        items: [
          _NavItem(Icons.home_rounded, Icons.home_outlined, 'Accueil'),
          _NavItem(Icons.inbox_rounded, Icons.inbox_outlined, 'Demandes',
              badge: _pendingAdminCount),
          _NavItem(Icons.meeting_room_rounded, Icons.meeting_room_outlined,
              'Salles'),
          _NavItem(
              Icons.bar_chart_rounded, Icons.bar_chart_outlined, 'Rapports'),
          _NavItem(Icons.person_rounded, Icons.person_outlined, 'Profil'),
        ],
      );
    }

    return _BottomNav(
      currentIndex: _navIndex,
      onTap: (i) => setState(() => _navIndex = i),
      items: [
        _NavItem(Icons.home_rounded, Icons.home_outlined, 'Accueil'),
        _NavItem(Icons.meeting_room_rounded, Icons.meeting_room_outlined,
            'Salles'),
        _NavItem(Icons.list_alt_rounded, Icons.list_alt_outlined,
            'Mes demandes'),
        _NavItem(Icons.person_rounded, Icons.person_outlined, 'Profil'),
      ],
    );
  }

  // ─── DASHBOARD ───────────────────────────────────────────────────────────
  Widget _buildDashboard() {
    final greeting = _getGreeting();
    final user = _user;

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      backgroundColor: AppColors.surfaceContainerLowest,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Hero header
          SliverToBoxAdapter(child: _buildHeroHeader(greeting, user)),

          // Red accent line
          const SliverToBoxAdapter(child: RedAccentBar()),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Stats section
                const SectionHeader(title: 'Aperçu'),
                const SizedBox(height: 16),
                _buildStatsGrid(),

                const SizedBox(height: 32),

                // Quick actions
                if (!_isAdmin) ...[
                  SectionHeader(
                    title: 'Actions rapides',
                    action: 'Voir les salles',
                    onAction: () => setState(() => _navIndex = 1),
                  ),
                  const SizedBox(height: 16),
                  _buildQuickActions(),
                  const SizedBox(height: 32),
                ],

                // Recent demandes
                SectionHeader(
                  title: _isAdmin ? 'Dernières demandes' : 'Mes demandes récentes',
                  action: 'Voir tout',
                  onAction: () =>
                      setState(() => _navIndex = _isAdmin ? 1 : 2),
                ),
                const SizedBox(height: 16),
                _buildRecentList(),

                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(String greeting, User? user) {
    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.navyGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.fullName ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.02 * 24,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isAdmin
                            ? AppColors.primary.withOpacity(0.3)
                            : Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _isAdmin ? 'ADMINISTRATEUR' : 'EMPLOYÉ',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Actions
              Column(
                children: [
                  IconButton(
                    onPressed: () => _logout(),
                    icon: const Icon(Icons.logout_rounded,
                        color: Colors.white70, size: 22),
                    tooltip: 'Déconnexion',
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const AlOmraneLogo(size: 28),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    if (_isAdmin) {
      return Row(
        children: [
          Expanded(
            child: StatCard(
              title: 'En attente',
              value: _enAttente.toString(),
              icon: Icons.schedule_rounded,
              color: AppColors.tertiary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatCard(
              title: 'Approuvées',
              value: _approuvees.toString(),
              icon: Icons.check_circle_rounded,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatCard(
              title: 'Rejetées',
              value: _rejetees.toString(),
              icon: Icons.cancel_rounded,
              color: AppColors.error,
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'En attente',
                value: _enAttente.toString(),
                icon: Icons.schedule_rounded,
                color: AppColors.tertiary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: 'Approuvées',
                value: _approuvees.toString(),
                icon: Icons.check_circle_rounded,
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StatCard(
          title: 'Rejetées',
          value: _rejetees.toString(),
          icon: Icons.cancel_rounded,
          color: AppColors.error,
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            icon: Icons.meeting_room_rounded,
            label: 'Réserver\nune salle',
            color: AppColors.primary,
            onTap: () => setState(() => _navIndex = 1),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.list_alt_rounded,
            label: 'Mes\ndemandes',
            color: AppColors.secondary,
            onTap: () => setState(() => _navIndex = 2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.person_rounded,
            label: 'Mon\nprofil',
            color: AppColors.navyBlue,
            onTap: () => setState(() => _navIndex = 3),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentList() {
    if (_recentDemandes.isEmpty) {
      return EmptyState(
        icon: Icons.inbox_outlined,
        title: _isAdmin ? 'Aucune demande' : 'Aucune réservation',
        subtitle: _isAdmin
            ? 'Les nouvelles demandes apparaîtront ici.'
            : 'Réservez votre première salle en appuyant sur le bouton ci-dessous.',
        actionLabel: _isAdmin ? null : 'Voir les salles',
        onAction: _isAdmin ? null : () => setState(() => _navIndex = 1),
      );
    }

    return Column(
      children: _recentDemandes.map((d) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DemandeCard(
            salleName: d.salleName ?? 'Salle #${d.salleId}',
            date: _formatDate(d.dateDebut),
            timeRange: '${d.heureDebut} – ${d.heureFin}',
            status: d.statut,
            motif: d.motif,
            onTap: () => setState(() => _navIndex = _isAdmin ? 1 : 2),
          ),
        );
      }).toList(),
    );
  }

  String _getGreeting() {
    final h = DateTime.now().hour;
    if (h < 5) return 'Bonne nuit';
    if (h < 12) return 'Bonjour';
    if (h < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }

  String _formatDate(String date) {
    try {
      final dt = DateTime.parse(date);
      return DateFormat('d MMM yyyy', 'fr_FR').format(dt);
    } catch (_) {
      return date;
    }
  }
}

// ─── QUICK ACTION CARD ───────────────────────────────────────────────────────
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── BOTTOM NAV ──────────────────────────────────────────────────────────────
class _NavItem {
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;
  final int badge;

  const _NavItem(this.activeIcon, this.inactiveIcon, this.label,
      {this.badge = 0});
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<_NavItem> items;

  const _BottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final item = items[i];
              final isActive = i == currentIndex;

              return GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primary.withOpacity(0.10)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      NotificationBadge(
                        count: item.badge,
                        child: Icon(
                          isActive ? item.activeIcon : item.inactiveIcon,
                          color: isActive
                              ? AppColors.primary
                              : AppColors.onSurfaceVariant,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isActive
                              ? AppColors.primary
                              : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
