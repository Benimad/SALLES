class ApiConstants {
  // For Android Emulator - use 10.0.2.2 to access host's localhost
  // For Physical Device - use your computer's actual IP address (e.g., 192.168.1.x)
  static const String baseUrl = 'http://10.0.2.2/salles/api';
  static const String wsUrl = 'ws://10.0.2.2:8080';
  static const String login = '$baseUrl/login.php';
  static const String register = '$baseUrl/register.php';
  static const String getSalles = '$baseUrl/get_salles.php';
  static const String createDemande = '$baseUrl/create_demande.php';
  static const String getDemandes = '$baseUrl/get_demandes.php';
  static const String updateDemande = '$baseUrl/update_demande.php';
  
  // Phase 3 - CRUD Salles
  static const String addSalle = '$baseUrl/add_salle.php';
  static const String updateSalle = '$baseUrl/update_salle.php';
  static const String deleteSalle = '$baseUrl/delete_salle.php';
  
  // Phase 3 - Pièces jointes
  static const String uploadAttachment = '$baseUrl/upload_attachment.php';
  static const String getAttachments = '$baseUrl/get_attachments.php';
  
  // Phase 3 - Notifications
  static const String sendNotification = '$baseUrl/send_notification.php';
  static const String updateFcmToken = '$baseUrl/update_fcm_token.php';
}

class AppConstants {
  static const String appName = 'Gestion des Salles';
  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String userRoleKey = 'user_role';
}
