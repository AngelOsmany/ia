import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:async';

/// Servicio de WebSocket REAL para chat en tiempo real
class WebSocketService {
  late WebSocketChannel _channel;
  bool _isConnected = false;
  late StreamController<dynamic> _messageController;

  WebSocketService() {
    _messageController = StreamController<dynamic>.broadcast();
  }

  Stream<dynamic> get messageStream => _messageController.stream;
  bool get isConnected => _isConnected;

  /// Conecta a un servidor WebSocket REAL
  Future<bool> connect(String url) async {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _isConnected = true;
      _messageController.add('Conectado a $url');

      // Escuchar mensajes del servidor
      _channel.stream.listen(
        (message) {
          _messageController.add(message);
        },
        onError: (error) {
          _messageController.addError(error);
          _isConnected = false;
        },
        onDone: () {
          _messageController.add('Conexión cerrada');
          _isConnected = false;
        },
      );

      return true;
    } catch (e) {
      _messageController.addError(e);
      _isConnected = false;
      return false;
    }
  }

  /// Enviar mensaje al servidor WebSocket
  void send(String message) {
    if (_isConnected) {
      try {
        _channel.sink.add(message);
      } catch (e) {
        _messageController.addError(e);
      }
    }
  }

  void disconnect() {
    _isConnected = false;
    _channel.sink.close();
    _messageController.add('Desconectado');
  }

  void dispose() {
    disconnect();
    _messageController.close();
  }
}
