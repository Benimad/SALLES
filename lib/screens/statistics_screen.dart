import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../utils/theme.dart';
import '../widgets/al_omrane_widgets.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final stats = await _apiService.getStatistics();
    if (mounted) setState(() { _stats = stats; _isLoading = false; });
  }

  int get _total => (_stats['total_demandes'] as num?)?.toInt() ?? 0;
  int get _approuvees => (_stats['approuvees'] as num?)?.toInt() ?? 0;
  int get _rejetees => (_stats['rejetees'] as num?)?.toInt() ?? 0;
  int get _enAttente => (_stats['en_attente'] as num?)?.toInt() ?? 0;
  int get _totalSalles => (_stats['total_salles'] as num?)?.toInt() ?? 0;
  int get _sallesDisponibles => (_stats['salles_disponibles'] as num?)?.toInt() ?? 0;
  List<dynamic> get _topSalles => (_stats['top_salles'] as List<dynamic>?) ?? [];
  List<dynamic> get _parMois => (_stats['par_mois'] as List<dynamic>?) ?? [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 120,
              backgroundColor: AppColors.navyBlue,
              leading: const SizedBox.shrink(),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(gradient: AppGradients.navyGradient),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: const [
                          Text('Tableau de bord',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.44)),
                          SizedBox(height: 4),
                          Text('Vue d\'ensemble statistique',
                              style: TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: RedAccentBar()),

            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              )
            else ...[
              // KPI Grid
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.55,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildListDelegate([
                    StatCard(
                      title: 'Total demandes',
                      value: _total.toString(),
                      icon: Icons.assignment_rounded,
                      color: AppColors.primary,
                    ),
                    StatCard(
                      title: 'Approuvées',
                      value: _approuvees.toString(),
                      icon: Icons.check_circle_rounded,
                      color: AppColors.secondary,
                    ),
                    StatCard(
                      title: 'En attente',
                      value: _enAttente.toString(),
                      icon: Icons.schedule_rounded,
                      color: AppColors.tertiary,
                    ),
                    StatCard(
                      title: 'Rejetées',
                      value: _rejetees.toString(),
                      icon: Icons.cancel_rounded,
                      color: AppColors.error,
                    ),
                  ]),
                ),
              ),

              // Salles KPI row
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'Total salles',
                          value: _totalSalles.toString(),
                          icon: Icons.meeting_room_rounded,
                          color: AppColors.navyBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          title: 'Disponibles',
                          value: _sallesDisponibles.toString(),
                          icon: Icons.check_rounded,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Pie chart
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: _ChartCard(
                    title: 'Répartition des demandes',
                    child: _total == 0
                        ? _noData()
                        : SizedBox(
                            height: 180,
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 3,
                                centerSpaceRadius: 40,
                                sections: [
                                  if (_approuvees > 0)
                                    PieChartSectionData(
                                      value: _approuvees.toDouble(),
                                      color: AppColors.secondary,
                                      title: '$_approuvees',
                                      radius: 55,
                                      titleStyle: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white),
                                    ),
                                  if (_enAttente > 0)
                                    PieChartSectionData(
                                      value: _enAttente.toDouble(),
                                      color: AppColors.tertiary,
                                      title: '$_enAttente',
                                      radius: 50,
                                      titleStyle: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white),
                                    ),
                                  if (_rejetees > 0)
                                    PieChartSectionData(
                                      value: _rejetees.toDouble(),
                                      color: AppColors.error,
                                      title: '$_rejetees',
                                      radius: 50,
                                      titleStyle: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white),
                                    ),
                                ],
                              ),
                            ),
                          ),
                  ),
                ),
              ),

              // Legend
              if (_total > 0)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _LegendDot(color: AppColors.secondary, label: 'Approuvées'),
                        const SizedBox(width: 16),
                        _LegendDot(color: AppColors.tertiary, label: 'En attente'),
                        const SizedBox(width: 16),
                        _LegendDot(color: AppColors.error, label: 'Rejetées'),
                      ],
                    ),
                  ),
                ),

              // Bar chart by month
              if (_parMois.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: _ChartCard(
                      title: 'Demandes par mois (6 derniers mois)',
                      child: SizedBox(
                        height: 200,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: _parMois
                                    .map((e) => (e['total'] as num?)?.toDouble() ?? 0)
                                    .fold<double>(0, (a, b) => a > b ? a : b) +
                                2,
                            barTouchData: BarTouchData(enabled: false),
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (v, _) {
                                    final idx = v.toInt();
                                    if (idx < 0 || idx >= _parMois.length) {
                                      return const SizedBox.shrink();
                                    }
                                    final label = (_parMois[idx]['mois'] as String? ?? '');
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(label,
                                          style: const TextStyle(
                                              fontSize: 10,
                                              color: AppColors.onSurfaceVariant)),
                                    );
                                  },
                                  reservedSize: 28,
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 28,
                                  getTitlesWidget: (v, _) => Text(
                                    v.toInt().toString(),
                                    style: const TextStyle(
                                        fontSize: 10, color: AppColors.onSurfaceVariant),
                                  ),
                                ),
                              ),
                              topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                            ),
                            gridData: FlGridData(
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (_) => FlLine(
                                color: AppColors.outlineVariant.withOpacity(0.3),
                                strokeWidth: 1,
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            barGroups: List.generate(
                              _parMois.length,
                              (i) => BarChartGroupData(
                                x: i,
                                barRods: [
                                  BarChartRodData(
                                    toY: (_parMois[i]['total'] as num?)?.toDouble() ?? 0,
                                    gradient: const LinearGradient(
                                      colors: [AppColors.primary, AppColors.primaryContainer],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                    ),
                                    width: 20,
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(4)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Top salles
              if (_topSalles.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                    child: _ChartCard(
                      title: 'Salles les plus réservées',
                      child: Column(
                        children: List.generate(_topSalles.length, (i) {
                          final s = _topSalles[i];
                          final count = (s['total'] as num?)?.toInt() ?? 0;
                          final maxCount = (_topSalles.first['total'] as num?)?.toInt() ?? 1;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: i == 0
                                        ? AppColors.primary
                                        : AppColors.surfaceContainerHighest,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text('${i + 1}',
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: i == 0
                                                ? Colors.white
                                                : AppColors.onSurfaceVariant)),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(s['nom'] as String? ?? '',
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.onSurface)),
                                      const SizedBox(height: 4),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: maxCount > 0 ? count / maxCount : 0,
                                          backgroundColor: AppColors.surfaceContainerHighest,
                                          valueColor: AlwaysStoppedAnimation(
                                            i == 0 ? AppColors.primary : AppColors.secondary,
                                          ),
                                          minHeight: 6,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text('$count',
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.onSurface)),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                )
              else
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _noData() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text('Aucune donnée disponible',
              style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14)),
        ),
      );
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _ChartCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
      ],
    );
  }
}
