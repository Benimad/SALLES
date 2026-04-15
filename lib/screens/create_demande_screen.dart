import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../models/salle.dart';
import '../models/demande.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/theme.dart';

class CreateDemandeScreen extends StatefulWidget {
  final Salle salle;

  const CreateDemandeScreen({super.key, required this.salle});

  @override
  State<CreateDemandeScreen> createState() => _CreateDemandeScreenState();
}

class _CreateDemandeScreenState extends State<CreateDemandeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _motifController = TextEditingController();
  final _apiService = ApiService();
  final _authService = AuthService();

  DateTime _dateDebut = DateTime.now();
  DateTime _dateFin = DateTime.now();
  TimeOfDay _heureDebut = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _heureFin = const TimeOfDay(hour: 10, minute: 0);
  bool _isLoading = false;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('fr_FR', null);
  }

  @override
  void dispose() {
    _motifController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isDebut) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isDebut ? _dateDebut : _dateFin,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AlOmraneTheme.navyBlue,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isDebut) {
          _dateDebut = picked;
          if (_dateFin.isBefore(_dateDebut)) {
            _dateFin = _dateDebut;
          }
        } else {
          _dateFin = picked;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isDebut) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isDebut ? _heureDebut : _heureFin,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            colorScheme: const ColorScheme.light(
              primary: AlOmraneTheme.navyBlue,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isDebut) {
          _heureDebut = picked;
        } else {
          _heureFin = picked;
        }
      });
    }
  }

  Future<void> _submitDemande() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final user = await _authService.getCurrentUser();
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final demande = Demande(
        id: 0,
        userId: user.id,
        salleId: widget.salle.id,
        dateDebut: DateFormat('yyyy-MM-dd').format(_dateDebut),
        dateFin: DateFormat('yyyy-MM-dd').format(_dateFin),
        heureDebut: '${_heureDebut.hour.toString().padLeft(2, '0')}:${_heureDebut.minute.toString().padLeft(2, '0')}',
        heureFin: '${_heureFin.hour.toString().padLeft(2, '0')}:${_heureFin.minute.toString().padLeft(2, '0')}',
        motif: _motifController.text,
        statut: 'en_attente',
      );

      final result = await _apiService.createDemande(demande);

      setState(() => _isLoading = false);

      if (mounted) {
        if (result['success'] == true) {
          _showSuccessDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text(result['message'] ?? 'Erreur lors de la création')),
                ],
              ),
              backgroundColor: AlOmraneTheme.statusRefused,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AlOmraneTheme.statusAccepted.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: AlOmraneTheme.statusAccepted,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Demande envoyée!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AlOmraneTheme.darkNavy,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Votre demande de réservation pour ${widget.salle.nom} a été soumise avec succès.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Elle sera traitée par un administrateur sous peu.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AlOmraneTheme.navyBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Retour à l\'accueil',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Step> get _steps => [
    Step(
      title: const Text('Salle'),
      content: _buildRoomInfoCard(),
      isActive: _currentStep >= 0,
      state: _currentStep > 0 ? StepState.complete : StepState.indexed,
    ),
    Step(
      title: const Text('Date & Heure'),
      content: _buildDateTimeSection(),
      isActive: _currentStep >= 1,
      state: _currentStep > 1 ? StepState.complete : StepState.indexed,
    ),
    Step(
      title: const Text('Motif'),
      content: _buildMotifSection(),
      isActive: _currentStep >= 2,
      state: _currentStep >= 2 ? StepState.complete : StepState.indexed,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle réservation'),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AlOmraneTheme.primaryGradient,
          ),
        ),
      ),
      body: _isLoading
          ? Container(
              decoration: const BoxDecoration(gradient: AlOmraneTheme.primaryGradient),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Envoi de la demande...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            )
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  Container(
                    height: 4,
                    decoration: const BoxDecoration(
                      gradient: AlOmraneTheme.accentGradient,
                    ),
                  ),
                  Expanded(
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        canvasColor: Colors.white,
                        colorScheme: const ColorScheme.light(
                          primary: AlOmraneTheme.navyBlue,
                        ),
                      ),
                      child: Stepper(
                        type: StepperType.vertical,
                        currentStep: _currentStep,
                        steps: _steps,
                        onStepTapped: (step) {
                          if (step < _currentStep) {
                            setState(() => _currentStep = step);
                          }
                        },
                        onStepContinue: () {
                          if (_currentStep < _steps.length - 1) {
                            setState(() => _currentStep++);
                          } else {
                            _submitDemande();
                          }
                        },
                        onStepCancel: () {
                          if (_currentStep > 0) {
                            setState(() => _currentStep--);
                          } else {
                            Navigator.pop(context);
                          }
                        },
                        controlsBuilder: (context, details) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: details.onStepContinue,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AlOmraneTheme.navyBlue,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      _currentStep == _steps.length - 1
                                          ? 'Soumettre la demande'
                                          : 'Continuer',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                TextButton(
                                  onPressed: details.onStepCancel,
                                  child: Text(
                                    _currentStep == 0 ? 'Annuler' : 'Retour',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ),
                              ],
                            ),
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

  Widget _buildRoomInfoCard() {
    return Hero(
      tag: 'salle_${widget.salle.id}',
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                AlOmraneTheme.navyBlue.withOpacity(0.05),
                Colors.white,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AlOmraneTheme.navyBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.meeting_room,
                        color: AlOmraneTheme.navyBlue,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.salle.nom,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AlOmraneTheme.darkNavy,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.people, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.salle.capacite} personnes',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Équipements',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AlOmraneTheme.darkNavy,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.salle.equipements.split(',').map((item) {
                    final trimmed = item.trim();
                    return Chip(
                      avatar: const Icon(Icons.check_circle, size: 16, color: AlOmraneTheme.navyBlue),
                      label: Text(trimmed, style: const TextStyle(fontSize: 12)),
                      backgroundColor: AlOmraneTheme.navyBlue.withOpacity(0.1),
                      side: BorderSide.none,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sélectionnez les dates et horaires',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AlOmraneTheme.darkNavy,
          ),
        ),
        const SizedBox(height: 20),
        // Date de début
        _buildDateTimeCard(
          icon: Icons.calendar_today,
          title: 'Date de début',
          subtitle: DateFormat('EEEE dd MMMM yyyy', 'fr_FR').format(_dateDebut),
          onTap: () => _selectDate(context, true),
        ),
        const SizedBox(height: 12),
        // Heure de début
        _buildDateTimeCard(
          icon: Icons.access_time,
          title: 'Heure de début',
          subtitle: _heureDebut.format(context),
          onTap: () => _selectTime(context, true),
        ),
        const Divider(height: 32),
        // Date de fin
        _buildDateTimeCard(
          icon: Icons.calendar_today,
          title: 'Date de fin',
          subtitle: DateFormat('EEEE dd MMMM yyyy', 'fr_FR').format(_dateFin),
          onTap: () => _selectDate(context, false),
        ),
        const SizedBox(height: 12),
        // Heure de fin
        _buildDateTimeCard(
          icon: Icons.access_time,
          title: 'Heure de fin',
          subtitle: _heureFin.format(context),
          onTap: () => _selectTime(context, false),
        ),
        const SizedBox(height: 20),
        // Summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AlOmraneTheme.navyBlue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AlOmraneTheme.navyBlue.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AlOmraneTheme.navyBlue),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Durée totale: ${_calculateDuration()}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AlOmraneTheme.navyBlue,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AlOmraneTheme.navyBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AlOmraneTheme.navyBlue),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AlOmraneTheme.darkNavy,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMotifSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Motif de la réservation',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AlOmraneTheme.darkNavy,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _motifController,
          decoration: InputDecoration(
            hintText: 'Décrivez l\'objet de votre réunion...',
            hintStyle: TextStyle(color: Colors.grey[400]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AlOmraneTheme.navyBlue, width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          maxLines: 5,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer le motif de la réservation';
            }
            if (value.length < 10) {
              return 'Le motif doit contenir au moins 10 caractères';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange[700]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Votre demande sera examinée par un administrateur avant d\'être approuvée.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.orange[800],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _calculateDuration() {
    final startDateTime = DateTime(
      _dateDebut.year,
      _dateDebut.month,
      _dateDebut.day,
      _heureDebut.hour,
      _heureDebut.minute,
    );
    final endDateTime = DateTime(
      _dateFin.year,
      _dateFin.month,
      _dateFin.day,
      _heureFin.hour,
      _heureFin.minute,
    );

    final duration = endDateTime.difference(startDateTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0 && minutes > 0) {
      return '$hours h $minutes min';
    } else if (hours > 0) {
      return '$hours h';
    } else {
      return '$minutes min';
    }
  }
}