import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/widgets/al_omrane_widgets.dart';
import '../../../models/salle.dart';
import '../../../models/demande.dart';
import '../../../core/providers/salles_provider.dart';
import '../../../core/providers/demandes_provider.dart';
import '../../requests/presentation/create_demande_screen.dart';

class SallesScreen extends ConsumerStatefulWidget {
  const SallesScreen({super.key});

  @override
  ConsumerState<SallesScreen> createState() => _SallesScreenState();
}

class _SallesScreenState extends ConsumerState<SallesScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Availability Filter
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Salle> _applyFilters(List<Salle> salles) {
    String query = _searchController.text.toLowerCase();
    return salles.where((s) => 
      s.nom.toLowerCase().contains(query) || 
      s.equipements.toLowerCase().contains(query)
    ).toList();
  }

  int _calculateRemainingSlots(Salle salle, List<Demande> approvedDemandes) {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final startStr = '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}';
    final endStr = '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}';

    int occupancy = 0;
    for (var d in approvedDemandes) {
      if (d.salleId == salle.id && d.dateDebut == dateStr) {
        if (_timeOverlaps(startStr, endStr, d.heureDebut, d.heureFin)) {
          occupancy += d.participantsExternes;
        }
      }
    }
    return salle.capacite - occupancy;
  }

  bool _timeOverlaps(String start1, String end1, String start2, String end2) {
    return (start1.compareTo(end2) < 0 && end1.compareTo(start2) > 0);
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) _startTime = picked; else _endTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sallesAsync = ref.watch(sallesStreamProvider);
    final demandesAsync = ref.watch(approvedDemandesStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverHeader(),
          SliverToBoxAdapter(child: _buildAvailabilityFilter()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            sliver: sallesAsync.when(
              loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
              error: (_, __) => const SliverFillRemaining(child: Center(child: Text("Erreur de chargement"))),
              data: (salles) {
                final filtered = _applyFilters(salles);
                final approvedDemandes = demandesAsync.value ?? [];

                if (filtered.isEmpty) {
                  return SliverFillRemaining(child: _buildEmptyState());
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final salle = filtered[index];
                      final slots = _calculateRemainingSlots(salle, approvedDemandes);
                      return _SalleListItem(
                        salle: salle,
                        remainingSlots: slots,
                        onTap: () => Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (_) => CreateDemandeScreen(
                            salle: salle,
                            initialDate: _selectedDate,
                            initialStartTime: _startTime,
                            initialEndTime: _endTime,
                          ))
                        ),
                      );
                    },
                    childCount: filtered.length,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        title: Text('Réserver une salle', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        background: Container(
          decoration: const BoxDecoration(gradient: AppGradients.primaryGradient),
        ),
      ),
    );
  }

  Widget _buildAvailabilityFilter() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.calendarClock, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text('Disponibilité en temps réel', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.onSurface)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _FilterItem(
                  label: 'Date',
                  value: DateFormat('d MMM', 'fr_FR').format(_selectedDate),
                  icon: LucideIcons.calendarDays,
                  onTap: _selectDate,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FilterItem(
                  label: 'De',
                  value: _startTime.format(context),
                  icon: LucideIcons.clock,
                  onTap: () => _selectTime(true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FilterItem(
                  label: 'À',
                  value: _endTime.format(context),
                  icon: LucideIcons.clock,
                  onTap: () => _selectTime(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            onChanged: (v) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Rechercher par nom ou équipement...',
              hintStyle: GoogleFonts.inter(color: AppColors.outlineVariant),
              prefixIcon: const Icon(LucideIcons.search, size: 20, color: AppColors.onSurfaceVariant),
              filled: true,
              fillColor: AppColors.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.building, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('Aucune salle trouvée', style: GoogleFonts.inter(color: Colors.grey[500])),
        ],
      ),
    );
  }
}

class _FilterItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _FilterItem({required this.label, required this.value, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outlineVariant.withOpacity(0.6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(icon, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SalleListItem extends StatelessWidget {
  final Salle salle;
  final int remainingSlots;
  final VoidCallback onTap;

  const _SalleListItem({required this.salle, required this.remainingSlots, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isFull = remainingSlots <= 0;
    final bool isPartial = remainingSlots < salle.capacite && remainingSlots > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHighest,
              image: salle.imageUrl != null 
                ? DecorationImage(image: NetworkImage(salle.imageUrl!), fit: BoxFit.cover)
                : null,
            ),
            child: Stack(
              children: [
                if (salle.imageUrl == null) 
                  const Center(child: Icon(LucideIcons.image, size: 48, color: Colors.white)),
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isFull ? AppColors.error : (isPartial ? AppColors.warning : AppColors.success),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      isFull ? 'COMPLET' : (isPartial ? 'PARTIEL' : 'DISPONIBLE'),
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        salle.nom,
                        style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.onSurface, letterSpacing: -0.5),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isFull ? AppColors.errorContainer : AppColors.secondaryContainer,
                        borderRadius: BorderRadius.circular(12)
                      ),
                      child: Text(
                        isFull ? 'Saturé' : '$remainingSlots/${salle.capacite} SLOTS', 
                        style: GoogleFonts.inter(
                          fontSize: 11, 
                          fontWeight: FontWeight.w800, 
                          color: isFull ? AppColors.onErrorContainer : AppColors.onSecondaryContainer
                        )
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(LucideIcons.users, size: 16, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text('${salle.capacite} Pers. max', style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(width: 16),
                    Icon(LucideIcons.layers, size: 16, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text('Étage ${salle.etage ?? 0}', style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Équipements inclus',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 0.5),
                ),
                const SizedBox(height: 8),
                Text(salle.equipements, style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurface, height: 1.5)),
                const SizedBox(height: 24),
                PrimaryGradientButton(
                  label: isFull ? 'Salle saturée' : 'Réserver cette salle',
                  onPressed: isFull ? null : onTap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
