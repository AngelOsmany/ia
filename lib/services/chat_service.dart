import 'dart:convert';
import 'web_socket_service.dart';

class ChatMessage {
  final String sender;
  final String message;
  final DateTime timestamp;
  final bool isUser;

  ChatMessage({
    required this.sender,
    required this.message,
    required this.timestamp,
    required this.isUser,
  });

  Map<String, dynamic> toJson() => {
    'sender': sender,
    'message': message,
    'timestamp': timestamp.toIso8601String(),
    'isUser': isUser,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    sender: json['sender'] ?? 'Usuario',
    message: json['message'] ?? '',
    timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    isUser: json['isUser'] ?? false,
  );
}

/// Servicio de Chat en tiempo real con WebSocket REAL
class ChatService {
  // Usar un servidor WebSocket público para demostración
  static const String wsUrl = 'wss://echo.websocket.org';
  
  final WebSocketService _wsService = WebSocketService();
  final List<ChatMessage> messages = [];

  Stream<ChatMessage> get messageStream {
    return _wsService.messageStream.map((data) {
      try {
        if (data is String) {
          if (data.startsWith('{')) {
            // Es JSON
            final json = jsonDecode(data) as Map<String, dynamic>;
            return ChatMessage.fromJson(json);
          } else {
            // Es mensaje de texto simple
            return ChatMessage(
              sender: 'Servidor',
              message: data,
              timestamp: DateTime.now(),
              isUser: false,
            );
          }
        }
        return ChatMessage(
          sender: 'Sistema',
          message: data.toString(),
          timestamp: DateTime.now(),
          isUser: false,
        );
      } catch (e) {
        return ChatMessage(
          sender: 'Sistema',
          message: 'Mensaje recibido: $data',
          timestamp: DateTime.now(),
          isUser: false,
        );
      }
    });
  }

  Future<bool> connect() async {
    try {
      final result = await _wsService.connect(wsUrl);
      if (result) {
        // Agregar mensaje de bienvenida local
        messages.add(ChatMessage(
          sender: 'Sistema',
          message: 'Conectado al servidor WebSocket',
          timestamp: DateTime.now(),
          isUser: false,
        ));
      }
      return result;
    } catch (e) {
      messages.add(ChatMessage(
        sender: 'Sistema',
        message: 'Error conectando: $e',
        timestamp: DateTime.now(),
        isUser: false,
      ));
      return false;
    }
  }

  void sendMessage(String sender, String message) {
    if (!_wsService.isConnected) {
      messages.add(ChatMessage(
        sender: 'Sistema',
        message: 'No conectado al servidor',
        timestamp: DateTime.now(),
        isUser: false,
      ));
      return;
    }

    final chatMessage = ChatMessage(
      sender: sender,
      message: message,
      timestamp: DateTime.now(),
      isUser: true,
    );
    
    try {
      // Enviar como JSON
      _wsService.send(jsonEncode(chatMessage.toJson()));
      messages.add(chatMessage);
    } catch (e) {
      messages.add(ChatMessage(
        sender: 'Sistema',
        message: 'Error enviando mensaje: $e',
        timestamp: DateTime.now(),
        isUser: false,
      ));
    }
  }

  void disconnect() {
    _wsService.disconnect();
    messages.add(ChatMessage(
      sender: 'Sistema',
      message: 'Desconectado del servidor',
      timestamp: DateTime.now(),
      isUser: false,
    ));
  }

  bool get isConnected => _wsService.isConnected;
}
