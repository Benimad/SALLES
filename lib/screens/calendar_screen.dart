import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/demande.dart';
import '../services/api_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _apiService = ApiService();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Demande> _allDemandes = [];
  List<Demande> _selectedDayDemandes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadDemandes();
  }

  Future<void> _loadDemandes() async {
    setState(() => _isLoading = true);
    final demandes = await _apiService.getDemandes();
    setState(() {
      _allDemandes = demandes.where((d) => d.statut == 'approuvee').toList();
      _isLoading = false;
      _updateSelectedDayDemandes();
    });
  }

  void _updateSelectedDayDemandes() {
    if (_selectedDay == null) return;
    
    _selectedDayDemandes = _allDemandes.where((demande) {
      final dateDebut = DateTime.parse(demande.dateDebut);
      final dateFin = DateTime.parse(demande.dateFin);
      return _selectedDay!.isAfter(dateDebut.subtract(const Duration(days: 1))) &&
             _selectedDay!.isBefore(dateFin.add(const Duration(days: 1)));
    }).toList();
  }

  List<Demande> _getEventsForDay(DateTime day) {
    return _allDemandes.where((demande) {
      final dateDebut = DateTime.parse(demande.dateDebut);
      final dateFin = DateTime.parse(demande.dateFin);
      return day.isAfter(dateDebut.subtract(const Duration(days: 1))) &&
             day.isBefore(dateFin.add(const Duration(days: 1)));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendrier des Réservations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDemandes,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                TableCalendar(
                  firstDay: DateTime.utc(2024, 1, 1),
                  lastDay: DateTime.utc(2025, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  eventLoader: _getEventsForDay,
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                      _updateSelectedDayDemandes();
                    });
                  },
                  onFormatChanged: (format) {
                    setState(() => _calendarFormat = format);
                  },
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: true,
                    titleCentered: true,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _selectedDayDemandes.isEmpty
                      ? Center(
                          child: Text(
                            'Aucune réservation pour le ${DateFormat('dd/MM/yyyy').format(_selectedDay!)}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _selectedDayDemandes.length,
                          itemBuilder: (context, index) {
                            final demande = _selectedDayDemandes[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  child: Icon(Icons.meeting_room),
                                ),
                                title: Text(
                                  demande.salleName ?? 'Salle #${demande.salleId}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text('Par: ${demande.userName ?? 'Utilisateur'}'),
                                    Text('${demande.heureDebut} - ${demande.heureFin}'),
                                    Text('Motif: ${demande.motif}'),
                                  ],
                                ),
                                trailing: const Icon(Icons.check_circle, color: Colors.green),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
