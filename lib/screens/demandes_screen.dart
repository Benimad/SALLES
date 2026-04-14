import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/demande.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class DemandesScreen extends StatefulWidget {
  const DemandesScreen({super.key});

  @override
  State<DemandesScreen> createState() => _DemandesScreenState();
}

class _DemandesScreenState extends State<DemandesScreen> {
  final _apiService = ApiService();
  final _authService = AuthService();
  List<Demande> _demandes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDemandes();
  }

  Future<void> _loadDemandes() async {
    setState(() => _isLoading = true);
    final user = await _authService.getCurrentUser();
    if (user != null) {
      final demandes = await _apiService.getDemandes(userId: user.id);
      setState(() {
        _demandes = demandes;
        _isLoading = false;
      });
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
                            '${DateFormat('dd/MM/yyyy').format(DateTime.parse(demande.dateDebut))} - ${demande.heureDebut}',
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
