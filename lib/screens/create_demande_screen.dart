// === FILE: create_demande_screen.dart ===
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/theme.dart';
import '../widgets/al_omrane_widgets.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/websocket_service.dart';
import '../models/salle.dart';
import '../models/demande.dart';

class CreateDemandeScreen extends StatefulWidget {
  final Salle salle;

  const CreateDemandeScreen({super.key, required this.salle});

  @override
  State<CreateDemandeScreen> createState() => _CreateDemandeScreenState();
}

class _CreateDemandeScreenState extends State<CreateDemandeScreen> {
  final ApiService _api = ApiService();
  final AuthService _auth = AuthService();
  final WebSocketService _ws = WebSocketService();

  int _currentStep = 0;

  DateTime? _dateDebut;
  DateTime? _dateFin;
  TimeOfDay? _heureDebut;
  TimeOfDay? _heureFin;

  final TextEditingController _motifController = TextEditingController();
  final _motifFormKey = GlobalKey<FormState>();

  bool _checkingAvailability = false;
  bool _submitting = false;
  String? _availabilityError;

  @override
  void dispose() {
    _motifController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) => DateFormat('dd/MM/yyyy').format(dt);
  String _formatDateApi(DateTime dt) => DateFormat('yyyy-MM-dd').format(dt);
  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';
  String _formatTimeDisplay(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}h${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickDateDebut() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateDebut ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: _datePickerTheme,
    );
    if (picked != null) {
      setState(() {
        _dateDebut = picked;
        if (_dateFin != null && _dateFin!.isBefore(picked)) {
          _dateFin = picked;
        }
      });
    }
  }

  Future<void> _pickDateFin() async {
    if (_dateDebut == null) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateFin ?? _dateDebut!,
      firstDate: _dateDebut!,
      lastDate: _dateDebut!.add(const Duration(days: 30)),
      builder: _datePickerTheme,
    );
    if (picked != null) {
      setState(() => _dateFin = picked);
    }
  }

  Widget _datePickerTheme(BuildContext ctx, Widget? child) {
    return Theme(
      data: ThemeData.light().copyWith(
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          onPrimary: AppColors.white,
          surface: AppColors.surfaceContainerLowest,
        ),
      ),
      child: child!,
    );
  }

  Future<void> _pickHeureDebut() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _heureDebut ?? const TimeOfDay(hour: 9, minute: 0),
      builder: _timePickerTheme,
    );
    if (picked != null) {
      setState(() {
        _heureDebut = picked;
        if (_heureFin != null && !_isHeurFinValid(picked, _heureFin!)) {
          _heureFin = null;
        }
      });
    }
  }

  Future<void> _pickHeureFin() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _heureFin ??
          TimeOfDay(
              hour: (_heureDebut?.hour ?? 9) + 1,
              minute: _heureDebut?.minute ?? 0),
      builder: _timePickerTheme,
    );
    if (picked != null) {
      if (_heureDebut != null && !_isHeurFinValid(_heureDebut!, picked)) {
        _showSnack('L\'heure de fin doit être après l\'heure de début');
        return;
      }
      setState(() => _heureFin = picked);
    }
  }

  Widget _timePickerTheme(BuildContext ctx, Widget? child) {
    return Theme(
      data: ThemeData.light().copyWith(
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          onPrimary: AppColors.white,
          surface: AppColors.surfaceContainerLowest,
        ),
      ),
      child: child!,
    );
  }

  bool _isHeurFinValid(TimeOfDay debut, TimeOfDay fin) {
    final debutMins = debut.hour * 60 + debut.minute;
    final finMins = fin.hour * 60 + fin.minute;
    return finMins > debutMins;
  }

  bool get _step1Valid => _dateDebut != null && _dateFin != null;
  bool get _step2Valid =>
      _heureDebut != null &&
      _heureFin != null &&
      _isHeurFinValid(_heureDebut!, _heureFin!);

  void _showSnack(String msg, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : AppColors.secondary,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _submitDemande() async {
    if (!_motifFormKey.currentState!.validate()) return;
    if (!_step1Valid || !_step2Valid) {
      _showSnack('Veuillez remplir toutes les étapes');
      return;
    }

    setState(() {
      _checkingAvailability = true;
      _availabilityError = null;
    });

    final availResult = await _api.checkAvailability(
      widget.salle.id,
      _formatDateApi(_dateDebut!),
      _formatTime(_heureDebut!),
      _formatTime(_heureFin!),
    );

    if (!mounted) return;

    if (availResult['available'] != true) {
      setState(() {
        _checkingAvailability = false;
        _availabilityError =
            'Cette salle n\'est pas disponible pour le créneau sélectionné.';
      });
      return;
    }

    setState(() {
      _checkingAvailability = false;
      _submitting = true;
    });

    try {
      final user = await _auth.getCurrentUser();
      if (user == null) {
        _showSnack('Session expirée, veuillez vous reconnecter');
        setState(() => _submitting = false);
        return;
      }

      final demande = Demande(
        id: 0,
        userId: user.id,
        salleId: widget.salle.id,
        dateDebut: _formatDateApi(_dateDebut!),
        dateFin: _formatDateApi(_dateFin!),
        heureDebut: _formatTime(_heureDebut!),
        heureFin: _formatTime(_heureFin!),
        motif: _motifController.text.trim(),
        statut: 'en_attente',
        salleName: widget.salle.nom,
        userName: '${user.prenom} ${user.nom}',
      );

      final result = await _api.createDemande(demande);

      if (!mounted) return;
      setState(() => _submitting = false);

      if (result['success'] == true) {
        _ws.sendNewDemande({
          'salle_id': widget.salle.id,
          'salle_name': widget.salle.nom,
          'user_id': user.id,
          'user_name': '${user.prenom} ${user.nom}',
          'date_debut': _formatDateApi(_dateDebut!),
          'heure_debut': _formatTime(_heureDebut!),
          'heure_fin': _formatTime(_heureFin!),
        });
        _showSuccessDialog();
      } else {
        _showSnack(result['message'] ?? 'Erreur lors de la création');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        _showSnack('Erreur: $e');
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.secondary,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Demande envoyée !',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Votre demande de réservation pour ${widget.salle.nom} a bien été soumise. Vous serez notifié dès qu\'elle sera traitée.',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: PrimaryGradientButton(
                label: 'Retour à l\'accueil',
                icon: Icons.arrow_back_rounded,
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          _buildHeader(),
          const RedAccentBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              child: Column(
                children: [
                  _StepIndicator(currentStep: _currentStep),
                  const SizedBox(height: 24),
                  _buildCurrentStep(),
                  const SizedBox(height: 24),
                  _buildNavButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.navyGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 24, 16),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded,
                    color: AppColors.white),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nouvelle réservation',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                      ),
                    ),
                    Text(
                      widget.salle.nom,
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
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildStep2();
      case 2:
        return _buildStep3();
      default:
        return const SizedBox();
    }
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.meeting_room_rounded,
          title: 'Informations sur la salle',
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.salle.nom,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
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
                        const Icon(Icons.people_rounded,
                            size: 13,
                            color: AppColors.onSecondaryContainer),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.salle.capacite} personnes',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSecondaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.salle.disponible
                          ? AppColors.secondaryContainer
                          : AppColors.errorContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      widget.salle.disponible ? 'Disponible' : 'Indisponible',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: widget.salle.disponible
                            ? AppColors.onSecondaryContainer
                            : AppColors.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
              if (widget.salle.equipements.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: widget.salle.equipements
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .map(
                        (eq) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: AppColors.outlineVariant, width: 1),
                          ),
                          child: Text(
                            eq,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        _SectionTitle(
          icon: Icons.date_range_rounded,
          title: 'Période de réservation',
        ),
        const SizedBox(height: 12),
        _DatePickerField(
          label: 'Date de début',
          value: _dateDebut != null ? _formatDate(_dateDebut!) : null,
          hint: 'Sélectionner une date',
          icon: Icons.calendar_today_rounded,
          onTap: _pickDateDebut,
        ),
        const SizedBox(height: 12),
        _DatePickerField(
          label: 'Date de fin',
          value: _dateFin != null ? _formatDate(_dateFin!) : null,
          hint: _dateDebut == null
              ? 'Choisir d\'abord une date de début'
              : 'Sélectionner une date',
          icon: Icons.calendar_month_rounded,
          onTap: _dateDebut != null ? _pickDateFin : null,
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.access_time_rounded,
          title: 'Horaires de la réservation',
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.tertiaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 18, color: AppColors.onTertiaryContainer),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'L\'heure de fin doit être ultérieure à l\'heure de début.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.onTertiaryContainer,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _DatePickerField(
          label: 'Heure de début',
          value: _heureDebut != null
              ? _formatTimeDisplay(_heureDebut!)
              : null,
          hint: 'Choisir l\'heure de début',
          icon: Icons.schedule_rounded,
          onTap: _pickHeureDebut,
        ),
        const SizedBox(height: 12),
        _DatePickerField(
          label: 'Heure de fin',
          value: _heureFin != null ? _formatTimeDisplay(_heureFin!) : null,
          hint: 'Choisir l\'heure de fin',
          icon: Icons.schedule_rounded,
          onTap: _pickHeureFin,
        ),
        if (_heureDebut != null && _heureFin != null && _step2Valid) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.secondaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded,
                    size: 18, color: AppColors.onSecondaryContainer),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Durée : ${_durationLabel()}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _durationLabel() {
    if (_heureDebut == null || _heureFin == null) return '';
    final mins = (_heureFin!.hour * 60 + _heureFin!.minute) -
        (_heureDebut!.hour * 60 + _heureDebut!.minute);
    final h = mins ~/ 60;
    final m = mins % 60;
    if (h == 0) return '$m min';
    if (m == 0) return '${h}h';
    return '${h}h ${m}min';
  }

  Widget _buildStep3() {
    return Form(
      key: _motifFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.summarize_rounded,
            title: 'Récapitulatif',
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              children: [
                _RecapRow(
                  icon: Icons.meeting_room_rounded,
                  label: 'Salle',
                  value: widget.salle.nom,
                ),
                const Divider(
                    height: 20, color: AppColors.outlineVariant),
                _RecapRow(
                  icon: Icons.calendar_today_rounded,
                  label: 'Du',
                  value: _dateDebut != null ? _formatDate(_dateDebut!) : '-',
                ),
                const SizedBox(height: 8),
                _RecapRow(
                  icon: Icons.calendar_month_rounded,
                  label: 'Au',
                  value: _dateFin != null ? _formatDate(_dateFin!) : '-',
                ),
                const Divider(height: 20, color: AppColors.outlineVariant),
                _RecapRow(
                  icon: Icons.access_time_rounded,
                  label: 'Horaire',
                  value: (_heureDebut != null && _heureFin != null)
                      ? '${_formatTimeDisplay(_heureDebut!)} – ${_formatTimeDisplay(_heureFin!)}'
                      : '-',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SectionTitle(
            icon: Icons.edit_note_rounded,
            title: 'Motif de la réservation',
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _motifController,
            maxLines: 5,
            minLines: 4,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.onSurface,
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText:
                  'Décrivez l\'objet de votre réunion (réunion d\'équipe, formation, présentation client...)',
              hintStyle: TextStyle(
                color: AppColors.onSurfaceVariant.withOpacity(0.6),
                fontSize: 13,
              ),
              filled: true,
              fillColor: AppColors.surfaceContainerLowest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: AppColors.outlineVariant, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: AppColors.outlineVariant, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                    color: AppColors.primary.withOpacity(0.4), width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: AppColors.error, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: AppColors.error, width: 2),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Veuillez indiquer le motif de la réservation';
              }
              if (val.trim().length < 10) {
                return 'Le motif doit contenir au moins 10 caractères';
              }
              return null;
            },
          ),
          if (_availabilityError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.errorContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 18, color: AppColors.onErrorContainer),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _availabilityError!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.onErrorContainer,
                        height: 1.4,
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

  Widget _buildNavButtons() {
    final isLastStep = _currentStep == 2;
    final isFirstStep = _currentStep == 0;

    return Row(
      children: [
        if (!isFirstStep)
          Expanded(
            child: OutlinedButton(
              onPressed: () => setState(() => _currentStep--),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.onSurfaceVariant,
                side: const BorderSide(
                    color: AppColors.outlineVariant, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Précédent',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        if (!isFirstStep) const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: isLastStep
              ? PrimaryGradientButton(
                  label: 'Soumettre la demande',
                  icon: Icons.send_rounded,
                  isLoading: _checkingAvailability || _submitting,
                  onPressed:
                      (_checkingAvailability || _submitting)
                          ? null
                          : _submitDemande,
                )
              : PrimaryGradientButton(
                  label: 'Suivant',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: _canProceed() ? _goNext : null,
                ),
        ),
      ],
    );
  }

  bool _canProceed() {
    if (_currentStep == 0) return _step1Valid;
    if (_currentStep == 1) return _step2Valid;
    return true;
  }

  void _goNext() {
    if (_currentStep < 2) {
      setState(() {
        _availabilityError = null;
        _currentStep++;
      });
    }
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;

  const _StepIndicator({required this.currentStep});

  static const List<String> _labels = [
    'Salle & Dates',
    'Horaires',
    'Motif',
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(_labels.length * 2 - 1, (i) {
        if (i.isOdd) {
          final stepIndex = i ~/ 2;
          final isCompleted = currentStep > stepIndex;
          return Expanded(
            child: Container(
              height: 2,
              color: isCompleted ? AppColors.primary : AppColors.outlineVariant,
            ),
          );
        }
        final stepIndex = i ~/ 2;
        final isCompleted = currentStep > stepIndex;
        final isCurrent = currentStep == stepIndex;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.secondary
                    : isCurrent
                        ? AppColors.primary
                        : AppColors.surfaceContainerHighest,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted
                      ? AppColors.secondary
                      : isCurrent
                          ? AppColors.primary
                          : AppColors.outlineVariant,
                  width: 2,
                ),
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check_rounded,
                        size: 16, color: AppColors.white)
                    : Text(
                        '${stepIndex + 1}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isCurrent
                              ? AppColors.white
                              : AppColors.onSurfaceVariant,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _labels[stepIndex],
              style: TextStyle(
                fontSize: 11,
                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                color: isCurrent
                    ? AppColors.primary
                    : isCompleted
                        ? AppColors.secondary
                        : AppColors.onSurfaceVariant,
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 17, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
      ],
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final String? value;
  final String hint;
  final IconData icon;
  final VoidCallback? onTap;

  const _DatePickerField({
    required this.label,
    required this.value,
    required this.hint,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    final isDisabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDisabled
              ? AppColors.surfaceContainerHighest.withOpacity(0.5)
              : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasValue ? AppColors.primary.withOpacity(0.3) : AppColors.outlineVariant,
            width: hasValue ? 1.5 : 1,
          ),
          boxShadow: isDisabled ? null : AppShadows.card,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: hasValue
                  ? AppColors.primary
                  : isDisabled
                      ? AppColors.outlineVariant
                      : AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: hasValue
                          ? AppColors.primary
                          : AppColors.onSurfaceVariant,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasValue ? value! : hint,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          hasValue ? FontWeight.w600 : FontWeight.w400,
                      color: hasValue
                          ? AppColors.onSurface
                          : AppColors.onSurfaceVariant.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: isDisabled
                  ? AppColors.outlineVariant
                  : AppColors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecapRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _RecapRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.onSurfaceVariant),
        const SizedBox(width: 10),
        Text(
          '$label : ',
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
