import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/user.dart';
import '../../../models/demande.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/demandes_provider.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/widgets/al_omrane_widgets.dart';
import '../../auth/presentation/login_screen.dart';
import '../../rooms/presentation/salles_screen.dart';
import '../../requests/presentation/demandes_screen.dart';
import '../../admin/presentation/admin_dashboard.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../requests/presentation/calendar_screen.dart';
import '../../rooms/presentation/manage_salles_screen.dart';
import '../../../shared/services/notification_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;
  List<Demande> _previousDemandes = [];

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authStateProvider);
    final demandesAsync = ref.watch(demandesStreamProvider);

    // Listen for status changes to trigger notifications
    ref.listen<AsyncValue<List<Demande>>>(demandesStreamProvider, (previous, next) {
      if (next.hasValue && next.value != null) {
        final currentDemandes = next.value!;
        final user = ref.read(authStateProvider).value;
        
        if (_previousDemandes.isNotEmpty && user != null && user.role != 'admin') {
          for (var d in currentDemandes) {
            final oldD = _previousDemandes.firstWhere((element) => element.id == d.id, orElse: () => d);
            if (oldD.statut != d.statut && d.statut != 'en_attente') {
              NotificationService().showDemandeStatusNotification(
                title: 'Mise à jour de votre demande',
                body: 'Votre demande pour ${d.salleName} est désormais : ${d.statut.toUpperCase()}',
                status: d.statut,
              );
            }
          }
        }
        _previousDemandes = currentDemandes;
      }
    });

    if (userAsync.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final user = userAsync.value;
    final demandes = demandesAsync.value ?? [];
    
    final recentDemandes = demandes.take(5).toList();
    final enAttente = demandes.where((d) => d.statut == 'en_attente').length;
    final approuvees = demandes.where((d) => d.statut == 'approuvee').length;
    final rejetees = demandes.where((d) => d.statut == 'rejetee').length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildDashboard(user, demandes, enAttente, approuvees, rejetees, recentDemandes),
          const SallesScreen(),
          const DemandesScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildDashboard(User? user, List<Demande> demandes, int enAttente, int approuvees, int rejetees, List<Demande> recentDemandes) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(demandesStreamProvider);
      },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: GradientHeader(
                title: 'Bonjour, ${user?.prenom ?? ''}',
                subtitle: user?.role == 'admin' ? 'Espace Administrateur' : 'Espace Collaborateur',
                trailing: GestureDetector(
                  onTap: () {
                    setState(() => _selectedIndex = 3);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                    ),
                    child: const CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Stats Section
                  Text(
                    'Vue d\'ensemble',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'En attente',
                          value: enAttente.toString(),
                          icon: LucideIcons.clock,
                          color: AppColors.warning,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: StatCard(
                          title: 'Confirmées',
                          value: approuvees.toString(),
                          icon: LucideIcons.checkCircle2,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  StatCard(
                    title: 'Demandes Rejetées',
                    value: rejetees.toString(),
                    icon: LucideIcons.xCircle,
                    color: AppColors.error,
                  ),

                  const SizedBox(height: 32),

                  // Actions Section
                  Text(
                    'Actions rapides',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildActionsGrid(user),

                  const SizedBox(height: 32),

                  // Recent Demandes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Demandes récentes',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurface,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() => _selectedIndex = 2);
                        },
                        child: Text('Voir tout', style: GoogleFonts.inter(color: AppColors.primary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildRecentList(recentDemandes),
                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildActionsGrid(User? user) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _ActionCard(
          title: 'Réserver',
          icon: LucideIcons.plusSquare,
          color: AppColors.primary,
          onTap: () {
            setState(() => _selectedIndex = 1);
          },
        ),
        _ActionCard(
          title: 'Calendrier',
          icon: LucideIcons.calendarDays,
          color: AppColors.info,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CalendarScreen())),
        ),
        if (user?.role == 'admin') ...[
          _ActionCard(
            title: 'Dashboard',
            icon: LucideIcons.layoutDashboard,
            color: AppColors.success,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminDashboard())),
          ),
          _ActionCard(
            title: 'Gestion Salles',
            icon: LucideIcons.building2,
            color: Colors.blueGrey,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ManageSallesScreen())),
          ),
        ],
      ],
    );
  }

  Widget _buildRecentList(List<Demande> recentDemandes) {
    if (recentDemandes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(LucideIcons.inbox, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Aucune demande récente',
              style: GoogleFonts.inter(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return Column(
      children: recentDemandes.map((d) => DemandeCard(
        salleName: d.salleName ?? 'Salle #${d.salleId}',
        date: d.dateDebut,
        timeRange: '${d.heureDebut} - ${d.heureFin}',
        status: d.statut,
        motif: d.motif,
        onTap: () {
          // Open details or PDF
        },
      )).toList(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5)),
        ],
      ),
      child: BottomNavigationBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(LucideIcons.home), activeIcon: Icon(LucideIcons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.building2), activeIcon: Icon(LucideIcons.building2), label: 'Salles'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.listOrdered), activeIcon: Icon(LucideIcons.listOrdered), label: 'Demandes'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.user), activeIcon: Icon(LucideIcons.user), label: 'Profil'),
        ],
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
