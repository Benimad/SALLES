import 'package:flutter/material.dart';
import '../models/salle.dart';
import '../services/api_service.dart';
import '../utils/theme.dart';
import '../widgets/al_omrane_widgets.dart';

class ManageSallesScreen extends StatefulWidget {
  const ManageSallesScreen({super.key});

  @override
  State<ManageSallesScreen> createState() => _ManageSallesScreenState();
}

class _ManageSallesScreenState extends State<ManageSallesScreen> {
  final _apiService = ApiService();
  List<Salle> _salles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final s = await _apiService.getSalles();
    if (mounted) setState(() { _salles = s; _isLoading = false; });
  }

  void _showForm({Salle? salle}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SalleFormSheet(
        salle: salle,
        onSave: (s) async {
          Navigator.pop(context);
          final res = salle == null
              ? await _apiService.addSalle(s)
              : await _apiService.updateSalle(s);
          if (!mounted) return;
          if (res['success'] == true) {
            _load();
            _toast(salle == null ? 'Salle ajoutée' : 'Salle modifiée', AppColors.secondary);
          } else {
            _toast(res['message'] ?? 'Erreur', AppColors.error);
          }
        },
      ),
    );
  }

  Future<void> _delete(Salle s) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppColors.surfaceContainerLowest,
        title: const Text('Supprimer la salle',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
        content: Text(
          'Voulez-vous supprimer "${s.nom}" ? Cette action est irréversible.',
          style: const TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final res = await _apiService.deleteSalle(s.id);
    if (!mounted) return;
    if (res['success'] == true) {
      _load();
      _toast('Salle supprimée', AppColors.error);
    } else {
      _toast(res['message'] ?? 'Erreur', AppColors.error);
    }
  }

  void _toast(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
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
              expandedHeight: 120,
              backgroundColor: AppColors.navyBlue,
              leading: const SizedBox.shrink(),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                    ),
                    onPressed: () => _showForm(),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(gradient: AppGradients.navyGradient),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 60, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text('Gestion des salles',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.44)),
                          const SizedBox(height: 4),
                          Text(
                            '${_salles.length} salle${_salles.length != 1 ? 's' : ''}',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.7), fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: RedAccentBar()),

            _isLoading
                ? const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
                : _salles.isEmpty
                    ? SliverFillRemaining(
                        child: EmptyState(
                          icon: Icons.meeting_room_rounded,
                          title: 'Aucune salle',
                          subtitle: 'Appuyez sur + pour ajouter une salle.',
                          actionLabel: 'Ajouter une salle',
                          onAction: () => _showForm(),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _SalleManageCard(
                                salle: _salles[i],
                                onEdit: () => _showForm(salle: _salles[i]),
                                onDelete: () => _delete(_salles[i]),
                              ),
                            ),
                            childCount: _salles.length,
                          ),
                        ),
                      ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Ajouter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _SalleManageCard extends StatelessWidget {
  final Salle salle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SalleManageCard({required this.salle, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: salle.disponible
                        ? AppColors.secondaryContainer
                        : AppColors.errorContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.meeting_room_rounded,
                    size: 24,
                    color: salle.disponible
                        ? AppColors.onSecondaryContainer
                        : AppColors.onErrorContainer,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(salle.nom,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onSurface)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: salle.disponible
                                  ? AppColors.secondaryContainer
                                  : AppColors.errorContainer,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              salle.disponible ? 'DISPO' : 'INDISPO',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: salle.disponible
                                    ? AppColors.onSecondaryContainer
                                    : AppColors.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.group_rounded, size: 14, color: AppColors.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text('${salle.capacite} personnes',
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.onSurfaceVariant)),
                          if (salle.etage != null) ...[
                            const SizedBox(width: 12),
                            Icon(Icons.layers_rounded, size: 14, color: AppColors.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text('Étage ${salle.etage}',
                                style: const TextStyle(
                                    fontSize: 13, color: AppColors.onSurfaceVariant)),
                          ],
                        ],
                      ),
                      if (salle.equipements.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          salle.equipements,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.onSurfaceVariant),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_rounded, size: 16, color: AppColors.primary),
                    label: const Text('Modifier',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                Container(width: 1, height: 30, color: AppColors.outlineVariant.withOpacity(0.3)),
                Expanded(
                  child: TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.error),
                    label: const Text('Supprimer',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.error,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SalleFormSheet extends StatefulWidget {
  final Salle? salle;
  final Function(Salle) onSave;

  const _SalleFormSheet({this.salle, required this.onSave});

  @override
  State<_SalleFormSheet> createState() => _SalleFormSheetState();
}

class _SalleFormSheetState extends State<_SalleFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomCtrl;
  late TextEditingController _capaciteCtrl;
  late TextEditingController _etageCtrl;
  late TextEditingController _locCtrl;
  late TextEditingController _equipCtrl;
  late TextEditingController _descCtrl;
  late bool _disponible;

  @override
  void initState() {
    super.initState();
    final s = widget.salle;
    _nomCtrl = TextEditingController(text: s?.nom ?? '');
    _capaciteCtrl = TextEditingController(text: s?.capacite.toString() ?? '');
    _etageCtrl = TextEditingController(text: s?.etage?.toString() ?? '');
    _locCtrl = TextEditingController(text: s?.localisation ?? '');
    _equipCtrl = TextEditingController(text: s?.equipements ?? '');
    _descCtrl = TextEditingController(text: s?.description ?? '');
    _disponible = s?.disponible ?? true;
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _capaciteCtrl.dispose();
    _etageCtrl.dispose();
    _locCtrl.dispose();
    _equipCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final salle = Salle(
      id: widget.salle?.id ?? 0,
      nom: _nomCtrl.text.trim(),
      capacite: int.tryParse(_capaciteCtrl.text) ?? 10,
      etage: int.tryParse(_etageCtrl.text),
      localisation: _locCtrl.text.trim().isNotEmpty ? _locCtrl.text.trim() : null,
      equipements: _equipCtrl.text.trim(),
      disponible: _disponible,
      description: _descCtrl.text.trim().isNotEmpty ? _descCtrl.text.trim() : null,
    );
    widget.onSave(salle);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Row(
                children: [
                  Text(
                    widget.salle == null ? 'Nouvelle salle' : 'Modifier la salle',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _field(_nomCtrl, 'Nom de la salle *', required: true),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: _field(_capaciteCtrl, 'Capacité *', isNumber: true, required: true)),
                        const SizedBox(width: 12),
                        Expanded(child: _field(_etageCtrl, 'Étage', isNumber: true)),
                      ]),
                      const SizedBox(height: 12),
                      _field(_locCtrl, 'Localisation'),
                      const SizedBox(height: 12),
                      _field(_equipCtrl, 'Équipements (séparés par virgule)'),
                      const SizedBox(height: 12),
                      _field(_descCtrl, 'Description', maxLines: 3),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _disponible ? Icons.check_circle_rounded : Icons.cancel_rounded,
                              color: _disponible ? AppColors.secondary : AppColors.error,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _disponible ? 'Salle disponible' : 'Salle indisponible',
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.onSurface),
                              ),
                            ),
                            Switch(
                              value: _disponible,
                              activeColor: AppColors.secondary,
                              onChanged: (v) => setState(() => _disponible = v),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      PrimaryGradientButton(
                        label: widget.salle == null ? 'Ajouter la salle' : 'Enregistrer',
                        icon: widget.salle == null ? Icons.add_rounded : Icons.save_rounded,
                        onPressed: _save,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint,
      {bool required = false, bool isNumber = false, int maxLines = 1}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(fontSize: 14, color: AppColors.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14),
        filled: true,
        fillColor: AppColors.surfaceContainerHighest,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.primary.withOpacity(0.2), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null
          : null,
    );
  }
}
