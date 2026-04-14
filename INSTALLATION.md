# Gestion des Demandes de Salles - Groupe Al Omrane

Application mobile Flutter pour la gestion des demandes de réservation de salles avec backend PHP.

## 📋 Fonctionnalités

### Pour les Employés
- ✅ Inscription et connexion
- ✅ Consultation des salles disponibles
- ✅ Création de demandes de réservation
- ✅ Suivi de l'état des demandes (en attente, approuvée, rejetée)
- ✅ Historique des réservations

### Pour les Administrateurs
- ✅ Toutes les fonctionnalités employés
- ✅ Validation ou rejet des demandes
- ✅ Vue d'ensemble de toutes les demandes
- ✅ Gestion centralisée

## 🛠️ Technologies Utilisées

### Frontend (Mobile)
- Flutter 3.11+
- Dart
- Packages: http, provider, shared_preferences, intl

### Backend
- PHP 7.4+
- MySQL
- REST API

## 📦 Installation

### Prérequis
- Flutter SDK (3.11 ou supérieur)
- Android Studio / VS Code
- XAMPP ou WAMP (pour PHP et MySQL)
- Git

### 1. Configuration du Backend

#### Étape 1: Installer XAMPP
1. Téléchargez et installez XAMPP depuis https://www.apachefriends.org/
2. Démarrez Apache et MySQL depuis le panneau de contrôle XAMPP

#### Étape 2: Créer la base de données
1. Ouvrez phpMyAdmin: http://localhost/phpmyadmin
2. Créez une nouvelle base de données nommée `gestion_salles`
3. Importez le fichier `backend/database.sql`

#### Étape 3: Configurer les fichiers PHP
1. Copiez le dossier `backend/api` dans `C:\xampp\htdocs\`
2. Modifiez `config.php` si nécessaire (host, username, password)

#### Étape 4: Tester l'API
- Accédez à: http://localhost/api/get_salles.php
- Vous devriez voir la liste des salles en JSON

### 2. Configuration de l'Application Flutter

#### Étape 1: Installer les dépendances
```bash
cd salles
flutter pub get
```

#### Étape 2: Configurer l'URL de l'API
Modifiez le fichier `lib/utils/constants.dart`:
```dart
static const String baseUrl = 'http://YOUR_IP_ADDRESS/api';
```

**Important:** 
- Pour tester sur émulateur Android: utilisez `http://10.0.2.2/api`
- Pour tester sur appareil physique: utilisez votre IP locale (ex: `http://192.168.1.100/api`)
- Pour trouver votre IP: `ipconfig` (Windows) ou `ifconfig` (Mac/Linux)

#### Étape 3: Lancer l'application
```bash
flutter run
```

## 👤 Comptes de Test

### Administrateur
- Email: admin@alomrane.ma
- Mot de passe: password

### Créer un compte employé
Utilisez la fonction d'inscription dans l'application

## 📱 Structure du Projet

```
salles/
├── lib/
│   ├── models/          # Modèles de données (User, Salle, Demande)
│   ├── services/        # Services API et authentification
│   ├── screens/         # Écrans de l'application
│   ├── widgets/         # Widgets réutilisables
│   ├── utils/           # Constantes et utilitaires
│   └── main.dart        # Point d'entrée
├── backend/
│   ├── api/             # Fichiers PHP de l'API
│   │   ├── config.php
│   │   ├── login.php
│   │   ├── register.php
│   │   ├── get_salles.php
│   │   ├── create_demande.php
│   │   ├── get_demandes.php
│   │   └── update_demande.php
│   └── database.sql     # Script de création de la BDD
└── README.md
```

## 🔧 Configuration Avancée

### Modifier les informations de connexion MySQL
Éditez `backend/api/config.php`:
```php
private $host = 'localhost';
private $db_name = 'gestion_salles';
private $username = 'root';
private $password = '';
```

### Ajouter des salles
Connectez-vous à phpMyAdmin et exécutez:
```sql
INSERT INTO salles (nom, capacite, equipements) 
VALUES ('Nom de la salle', 30, 'Projecteur, Wifi');
```

## 🐛 Dépannage

### Erreur de connexion à l'API
- Vérifiez que Apache et MySQL sont démarrés dans XAMPP
- Vérifiez l'URL dans `constants.dart`
- Testez l'API dans le navigateur

### Erreur de base de données
- Vérifiez que la base de données `gestion_salles` existe
- Vérifiez les identifiants dans `config.php`

### L'application ne se lance pas
```bash
flutter clean
flutter pub get
flutter run
```

## 📄 API Endpoints

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| POST | /api/login.php | Connexion utilisateur |
| POST | /api/register.php | Inscription utilisateur |
| GET | /api/get_salles.php | Liste des salles |
| POST | /api/create_demande.php | Créer une demande |
| GET | /api/get_demandes.php | Liste des demandes |
| POST | /api/update_demande.php | Mettre à jour une demande |

## 👥 Auteurs

Projet de stage - Groupe Al Omrane

## 📝 Licence

Ce projet est développé dans le cadre d'un stage académique.
