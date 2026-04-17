# 📱 Guide: Exécuter l'App sur Votre Téléphone

## 🎯 Vue d'Ensemble

Ce guide vous explique comment exécuter l'application SALLES sur votre téléphone physique (Android ou iOS).

---

## ✅ Prérequis

- ✅ Téléphone Android (5.0+) ou iOS (11.0+)
- ✅ Câble USB
- ✅ PC et téléphone sur le même réseau WiFi
- ✅ Backend configuré et fonctionnel
- ✅ Flutter installé

---

## 📋 MÉTHODE 1: Via WiFi (Recommandé)

### Étape 1: Trouver l'IP de Votre PC

#### Windows
```bash
ipconfig
```
Cherchez **"Adresse IPv4"** (exemple: `192.168.1.100`)

#### Mac/Linux
```bash
ifconfig
# ou
ip addr show
```

**Notez cette adresse IP!** Vous en aurez besoin.

---

### Étape 2: Configurer le Backend

#### A. Modifier config.php

Ouvrez `backend/api/config.php` et vérifiez:

```php
<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json; charset=UTF-8");

// Configuration base de données
$host = "localhost";
$db_name = "gestion_salles";
$username = "root";
$password = ""; // Votre mot de passe MySQL

try {
    $conn = new PDO("mysql:host=$host;dbname=$db_name;charset=utf8", $username, $password);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch(PDOException $e) {
    echo json_encode(["success" => false, "message" => "Erreur de connexion: " . $e->getMessage()]);
    exit();
}
?>
```

#### B. Démarrer les Serveurs

**Terminal 1 - API PHP:**
```bash
cd backend/api
php -S 0.0.0.0:8000
```
✅ Serveur démarré sur: `http://0.0.0.0:8000`

**Terminal 2 - WebSocket:**
```bash
cd backend
php websocket_server.php
```
✅ WebSocket démarré sur: `ws://0.0.0.0:8080`

**Terminal 3 - MySQL:**
Assurez-vous que MySQL est démarré:
```bash
# Windows
net start MySQL80

# Mac
brew services start mysql

# Linux
sudo systemctl start mysql
```

---

### Étape 3: Configurer l'App Flutter

#### A. Modifier constants.dart

Ouvrez `lib/utils/constants.dart`:

```dart
class ApiConstants {
  // ⚠️ REMPLACEZ 192.168.1.100 PAR VOTRE IP
  static const String baseUrl = 'http://192.168.1.100:8000/api';
  static const String wsUrl = 'ws://192.168.1.100:8080';
  
  static const String login = '$baseUrl/login.php';
  static const String register = '$baseUrl/register.php';
  static const String getSalles = '$baseUrl/get_salles.php';
  static const String createDemande = '$baseUrl/create_demande.php';
  static const String getDemandes = '$baseUrl/get_demandes.php';
  static const String updateDemande = '$baseUrl/update_demande.php';
  
  static const String addSalle = '$baseUrl/add_salle.php';
  static const String updateSalle = '$baseUrl/update_salle.php';
  static const String deleteSalle = '$baseUrl/delete_salle.php';
  
  static const String uploadAttachment = '$baseUrl/upload_attachment.php';
  static const String getAttachments = '$baseUrl/get_attachments.php';
  
  static const String sendNotification = '$baseUrl/send_notification.php';
  static const String updateFcmToken = '$baseUrl/update_fcm_token.php';
}
```

**Exemple avec IP 192.168.1.100:**
```dart
static const String baseUrl = 'http://192.168.1.100:8000/api';
static const String wsUrl = 'ws://192.168.1.100:8080';
```

#### B. Sauvegarder les Modifications

```bash
# Sauvegarder
Ctrl + S

# Vérifier qu'il n'y a pas d'erreurs
flutter analyze
```

---

### Étape 4: Préparer Votre Téléphone

#### Android

1. **Activer le Mode Développeur:**
   - Allez dans **Paramètres** → **À propos du téléphone**
   - Tapez **7 fois** sur **Numéro de build**
   - Message: "Vous êtes maintenant développeur!"

