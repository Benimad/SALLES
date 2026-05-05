import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../models/demande.dart';
import '../../../models/user.dart';
import '../../../shared/services/firestore_service.dart';
import '../../../shared/services/firebase_auth_service.dart';
import '../../../shared/services/pdf_service.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/widgets/al_omrane_widgets.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  final _apiService = FirestoreService();
  final _authService = FirebaseAuthService();
  final _pdfService = PdfService();
  
  late TabController _tabController;
  List<Demande> _demandes = [];
  bool _isLoading = true;
  StreamSubscription<List<Demande>>? _demandesSubscription;
  
  int _pendingCount = 0;
  int _approvedCount = 0;
  int _rejectedCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _setupRealtimeListener();
  }

  @override
  void dispose() {
    _demandesSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _setupRealtimeListener() {
    _demandesSubscription = _apiService.watchDemandes(admin: true).listen(
      (demandes) {
        if (mounted) {
          setState(() {
            _demandes = demandes;
            _pendingCount = demandes.where((d) => d.statut == 'en_attente').length;
            _approvedCount = demandes.where((d) => d.statut == 'approuvee').length;
            _rejectedCount = demandes.where((d) => d.statut == 'rejetee').length;
            _isLoading = false;
          });
        }
      },
    );
  }

  Future<void> _updateStatus(String demandeId, String status, {String? reason}) async {
    final res = await _apiService.updateDemandeStatus(
      demandeId: demandeId,
      statut: status,
      raisonRejet: reason,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Statut mis à jour'),
          backgroundColor: res['success'] ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Console Admin', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        leading: const AlOmraneBackButton(),
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.fileDown),
            onPressed: () => _pdfService.generateDemandesListPdf(_demandes),
            tooltip: 'Exporter le rapport PDF',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatsHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDemandesList('en_attente'),
                _buildDemandesList('approuvee'),
                _buildDemandesList('rejetee'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(child: _MiniStat(label: 'Attente', value: _pendingCount, color: AppColors.warning)),
          const SizedBox(width: 12),
          Expanded(child: _MiniStat(label: 'Approuvées', value: _approvedCount, color: AppColors.success)),
          const SizedBox(width: 12),
          Expanded(child: _MiniStat(label: 'Rejetées', value: _rejectedCount, color: AppColors.error)),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: Colors.grey,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        tabs: const [
          Tab(text: 'EN ATTENTE'),
          Tab(text: 'APPROUVÉES'),
          Tab(text: 'REJETÉES'),
        ],
      ),
    );
  }

  Widget _buildDemandesList(String status) {
    final filtered = _demandes.where((d) => d.statut == status).toList();

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.inbox, size: 64, color: Colors.grey[200]),
            const SizedBox(height: 16),
            Text('Aucune demande', style: GoogleFonts.inter(color: Colors.grey[400])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final demande = filtered[index];
        return _AdminDemandeCard(
          demande: demande,
          onApprove: () => _updateStatus(demande.id, 'approuvee'),
          onReject: () => _showRejectDialog(demande.id),
          onDownload: () => _pdfService.generateDemandePdf(demande),
        );
      },
    );
  }

  void _showRejectDialog(String id) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Raison du rejet'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Motif du refus...'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              _updateStatus(id, 'rejetee', reason: ctrl.text);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Confirmer'),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _AdminDemandeCard extends StatelessWidget {
  final Demande demande;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onDownload;

  const _AdminDemandeCard({
    required this.demande,
    required this.onApprove,
    required this.onReject,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                        demande.salleName ?? 'Salle #${demande.salleId}',
                        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.download, color: AppColors.primary),
                      onPressed: onDownload,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Demandeur: ${demande.userName ?? 'N/A'}',
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _InfoChip(icon: LucideIcons.calendarDays, label: demande.dateDebut),
                    const SizedBox(width: 12),
                    _InfoChip(icon: LucideIcons.clock, label: '${demande.heureDebut} - ${demande.heureFin}'),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Motif:',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                Text(demande.motif, style: GoogleFonts.inter(fontSize: 14)),
              ],
            ),
          ),
          if (demande.statut == 'en_attente') ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: onReject,
                      icon: const Icon(LucideIcons.x, size: 18),
                      label: const Text('REJETER'),
                      style: TextButton.styleFrom(foregroundColor: AppColors.error),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onApprove,
                      icon: const Icon(LucideIcons.check, size: 18),
                      label: const Text('APPROUVER'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey[700])),
      ],
    );
  }
}
