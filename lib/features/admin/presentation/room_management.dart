import 'package:flutter/material.dart';
import '../../../models/salle.dart';
import '../../../shared/services/firestore_service.dart';
import '../../../core/theme/theme.dart';

class AdminRoomManagement extends StatefulWidget {
  const AdminRoomManagement({super.key});

  @override
  State<AdminRoomManagement> createState() => _AdminRoomManagementState();
}

class _AdminRoomManagementState extends State<AdminRoomManagement>
    with SingleTickerProviderStateMixin {
  final _apiService = FirestoreService();
  late AnimationController _animationController;
  
  List<Salle> _salles = [];
  List<Salle> _filteredSalles = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _sortBy = 'name'; // name, capacity, floor

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _loadRooms();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadRooms() async {
    setState(() => _isLoading = true);
    final salles = await _apiService.getSalles();
    setState(() {
      _salles = salles;
      _applyFilters();
      _isLoading = false;
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredSalles = _salles
          .where((s) =>
              s.nom.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (s.localisation ?? '').toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();

      // Sort
      switch (_sortBy) {
        case 'name':
          _filteredSalles.sort((a, b) => a.nom.compareTo(b.nom));
          break;
        case 'capacity':
          _filteredSalles.sort((a, b) => b.capacite.compareTo(a.capacite));
          break;
        case 'floor':
          _filteredSalles.sort((a, b) => (a.etage ?? 0).compareTo(b.etage ?? 0));
          break;
      }
    });
  }

  Future<void> _editRoom(Salle salle) async {
    final nomController = TextEditingController(text: salle.nom);
    final capaciteController = TextEditingController(text: salle.capacite.toString());
    final localisationController = TextEditingController(text: salle.localisation);
    final descriptionController = TextEditingController(text: salle.description);
    final etageController = TextEditingController(text: salle.etage.toString());

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Modifier la salle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildEditField('Nom', nomController),
              _buildEditField('Capacité', capaciteController, keyboardType: TextInputType.number),
              _buildEditField('Étage', etageController, keyboardType: TextInputType.number),
              _buildEditField('Localisation', localisationController),
              _buildEditField('Description', descriptionController, maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    );

    if (result ?? false) {
      // TODO: Call API to update room
      _showNotification('Succès', 'Salle mise à jour', true);
      _loadRooms();
    }
  }

  Future<void> _deleteRoom(Salle salle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 12),
            Text('Supprimer la salle'),
          ],
        ),
        content: Text('Êtes-vous sûr de vouloir supprimer "${salle.nom}"?\nCette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      // TODO: Call API to delete room
      _showNotification('Succès', 'Salle supprimée', true);
      _loadRooms();
    }
  }

  Future<void> _showAddRoomDialog() async {
    final nomController = TextEditingController();
    final capaciteController = TextEditingController();
    final etageController = TextEditingController();
    final localisationController = TextEditingController();
    final descriptionController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Ajouter une nouvelle salle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildEditField('Nom', nomController),
              _buildEditField('Capacité', capaciteController, keyboardType: TextInputType.number),
              _buildEditField('Étage', etageController, keyboardType: TextInputType.number),
              _buildEditField('Localisation', localisationController),
              _buildEditField('Description', descriptionController, maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );

    if (result ?? false) {
      // TODO: Call API to add room
      _showNotification('Succès', 'Salle ajoutée', true);
      _loadRooms();
    }
  }

  void _showNotification(String title, String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(message),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        title: const Text('Gestion des Salles'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRooms,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRoomDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search and Sort Bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                          _applyFilters();
                        },
                        decoration: InputDecoration(
                          hintText: 'Rechercher une salle...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    setState(() => _searchQuery = '');
                                    _applyFilters();
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildSortButton('Nom', 'name'),
                            _buildSortButton('Capacité', 'capacity'),
                            _buildSortButton('Étage', 'floor'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Rooms Grid
                Expanded(
                  child: _filteredSalles.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.meeting_room,
                                size: 64,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Aucune salle trouvée',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.9,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: _filteredSalles.length,
                          itemBuilder: (context, index) {
                            final salle = _filteredSalles[index];
                            return _buildRoomCard(salle);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildSortButton(String label, String value) {
    final isSelected = _sortBy == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _sortBy = value);
          _applyFilters();
        },
        backgroundColor: Colors.grey[200],
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildRoomCard(Salle salle) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        onTap: () => _editRoom(salle),
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        salle.nom,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${salle.etage}F - ${salle.localisation}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.people,
                                size: 14,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${salle.capacite} pers.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: const Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 8),
                        Text('Modifier'),
                      ],
                    ),
                    onTap: () => _editRoom(salle),
                  ),
                  PopupMenuItem(
                    child: const Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Supprimer'),
                      ],
                    ),
                    onTap: () => _deleteRoom(salle),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}