2. **Activer le Débogage USB:**
   - Retournez aux **Paramètres**
   - Allez dans **Options pour les développeurs**
   - Activez **Débogage USB**
   - Activez **Installer via USB** (si disponible)

3. **Connecter le Téléphone:**
   - Branchez le câble USB
   - Sur le téléphone, autorisez le débogage USB
   - Cochez "Toujours autoriser depuis cet ordinateur"

#### iOS

1. **Connecter l'iPhone:**
   - Branchez le câble Lightning/USB-C
   - Déverrouillez l'iPhone
   - Faites confiance à l'ordinateur

2. **Configurer Xcode (Mac uniquement):**
   - Ouvrez Xcode
   - Allez dans **Preferences** → **Accounts**
   - Ajoutez votre Apple ID
   - Créez un certificat de développement

---

### Étape 5: Vérifier la Connexion

#### A. Vérifier le Téléphone

```bash
flutter devices
```

**Résultat attendu:**
```
2 connected devices:

SM G973F (mobile) • 1234567890ABCDEF • android-arm64 • Android 12 (API 31)
sdk gphone64 x86 64 (mobile) • emulator-5554 • android-x64 • Android 14 (API 34) (emulator)
```

#### B. Vérifier le Réseau

⚠️ **IMPORTANT:** PC et téléphone doivent être sur le **MÊME WiFi**!

**Tester depuis le téléphone:**
1. Ouvrez le navigateur sur votre téléphone
2. Allez sur: `http://VOTRE_IP:8000/api/get_salles.php`
3. Vous devriez voir du JSON

**Si ça ne marche pas:**
- Vérifiez que vous êtes sur le même WiFi
- Désactivez le pare-feu temporairement
- Vérifiez que les serveurs sont démarrés

---

### Étape 6: Lancer l'App

```bash
flutter run
```

**Sélectionnez votre téléphone:**
```
Multiple devices found:
[1]: SM G973F (1234567890ABCDEF)
[2]: sdk gphone64 x86 64 (emulator-5554)

Please choose one (or "q" to quit): 1
```

**Compilation et Installation:**
```
Launching lib\main.dart on SM G973F in debug mode...
Running Gradle task 'assembleDebug'...
✓ Built build\app\outputs\flutter-apk\app-debug.apk
Installing build\app\outputs\flutter-apk\app-debug.apk...
Debug service listening on ws://127.0.0.1:xxxxx/ws
Syncing files to device SM G973F...
```

✅ **L'app s'ouvre sur votre téléphone!**

---

## 📋 MÉTHODE 2: Via USB (Port Forwarding)

Si vous ne pouvez pas utiliser le même WiFi:

### Android

```bash
# Activer le port forwarding
adb reverse tcp:8000 tcp:8000
adb reverse tcp:8080 tcp:8080
```

Dans `constants.dart`:
```dart
static const String baseUrl = 'http://localhost:8000/api';
static const String wsUrl = 'ws://localhost:8080';
```

### iOS

iOS gère automatiquement, utilisez `localhost`:
```dart
static const String baseUrl = 'http://localhost:8000/api';
static const String wsUrl = 'ws://localhost:8080';
```

---

## 🔧 Configuration Pare-feu

### Windows Firewall

```bash
# Autoriser PHP
netsh advfirewall firewall add rule name="PHP Server" dir=in action=allow protocol=TCP localport=8000

# Autoriser WebSocket
netsh advfirewall firewall add rule name="WebSocket Server" dir=in action=allow protocol=TCP localport=8080
```

### Mac Firewall

```bash
# Désactiver temporairement
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate off

# Réactiver après
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
```

---

## 🐛 Dépannage

### Problème 1: "Connection refused"

**Cause:** Le téléphone ne peut pas atteindre le serveur

**Solutions:**
1. Vérifiez que PC et téléphone sont sur le même WiFi
2. Vérifiez l'IP dans `constants.dart`
3. Testez l'URL dans le navigateur du téléphone
4. Désactivez le pare-feu temporairement
5. Redémarrez les serveurs avec `0.0.0.0` au lieu de `localhost`

### Problème 2: "Device not found"

**Cause:** Flutter ne détecte pas le téléphone

