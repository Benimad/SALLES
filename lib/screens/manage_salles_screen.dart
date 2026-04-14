import 'package:flutter/material.dart';
import '../models/salle.dart';
import '../services/api_service.dart';

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

  void _showAddEditDialog({Salle? salle}) {
    final isEdit = salle != null;
    final nomController = TextEditingController(text: salle?.nom ?? '');
    final capaciteController = TextEditingController(
      text: salle?.capacite.toString() ?? '',
    );
    final equipementsController = TextEditingController(
      text: salle?.equipements ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Modifier la salle' : 'Ajouter une salle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomController,
                decoration: const InputDecoration(
                  labelText: 'Nom de la salle',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: capaciteController,
                decoration: const InputDecoration(
                  labelText: 'Capacité',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: equipementsController,
                decoration: const InputDecoration(
                  labelText: 'Équipements',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implémenter l'ajout/modification
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fonctionnalité à venir')),
              );
            },
            child: Text(isEdit ? 'Modifier' : 'Ajouter'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(Salle salle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la salle'),
        content: Text('Voulez-vous vraiment supprimer "${salle.nom}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implémenter la suppression
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fonctionnalité à venir')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Salles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSalles,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _salles.isEmpty
              ? const Center(child: Text('Aucune salle'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _salles.length,
                  itemBuilder: (context, index) {
                    final salle = _salles[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: salle.disponible ? Colors.green : Colors.red,
                          child: Text(
                            salle.nom[0],
                            style: const TextStyle(color: Colors.white),
                          ),
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
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 20),
                                  SizedBox(width: 8),
                                  Text('Modifier'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, size: 20, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Supprimer', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showAddEditDialog(salle: salle);
                            } else if (value == 'delete') {
                              _showDeleteDialog(salle);
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter une salle'),
      ),
    );
  }
}
