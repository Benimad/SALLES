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
