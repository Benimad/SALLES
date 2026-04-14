import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/salle.dart';
import '../models/demande.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/file_service.dart';

class CreateDemandeWithAttachmentsScreen extends StatefulWidget {
  final Salle salle;

  const CreateDemandeWithAttachmentsScreen({super.key, required this.salle});

  @override
  State<CreateDemandeWithAttachmentsScreen> createState() => _CreateDemandeWithAttachmentsScreenState();
}

class _CreateDemandeWithAttachmentsScreenState extends State<CreateDemandeWithAttachmentsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _motifController = TextEditingController();
  final _apiService = ApiService();
  final _authService = AuthService();
  final _fileService = FileService();

  DateTime _dateDebut = DateTime.now();
  DateTime _dateFin = DateTime.now();
  TimeOfDay _heureDebut = TimeOfDay.now();
  TimeOfDay _heureFin = TimeOfDay.now();
  bool _isLoading = false;
  List<File> _attachedFiles = [];

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

  Future<void> _pickFiles() async {
    final files = await _fileService.pickMultipleFiles();
    if (files.isNotEmpty) {
      setState(() {
        _attachedFiles.addAll(files);
      });
    }
  }

  Future<void> _takePhoto() async {
    final photo = await _fileService.takePhoto();
    if (photo != null) {
      setState(() {
        _attachedFiles.add(photo);
      });
    }
  }

  Future<void> _pickImage() async {
    final image = await _fileService.pickImageFromGallery();
    if (image != null) {
      setState(() {
        _attachedFiles.add(image);
      });
    }
  }

  void _removeFile(int index) {
    setState(() {
      _attachedFiles.removeAt(index);
    });
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Prendre une photo'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choisir une image'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text('Joindre des fichiers'),
              onTap: () {
                Navigator.pop(context);
                _pickFiles();
              },
            ),
          ],
        ),
      ),
    );
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

      if (result['success'] == true && _attachedFiles.isNotEmpty) {
        final demandeId = result['demande_id'];
        for (var file in _attachedFiles) {
          await _fileService.uploadFile(file, demandeId);
        }
      }

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pièces jointes',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: _showAttachmentOptions,
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter'),
                  ),
                ],
              ),
              if (_attachedFiles.isNotEmpty) ...[
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _attachedFiles.length,
                  itemBuilder: (context, index) {
                    final file = _attachedFiles[index];
                    return Card(
                      child: ListTile(
                        leading: _fileService.isImage(file)
                            ? Image.file(file, width: 50, height: 50, fit: BoxFit.cover)
                            : Icon(Icons.insert_drive_file, color: Colors.blue),
                        title: Text(
                          file.path.split('/').last,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(_fileService.getFileSize(file)),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => _removeFile(index),
                        ),
                      ),
                    );
                  },
                ),
              ],
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
