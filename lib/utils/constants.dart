class ApiConstants {
  static const String baseUrl = 'http://your-server.com/api';
  static const String login = '$baseUrl/login.php';
  static const String register = '$baseUrl/register.php';
  static const String getSalles = '$baseUrl/get_salles.php';
  static const String createDemande = '$baseUrl/create_demande.php';
  static const String getDemandes = '$baseUrl/get_demandes.php';
  static const String updateDemande = '$baseUrl/update_demande.php';
}

class AppConstants {
  static const String appName = 'Gestion des Salles';
  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String userRoleKey = 'user_role';
}
