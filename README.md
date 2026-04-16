# 🏢 SALLES - Room Booking & Management System
## Groupe Al Omrane

![Version](https://img.shields.io/badge/Version-1.0.0-blue)
![Status](https://img.shields.io/badge/Status-Production%20Ready-green)
![Flutter](https://img.shields.io/badge/Flutter-3.x-blue)
![Backend](https://img.shields.io/badge/Backend-PHP%207.4+-purple)

A professional room booking and management system for Groupe Al Omrane enabling employees to request rooms and administrators to manage approvals with real-time updates.

---

## 📋 Quick Links

- 🚀 **[Quick Start Guide](#quick-start)**
- 📚 **[Full Documentation](IMPLEMENTATION_GUIDE.md)**
- 🔌 **[WebSocket Guide](WEBSOCKET_IMPLEMENTATION.md)**
- 💻 **[Local Development Setup](#local-setup)**
- 🚢 **[Production Deployment](#deploying-to-production)**

---

## ✨ Key Features

### 👥 For End Users
- ✅ Secure user authentication with registration
- ✅ Browse available rooms with real-time availability
- ✅ Create booking requests with automatic conflict detection
- ✅ Track booking status with instant notifications
- ✅ Calendar view for easy date selection
- ✅ Attach documents to requests

### 👨‍💼 For Administrators
- ✅ Dashboard with pending booking requests
- ✅ One-click approve/reject with reasons
- ✅ Real-time notifications for new requests
- ✅ Complete room management (CRUD)
- ✅ Analytics dashboard with booking statistics
- ✅ User management and access control

### ⚡ System Features
- ✅ **Real-time Communication** via WebSocket
- ✅ **Push Notifications** via Firebase FCM
- ✅ **Automatic Conflict Detection** with real-time availability
- ✅ **Offline Support** with synchronization
- ✅ **Professional Design** with Al Omrane branding
- ✅ **Complete Audit Trail** of all requests

---

## 🛠 Tech Stack

| Component | Technology | Version |
|-----------|-----------|---------|
| **Frontend** | Flutter/Dart | 3.x |
| **Backend** | PHP | 7.4+ |
| **Database** | MySQL | 8.0+ |
| **Real-time** | Ratchet WebSocket | - |
| **Notifications** | Firebase FCM | - |
| **State Mgmt** | Provider | 6.x |
| **API** | RESTful + WebSocket | - |

---

## 🚀 Quick Start

### Prerequisites
```bash
# Required
- PHP 7.4+
- MySQL 8.0+
- Flutter 3.x
- Composer (for PHP dependencies)

# Optional
- Postman (for API testing)
- Docker (for containerized deployment)
```

### 1️⃣ Backend Setup (30 seconds)

```bash
# Navigate to backend
cd backend

# Create database
mysql -u root -p < database.sql

# Install dependencies
composer install

# Start WebSocket server (Terminal 1)
php websocket_server.php
# Output: WebSocket server started on port 8080 ✅

# Start PHP server (Terminal 2)
cd api
php -S localhost:8000
# Output: Development Server running at http://localhost:8000 ✅
```

### 2️⃣ Flutter Setup (1 minute)

```bash
# Get dependencies
flutter pub get

# Update API configuration in lib/utils/constants.dart
# For Android Emulator:
# baseUrl = 'http://10.0.2.2/salles/api'
# wsUrl = 'ws://10.0.2.2:8080'

# Run the app
flutter run

# Select your device when prompted
```

### 3️⃣ First Login ✅

```
Email:    admin@alomrane.ma
Password: password
Role:     Admin
```

---

## 📁 Project Structure

```
salles/
├── backend/
│   ├── api/
│   │   ├── login.php                 # Authentication
│   │   ├── register.php              # User registration
│   │   ├── get_salles.php            # Room listing
│   │   ├── create_demande.php        # Booking creation
│   │   ├── get_demandes.php          # Booking retrieval
│   │   ├── update_demande.php        # Booking approval
│   │   ├── check_availability.php    # Real-time checking
│   │   └── ...                       # Other endpoints
│   ├── websocket_server.php          # Real-time server
│   ├── database.sql                  # Database schema
│   └── composer.json                 # PHP dependencies
│
├── lib/
│   ├── main.dart                     # App entry point
│   ├── screens/
│   │   ├── login_screen.dart         # User login
│   │   ├── home_screen.dart          # User dashboard
│   │   ├── salles_screen.dart        # Room listing
│   │   ├── create_demande_screen.dart # Booking form
│   │   ├── demandes_screen.dart      # Booking history
│   │   ├── admin_screen.dart         # Admin dashboard
│   │   └── ...
│   ├── services/
│   │   ├── api_service.dart          # API communication
│   │   ├── auth_service.dart         # Authentication
│   │   ├── websocket_service.dart    # Real-time updates
│   │   └── notification_service.dart # Notifications
│   ├── models/
│   │   ├── user.dart
│   │   ├── salle.dart
│   │   ├── demande.dart
│   │   └── attachment.dart
│   └── utils/
│       ├── constants.dart            # Configuration
│       └── theme.dart                # UI Theme
│
├── android/                          # Android configuration
├── ios/                              # iOS configuration
├── pubspec.yaml                      # Flutter dependencies
├── README.md                         # This file
├── IMPLEMENTATION_GUIDE.md           # Complete technical guide
└── WEBSOCKET_IMPLEMENTATION.md       # Real-time details
```

---

## 🔌 API Quick Reference

### Authentication
```bash
# Login
curl -X POST http://localhost:8000/api/login.php \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@alomrane.ma","password":"password"}'

# Register
curl -X POST http://localhost:8000/api/register.php \
  -H "Content-Type: application/json" \
  -d '{"nom":"Dupont","prenom":"Jean","email":"jean@example.com","password":"pass123"}'
```

### Rooms
```bash
# Get all rooms
curl -X GET http://localhost:8000/api/get_salles.php \
  -H "Authorization: Bearer YOUR_TOKEN"

# Check availability
curl -X POST http://localhost:8000/api/check_availability.php \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"salle_id":1,"date_debut":"2026-05-01","heure_debut":"09:00","heure_fin":"11:00"}'
```

### Bookings
```bash
# Create booking
curl -X POST http://localhost:8000/api/create_demande.php \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"user_id":1,"salle_id":1,"date_debut":"2026-05-01","date_fin":"2026-05-01","heure_debut":"09:00","heure_fin":"11:00","motif":"Réunion équipe"}'

# Get my bookings
curl -X GET "http://localhost:8000/api/get_demandes.php?user_id=1"

# Admin: Get all bookings
curl -X GET "http://localhost:8000/api/get_demandes.php?admin=1"

# Approve booking
curl -X POST http://localhost:8000/api/update_demande.php \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"demande_id":1,"statut":"approuvee"}'
```

---

## 🚢 Deploying to Production

### Pre-deployment Checklist
- [ ] Update database credentials
- [ ] Configure Firebase credentials
- [ ] Set production API URL
- [ ] Enable HTTPS/SSL
- [ ] Set up backups
- [ ] Configure firewall
- [ ] Test end-to-end
- [ ] Create backup admin account

### Docker Deployment
```bash
# Build Docker image
docker-compose build

# Run containers
docker-compose up -d

# Check logs
docker-compose logs -f

# Stop containers
docker-compose down
```

### Manual Server Deployment
```bash
# 1. Connect to server
ssh user@yourserver.com

# 2. Clone repository
git clone <repo-url>
cd salles

# 3. Setup database
mysql -u root -p < backend/database.sql

# 4. Install dependencies
composer install

# 5. Configure environment
cp .env.example .env
nano .env  # Edit with production values

# 6. Start services (using supervisor or systemd)
sudo systemctl start salles-websocket
sudo systemctl start salles-api
```

---

## 🧪 Testing

### Running Tests
```bash
# Flutter unit tests
flutter test

# Flutter widget tests
flutter test test/

# API testing with Postman
# Import postman_collection.json
```

### Manual Testing Checklist
- [ ] Login with correct credentials
- [ ] Login rejects wrong password
- [ ] Create booking for available time
- [ ] Get error for overlapping bookings
- [ ] Admin can approve requests
- [ ] User receives notifications
- [ ] WebSocket real-time updates work
- [ ] File attachments work
- [ ] Calendar navigation works
- [ ] Logout clears session

---

## 🔐 Security Notes

### Implemented
- ✅ Password hashing with bcrypt
- ✅ SQL injection prevention
- ✅ CORS headers
- ✅ Token validation
- ✅ Input sanitization

### Before Production
- [ ] Enable HTTPS/SSL
- [ ] Implement JWT tokens
- [ ] Set up rate limiting
- [ ] Enable access logging
- [ ] Configure firewall rules
- [ ] Set up intrusion detection
- [ ] Implement API key rotation
- [ ] Regular security audits

---

## 🐛 Troubleshooting

### WebSocket Issues
```bash
# Check if running
netstat -an | grep 8080

# Restart server
php backend/websocket_server.php

# Check for port conflicts
lsof -i :8080
```

### Database Issues
```bash
# Test connection
mysql -u root -p -h localhost

# Check database
mysql> USE gestion_salles;
mysql> SHOW TABLES;
```

### Flutter Build Issues
```bash
# Clean build
flutter clean
flutter pub get
flutter run -v  # Verbose for debugging
```

### API Issues
```bash
# Enable PHP error reporting
php -i | grep error_reporting

# Check PHP error logs
tail -f /var/log/php-errors.log

# Test API endpoint
curl -X GET http://localhost:8000/api/get_salles.php
```

---

## 📊 System Requirements

### Minimum
- RAM: 2GB
- Storage: 500MB
- CPU: 2 cores

### Recommended
- RAM: 4GB+
- Storage: 2GB
- CPU: 4+ cores
- Network: 10Mbps

---

## 📞 Support

For technical issues:
1. Check [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md)
2. Review error logs
3. Test with Postman
4. Contact development team

**Email:** imadelberrioui@gmail.com
**Phone:** +212 703 43 89 29

---

## 📝 License

Internal Use Only - Groupe Al Omrane
All rights reserved © 2024-2025

---

## 🎉 Getting Help

- **[Full Documentation](IMPLEMENTATION_GUIDE.md)** - Complete technical reference
- **[WebSocket Docs](WEBSOCKET_IMPLEMENTATION.md)** - Real-time communication
- **[API Endpoints](#-api-quick-reference)** - API reference
- **Flutter Docs** - https://docs.flutter.dev

---

**Last Updated:** April 2026
**Status:** ✅ Production Ready
**Version:** 1.0.0

---

*Happy Booking! 🎊*

