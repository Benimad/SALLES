# 📚 SALLES Developer Quick Reference

## 🚀 Start Developing in 60 Seconds

### Option A: Docker (Recommended)
```bash
cd salles
docker-compose up -d
# Services ready at:
# API: http://localhost:8000/api/
# WS: ws://localhost:8080
# DB: http://localhost:8881 (phpmyadmin)
```

### Option B: Manual Setup
```bash
# Terminal 1
cd salles/backend
composer install
php websocket_server.php

# Terminal 2
cd salles/backend/api
php -S localhost:8000

# Terminal 3
cd salles
flutter pub get
flutter run
```

---

## 🔑 Default Credentials

| Role | Email | Password | Access |
|------|-------|----------|--------|
| Admin | admin@alomrane.ma | password | Full system access |
| Demo User | Can register | Any password | Limited to employee features |

---

## 📁 File Structure Quick Guide

```
lib/
├── services/
│   ├── api_service.dart       ← API calls to backend
│   ├── auth_service.dart      ← Login/session management
│   ├── websocket_service.dart ← Real-time updates
│   └── notification_service.dart ← Push notifications
├── screens/
│   ├── login_screen.dart      ← Auth screens
│   ├── home_screen.dart       ← User dashboard
│   ├── admin_screen.dart      ← Admin dashboard
│   └── ... (13 total screens)
├── models/
│   ├── user.dart
│   ├── salle.dart
│   ├── demande.dart
│   └── attachment.dart
└── utils/
    └── constants.dart         ← API URLs & config

backend/
├── api/
│   ├── login.php              ← Authentication
│   ├── create_demande.php     ← Booking creation
│   ├── get_salles.php         ← Room listing
│   └── ... (10 total endpoints)
├── websocket_server.php       ← Real-time server
└── database.sql               ← Schema
```

---

##🔧 Common Development Tasks

### Modify API Endpoint URL
**File:** `lib/utils/constants.dart`
```dart
static const String baseUrl = 'http://10.0.2.2/salles/api'; // Android
// OR
static const String baseUrl = 'http://192.168.1.X/salles/api'; // Physical device
```

### Add New API Endpoint
**Backend:** `backend/api/new_endpoint.php`
```php
<?php
require_once 'config.php';
$db = getDB();

try {
  $input = json_decode(file_get_contents("php://input"), true);
  // Your logic here
  echo ApiResponse::success($data, 'Message');
} catch(Exception $e) {
  echo ApiResponse::error($e->getMessage());
}
?>
```

**Frontend:** `lib/services/api_service.dart`
```dart
Future<List<MyData>> getMyData() async {
  try {
    final response = await http.get(
      Uri.parse(ApiConstants.myEndpoint),
      headers: await _getHeaders(),
    );
    // Handle response
  } catch (e) {
    debugPrint('Error: $e');
    return [];
  }
}
```

### Add New Flutter Screen
1. Create `lib/screens/my_screen.dart`
2. Add to `lib/main.dart` routes
3. Create corresponding service if needed
4. Test navigation

### Send Real-Time Message (WebSocket)
```dart
WebSocketService().sendNewDemande({
  'id': demandeId,
  'room': 'Conference A',
  'timestamp': DateTime.now().toString(),
});

// Listen for updates
WebSocketService().stream.listen((data) {
  if (data['type'] == 'demande_update') {
    setState(() { /* Update UI */ });
  }
});
```

### Add Validation
```php
// Backend validation
$errors = [];
if (empty($input['email'])) $errors['email'] = 'Email required';
if (!filter_var($input['email'], FILTER_VALIDATE_EMAIL)) 
    $errors['email'] = 'Invalid email';

if (!empty($errors)) {
  echo ApiResponse::validation($errors);
  exit();
}
```

---

## 🧪 Testing Commands

```bash
# Flutter unit tests
flutter test

# Build APK for Android
flutter build apk --release

# Build iOS app
flutter build ios --release

# Test API endpoint
curl -X GET http://localhost:8000/api/get_salles.php

# Test WebSocket connection
wscat -c ws://localhost:8080
```

---

## 🐛 Debug Commands

```bash
# Flutter verbose logging
flutter run -v

# Flutter inspect widget
flutter inspect

# PHP error logs
tail -f /var/log/php_errors.log

# MySQL logs
tail -f /var/log/mysql/error.log

# WebSocket server logs
php websocket_server.php | tee output.log
```

---

## 📊 Database Quick Queries

