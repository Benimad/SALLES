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
  final _searchController = TextEditingController();
  List<Salle> _salles = [];
  List<Salle> _filteredSalles = [];
  bool _isLoading = true;
  int _minCapacity = 0;

  @override
  void initState() {
    super.initState();
    _loadSalles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSalles() async {
    setState(() => _isLoading = true);
    final salles = await _apiService.getSalles();
    setState(() {
      _salles = salles;
      _filteredSalles = salles;
      _isLoading = false;
    });
  }

  void _filterSalles(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSalles = _salles.where((s) => s.capacite >= _minCapacity).toList();
      } else {
        _filteredSalles = _salles.where((salle) {
          final matchesQuery = salle.nom.toLowerCase().contains(query.toLowerCase()) ||
              salle.equipements.toLowerCase().contains(query.toLowerCase());
          final matchesCapacity = salle.capacite >= _minCapacity;
          return matchesQuery && matchesCapacity;
        }).toList();
      }
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrer par capacité'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Capacité minimale: $_minCapacity personnes'),
              Slider(
                value: _minCapacity.toDouble(),
                min: 0,
                max: 100,
                divisions: 20,
                label: _minCapacity.toString(),
                onChanged: (value) {
                  setDialogState(() => _minCapacity = value.toInt());
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _minCapacity = 0);
              Navigator.pop(context);
              _filterSalles(_searchController.text);
            },
            child: const Text('Réinitialiser'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _filterSalles(_searchController.text);
            },
            child: const Text('Appliquer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Rechercher une salle...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _filterSalles('');
                              },
                            )
                          : null,
                    ),
                    onChanged: _filterSalles,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    Icons.filter_list,
                    color: _minCapacity > 0 ? Colors.blue : null,
                  ),
                  onPressed: _showFilterDialog,
                  tooltip: 'Filtrer',
                ),
              ],
            ),
          ),
          if (_minCapacity > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Chip(
                label: Text('Capacité ≥ $_minCapacity'),
                onDeleted: () {
                  setState(() => _minCapacity = 0);
                  _filterSalles(_searchController.text);
                },
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredSalles.isEmpty
                    ? const Center(child: Text('Aucune salle trouvée'))
                    : RefreshIndicator(
                        onRefresh: _loadSalles,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredSalles.length,
                          itemBuilder: (context, index) {
                            final salle = _filteredSalles[index];
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
          ),
        ],
      ),
    );
  }
}