**Solutions:**
```bash
# Android
adb devices
adb kill-server
adb start-server

# Reconnectez le câble USB
# Réautorisez le débogage USB
```

### Problème 3: "API returns 404"

**Cause:** Mauvaise URL ou serveur non démarré

**Solutions:**
1. Vérifiez que le serveur PHP est démarré
2. Testez l'URL dans le navigateur
3. Vérifiez les logs du serveur PHP

### Problème 4: "WebSocket connection failed"

**Cause:** WebSocket non accessible

**Solutions:**
1. Vérifiez que `websocket_server.php` est démarré
2. Testez avec `wscat -c ws://VOTRE_IP:8080`
3. Vérifiez le pare-feu

### Problème 5: "Hot reload not working"

**Cause:** Normal sur téléphone physique

**Solution:**
```bash
# Utilisez hot restart au lieu de hot reload
# Dans le terminal: r (restart)
```

---

## 📊 Checklist Complète

### Avant de Lancer

- [ ] MySQL démarré
- [ ] Base de données créée (`gestion_salles`)
- [ ] IP du PC notée
- [ ] Serveur PHP démarré (`php -S 0.0.0.0:8000`)
- [ ] WebSocket démarré (`php websocket_server.php`)
- [ ] `constants.dart` modifié avec la bonne IP
- [ ] Téléphone en mode développeur
- [ ] Débogage USB activé
- [ ] Téléphone connecté via USB
- [ ] PC et téléphone sur le même WiFi
- [ ] Pare-feu configuré
- [ ] `flutter devices` détecte le téléphone

### Pendant l'Exécution

- [ ] App installée sur le téléphone
- [ ] Splash screen s'affiche
- [ ] Login screen s'affiche
- [ ] Connexion API fonctionne
- [ ] WebSocket connecté
- [ ] Notifications fonctionnent

---

## 🎯 Script Automatique

Utilisez le script fourni:

```bash
# Windows
configure_phone.bat

# Le script va:
# 1. Trouver votre IP
# 2. Afficher les URLs à configurer
# 3. Donner les commandes à exécuter
```

---

## 📱 Test de Connexion

### Test 1: API

Depuis le navigateur du téléphone:
```
http://VOTRE_IP:8000/api/get_salles.php
```

**Résultat attendu:** JSON avec la liste des salles

### Test 2: WebSocket

Installez une app de test WebSocket sur votre téléphone et connectez-vous à:
```
ws://VOTRE_IP:8080
```

**Résultat attendu:** Connexion établie

---

## 🚀 Commandes Rapides

### Démarrage Complet

**Terminal 1:**
```bash
cd backend/api
php -S 0.0.0.0:8000
```

**Terminal 2:**
```bash
cd backend
php websocket_server.php
```

**Terminal 3:**
```bash
flutter run
```

### Arrêt

```bash
# Arrêter l'app
q

# Arrêter les serveurs
Ctrl + C (dans chaque terminal)
```

---

## 💡 Conseils

1. **Gardez les terminaux ouverts** pendant que vous testez
2. **Utilisez Hot Restart** (r) au lieu de Hot Reload
3. **Vérifiez les logs** dans les terminaux pour déboguer
4. **Testez d'abord dans le navigateur** du téléphone
5. **Notez votre IP** pour ne pas la chercher à chaque fois

---

## 📞 Support

Si vous rencontrez des problèmes:

1. Vérifiez la checklist ci-dessus
2. Consultez la section Dépannage
3. Vérifiez les logs des serveurs
4. Testez les URLs dans le navigateur

---

## ✅ Résumé

**Configuration minimale:**
```dart
// constants.dart
static const String baseUrl = 'http://VOTRE_IP:8000/api';
static const String wsUrl = 'ws://VOTRE_IP:8080';
```

**Commandes:**
```bash
# Terminal 1
cd backend/api && php -S 0.0.0.0:8000

# Terminal 2
cd backend && php websocket_server.php

# Terminal 3
flutter run
```

**Vérifications:**
- ✅ Même WiFi
- ✅ Débogage USB activé
- ✅ Serveurs démarrés
- ✅ IP correcte dans constants.dart

---

**Bonne chance! 🎉**
