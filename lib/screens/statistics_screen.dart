import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/demande.dart';
import '../services/api_service.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final _apiService = ApiService();
  List<Demande> _demandes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final demandes = await _apiService.getDemandes();
    setState(() {
      _demandes = demandes;
      _isLoading = false;
    });
  }

  int get _totalDemandes => _demandes.length;
  int get _enAttente => _demandes.where((d) => d.statut == 'en_attente').length;
  int get _approuvees => _demandes.where((d) => d.statut == 'approuvee').length;
  int get _rejetees => _demandes.where((d) => d.statut == 'rejetee').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cartes de statistiques
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total',
                          _totalDemandes.toString(),
                          Colors.blue,
                          Icons.list_alt,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'En attente',
                          _enAttente.toString(),
                          Colors.orange,
                          Icons.pending,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Approuvées',
                          _approuvees.toString(),
                          Colors.green,
                          Icons.check_circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Rejetées',
                          _rejetees.toString(),
                          Colors.red,
                          Icons.cancel,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // Graphique en camembert
                  const Text(
                    'Répartition des demandes',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 250,
                    child: _totalDemandes > 0
                        ? PieChart(
                            PieChartData(
                              sections: [
                                PieChartSectionData(
                                  value: _enAttente.toDouble(),
                                  title: '$_enAttente',
                                  color: Colors.orange,
                                  radius: 100,
                                  titleStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                PieChartSectionData(
                                  value: _approuvees.toDouble(),
                                  title: '$_approuvees',
                                  color: Colors.green,
                                  radius: 100,
                                  titleStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                PieChartSectionData(
                                  value: _rejetees.toDouble(),
                                  title: '$_rejetees',
                                  color: Colors.red,
                                  radius: 100,
                                  titleStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                              sectionsSpace: 2,
                              centerSpaceRadius: 40,
                            ),
                          )
                        : const Center(child: Text('Aucune donnée')),
                  ),
                  const SizedBox(height: 16),
                  
                  // Légende
                  _buildLegend(),
                  
                  const SizedBox(height: 32),
                  
                  // Taux d'approbation
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Taux d\'approbation',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          LinearProgressIndicator(
                            value: _totalDemandes > 0 ? _approuvees / _totalDemandes : 0,
                            minHeight: 20,
                            backgroundColor: Colors.grey[300],
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_totalDemandes > 0 ? ((_approuvees / _totalDemandes) * 100).toStringAsFixed(1) : 0}%',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildLegendItem('En attente', Colors.orange),
        _buildLegendItem('Approuvées', Colors.green),
        _buildLegendItem('Rejetées', Colors.red),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }
}
