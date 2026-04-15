import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/demande.dart';
import '../services/api_service.dart';
import '../utils/theme.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  final _apiService = ApiService();
  List<Demande> _demandes = [];
  List<Demande> _filteredDemandes = [];
  bool _isLoading = true;
  String _selectedFilter = 'en_attente';

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _loadDemandes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      setState(() {
        switch (_tabController.index) {
          case 0:
            _selectedFilter = 'en_attente';
            break;
          case 1:
            _selectedFilter = 'approuvee';
            break;
          case 2:
            _selectedFilter = 'rejetee';
            break;
        }
        _applyFilter();
      });
    }
  }

  Future<void> _loadDemandes() async {
    setState(() => _isLoading = true);
    final demandes = await _apiService.getDemandes();
    setState(() {
      _demandes = demandes;
      _applyFilter();
      _isLoading = false;
    });
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

  Future<void> _updateStatut(int demandeId, String statut) async {
    final result = await _apiService.updateDemandeStatut(demandeId, statut);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                statut == 'approuvee' ? Icons.check_circle : Icons.cancel,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(result['message'] ?? 'Statut mis à jour')),
            ],
          ),
          backgroundColor: statut == 'approuvee'
              ? AlOmraneTheme.statusAccepted
              : AlOmraneTheme.statusRefused,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );

      if (result['success'] == true) {
        _loadDemandes();
      }
    }
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

  int _getCountByStatus(String statut) {
    return _demandes.where((d) => d.statut == statut).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 160,
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
                      padding: const EdgeInsets.fromLTRB(20, 60, 20, 60),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Administration',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_demandes.length} demandes à gérer',
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
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: AlOmraneTheme.redAccent,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: [
                  Tab(
                    icon: Badge(
                      label: Text(_getCountByStatus('en_attente').toString()),
                      isLabelVisible: _getCountByStatus('en_attente') > 0,
                      child: const Icon(Icons.schedule),
                    ),
                    text: 'En attente',
                  ),
                  Tab(
                    icon: Badge(
                      label: Text(_getCountByStatus('approuvee').toString()),
                      isLabelVisible: _getCountByStatus('approuvee') > 0,
                      child: const Icon(Icons.check_circle),
                    ),
                    text: 'Approuvées',
                  ),
                  Tab(
                    icon: Badge(
                      label: Text(_getCountByStatus('rejetee').toString()),
                      isLabelVisible: _getCountByStatus('rejetee') > 0,
                      child: const Icon(Icons.cancel),
                    ),
                    text: 'Rejetées',
                  ),
                ],
              ),
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
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildDemandeList('en_attente'),
            _buildDemandeList('approuvee'),
            _buildDemandeList('rejetee'),
          ],
        ),
      ),
    );
  }

  Widget _buildDemandeList(String filter) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredList =
        _demandes.where((d) => d.statut == filter).toList();

    if (filteredList.isEmpty) {
      return _buildEmptyState(filter);
    }

    return RefreshIndicator(
      onRefresh: _loadDemandes,
      color: AlOmraneTheme.navyBlue,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredList.length,
        itemBuilder: (context, index) {
          final demande = filteredList[index];
          return _buildDemandeCard(demande);
        },
      ),
    );
  }

  Widget _buildEmptyState(String filter) {
    final messages = {
      'en_attente': 'Aucune demande en attente',
      'approuvee': 'Aucune demande approuvée',
      'rejetee': 'Aucune demande rejetée',
    };

    final icons = {
      'en_attente': Icons.inbox,
      'approuvee': Icons.check_circle_outline,
      'rejetee': Icons.cancel_outlined,
    };

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              icons[filter],
              size: 48,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            messages[filter]!,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemandeCard(Demande demande) {
    final statusColor = _getStatusColor(demande.statut);
    final statusIcon = _getStatusIcon(demande.statut);
    final isPending = demande.statut == 'en_attente';

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
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.person, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      demande.userName ?? 'Utilisateur #${demande.userId}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd/MM/yyyy')
                        .format(DateTime.parse(demande.dateDebut)),
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    demande.heureDebut,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
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
                  _buildDetailRow(
                    Icons.date_range,
                    'Du ${DateFormat('dd/MM/yyyy').format(DateTime.parse(demande.dateDebut))} au ${DateFormat('dd/MM/yyyy').format(DateTime.parse(demande.dateFin))}',
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    Icons.access_time,
                    'De ${demande.heureDebut} à ${demande.heureFin}',
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    Icons.description,
                    'Motif: ${demande.motif}',
                    isMultiline: true,
                  ),

                  if (isPending) ...[
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _updateStatut(demande.id, 'approuvee'),
                            icon: const Icon(Icons.check),
                            label: const Text('Approuver'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AlOmraneTheme.statusAccepted,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _updateStatut(demande.id, 'rejetee'),
                            icon: const Icon(Icons.close),
                            label: const Text('Rejeter'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AlOmraneTheme.statusRefused,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
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
