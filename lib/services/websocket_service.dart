import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../utils/constants.dart';

enum WsStatus { disconnected, connecting, connected }

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  Timer? _reconnectTimer;
  Timer? _pingTimer;

  WsStatus _status = WsStatus.disconnected;
  String? _userId;
  String? _role;
  int _reconnectAttempts = 0;
  static const _maxReconnectAttempts = 10;
  static const _reconnectBaseDelay = Duration(seconds: 3);

  Stream<Map<String, dynamic>> get stream => _controller.stream;
  WsStatus get status => _status;
  bool get isConnected => _status == WsStatus.connected;

  void connect(String userId, [String role = 'employe']) {
    if (_userId == userId && _status == WsStatus.connected) return;
    _userId = userId;
    _role = role;
    _reconnectAttempts = 0;
    _doConnect();
  }

  void _doConnect() {
    _cleanup();
    _status = WsStatus.connecting;

    try {
      _channel = WebSocketChannel.connect(Uri.parse(ApiConstants.wsUrl));
      _status = WsStatus.connected;
      _reconnectAttempts = 0;

      // Authenticate
      _send({'type': 'auth', 'userId': _userId, 'role': _role ?? 'employe'});

      // Start ping to keep connection alive
      _pingTimer = Timer.periodic(const Duration(seconds: 25), (_) {
        _send({'type': 'ping'});
      });

      _subscription = _channel!.stream.listen(
        (raw) {
          try {
            final data = jsonDecode(raw as String) as Map<String, dynamic>;
            if (data['type'] != 'pong') {
              _controller.add(data);
            }
          } catch (e) {
            debugPrint('[WS] Parse error: $e');
          }
        },
        onError: (error) {
          debugPrint('[WS] Error: $error');
          _scheduleReconnect();
        },
        onDone: () {
          debugPrint('[WS] Connection closed');
          _scheduleReconnect();
        },
      );
    } catch (e) {
      debugPrint('[WS] Connect error: $e');
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _status = WsStatus.disconnected;
    _pingTimer?.cancel();
    _pingTimer = null;

    if (_userId == null || _reconnectAttempts >= _maxReconnectAttempts) return;

    final delay = _reconnectBaseDelay * (1 << _reconnectAttempts.clamp(0, 5));
    _reconnectAttempts++;
    debugPrint('[WS] Reconnecting in ${delay.inSeconds}s (attempt $_reconnectAttempts)');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, _doConnect);
  }

  void _cleanup() {
    _pingTimer?.cancel();
    _pingTimer = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
  }

  void _send(Map<String, dynamic> data) {
    if (_status == WsStatus.connected && _channel != null) {
      try {
        _channel!.sink.add(jsonEncode(data));
      } catch (e) {
        debugPrint('[WS] Send error: $e');
      }
    }
  }

  void sendNewDemande(Map<String, dynamic> demandeData) {
    _send({'type': 'new_demande', 'data': demandeData});
  }

  void sendDemandeUpdate(String demandeId, String status,
      [String? targetUserId]) {
    _send({
      'type': 'demande_update',
      'demandeId': demandeId,
      'status': status,
      'userId': targetUserId ?? '',
    });
  }

  void dispose() {
    _cleanup();
    _userId = null;
    _status = WsStatus.disconnected;
  }
}
