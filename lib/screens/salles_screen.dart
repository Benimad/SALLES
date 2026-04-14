import 'package:flutter/material.dart';
import '../models/salle.dart';
import '../services/api_service.dart';
import 'create_demande_screen.dart';

class SallesScreen extends StatefulWidget {
  const SallesScreen({super.key});

  @override
  State<SallesScreen> createState() => _SallesScreenState();
}

class _SallesScreenState extends State<SallesScreen> {
  final _apiService = ApiService();
  List<Salle> _salles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSalles();
  }

  Future<void> _loadSalles() async {
    setState(() => _isLoading = true);
    final salles = await _apiService.getSalles();
    setState(() {
      _salles = salles;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _salles.isEmpty
              ? const Center(child: Text('Aucune salle disponible'))
              : RefreshIndicator(
                  onRefresh: _loadSalles,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _salles.length,
                    itemBuilder: (context, index) {
                      final salle = _salles[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(salle.nom[0]),
                          ),
                          title: Text(
                            salle.nom,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('Capacité: ${salle.capacite} personnes'),
                              Text('Équipements: ${salle.equipements}'),
                            ],
                          ),
                          trailing: salle.disponible
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : const Icon(Icons.cancel, color: Colors.red),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CreateDemandeScreen(salle: salle),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
