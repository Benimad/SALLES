import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Demander la permission pour les notifications
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Notifications autorisées');
    }

    // Configuration des notifications locales
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Créer le canal de notification Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'salles_channel',
      'Notifications Salles',
      description: 'Notifications pour les demandes de salles',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Écouter les messages en premier plan
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Écouter les messages en arrière-plan
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    // Obtenir le token FCM
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      await _saveToken(token);
      print('FCM Token: $token');
    }

    // Écouter les changements de token
    _firebaseMessaging.onTokenRefresh.listen(_saveToken);
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', token);
    // TODO: Envoyer le token au serveur
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('fcm_token');
  }

  void _handleForegroundMessage(RemoteMessage message) {
    print('Message reçu en premier plan: ${message.notification?.title}');
    _showLocalNotification(message);
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    print('Message ouvert depuis l\'arrière-plan: ${message.notification?.title}');
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'salles_channel',
      'Notifications Salles',
      channelDescription: 'Notifications pour les demandes de salles',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'Nouvelle notification',
      message.notification?.body ?? '',
      details,
      payload: message.data.toString(),
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapée: ${response.payload}');
    // TODO: Navigation vers l'écran approprié
  }

  // Notifications locales personnalisées
  Future<void> showDemandeStatusNotification({
    required String title,
    required String body,
    required String status,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'salles_channel',
      'Notifications Salles',
      channelDescription: 'Notifications pour les demandes de salles',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }
}

// Handler pour les messages en arrière-plan (doit être top-level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Message en arrière-plan: ${message.notification?.title}');
}
