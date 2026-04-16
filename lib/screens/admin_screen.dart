import 'package:flutter/material.dart';
import '../models/demande.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';
import '../utils/theme.dart';
import '../widgets/al_omrane_widgets.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  final _apiService = ApiService();
  late TabController _tabCtrl;

  List<Demande> _all = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _load();
    WebSocketService().stream.listen(_onWsMessage);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final demandes = await _apiService.getDemandes();
    if (mounted) {
      setState(() {
        _all = demandes;
        _isLoading = false;
      });
    }
  }

  void _onWsMessage(Map<String, dynamic> data) {
    if (!mounted) return;
    if (data['type'] == 'new_demande') {
      _load();
      _showToast('Nouvelle demande reçue', Icons.notification_add_rounded, AppColors.secondary);
    }
  }

  void _showToast(String msg, IconData icon, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(msg, style: const TextStyle(fontSize: 14))),
        ]),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  List<Demande> get _pending => _all.where((d) => d.statut == 'en_attente').toList();
  List<Demande> get _approved => _all.where((d) => d.statut == 'approuvee').toList();
  List<Demande> get _rejected => _all.where((d) => d.statut == 'rejetee').toList();

  Future<void> _approve(Demande d) async {
    final res = await _apiService.updateDemandeStatut(d.id, 'approuvee');
    if (res['success'] == true) {
      WebSocketService().sendDemandeUpdate(d.id.toString(), 'approuvee', d.userId.toString());
      _load();
      _showToast('Demande approuvée', Icons.check_circle_rounded, AppColors.secondary);
    }
  }

  Future<void> _reject(Demande d) async {
    final reason = await _showRejectDialog();
    if (reason == null) return;
    final res = await _apiService.updateDemandeStatutWithReason(d.id, 'rejetee', reason);
    if (res['success'] == true) {
      WebSocketService().sendDemandeUpdate(d.id.toString(), 'rejetee', d.userId.toString());
      _load();
      _showToast('Demande rejetée', Icons.cancel_rounded, AppColors.error);
    }
  }

  Future<String?> _showRejectDialog() async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppColors.surfaceContainerLowest,
        title: const Text('Raison du rejet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.onSurface)),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          style: const TextStyle(fontSize: 14, color: AppColors.onSurface),
          decoration: InputDecoration(
            hintText: 'Précisez la raison...',
            hintStyle: const TextStyle(color: AppColors.onSurfaceVariant),
            filled: true,
            fillColor: AppColors.surfaceContainerHighest,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Rejeter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: 160,
            backgroundColor: AppColors.navyBlue,
            leading: const SizedBox.shrink(),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: AppGradients.navyGradient),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text('Gestion des demandes',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.44)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _AdminStat(value: _pending.length, label: 'En attente', color: AppColors.tertiaryContainer),
                            const SizedBox(width: 10),
                            _AdminStat(value: _approved.length, label: 'Approuvées', color: AppColors.secondaryContainer),
                            const SizedBox(width: 10),
                            _AdminStat(value: _rejected.length, label: 'Rejetées', color: AppColors.errorContainer),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(52),
              child: Column(
                children: [
                  const RedAccentBar(),
                  TabBar(
                    controller: _tabCtrl,
                    indicatorColor: Colors.white,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white54,
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                    tabs: [
                      Tab(text: 'En attente (${_pending.length})'),
                      Tab(text: 'Approuvées'),
                      Tab(text: 'Rejetées'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : TabBarView(
                controller: _tabCtrl,
                children: [
                  _DemandeList(
                    demandes: _pending,
                    showActions: true,
                    onApprove: _approve,
                    onReject: _reject,
                    onRefresh: _load,
                  ),
                  _DemandeList(
                    demandes: _approved,
                    showActions: false,
                    onRefresh: _load,
                  ),
                  _DemandeList(
                    demandes: _rejected,
                    showActions: false,
                    onRefresh: _load,
                  ),
                ],
              ),
      ),
    );
  }
}

class _AdminStat extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  const _AdminStat({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$value',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.onSurface)),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(fontSize: 11, color: AppColors.onSurface)),
        ],
      ),
    );
  }
}

class _DemandeList extends StatelessWidget {
  final List<Demande> demandes;
  final bool showActions;
  final Future<void> Function(Demande)? onApprove;
  final Future<void> Function(Demande)? onReject;
  final Future<void> Function() onRefresh;

  const _DemandeList({
    required this.demandes,
    required this.showActions,
    this.onApprove,
    this.onReject,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (demandes.isEmpty) {
      return EmptyState(
        icon: showActions ? Icons.check_circle_outline_rounded : Icons.inbox_rounded,
        title: 'Aucune demande',
        subtitle: showActions ? 'Toutes les demandes ont été traitées.' : 'Aucun élément ici.',
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: demandes.length,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _AdminDemandeCard(
            demande: demandes[i],
            showActions: showActions,
            onApprove: onApprove,
            onReject: onReject,
          ),
        ),
      ),
    );
  }
}

class _AdminDemandeCard extends StatefulWidget {
  final Demande demande;
  final bool showActions;
  final Future<void> Function(Demande)? onApprove;
  final Future<void> Function(Demande)? onReject;

  const _AdminDemandeCard({
    required this.demande,
    required this.showActions,
    this.onApprove,
    this.onReject,
  });

  @override
  State<_AdminDemandeCard> createState() => _AdminDemandeCardState();
}

class _AdminDemandeCardState extends State<_AdminDemandeCard> {
  bool _isActing = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.demande;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.userName ?? 'Utilisateur #${d.userId}',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface)),
                      const SizedBox(height: 2),
                      Text(d.salleName ?? 'Salle #${d.salleId}',
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                ),
                if (!widget.showActions) StatusChip(status: d.statut),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow(Icons.subject_rounded, d.motif),
                const SizedBox(height: 6),
                _infoRow(Icons.calendar_today_rounded, '${d.dateDebut} · ${d.heureDebut}–${d.heureFin}'),
                if (d.participantsExternes > 0) ...[
                  const SizedBox(height: 4),
                  _infoRow(Icons.people_rounded, '${d.participantsExternes} participant(s) externe(s)'),
                ],
              ],
            ),
          ),
          if (widget.showActions) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isActing
                          ? null
                          : () async {
                              setState(() => _isActing = true);
                              await widget.onReject?.call(d);
                              if (mounted) setState(() => _isActing = false);
                            },
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: const Text('Rejeter'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isActing
                          ? null
                          : () async {
                              setState(() => _isActing = true);
                              await widget.onApprove?.call(d);
                              if (mounted) setState(() => _isActing = false);
                            },
                      icon: _isActing
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check_rounded, size: 16),
                      label: const Text('Approuver'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else
            const SizedBox(height: 14),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
