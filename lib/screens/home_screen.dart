import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import 'salles_screen.dart';
import 'demandes_screen.dart';
import 'admin_screen.dart';
import 'login_screen.dart';
import 'calendar_screen.dart';
import 'statistics_screen.dart';
import 'profile_screen.dart';
import 'manage_salles_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  User? _currentUser;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _authService.getCurrentUser();
    setState(() => _currentUser = user);
  }

  List<Widget> get _screens {
    if (_currentUser?.role == 'admin') {
      return [
        const SallesScreen(),
        const DemandesScreen(),
        const AdminScreen(),
      ];
    }
    return [
      const SallesScreen(),
      const DemandesScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Salles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CalendarScreen()),
              );
            },
            tooltip: 'Calendrier',
          ),
          if (_currentUser?.role == 'admin') ..[
            IconButton(
              icon: const Icon(Icons.bar_chart),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const StatisticsScreen()),
                );
              },
              tooltip: 'Statistiques',
            ),
            IconButton(
              icon: const Icon(Icons.meeting_room_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ManageSallesScreen()),
                );
              },
              tooltip: 'Gérer les salles',
            ),
          ],
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person),
                    SizedBox(width: 8),
                    Text('Mon profil'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Déconnexion', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'profile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              } else if (value == 'logout') {
                _logout();
              }
            },
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.meeting_room),
            label: 'Salles',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Mes Demandes',
          ),
          if (_currentUser?.role == 'admin')
            const BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings),
              label: 'Administration',
            ),
        ],
      ),
    );
  }
}
