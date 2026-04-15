# WebSocket Real-Time Communication

## 🎯 Overview
Implementation of WebSocket for real-time bidirectional communication between Flutter app and PHP backend.

## 📦 Features
- **Real-time notifications** for new booking requests
- **Live status updates** when admin approves/rejects requests
- **Auto-reconnection** on connection loss
- **User authentication** via WebSocket
- **Broadcast messaging** to specific users or admins

## 🚀 Setup

### Backend (PHP)

1. **Install Composer dependencies**:
```bash
cd backend
composer install
```

2. **Start WebSocket server**:
```bash
php websocket_server.php
```

Server runs on `ws://localhost:8080`

### Frontend (Flutter)

1. **Add dependency** (already added):
```yaml
dependencies:
  web_socket_channel: ^2.4.0
```

2. **Update API constants** in `lib/utils/constants.dart`:
```dart
static const String wsUrl = 'ws://your-server.com:8080';
```

3. **Initialize WebSocket** after login:
```dart
import 'package:salles/services/websocket_service.dart';

// After successful login
final userId = await AuthService().getUserId();
WebSocketService().connect(userId);

// Listen to messages
WebSocketService().stream.listen((data) {
  if (data['type'] == 'new_demande') {
    // Show notification for new booking
  } else if (data['type'] == 'demande_update') {
    // Update booking status in real-time
  }
});
```

## 📡 Message Types

### 1. Authentication
```json
{
  "type": "auth",
  "userId": "123"
}
```

### 2. New Booking Request
```json
{
  "type": "new_demande",
  "data": {
    "id": "456",
    "salle": "Salle A",
    "user": "John Doe",
    "date": "2024-01-15"
  }
}
```

### 3. Booking Status Update
```json
{
  "type": "demande_update",
  "demandeId": "456",
  "status": "approuvee"
}
```

## 🔧 Usage Examples

### Send New Booking Notification
```dart
WebSocketService().sendNewDemande({
  'id': demande.id,
  'salle': demande.salle,
  'user': demande.userName,
  'date': demande.date,
});
```

### Send Status Update
```dart
WebSocketService().sendDemandeUpdate(demandeId, 'approuvee');
```

### Listen to Real-time Updates
```dart
StreamBuilder<Map<String, dynamic>>(
  stream: WebSocketService().stream,
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      final message = snapshot.data!;
      // Handle message
    }
    return YourWidget();
  },
)
```

## 🛡️ Production Deployment

### 1. Use Secure WebSocket (WSS)
```dart
static const String wsUrl = 'wss://your-server.com:8080';
```

### 2. Configure SSL Certificate
```bash
# Generate SSL certificate
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365
```

### 3. Run as Background Service
```bash
# Using systemd
sudo nano /etc/systemd/system/salles-websocket.service
```

```ini
[Unit]
Description=Salles WebSocket Server
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/var/www/salles/backend
ExecStart=/usr/bin/php websocket_server.php
Restart=always

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl enable salles-websocket
sudo systemctl start salles-websocket
```

## 📊 Benefits

✅ **Instant Updates** - No polling required
✅ **Reduced Server Load** - Efficient bidirectional communication
✅ **Better UX** - Real-time notifications without refresh
✅ **Scalable** - Handles multiple concurrent connections
✅ **Auto-reconnect** - Maintains connection stability

## 🔍 Monitoring

Check WebSocket server logs:
```bash
tail -f /var/log/salles-websocket.log
```

Test connection:
```bash
wscat -c ws://localhost:8080
```

## 🎨 Integration with UI

The WebSocket service integrates seamlessly with the Al Omrane UI:
- Real-time badge updates on notification icon
- Live status changes in booking cards
- Instant admin notifications for new requests
- Auto-refresh of booking lists

## 📝 Notes

- WebSocket runs on port 8080 (configurable)
- Requires Ratchet PHP library
- Auto-reconnects every 5 seconds on disconnect
- Broadcasts to all connected clients (can be filtered by user role)
