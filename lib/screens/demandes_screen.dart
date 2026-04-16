import 'package:flutter/material.dart';
import '../models/demande.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/websocket_service.dart';
import '../utils/theme.dart';
import '../widgets/al_omrane_widgets.dart';

class DemandesScreen extends StatefulWidget {
  const DemandesScreen({super.key});

  @override
  State<DemandesScreen> createState() => _DemandesScreenState();
}

class _DemandesScreenState extends State<DemandesScreen> {
  final _apiService = ApiService();
  final _authService = AuthService();

  List<Demande> _demandes = [];
  List<Demande> _filtered = [];
  bool _isLoading = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
    WebSocketService().stream.listen(_onWsMessage);
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final user = await _authService.getCurrentUser();
    final demandes = await _apiService.getDemandes(
      userId: user?.role == 'employe' ? user!.id : null,
    );
    if (mounted) {
      setState(() {
        _demandes = demandes;
        _applyFilter();
        _isLoading = false;
      });
    }
  }

  void _onWsMessage(Map<String, dynamic> data) {
    if (!mounted) return;
    if (data['type'] == 'demande_update') {
      _load();
    }
  }

  void _applyFilter() {
    setState(() {
      _filtered = _filter == 'all'
          ? _demandes
          : _demandes.where((d) => d.statut == _filter).toList();
    });
  }

  void _setFilter(String f) {
    _filter = f;
    _applyFilter();
  }

  void _showDetail(Demande d) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DemandeDetailSheet(demande: d),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = _demandes.where((d) => d.statut == 'en_attente').length;
    final approved = _demandes.where((d) => d.statut == 'approuvee').length;
    final rejected = _demandes.where((d) => d.statut == 'rejetee').length;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 140,
              backgroundColor: AppColors.navyBlue,
              leading: const SizedBox.shrink(),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration:
                      const BoxDecoration(gradient: AppGradients.navyGradient),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text('Mes demandes',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.48)),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _MiniStat(label: 'En attente', value: pending, color: AppColors.tertiaryContainer),
                              const SizedBox(width: 8),
                              _MiniStat(label: 'Approuvées', value: approved, color: AppColors.secondaryContainer),
                              const SizedBox(width: 8),
                              _MiniStat(label: 'Rejetées', value: rejected, color: AppColors.errorContainer),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: RedAccentBar()),

            // Filter chips
            SliverToBoxAdapter(
              child: Container(
                color: AppColors.surfaceContainerLowest,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(label: 'Toutes', value: 'all', current: _filter, count: _demandes.length, onTap: () => _setFilter('all')),
                      const SizedBox(width: 8),
                      _FilterChip(label: 'En attente', value: 'en_attente', current: _filter, count: pending, color: AppColors.tertiaryContainer, onTap: () => _setFilter('en_attente')),
                      const SizedBox(width: 8),
                      _FilterChip(label: 'Approuvées', value: 'approuvee', current: _filter, count: approved, color: AppColors.secondaryContainer, onTap: () => _setFilter('approuvee')),
                      const SizedBox(width: 8),
                      _FilterChip(label: 'Rejetées', value: 'rejetee', current: _filter, count: rejected, color: AppColors.errorContainer, onTap: () => _setFilter('rejetee')),
                    ],
                  ),
                ),
              ),
            ),

            _isLoading
                ? const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  )
                : _filtered.isEmpty
                    ? SliverFillRemaining(
                        child: EmptyState(
                          icon: Icons.inbox_rounded,
                          title: 'Aucune demande',
                          subtitle: _filter == 'all'
                              ? 'Vous n\'avez pas encore de demandes.'
                              : 'Aucune demande dans cette catégorie.',
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _DemandeCard(
                                demande: _filtered[i],
                                onTap: () => _showDetail(_filtered[i]),
                              ),
                            ),
                            childCount: _filtered.length,
                          ),
                        ),
                      ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _MiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.85),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$value $label',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.onSurface),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final String current;
  final int count;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.current,
    required this.count,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = value == current;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : (color ?? AppColors.surfaceContainerHighest),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.white : AppColors.onSurfaceVariant)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.white.withOpacity(0.25)
                    : AppColors.surfaceContainerLowest.withOpacity(0.8),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text('$count',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isActive ? Colors.white : AppColors.onSurfaceVariant)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DemandeCard extends StatelessWidget {
  final Demande demande;
  final VoidCallback onTap;

  const _DemandeCard({required this.demande, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 90,
              decoration: BoxDecoration(
                color: demande.statut == 'approuvee'
                    ? AppColors.secondary
                    : demande.statut == 'rejetee'
                        ? AppColors.error
                        : AppColors.tertiary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            demande.salleName ?? 'Salle #${demande.salleId}',
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurface),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusChip(status: demande.statut),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      demande.motif,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 13, color: AppColors.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          '${demande.dateDebut} · ${demande.heureDebut}–${demande.heureFin}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.chevron_right_rounded,
                  color: AppColors.onSurfaceVariant, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _DemandeDetailSheet extends StatelessWidget {
  final Demande demande;
  const _DemandeDetailSheet({required this.demande});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.all(20),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          demande.salleName ?? 'Salle #${demande.salleId}',
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                              letterSpacing: -0.4),
                        ),
                      ),
                      StatusChip(status: demande.statut),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _DetailRow(icon: Icons.subject_rounded, label: 'Motif', value: demande.motif),
                  if (demande.description != null && demande.description!.isNotEmpty)
                    _DetailRow(icon: Icons.notes_rounded, label: 'Description', value: demande.description!),
                  _DetailRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Période',
                    value: demande.dateDebut == demande.dateFin
                        ? demande.dateDebut
                        : '${demande.dateDebut} → ${demande.dateFin}',
                  ),
                  _DetailRow(
                    icon: Icons.schedule_rounded,
                    label: 'Horaire',
                    value: '${demande.heureDebut} → ${demande.heureFin}',
                  ),
                  if (demande.participantsExternes > 0)
                    _DetailRow(
                      icon: Icons.people_rounded,
                      label: 'Participants ext.',
                      value: '${demande.participantsExternes}',
                    ),
                  if (demande.createdAt != null)
                    _DetailRow(
                      icon: Icons.access_time_rounded,
                      label: 'Soumise le',
                      value: demande.createdAt!,
                    ),
                  if (demande.statut == 'rejetee' && demande.raisonRejet != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.errorContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_rounded,
                              size: 16, color: AppColors.onErrorContainer),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Raison du rejet',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.onErrorContainer)),
                                const SizedBox(height: 4),
                                Text(demande.raisonRejet!,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.onErrorContainer,
                                        height: 1.4)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SecondaryButton(
                    label: 'Fermer',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(label,
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
