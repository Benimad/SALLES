// === FILE: salles_screen.dart ===
import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../widgets/al_omrane_widgets.dart';
import '../services/api_service.dart';
import '../models/salle.dart';
import 'create_demande_screen.dart';

class SallesScreen extends StatefulWidget {
  const SallesScreen({super.key});

  @override
  State<SallesScreen> createState() => _SallesScreenState();
}

class _SallesScreenState extends State<SallesScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Salle> _salles = [];
  List<Salle> _filtered = [];
  bool _loading = true;
  String? _error;
  int? _capacityFilter;

  static const List<int?> _capacityOptions = [null, 10, 20, 30, 50, 100];

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final salles = await _api.getSalles();
      if (mounted) {
        setState(() {
          _salles = salles;
          _loading = false;
        });
        _applyFilters();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Impossible de charger les salles';
          _loading = false;
        });
      }
    }
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filtered = _salles.where((s) {
        final matchSearch = query.isEmpty ||
            s.nom.toLowerCase().contains(query) ||
            s.equipements.toLowerCase().contains(query);
        final matchCapacity =
            _capacityFilter == null || s.capacite >= _capacityFilter!;
        return matchSearch && matchCapacity;
      }).toList();
    });
  }

  void _showCapacityFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: Text(
                    'Capacité minimale',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
                ..._capacityOptions.map((cap) {
                  final label =
                      cap == null ? 'Toutes les salles' : '≥ $cap personnes';
                  final selected = _capacityFilter == cap;
                  return ListTile(
                    leading: Icon(
                      selected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      color: selected
                          ? AppColors.primary
                          : AppColors.onSurfaceVariant,
                    ),
                    title: Text(
                      label,
                      style: TextStyle(
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: selected
                            ? AppColors.primary
                            : AppColors.onSurface,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        _capacityFilter = cap;
                      });
                      _applyFilters();
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 140,
              floating: false,
              pinned: true,
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: AppColors.navyBlue,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: AppGradients.navyGradient,
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const AlOmraneLogo(size: 36),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Salles de réunion',
                                      style: TextStyle(
                                        color: AppColors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.44,
                                      ),
                                    ),
                                    Text(
                                      '${_salles.length} salle${_salles.length != 1 ? 's' : ''} disponible${_salles.length != 1 ? 's' : ''}',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                collapseMode: CollapseMode.parallax,
                title: const Text(
                  'Salles de réunion',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              ),
            ),
            SliverToBoxAdapter(
              child: const RedAccentBar(),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: AppShadows.card,
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.onSurface,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Rechercher une salle...',
                            hintStyle: TextStyle(
                              color: AppColors.onSurfaceVariant.withOpacity(0.6),
                              fontSize: 14,
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: AppColors.onSurfaceVariant,
                              size: 20,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close_rounded,
                                        size: 18,
                                        color: AppColors.onSurfaceVariant),
                                    onPressed: () {
                                      _searchController.clear();
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            filled: false,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _showCapacityFilter,
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: _capacityFilter != null
                              ? AppColors.primary
                              : AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: AppShadows.card,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.people_rounded,
                              size: 18,
                              color: _capacityFilter != null
                                  ? AppColors.white
                                  : AppColors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _capacityFilter != null
                                  ? '≥${_capacityFilter}p'
                                  : 'Capacité',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: _capacityFilter != null
                                    ? AppColors.white
                                    : AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_loading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (_error != null)
              SliverFillRemaining(
                child: EmptyState(
                  icon: Icons.wifi_off_rounded,
                  title: 'Erreur de chargement',
                  subtitle: _error!,
                  actionLabel: 'Réessayer',
                  onAction: _load,
                ),
              )
            else if (_filtered.isEmpty)
              SliverFillRemaining(
                child: EmptyState(
                  icon: Icons.meeting_room_rounded,
                  title: 'Aucune salle trouvée',
                  subtitle: _searchController.text.isNotEmpty
                      ? 'Aucune salle ne correspond à votre recherche'
                      : 'Il n\'y a pas de salles disponibles pour le moment',
                  actionLabel: _searchController.text.isNotEmpty
                      ? 'Effacer la recherche'
                      : null,
                  onAction: _searchController.text.isNotEmpty
                      ? () {
                          _searchController.clear();
                        }
                      : null,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final salle = _filtered[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _SalleCard(
                          salle: salle,
                          onReserver: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    CreateDemandeScreen(salle: salle),
                              ),
                            );
                          },
                        ),
                      );
                    },
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

class _SalleCard extends StatelessWidget {
  final Salle salle;
  final VoidCallback onReserver;

  const _SalleCard({required this.salle, required this.onReserver});

  List<String> get _equipementsList {
    return salle.equipements
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final equipements = _equipementsList;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows.card,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: salle.disponible
                    ? AppGradients.greenGradient
                    : LinearGradient(
                        colors: [
                          AppColors.outlineVariant,
                          AppColors.outlineVariant,
                        ],
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              salle.nom,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurface,
                                letterSpacing: -0.01,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondaryContainer,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.people_rounded,
                                        size: 13,
                                        color: AppColors.onSecondaryContainer,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${salle.capacite} personnes',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.onSecondaryContainer,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _AvailabilityChip(disponible: salle.disponible),
                    ],
                  ),
                  if (equipements.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: equipements.take(5).map((eq) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.outlineVariant,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            eq,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryGradientButton(
                      label: 'Réserver cette salle',
                      icon: Icons.add_rounded,
                      onPressed: salle.disponible ? onReserver : null,
                    ),
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

class _AvailabilityChip extends StatelessWidget {
  final bool disponible;
  const _AvailabilityChip({required this.disponible});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: disponible
            ? AppColors.secondaryContainer
            : AppColors.errorContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: disponible
                  ? AppColors.secondary
                  : AppColors.error,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            disponible ? 'Disponible' : 'Indisponible',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: disponible
                  ? AppColors.onSecondaryContainer
                  : AppColors.onErrorContainer,
            ),
          ),
        ],
      ),
    );
  }
}
