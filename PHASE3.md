# Phase 3 - Notifications Push, CRUD Salles & Pièces Jointes

## 🎉 Nouvelles Fonctionnalités Majeures

### 1. 🔔 Notifications Push en Temps Réel

#### Fonctionnalités
- **Firebase Cloud Messaging (FCM)** intégré
- Notifications push pour les changements de statut des demandes
- Notifications locales pour l'application en premier plan
- Badge et son personnalisés
- Gestion des tokens FCM par utilisateur

#### Utilisation
```dart
// Envoyer une notification
await NotificationService().showDemandeStatusNotification(
  title: 'Demande approuvée',
  body: 'Votre demande pour la Salle A a été approuvée',
  status: 'approuvee',
);
```

#### Configuration Requise
1. Créer un projet Firebase
2. Télécharger `google-services.json`
3. Placer dans `android/app/`
4. Configurer la clé serveur dans `send_notification.php`

Voir **FIREBASE_SETUP.md** pour les instructions détaillées.

---

### 2. 🏢 API Backend Complète pour CRUD des Salles

#### Endpoints Créés

**Ajouter une salle**
```php
POST /api/add_salle.php
{
  "nom": "Salle E",
  "capacite": 15,
  "equipements": "Projecteur, Wifi",
  "disponible": 1
}
```

**Modifier une salle**
```php
POST /api/update_salle.php
{
  "id": 5,
  "nom": "Salle E - Modifiée",
  "capacite": 20,
  "equipements": "Projecteur, Wifi, Tableau",
  "disponible": 1
}
```

**Supprimer une salle**
```php
POST /api/delete_salle.php
{
  "id": 5
}
```

#### Fonctionnalités
- ✅ Ajout de nouvelles salles
- ✅ Modification des salles existantes
- ✅ Suppression avec vérification des réservations actives
- ✅ Toggle disponibilité
- ✅ Validation des données
- ✅ Interface admin complète

#### Interface Utilisateur
- Formulaire d'ajout/modification avec validation
- Switch pour la disponibilité
- Confirmation avant suppression
- Actualisation automatique de la liste
- Messages de succès/erreur

---

### 3. 📎 Pièces Jointes aux Demandes

#### Types de Fichiers Supportés
- **Images:** JPG, JPEG, PNG, GIF
- **Documents:** PDF, DOC, DOCX, TXT
- **Taille max:** 10 MB par fichier

#### Fonctionnalités
- 📷 Prendre une photo avec la caméra
- 🖼️ Sélectionner des images depuis la galerie
- 📄 Joindre des documents
- 📎 Plusieurs fichiers par demande
- 👁️ Prévisualisation des images
- 🗑️ Suppression avant envoi
- 📊 Affichage de la taille des fichiers

#### Utilisation

**Ajouter des pièces jointes lors de la création:**
```dart
// L'écran CreateDemandeWithAttachmentsScreen permet:
- Prendre une photo
- Choisir une image
- Joindre des fichiers
- Voir la liste des fichiers attachés
- Supprimer des fichiers avant envoi
```

**Upload automatique:**
Les fichiers sont automatiquement uploadés après la création de la demande.

#### API Backend

**Upload d'un fichier**
```php
POST /api/upload_attachment.php
FormData:
  - file: [fichier]
  - demande_id: [ID]
```

**Récupérer les pièces jointes**
```php
GET /api/get_attachments.php?demande_id=123
```

---

## 📦 Nouvelles Dépendances

```yaml
# Firebase & Notifications
firebase_core: ^2.24.2
firebase_messaging: ^14.7.9
flutter_local_notifications: ^16.3.0

# Gestion de fichiers
image_picker: ^1.0.7
file_picker: ^6.1.1
dio: ^5.4.0
mime: ^1.0.5
```

## 🗄️ Modifications de la Base de Données

### Nouvelles Tables

**Table: attachments**
```sql
CREATE TABLE attachments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    demande_id INT NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(255) NOT NULL,
    file_type VARCHAR(100),
    file_size INT NOT NULL,
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (demande_id) REFERENCES demandes(id) ON DELETE CASCADE
);
```

