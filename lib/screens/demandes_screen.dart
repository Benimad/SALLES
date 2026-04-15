import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import '../models/demande.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/pdf_service.dart';
import '../utils/theme.dart';
import '../widgets/al_omrane_widgets.dart';

class DemandesScreen extends StatefulWidget {
  const DemandesScreen({super.key});

  @override
  State<DemandesScreen> createState() => _DemandesScreenState();
}

class _DemandesScreenState extends State<DemandesScreen>
    with SingleTickerProviderStateMixin {
  final _apiService = ApiService();
  final _authService = AuthService();
  final _pdfService = PdfService();
  List<Demande> _demandes = [];
  List<Demande> _filteredDemandes = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _loadDemandes();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadDemandes() async {
    setState(() => _isLoading = true);
    final user = await _authService.getCurrentUser();
    if (user != null) {
      final demandes = await _apiService.getDemandes(userId: user.id);
      setState(() {
        _demandes = demandes;
        _applyFilter();
        _isLoading = false;
      });
      _animationController.forward();
    }
  }

  void _applyFilter() {
    setState(() {
      if (_selectedFilter == 'all') {
        _filteredDemandes = _demandes;
      } else {
        _filteredDemandes =
            _demandes.where((d) => d.statut == _selectedFilter).toList();
      }
    });
  }

  Color _getStatusColor(String statut) {
    switch (statut) {
      case 'approuvee':
        return AlOmraneTheme.statusAccepted;
      case 'rejetee':
        return AlOmraneTheme.statusRefused;
      default:
        return AlOmraneTheme.statusPending;
    }
  }

  IconData _getStatusIcon(String statut) {
    switch (statut) {
      case 'approuvee':
        return Icons.check_circle;
      case 'rejetee':
        return Icons.cancel;
      default:
        return Icons.schedule;
    }
  }

  String _getStatusText(String statut) {
    switch (statut) {
      case 'approuvee':
        return 'Approuvée';
      case 'rejetee':
        return 'Rejetée';
      default:
        return 'En attente';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 120,
              floating: true,
              pinned: true,
              elevation: 0,
              backgroundColor: AlOmraneTheme.navyBlue,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: AlOmraneTheme.primaryGradient,
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Mes demandes',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_demandes.length} demandes au total',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                if (_filteredDemandes.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                    onPressed: () =>
                        _pdfService.generateDemandesListPdf(_filteredDemandes),
                    tooltip: 'Exporter en PDF',
                  ),
              ],
            ),
            SliverToBoxAdapter(
              child: Container(
                height: 4,
                decoration: const BoxDecoration(
                  gradient: AlOmraneTheme.accentGradient,
                ),
              ),
            ),
          ];
        },
        body: Column(
          children: [
            // Filter chips
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('all', 'Toutes', Icons.filter_list),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                        'en_attente', 'En attente', Icons.schedule, Colors.orange),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                        'approuvee', 'Approuvées', Icons.check_circle, Colors.green),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                        'rejetee', 'Rejetées', Icons.cancel, Colors.red),
                  ],
                ),
              ),
            ),

            // List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredDemandes.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadDemandes,
                          color: AlOmraneTheme.navyBlue,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredDemandes.length,
                            itemBuilder: (context, index) {
                              final demande = _filteredDemandes[index];
                              return AnimatedBuilder(
                                animation: _animationController,
                                builder: (context, child) {
                                  final delay = index * 100;
                                  final animation =
                                      Tween<double>(begin: 0.0, end: 1.0).animate(
                                    CurvedAnimation(
                                      parent: _animationController,
                                      curve: Interval(
                                        delay / 1000,
                                        (delay + 400) / 1000,
                                        curve: Curves.easeOutCubic,
                                      ),
                                    ),
                                  );

                                  return Transform.translate(
                                    offset: Offset(0, 50 * (1 - animation.value)),
                                    child: Opacity(
                                      opacity: animation.value,
                                      child: _buildDemandeCard(demande),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon,
      [Color? color]) {
    final isSelected = _selectedFilter == value;
    final chipColor = color ?? AlOmraneTheme.navyBlue;

    return FilterChip(
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
          _applyFilter();
        });
      },
      backgroundColor: Colors.grey[100],
      selectedColor: chipColor.withOpacity(0.15),
      checkmarkColor: chipColor,
      side: isSelected ? BorderSide(color: chipColor) : BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? chipColor : Colors.grey[600]),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? chipColor : Colors.grey[700],
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inbox_outlined,
              size: 60,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _selectedFilter == 'all'
                ? 'Aucune demande'
                : 'Aucune demande ${_getStatusText(_selectedFilter).toLowerCase()}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedFilter == 'all'
                ? 'Créez votre première réservation!'
                : 'Essayez un autre filtre',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          if (_selectedFilter != 'all') ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedFilter = 'all';
                  _applyFilter();
                });
              },
              icon: const Icon(Icons.clear_all),
              label: const Text('Voir toutes les demandes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AlOmraneTheme.navyBlue,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDemandeCard(Demande demande) {
    final statusColor = _getStatusColor(demande.statut);
    final statusIcon = _getStatusIcon(demande.statut);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(statusIcon, color: statusColor, size: 28),
          ),
          title: Text(
            demande.salleName ?? 'Salle #${demande.salleId}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  DateFormat('dd/MM/yyyy')
                      .format(DateTime.parse(demande.dateDebut)),
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(width: 12),
                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  demande.heureDebut,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor, width: 1),
            ),
            child: Text(
              _getStatusText(demande.statut),
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date range
                  _buildDetailRow(
                    Icons.date_range,
                    'Du ${DateFormat('dd/MM/yyyy').format(DateTime.parse(demande.dateDebut))} au ${DateFormat('dd/MM/yyyy').format(DateTime.parse(demande.dateFin))}',
                  ),
                  const SizedBox(height: 12),
                  // Time range
                  _buildDetailRow(
                    Icons.access_time,
                    'De ${demande.heureDebut} à ${demande.heureFin}',
                  ),
                  const SizedBox(height: 12),
                  // Motif
                  _buildDetailRow(
                    Icons.description,
                    demande.motif,
                    isMultiline: true,
                  ),

                  if (demande.statut == 'approuvee') ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _pdfService.generateDemandePdf(demande),
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Télécharger le PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AlOmraneTheme.navyBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text,
      {bool isMultiline = false}) {
    return Row(
      crossAxisAlignment:
          isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AlOmraneTheme.navyBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AlOmraneTheme.navyBlue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
