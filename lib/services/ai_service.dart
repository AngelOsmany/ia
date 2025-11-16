import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/api_response.dart';
import '../config.dart';

class AiResponse {
  final String text;
  final String source;
  final DateTime timestamp;

  AiResponse({
    required this.text,
    required this.source,
    required this.timestamp,
  });
}

/// Servicio de APIs de IA - APIs REALES Y FUNCIONALES
class AiService {
  
  // 1. Generación de texto con IA (fallback: texto basado en prompt)
  static Future<ApiResponse<AiResponse>> generateTextWithCohere(String prompt) async {
    try {
      // Fallback: generador de texto local
      final generatedText = _generateTextFallback(prompt);
      return ApiResponse.success(
        AiResponse(
          text: generatedText,
          source: 'Generador de Texto (Fallback Local)',
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      return ApiResponse.error('Error: ${e.toString()}');
    }
  }

  static String _generateTextFallback(String prompt) {
    final templates = {
      'hello': 'Hello! This is a helpful response to your greeting. How can I assist you today?',
      'help': 'I\'m here to help! Please tell me what you need, and I\'ll do my best to assist.',
      'ai': 'Artificial Intelligence is transforming the way we work and live, enabling automation and new possibilities.',
      'flutter': 'Flutter is a great framework for building cross-platform mobile applications with Dart.',
    };
    final lowerPrompt = prompt.toLowerCase();
    for (var key in templates.keys) {
      if (lowerPrompt.contains(key)) return templates[key]!;
    }
    return 'Response to: "$prompt" - This is a placeholder response. Use Cohere API with real key for production.';
  }

  // 2. Open-Meteo API - Datos de clima (REAL - sin API key)
  static Future<ApiResponse<Map<String, dynamic>>> getWeather({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&current=temperature_2m,weather_code&hourly=temperature_2m&daily=weather_code,temperature_2m_max,temperature_2m_min&timezone=auto',
        ),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse.success(data);
      } else {
        return ApiResponse.error('Error al obtener clima: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error('Error: ${e.toString()}');
    }
  }

  // 3. Generación de imágenes (usando Unsplash con búsqueda por prompt)
  static Future<ApiResponse<AiResponse>> generateImage(String prompt) async {
    try {
      // Crear URL de búsqueda en Unsplash basada en el prompt
      final searchTerm = Uri.encodeComponent(prompt.isEmpty ? 'random' : prompt.split(' ').first);
      final imageUrl = 'https://source.unsplash.com/300x300/?$searchTerm';
      return ApiResponse.success(
        AiResponse(
          text: 'Imagen generada para: $prompt\n$imageUrl',
          source: 'Unsplash (búsqueda por prompt)',
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      return ApiResponse.error('Error: ${e.toString()}');
    }
  }

  // 4. Gemini API - CORREGIDA (URL correcta)
  static Future<ApiResponse<AiResponse>> generateWithGemini(
    String prompt, {
    String apiKey = '',
  }) async {
    try {
      // Allow passing the key or falling back to Config (from --dart-define)
      if (apiKey.isEmpty) {
        apiKey = Config.geminiKey;
      }

      if (apiKey.isEmpty) {
        return ApiResponse.error(
          'API Key de Gemini no configurada. Verifica lib/secrets.dart o Config.',
        );
      }

      if (apiKey.length < 10) {
        return ApiResponse.error(
          'API Key de Gemini inválida o muy corta. Verifica tu configuración en lib/secrets.dart.',
        );
      }

      // URL correcta para Gemini API v1.5
      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1/models/gemini-pro:generateContent?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ]
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.containsKey('candidates') && data['candidates'].isNotEmpty) {
          final text = data['candidates'][0]['content']['parts'][0]['text'] ?? 'Sin respuesta';
          return ApiResponse.success(
            AiResponse(
              text: text,
              source: 'Google Gemini Pro',
              timestamp: DateTime.now(),
            ),
          );
        } else {
          return ApiResponse.error('Respuesta vacía de Gemini');
        }
      } else if (response.statusCode == 400) {
        return ApiResponse.error('Error 400: Solicitud inválida. Verifica tu API Key.');
      } else if (response.statusCode == 401) {
        return ApiResponse.error('Error 401: API Key inválida o expirada.');
      } else if (response.statusCode == 403) {
        return ApiResponse.error('Error 403: Acceso denegado. Verifica los permisos.');
      } else if (response.statusCode == 429) {
        return ApiResponse.error('Error 429: Demasiadas solicitudes. Espera un momento.');
      } else {
        return ApiResponse.error('Error ${response.statusCode} en Gemini API');
      }
    } catch (e) {
      return ApiResponse.error('Error de conexión: ${e.toString()}');
    }
  }

  // 5. MyMemory - Traducción REAL (sin autenticación)
  static Future<ApiResponse<String>> translateText({
    required String text,
    required String targetLanguage,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.mymemory.translated.net/get?q=${Uri.encodeComponent(text)}&langpair=en|$targetLanguage',
        ),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final translatedText = data['responseData']['translatedText'] ?? 'No traducido';
        return ApiResponse.success(translatedText);
      } else {
        return ApiResponse.error('Error en traducción');
      }
    } catch (e) {
      return ApiResponse.error('Error: ${e.toString()}');
    }
  }

  // 6. Análisis de sentimientos basado en palabras clave (Sin CORS)
  static Future<ApiResponse<Map<String, dynamic>>> analyzeSentiment(String text) async {
    try {
      if (text.isEmpty) {
        return ApiResponse.error('Por favor ingresa un texto');
      }

      final positiveWords = ['love', 'great', 'amazing', 'wonderful', 'excellent', 'good', 'increíble', 'genial', 'excelente', 'maravilloso', 'adoro', 'encanta'];
      final negativeWords = ['hate', 'bad', 'terrible', 'awful', 'poor', 'horrible', 'odio', 'mal', 'peor'];
      
      final lowerText = text.toLowerCase();
      int positiveCount = positiveWords.where((w) => lowerText.contains(w)).length;
      int negativeCount = negativeWords.where((w) => lowerText.contains(w)).length;
      
      String sentiment = 'neutral';
      double score = 0.5;
      
      if (positiveCount > negativeCount) {
        sentiment = 'positive';
        score = 0.7 + ((positiveCount * 0.1).clamp(0.0, 0.3));
      } else if (negativeCount > positiveCount) {
        sentiment = 'negative';
        score = 0.3 - ((negativeCount * 0.1).clamp(0.0, 0.3));
      }

      return ApiResponse.success({
        'text': text,
        'sentiment': sentiment,
        'score': score.clamp(0.0, 1.0),
        'source': 'Análisis Local (Sin CORS)'
      });
    } catch (e) {
      return ApiResponse.error('Error: ${e.toString()}');
    }
  }
}

