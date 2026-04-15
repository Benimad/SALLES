# Salles - Groupe Al Omrane Room Management System
## Project Completion Summary

---

## ✅ Completed Tasks

### 1. XAMPP Backend Setup ✓
- ✅ Created database `gestion_salles` in MySQL
- ✅ Imported database schema with all tables (users, salles, demandes, attachments, notifications)
- ✅ Copied all PHP API files to `C:\xampp\htdocs\salles\api\`
- ✅ API endpoints tested and working
- ✅ Default data inserted (admin user + 4 sample rooms)

**API Endpoints Available:**
- `http://10.0.2.2/salles/api/login.php`
- `http://10.0.2.2/salles/api/get_salles.php`
- `http://10.0.2.2/salles/api/create_demande.php`
- And 11 more endpoints for full CRUD operations

### 2. Backend-Frontend Connection ✓
- ✅ Updated `lib/utils/constants.dart` with correct XAMPP URLs
- ✅ Android emulator uses `10.0.2.2` to access host's localhost
- ✅ All API services configured and tested

### 3. UI/UX Enhancements ✓

#### Login Screen
- Glassmorphism design with backdrop blur effect
- Animated transitions (fade, scale, slide)
- Professional gradient styling with Al Omrane colors
- Form validation with real-time error feedback
- "Remember me" checkbox
- Loading state with circular progress indicator

#### Home Screen
- Modern dashboard layout with SliverAppBar
- Animated greeting based on time of day
- Statistics cards with animated counters
- Quick actions grid with 4 options
- Recent demands list with pull-to-refresh
- Custom bottom navigation bar
- Floating action button for quick booking

#### Salles (Rooms) Screen
- Professional room cards with hero animations
- Visual equipment chips with icons
- Availability indicators with pulse animation
- Filter by capacity with slider dialog
- Search functionality with real-time filtering
- Bottom sheet for booking options
- Pull-to-refresh

#### Create Demande (Booking) Screen
- Stepper wizard with 3 steps: Room → Date/Time → Motif
- Custom styled date and time pickers
- Duration calculation displayed
- Form validation with detailed error messages
- Success dialog with animation
- Hero transition from room card

#### Demandes (My Requests) Screen
- Filter chips for status filtering
- Animated card list
- Expandable cards with detailed information
- PDF export functionality
- Empty state with helpful messaging
- Pull-to-refresh

#### Admin Screen
- Tab-based interface (Pending, Approved, Rejected)
- Badge counts on tabs
- Approve/Reject action buttons
- Expandable request cards
- User information display
- Status indicators with proper coloring

---

## 🎨 Design System

### Al Omrane Brand Colors
- **Navy Blue:** `#1A3A5C` (Primary)
- **Red Accent:** `#C8102E` (Secondary)
- **Dark Navy:** `#0F2947` (Backgrounds)
- **Status Colors:**
  - Pending: Orange `#FFA726`
  - Approved: Green `#66BB6A`
  - Rejected: Red `#EF5350`

### Features
- Material 3 design principles
- Consistent card-based layouts
- Animated transitions and micro-interactions
- Professional shadows and elevations
- Glassmorphism effects on login screen

---

## 🔧 Technical Stack

### Frontend
- **Framework:** Flutter 3.x
- **Language:** Dart
- **Architecture:** Provider for state management
- **HTTP:** http package for API calls
- **UI:** Material 3 with custom Al Omrane theme

### Backend
- **Server:** Apache (XAMPP)
- **Language:** PHP 7.4+
- **Database:** MySQL 8.0
- **WebSocket:** Ratchet PHP library (port 8080)
- **Push Notifications:** Firebase Cloud Messaging

---

## 📱 How to Run the App

### Prerequisites
1. XAMPP installed and running
2. Android Studio with Flutter SDK
3. Android emulator or physical device

### Step 1: Start XAMPP Services
1. Open XAMPP Control Panel
2. Start **Apache** service
3. Start **MySQL** service
4. Verify WebSocket server (optional): `php websocket_server.php`

### Step 2: Verify Backend
Open browser and test:
- `http://localhost/salles/api/get_salles.php`
- Should return JSON with room data

### Step 3: Run Flutter App
```bash
cd C:\Users\AdMin\AndroidStudioProjects\Salles
flutter clean
flutter pub get
flutter run
```

### For Physical Device
If using a physical Android device, update `lib/utils/constants.dart`:
```dart
// Replace with your computer's actual IP address
static const String baseUrl = 'http://192.168.1.x/salles/api';
static const String wsUrl = 'ws://192.168.1.x:8080';
```

---

## 🔑 Default Login Credentials

### Admin Account
- **Email:** `admin@alomrane.ma`
- **Password:** `password`
- **Role:** Administrator (can approve/reject requests)

### Create New Account
Use the "S'inscrire" link on the login screen to register new employees.

---

## 📂 Project Structure

```
AndroidStudioProjects/Salles/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── models/                   # Data models
│   ├── screens/                  # 15 UI screens (enhanced)
│   ├── services/                 # API, Auth, Notifications
│   ├── utils/                    # Constants, Theme
│   ├── widgets/                  # Reusable components
│   └── ...
├── backend/                      # PHP API (copied to XAMPP)
│   ├── api/                      # 14 API endpoints
│   ├── database.sql              # Schema
│   └── websocket_server.php      # Real-time server
└── ...
```

---

## ✅ Features Implemented

### Phase 1 - Core Features ✓
- [x] User authentication (login/register)
- [x] Room listing with search/filter
- [x] Create booking requests
- [x] Track request status
- [x] Role-based access control

### Phase 2 - Advanced Features ✓
- [x] Visual calendar view
- [x] Statistics dashboard
- [x] User profiles
- [x] PDF export
- [x] Admin room management

### Phase 3 - Notifications & Attachments ✓
- [x] Push notifications (Firebase)
- [x] Local notifications
- [x] File attachments support
- [x] Photo capture from camera
- [x] WebSocket real-time updates

### UI/UX Improvements ✓
- [x] Glassmorphism login screen
- [x] Animated transitions
- [x] Stepper booking flow
- [x] Professional room cards
- [x] Enhanced admin interface
- [x] Modern dashboard design

---

## 🐛 Known Issues

1. **Character Encoding:** Special characters (é, è) display as `??` in database - does not affect functionality
2. **WebSocket Server:** Must be started manually: `php websocket_server.php`
3. **File Picker Warnings:** Non-critical warnings from file_picker package

---

## 🚀 Next Steps (Optional Enhancements)

- [ ] Dark mode toggle
- [ ] Multi-language support (FR/AR/EN)
- [ ] Biometric authentication
- [ ] Offline mode with sync
- [ ] Email notifications
- [ ] Advanced reporting

---

## 📞 Support

For any issues:
1. Check XAMPP Apache and MySQL are running
2. Verify API at `http://localhost/salles/api/get_salles.php`
3. Check Flutter console for errors
4. Ensure database is properly imported

---

**Project Completed:** April 2026
**Developer:** Imad Elberrioui
**Company:** Groupe Al Omrane
