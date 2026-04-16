import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  Future<void> initialize() async {
    debugPrint('NotificationService: initialized (WebSocket-based)');
  }

  void showLocalNotification({
    required String title,
    required String body,
    String status = 'info',
  }) {
    Color bgColor;
    IconData icon;
    switch (status) {
      case 'approuvee':
        bgColor = const Color(0xFF006E2D);
        icon = Icons.check_circle_rounded;
        break;
      case 'rejetee':
        bgColor = const Color(0xFFBA0013);
        icon = Icons.cancel_rounded;
        break;
      default:
        bgColor = const Color(0xFF1A3A5C);
        icon = Icons.notifications_rounded;
    }

    messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  if (body.isNotEmpty)
                    Text(body,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> showDemandeStatusNotification({
    required String title,
    required String body,
    required String status,
  }) async {
    showLocalNotification(title: title, body: body, status: status);
  }

  Future<void> cancelAllNotifications() async {}
}
