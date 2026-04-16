class ApiConstants {
  // ===== SERVER CONFIGURATION =====
  // For Android Emulator - use 10.0.2.2 to access host's localhost
  // For Physical Device - use your computer's actual IP address (e.g., 192.168.1.x)
  // For iOS Simulator - use localhost
  static const String baseUrl = 'http://10.0.2.2/salles/api';
  static const String wsUrl = 'ws://10.0.2.2:8080';

  // ===== Authentication Endpoints =====
  static const String login = '$baseUrl/login.php';
  static const String register = '$baseUrl/register.php';
  static const String getUser = '$baseUrl/get_user.php';
  static const String updateFcmToken = '$baseUrl/update_fcm_token.php';

  // ===== Room (Salle) Endpoints =====
  static const String getSalles = '$baseUrl/get_salles.php';
  static const String addSalle = '$baseUrl/add_salle.php';
  static const String updateSalle = '$baseUrl/update_salle.php';
  static const String deleteSalle = '$baseUrl/delete_salle.php';
  static const String checkAvailability = '$baseUrl/check_availability.php';

  // ===== Booking (Demande) Endpoints =====
  static const String createDemande = '$baseUrl/create_demande.php';
  static const String getDemandes = '$baseUrl/get_demandes.php';
  static const String updateDemande = '$baseUrl/update_demande.php';

  // ===== File Attachment Endpoints =====
  static const String uploadAttachment = '$baseUrl/upload_attachment.php';
  static const String getAttachments = '$baseUrl/get_attachments.php';

  // ===== Notification Endpoints =====
  static const String sendNotification = '$baseUrl/send_notification.php';

  // ===== Timeouts =====
  static const int connectTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
}

class AppConstants {
  static const String appName = 'Salles - Groupe Al Omrane';
  static const String tokenKey = 'auth_token';
  static const String userDataKey = 'user_data';
  static const String userIdKey = 'user_id';
  static const String userRoleKey = 'user_role';
  
  static const String roleEmployee = 'employe';
  static const String roleAdmin = 'admin';
  
  static const String statusPending = 'en_attente';
  static const String statusApproved = 'approuvee';
  static const String statusRejected = 'rejetee';

  // Timeout durations
  static const Duration webSocketReconnectDelay = Duration(seconds: 5);
  static const Duration apiTimeout = Duration(seconds: 30);
}

class ValidationConstants {
  static const int minPasswordLength = 6;
  static const int maxNameLength = 100;
  static const int maxMotifLength = 500;

  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
}

class UIConstants {
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  
  static const double defaultBorderRadius = 12.0;
  static const double smallBorderRadius = 8.0;
  
  static const double defaultElevation = 4.0;
}