```sql
-- Create test data
INSERT INTO users (nom, prenom, email, password, role) 
VALUES ('Test', 'User', 'test@example.com', 
        '$2y$10$...', 'employe');

-- Get all pending requests
SELECT * FROM demandes WHERE statut = 'en_attente';

-- Get bookings for specific room
SELECT * FROM demandes WHERE salle_id = 1;

-- Most booked rooms
SELECT salle_id, COUNT(*) as count FROM demandes 
GROUP BY salle_id ORDER BY count DESC LIMIT 5;
```

---

## 🚀 Performance Tips

1. **Add database indices**
   ```sql
   ALTER TABLE demandes ADD INDEX idx_check_conflicts 
   (salle_id, date_debut, date_fin, statut);
   ```

2. **Implement caching** in Flutter
   ```dart
   final cache = <String, List<Salle>>{};
   List<Salle> getSallesFromCache() => cache['salles'] ?? [];
   ```

3. **Lazy load lists**
   ```dart
   ListView.builder(
     itemCount: items.length,
     itemBuilder: (context, index) => ItemTile(item: items[index]),
   )
   ```

4. **Use pagination**
   ```dart
   ApiService().getDemandes(limit: 20, offset: 0);
   ```

---

## 🔐 Security Checklist

- ✅ Use HTTPS in production
- ✅ Validate all inputs
- ✅ Use prepared statements
- ✅ Hash passwords with bcrypt
- ✅ Set secure CORS headers
- ✅ Implement rate limiting
- ✅ Log security events
- ✅ Use strong encryption keys
- ✅ Regularly update dependencies
- ✅ Conduct penetration testing

---

## 📱 Device-Specific Config

### Android Emulator
```dart
// lib/utils/constants.dart
static const String baseUrl = 'http://10.0.2.2/salles/api';
static const String wsUrl = 'ws://10.0.2.2:8080';
```

### Physical Android Device
```dart
// lib/utils/constants.dart
static const String baseUrl = 'http://192.168.1.100/salles/api'; // Your IP
static const String wsUrl = 'ws://192.168.1.100:8080';
```

### iOS Device
```dart
// lib/utils/constants.dart
static const String baseUrl = 'http://localhost/salles/api';
static const String wsUrl = 'ws://localhost:8080';
```

---

## 📞 Helpful Commands

```bash
# Check what's running on port 8000
lsof -i :8000

# Kill process on port 8000
kill -9 $(lsof -t -i :8000)

# Find your local IP
hostname -I

# Test database connection
mysql -u root -p gestion_salles -e "SELECT 1"

# Check PHP version
php -v

# Check composer installation
composer --version
```

---

## 🎯 Common Issues & Solutions

**Issue: "WebSocket connection refused"**
```
Solution:
1. Check WebSocket server is running: php websocket_server.php
2. Check port 8080 is open: lsof -i :8080
3. Update API URL in constants.dart
```

**Issue: "Database connection error"**
```
Solution:
1. Check MySQL is running: sudo service mysql status
2. Verify credentials in .env
3. Check database exists: mysql -u root -p -e "SHOW DATABASES"
```

**Issue: "Flutter build fails"**
```
Solution:
1. Clean build: flutter clean
2. Get dependencies: flutter pub get
3. Check SDK: flutter doctor
4. Update SDK: flutter upgrade
```

**Issue: "CORS error in API calls"**
```
Solution:
1. Check CORS headers in backend/api/config.php
2. Verify Access-Control-Allow-Origin
3. Check request headers in browser DevTools
```

---

## 📚 Documentation Links

- Full Guide: [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md)
- Deployment: [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
- WebSocket: [WEBSOCKET_IMPLEMENTATION.md](WEBSOCKET_IMPLEMENTATION.md)
- README: [README.md](README.md)

---

## ✅ Pre-deployment Checklist

- [ ] Test login with valid credentials
- [ ] Test create booking
- [ ] Test admin approval
- [ ] Verify WebSocket connection
- [ ] Check push notifications
- [ ] Test with 100+ concurrent users
- [ ] Performance test
- [ ] Security audit
- [ ] Database backup test
- [ ] LoadBalancing ready

---

## 🎓 Learning Path

1. **Week 1:** Understand Flutter basics & services
2. **Week 2:** Learn API integration & authentication
3. **Week 3:** Master WebSocket real-time features
4. **Week 4:** Deploy & scale the application

---

## 🔗 Useful Links

- [Flutter Docs](https://docs.flutter.dev)
- [PHP Manual](https://www.php.net/manual)
- [MySQL Docs](https://dev.mysql.com/doc)
- [Ratchet WebSocket](http://socketo.me)
- [Firebase FCM](https://firebase.google.com/docs/cloud-messaging)

---

**Happy Coding!** 🚀

Last Updated: April 2026
