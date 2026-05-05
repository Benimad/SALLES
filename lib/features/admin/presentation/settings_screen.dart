import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _emailOnNewRequest = true;
  bool _pushNotifications = true;
  String _theme = 'light';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        title: const Text('Paramètres Admin'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Section
            Container(
              color: AppColors.primary.withOpacity(0.1),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primary,
                    child: const Text(
                      'AD',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Administrateur',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'admin@groupealomrane.com',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.edit),
                      label: const Text('Modifier le Profil'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Notifications Section
            _buildSectionHeader('Notifications'),
            _buildSwitchTile(
              'Activer les notifications',
              'Recevez les alertes importantes',
              _notificationsEnabled,
              (value) => setState(() => _notificationsEnabled = value),
            ),
            _buildSwitchTile(
              'Email pour nouvelles demandes',
              'Envoyez un email à chaque nouvelle demande',
              _emailOnNewRequest,
              (value) => setState(() => _emailOnNewRequest = value),
            ),
            _buildSwitchTile(
              'Notifications Push',
              'Notifications push sur mobile',
              _pushNotifications,
              (value) => setState(() => _pushNotifications = value),
            ),

            // Display Section
            _buildSectionHeader('Affichage'),
            _buildThemeSelector(),

            // Security Section
            _buildSectionHeader('Sécurité'),
            _buildListTile(
              Icons.lock,
              'Changer le mot de passe',
              'Mettre à jour votre mot de passe',
              () {},
            ),
            _buildListTile(
              Icons.security,
              'Authentification à deux facteurs',
              'Ajouter une couche de sécurité supplémentaire',
              () {},
            ),

            // System Section
            _buildSectionHeader('Système'),
            _buildListTile(
              Icons.storage,
              'Sauvegarde de base de données',
              'Sauvegarde automatique quotidienne',
              () {},
            ),
            _buildListTile(
              Icons.cleaning_services,
              'Nettoyage des données',
              'Supprimer les anciennes données d\'audit',
              () {},
            ),
            _buildListTile(
              Icons.info,
              'À propos',
              'Version 1.0.0 • Build 42',
              () {},
            ),

            // Logout
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: const Row(
                          children: [
                            Icon(Icons.logout, color: Colors.red),
                            SizedBox(width: 12),
                            Text('Déconnexion'),
                          ],
                        ),
                        content: const Text('Êtes-vous sûr de vouloir vous déconnecter?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Annuler'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              // TODO: Implement logout
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text('Déconnecter'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Déconnexion'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }

  Widget _buildListTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildThemeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thème',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildThemeButton('light', '☀️ Clair'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildThemeButton('dark', '🌙 Sombre'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeButton(String value, String label) {
    final isSelected = _theme == value;
    return ElevatedButton(
      onPressed: () => setState(() => _theme = value),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? AppColors.primary : Colors.grey[200],
        foregroundColor: isSelected ? Colors.white : Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(label),
    );
  }
}