**Table: notifications**
```sql
CREATE TABLE notifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    type VARCHAR(50) DEFAULT 'general',
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

**Modification: users**
```sql
ALTER TABLE users ADD COLUMN fcm_token VARCHAR(255) DEFAULT NULL;
```

### Script de Migration
Exécutez `backend/database_phase3.sql` pour mettre à jour votre base de données.

---

## 🚀 Installation

### 1. Mettre à jour les dépendances
```bash
flutter pub get
```

### 2. Configurer Firebase
Suivez les instructions dans **FIREBASE_SETUP.md**

### 3. Mettre à jour la base de données
```sql
mysql -u root -p gestion_salles < backend/database_phase3.sql
```

### 4. Créer le dossier uploads
```bash
mkdir backend/uploads
chmod 777 backend/uploads
```

### 5. Configurer les permissions Android
Dans `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

---

## 📱 Nouveaux Écrans

### CreateDemandeWithAttachmentsScreen
Écran amélioré de création de demande avec support des pièces jointes.

**Accès:** Cliquer sur une salle dans la liste

**Fonctionnalités:**
- Formulaire de réservation complet
- Sélection de dates et heures
- Ajout de pièces jointes
- Prévisualisation des fichiers
- Upload automatique

---

## 🔧 Configuration Backend

### 1. Clé Serveur Firebase
Dans `backend/api/send_notification.php`:
```php
$serverKey = 'VOTRE_CLE_SERVEUR_FIREBASE';
```

### 2. Permissions du dossier uploads
```bash
chmod 777 backend/uploads
```

### 3. Taille maximale d'upload PHP
Dans `php.ini`:
```ini
upload_max_filesize = 10M
post_max_size = 10M
```

---

## 🎯 Flux de Notifications

### Scénario 1: Demande Créée
1. Employé crée une demande
2. Admin reçoit une notification push
3. Notification stockée en BDD

### Scénario 2: Demande Approuvée
1. Admin approuve la demande
2. Employé reçoit une notification push
3. Notification "Demande approuvée"
4. Badge et son

### Scénario 3: Demande Rejetée
1. Admin rejette la demande
2. Employé reçoit une notification push
3. Notification "Demande rejetée"

---

## 📊 Statistiques d'Utilisation

### Fichiers Créés: 15
- 6 fichiers PHP (API)
- 5 fichiers Dart (Services & Écrans)
- 2 fichiers de modèles
- 2 fichiers de documentation

### Lignes de Code: ~2500
- Backend PHP: ~800 lignes
- Frontend Flutter: ~1700 lignes

---

## 🐛 Résolution de Problèmes

### Notifications ne fonctionnent pas
1. Vérifier que Firebase est configuré
2. Vérifier le fichier `google-services.json`
3. Vérifier la clé serveur dans `send_notification.php`
4. Vérifier les permissions Android

### Upload de fichiers échoue
1. Vérifier les permissions du dossier `uploads/`
2. Vérifier `upload_max_filesize` dans php.ini
3. Vérifier que le dossier existe

### CRUD des salles ne fonctionne pas
1. Vérifier les URLs dans `constants.dart`
2. Tester les endpoints avec Postman
3. Vérifier les logs PHP

---

## 🔐 Sécurité

### Fichiers Uploadés
- Validation du type de fichier
- Limite de taille (10 MB)
- Noms de fichiers uniques (uniqid)
- Stockage sécurisé

### Notifications
- Tokens FCM chiffrés
- Authentification requise
- Validation des données

### API
- Authentification par token
- Validation des entrées
- Protection CSRF
- Headers CORS configurés

---

## 📈 Améliorations Futures (Phase 4)

- [ ] Compression automatique des images
- [ ] Prévisualisation des PDF
- [ ] Notifications groupées
- [ ] Historique des notifications
- [ ] Notifications par email
- [ ] Webhooks pour intégrations
- [ ] API REST complète avec Swagger
- [ ] Tests automatisés

---

## 📞 Support

Pour toute question:
1. Consultez FIREBASE_SETUP.md
2. Consultez INSTALLATION.md
3. Vérifiez les logs PHP et Flutter

---

**Version:** 3.0.0  
**Date:** 2024  
**Développé pour:** Groupe Al Omrane  
**Technologies:** Flutter, PHP, MySQL, Firebase
