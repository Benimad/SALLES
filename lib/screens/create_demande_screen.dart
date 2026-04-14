import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/salle.dart';
import '../models/demande.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

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
  TimeOfDay _heureDebut = TimeOfDay.now();
  TimeOfDay _heureFin = TimeOfDay.now();
  bool _isLoading = false;

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
    );
    if (picked != null) {
      setState(() {
        if (isDebut) {
          _dateDebut = picked;
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
      if (user == null) return;

      final demande = Demande(
        id: 0,
        userId: user.id,
        salleId: widget.salle.id,
        dateDebut: DateFormat('yyyy-MM-dd').format(_dateDebut),
        dateFin: DateFormat('yyyy-MM-dd').format(_dateFin),
        heureDebut: '${_heureDebut.hour}:${_heureDebut.minute}',
        heureFin: '${_heureFin.hour}:${_heureFin.minute}',
        motif: _motifController.text,
        statut: 'en_attente',
      );

      final result = await _apiService.createDemande(demande);

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Demande créée')),
        );

        if (result['success'] == true) {
          Navigator.pop(context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Réserver ${widget.salle.nom}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.salle.nom,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('Capacité: ${widget.salle.capacite} personnes'),
                      Text('Équipements: ${widget.salle.equipements}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                title: const Text('Date de début'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(_dateDebut)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context, true),
              ),
              ListTile(
                title: const Text('Heure de début'),
                subtitle: Text(_heureDebut.format(context)),
                trailing: const Icon(Icons.access_time),
                onTap: () => _selectTime(context, true),
              ),
              const Divider(),
              ListTile(
                title: const Text('Date de fin'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(_dateFin)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context, false),
              ),
              ListTile(
                title: const Text('Heure de fin'),
                subtitle: Text(_heureFin.format(context)),
                trailing: const Icon(Icons.access_time),
                onTap: () => _selectTime(context, false),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _motifController,
                decoration: const InputDecoration(
                  labelText: 'Motif de la réservation',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer le motif';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitDemande,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Soumettre la demande', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
