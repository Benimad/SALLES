import 'package:flutter/material.dart';
import '../models/salle.dart';
import '../services/api_service.dart';
import '../utils/theme.dart';
import 'create_demande_screen.dart';
import 'create_demande_with_attachments_screen.dart';

class SallesScreen extends StatefulWidget {
  const SallesScreen({super.key});

  @override
  State<SallesScreen> createState() => _SallesScreenState();
}

class _SallesScreenState extends State<SallesScreen>
    with SingleTickerProviderStateMixin {
  final _apiService = ApiService();
  final _searchController = TextEditingController();
  List<Salle> _salles = [];
  List<Salle> _filteredSalles = [];
  bool _isLoading = true;
  int _minCapacity = 0;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _loadSalles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
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
    _animationController.forward();
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.filter_list, color: AlOmraneTheme.navyBlue),
            SizedBox(width: 12),
            Text('Filtrer par capacité'),
          ],
        ),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Capacité minimale: $_minCapacity personnes',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AlOmraneTheme.navyBlue,
                  thumbColor: AlOmraneTheme.redAccent,
                  overlayColor: AlOmraneTheme.redAccent.withOpacity(0.2),
                ),
                child: Slider(
                  value: _minCapacity.toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 20,
                  label: _minCapacity.toString(),
                  onChanged: (value) {
                    setDialogState(() => _minCapacity = value.toInt());
                  },
                ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AlOmraneTheme.navyBlue,
            ),
            child: const Text('Appliquer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 140,
              floating: true,
              pinned: true,
              elevation: 0,
              backgroundColor: AlOmraneTheme.navyBlue,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: AlOmraneTheme.primaryGradient,
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Salles disponibles',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_salles.length} salles trouvées',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                height: 4,
                decoration: const BoxDecoration(
                  gradient: AlOmraneTheme.accentGradient,
                ),
              ),
            ),
          ];
        },
        body: Column(
          children: [
            // Search Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Rechercher une salle...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: const Icon(Icons.search, color: AlOmraneTheme.navyBlue),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.grey),
                                onPressed: () {
                                  _searchController.clear();
                                  _filterSalles('');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AlOmraneTheme.navyBlue, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onChanged: _filterSalles,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: _minCapacity > 0 ? AlOmraneTheme.navyBlue : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.filter_list,
                        color: _minCapacity > 0 ? Colors.white : Colors.grey[600],
                      ),
                      onPressed: _showFilterDialog,
                      tooltip: 'Filtrer',
                    ),
                  ),
                ],
              ),
            ),

            // Active filter chip
            if (_minCapacity > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                alignment: Alignment.centerLeft,
                child: Chip(
                  avatar: const Icon(Icons.group, size: 18, color: AlOmraneTheme.navyBlue),
                  label: Text('Capacité ≥ $_minCapacity'),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () {
                    setState(() => _minCapacity = 0);
                    _filterSalles(_searchController.text);
                  },
                  backgroundColor: AlOmraneTheme.navyBlue.withOpacity(0.1),
                  side: BorderSide.none,
                ),
              ),

            // Room List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredSalles.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadSalles,
                          color: AlOmraneTheme.navyBlue,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredSalles.length,
                            itemBuilder: (context, index) {
                              final salle = _filteredSalles[index];
                              return AnimatedBuilder(
                                animation: _animationController,
                                builder: (context, child) {
                                  final delay = index * 100;
                                  final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
                                    CurvedAnimation(
                                      parent: _animationController,
                                      curve: Interval(
                                        delay / 1000,
                                        (delay + 400) / 1000,
                                        curve: Curves.easeOutCubic,
                                      ),
                                    ),
                                  );

                                  return Transform.translate(
                                    offset: Offset(0, 50 * (1 - animation.value)),
                                    child: Opacity(
                                      opacity: animation.value,
                                      child: _buildRoomCard(salle),
                                    ),
                                  );
                                },
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 24),
          Text(
            'Aucune salle trouvée',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez d\'autres critères de recherche',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _searchController.clear();
              setState(() => _minCapacity = 0);
              _filterSalles('');
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Réinitialiser les filtres'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AlOmraneTheme.navyBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomCard(Salle salle) {
    return Hero(
      tag: 'salle_${salle.id}',
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: () => _showBookingOptions(salle),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with image placeholder
              Container(
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AlOmraneTheme.navyBlue,
                      AlOmraneTheme.darkNavy,
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Stack(
                  children: [
                    // Background pattern
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.1,
                        child: Icon(
                          Icons.meeting_room,
                          size: 100,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    // Content
                    Positioned(
                      left: 20,
                      bottom: 20,
                      right: 20,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.meeting_room,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  salle.nom,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.people,
                                      size: 16,
                                      color: Colors.white70,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${salle.capacite} personnes',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: salle.disponible
                                  ? AlOmraneTheme.statusAccepted.withOpacity(0.9)
                                  : AlOmraneTheme.statusRefused.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  salle.disponible ? Icons.check_circle : Icons.cancel,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  salle.disponible ? 'Disponible' : 'Occupée',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Equipment section
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Équipements',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AlOmraneTheme.darkNavy,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildEquipmentChips(salle.equipements),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CreateDemandeScreen(salle: salle),
                                ),
                              );
                            },
                            icon: const Icon(Icons.calendar_today, size: 18),
                            label: const Text('Réserver'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AlOmraneTheme.navyBlue,
                              side: const BorderSide(color: AlOmraneTheme.navyBlue),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CreateDemandeWithAttachmentsScreen(salle: salle),
                                ),
                              );
                            },
                            icon: const Icon(Icons.attach_file, size: 18),
                            label: const Text('Avec pièces'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AlOmraneTheme.redAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEquipmentChips(String equipements) {
    final items = equipements.split(',').map((e) => e.trim()).toList();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        IconData icon = Icons.circle;
        if (item.toLowerCase().contains('projecteur')) icon = Icons.videocam;
        else if (item.toLowerCase().contains('tableau')) icon = Icons.edit;
        else if (item.toLowerCase().contains('wifi')) icon = Icons.wifi;
        else if (item.toLowerCase().contains('climatisation')) icon = Icons.ac_unit;
        else if (item.toLowerCase().contains('ordinateur')) icon = Icons.computer;
        else if (item.toLowerCase().contains('audio')) icon = Icons.speaker;
        else if (item.toLowerCase().contains('écran') || item.toLowerCase().contains('tv')) icon = Icons.tv;

        return Chip(
          avatar: Icon(icon, size: 16, color: AlOmraneTheme.navyBlue),
          label: Text(
            item,
            style: const TextStyle(fontSize: 12),
          ),
          backgroundColor: AlOmraneTheme.navyBlue.withOpacity(0.1),
          side: BorderSide.none,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        );
      }).toList(),
    );
  }

  void _showBookingOptions(Salle salle) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      salle.nom,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AlOmraneTheme.darkNavy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Capacité: ${salle.capacite} personnes',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Choisir le type de réservation',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AlOmraneTheme.navyBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.calendar_today,
                          color: AlOmraneTheme.navyBlue,
                        ),
                      ),
                      title: const Text('Réservation simple'),
                      subtitle: const Text('Réserver la salle sans pièces jointes'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateDemandeScreen(salle: salle),
                          ),
                        );
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AlOmraneTheme.redAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.attach_file,
                          color: AlOmraneTheme.redAccent,
                        ),
                      ),
                      title: const Text('Réservation avec pièces jointes'),
                      subtitle: const Text('Joindre des documents à votre demande'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateDemandeWithAttachmentsScreen(salle: salle),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}