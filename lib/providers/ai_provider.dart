import 'package:flutter/foundation.dart';
import '../models/ai_models.dart';
import '../services/huggingface_service.dart';

class AIProvider with ChangeNotifier {
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String _currentFeature = 'chat';

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String get currentFeature => _currentFeature;

  // SOLO 3 FUNCIONES - SIN TRADUCCIÓN
  final List<AIFeature> _availableFeatures = [
    AIFeature(
      id: 'chat',
      name: '💬 Chat IA',
      description: 'Chatea con inteligencia artificial en tiempo real',
      icon: '💬',
    ),
    AIFeature(
      id: 'sentiment', 
      name: '😊 Análisis Sentimientos',
      description: 'Analiza el sentimiento de textos',
      icon: '😊',
    ),
    AIFeature(
      id: 'image',
      name: '🖼️ Generar Imagen',
      description: 'Crea imágenes desde descripciones',
      icon: '🖼️',
    ),
  ];

  List<AIFeature> get availableFeatures => _availableFeatures;

  void setFeature(String feature) {
    _currentFeature = feature;
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    if (text.isEmpty) return;

    // Agregar mensaje del usuario
    _messages.add(ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    ));
    notifyListeners();

    _isLoading = true;
    notifyListeners();

    try {
      String response = '';

      // SOLO 3 CASOS - SIN TRADUCCIÓN
      switch (_currentFeature) {
        case 'chat':
          response = await HuggingFaceService.generateText(text);
          break;
        case 'sentiment':
          response = await HuggingFaceService.analyzeSentiment(text);
          break;
        case 'image':
          final images = await HuggingFaceService.generateImage(text);
          response = images.isNotEmpty ? images.first : 'No se pudo generar la imagen';
          break;
      }

      // Agregar respuesta de la IA
      _messages.add(ChatMessage(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
      ));

    } catch (e) {
      _messages.add(ChatMessage(
        text: '❌ Error: $e\n\n💡 Si el error persiste:\n• Ejecuta en Android: flutter run -d android\n• Los modelos pueden tardar en cargar (30s)\n• Verifica tu conexión a internet',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  void removeMessage(int index) {
    if (index >= 0 && index < _messages.length) {
      _messages.removeAt(index);
      notifyListeners();
    }
  }
}

class AIFeature {
  final String id;
  final String name;
  final String description;
  final String icon;

  AIFeature({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });
}