class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  // Método para copiar el mensaje
  ChatMessage copyWith({
    String? text,
    bool? isUser,
    DateTime? timestamp,
  }) {
    return ChatMessage(
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  // Convertir a mapa para persistencia
  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // Crear desde mapa
  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      text: map['text'] ?? '',
      isUser: map['isUser'] ?? false,
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}

class ImageGenerationRequest {
  final String prompt;
  final int numberOfImages;
  final String? style;
  final String? size;

  ImageGenerationRequest({
    required this.prompt,
    this.numberOfImages = 1,
    this.style,
    this.size = '512x512',
  });

  Map<String, dynamic> toJson() {
    return {
      'inputs': prompt,
      'parameters': {
        'num_images': numberOfImages,
        'guidance_scale': 7.5,
        'num_inference_steps': 20,
        if (style != null) 'style': style,
        if (size != null) 'size': size,
      }
    };
  }
}

// Modelo para configuración de la app
class AppConfig {
  final String apiKey;
  final bool useProxy;
  final String proxyUrl;
  final bool debugMode;

  AppConfig({
    required this.apiKey,
    this.useProxy = true,
    this.proxyUrl = 'https://cors-anywhere.herokuapp.com/',
    this.debugMode = false,
  });
}