import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/demande.dart';
import '../services/api_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _apiService = ApiService();
  List<Demande> _demandes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDemandes();
  }

  Future<void> _loadDemandes() async {
    setState(() => _isLoading = true);
    final demandes = await _apiService.getDemandes();
    setState(() {
      _demandes = demandes;
      _isLoading = false;
    });
  }

  Future<void> _updateStatut(int demandeId, String statut) async {
    final result = await _apiService.updateDemandeStatut(demandeId, statut);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Statut mis à jour')),
      );

      if (result['success'] == true) {
        _loadDemandes();
      }
    }
  }

  Color _getStatusColor(String statut) {
    switch (statut) {
      case 'approuvee':
        return Colors.green;
      case 'rejetee':
        return Colors.red;
      default:
        return Colors.orange;
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _demandes.isEmpty
              ? const Center(child: Text('Aucune demande'))
              : RefreshIndicator(
                  onRefresh: _loadDemandes,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _demandes.length,
                    itemBuilder: (context, index) {
                      final demande = _demandes[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ExpansionTile(
                          leading: Icon(
                            Icons.meeting_room,
                            color: _getStatusColor(demande.statut),
                          ),
                          title: Text(
                            demande.salleName ?? 'Salle #${demande.salleId}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Par: ${demande.userName ?? 'Utilisateur #${demande.userId}'}',
                          ),
                          trailing: Chip(
                            label: Text(
                              _getStatusText(demande.statut),
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                            backgroundColor: _getStatusColor(demande.statut),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today, size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Du ${DateFormat('dd/MM/yyyy').format(DateTime.parse(demande.dateDebut))} au ${DateFormat('dd/MM/yyyy').format(DateTime.parse(demande.dateFin))}',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time, size: 16),
                                      const SizedBox(width: 8),
                                      Text('De ${demande.heureDebut} à ${demande.heureFin}'),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.description, size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text('Motif: ${demande.motif}')),
                                    ],
                                  ),
                                  if (demande.statut == 'en_attente') ...[
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () => _updateStatut(demande.id, 'approuvee'),
                                            icon: const Icon(Icons.check),
                                            label: const Text('Approuver'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () => _updateStatut(demande.id, 'rejetee'),
                                            icon: const Icon(Icons.close),
                                            label: const Text('Rejeter'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
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
                      );
                    },
                  ),
                ),
    );
  }
}
