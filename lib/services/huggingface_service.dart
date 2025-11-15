import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class HuggingFaceService {
  static const String _baseUrl = 'https://api-inference.huggingface.co/models';

  // Read token and optional proxy from compile-time environment to avoid hardcoding
  // Use: flutter run -d chrome --dart-define=HF_TOKEN=your_token --dart-define=CORS_PROXY=https://your-proxy/
  static const String _token = String.fromEnvironment('HF_TOKEN', defaultValue: '');
  static const String _corsProxy = String.fromEnvironment('CORS_PROXY', defaultValue: '');

  static Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (_token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // CHAT REAL - Con manejo de CORS para web
  static Future<String> generateText(String prompt) async {
    try {
      final target = '$_baseUrl/microsoft/DialoGPT-medium';
      if (kIsWeb && _corsProxy.isEmpty) {
        return '🔒 En navegador (web) las peticiones a la API pueden bloquearse por CORS.\n\n' 
               'Opciones:\n' 
               '• Ejecuta la app en Android/iOS donde funciona la API.\n' 
               '• Provee un proxy CORS seguro y vuelve a compilar con: --dart-define=CORS_PROXY=https://your-proxy/?url=';
      }

      final url = kIsWeb && _corsProxy.isNotEmpty
          ? '$_corsProxy${Uri.encodeFull(target)}'
          : target;

      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: json.encode({
          'inputs': prompt,
          'parameters': {
            'max_length': 100,
            'temperature': 0.9,
            'do_sample': true,
          }
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['generated_text'] ?? '🤖: ¿En qué más puedo ayudarte?';
      } 
      else if (response.statusCode == 503) {
        return '⏳ El modelo de chat se está cargando. Esto es normal en el primer uso. Espera 20-30 segundos y vuelve a intentar.';
      }
      else {
        return '❌ Error del servidor: ${response.statusCode}. Intenta nuevamente.';
      }
    } catch (e) {
      // Para web, intentamos con proxy CORS
      return await _generateTextWithProxy(prompt);
    }
  }

  // Chat con proxy CORS para web
  static Future<String> _generateTextWithProxy(String prompt) async {
    try {
      final proxy = _corsProxy.isNotEmpty ? _corsProxy : 'https://corsproxy.io/?';
      final target = '$_baseUrl/microsoft/DialoGPT-medium';
      final url = '${proxy}${Uri.encodeFull(target)}';

      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: json.encode({
          'inputs': prompt,
          'parameters': {
            'max_length': 100,
            'temperature': 0.9,
            'do_sample': true,
          }
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['generated_text'] ?? '🤖: ¡Hola! ¿En qué puedo ayudarte?';
      } 
      else if (response.statusCode == 503) {
        return '⏳ El modelo de chat se está cargando. Por favor espera 20-30 segundos.';
      }
      else {
        return '❌ Error temporal: ${response.statusCode}. Los servicios pueden estar ocupados.';
      }
    } catch (e) {
      return '🔌 Error de conexión. Verifica tu internet o intenta en Android.';
    }
  }

  // GENERACIÓN DE IMÁGENES REAL con visualización
  static Future<List<String>> generateImage(String prompt) async {
    try {
      final target = '$_baseUrl/runwayml/stable-diffusion-v1-5';
      if (kIsWeb && _corsProxy.isEmpty) {
        return ['🔒 En navegador (web) las peticiones a modelos de imágenes suelen bloquearse por CORS.\n' 
                'Provee un proxy con --dart-define=CORS_PROXY=https://your-proxy/?url= o ejecuta en Android/iOS.'];
      }

      final url = kIsWeb && _corsProxy.isNotEmpty
          ? '$_corsProxy${Uri.encodeFull(target)}'
          : target;

      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: json.encode({
          'inputs': prompt,
          'parameters': {
            'num_inference_steps': 20,
          }
        }),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        // If the API returns raw image bytes
        final contentType = response.headers['content-type'] ?? '';
        if (contentType.startsWith('image/')) {
          final base64Image = base64Encode(response.bodyBytes);
          return ['data:$contentType;base64,$base64Image'];
        }

        // If the API returns JSON with base64 (various shapes), be robust
        final body = response.body;
        try {
          final decoded = json.decode(body);
          // Common HF shapes: {"images": ["...base64..."]} or ["...base64..."]
          if (decoded is Map && decoded.containsKey('images')) {
            final imgs = decoded['images'];
            if (imgs is List && imgs.isNotEmpty) {
              return ['data:image/png;base64,${imgs[0]}'];
            }
          }
          if (decoded is List && decoded.isNotEmpty && decoded[0] is String) {
            return ['data:image/png;base64,${decoded[0]}'];
          }
        } catch (_) {
          // not JSON, continue
        }

        // Fallback: return textual response
        return ['✅ Imagen generada (respuesta no binaria): ${response.body}'];
      } else if (response.statusCode == 503) {
        return ['⏳ El modelo de imágenes se está cargando. Esto puede tomar 30-60 segundos en la primera ejecución.'];
      } else {
        return await _generateImageWithProxy(prompt);
      }
    } catch (e) {
      return await _generateImageWithProxy(prompt);
    }
  }

  // Imágenes con proxy CORS
  static Future<List<String>> _generateImageWithProxy(String prompt) async {
    try {
      final proxy = _corsProxy.isNotEmpty ? _corsProxy : 'https://corsproxy.io/?';
      final target = '$_baseUrl/runwayml/stable-diffusion-v1-5';
      final url = '${proxy}${Uri.encodeFull(target)}';

      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: json.encode({
          'inputs': prompt,
        }),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'] ?? '';
        if (contentType.startsWith('image/')) {
          final base64Image = base64Encode(response.bodyBytes);
          return ['data:$contentType;base64,$base64Image'];
        }

        try {
          final decoded = json.decode(response.body);
          if (decoded is Map && decoded.containsKey('images')) {
            final imgs = decoded['images'];
            if (imgs is List && imgs.isNotEmpty) {
              return ['data:image/png;base64,${imgs[0]}'];
            }
          }
          if (decoded is List && decoded.isNotEmpty && decoded[0] is String) {
            return ['data:image/png;base64,${decoded[0]}'];
          }
        } catch (_) {}

        return ['✅ Imagen generada (respuesta no binaria): ${response.body}'];
      } else {
        return ['❌ Error generando imagen: ${response.statusCode}. Intenta con una descripción más simple.'];
      }
    } catch (e) {
      return ['🔌 Error de conexión: $e'];
    }
  }

  // ANÁLISIS DE SENTIMIENTOS REAL
  static Future<String> analyzeSentiment(String text) async {
    try {
      final target = '$_baseUrl/cardiffnlp/twitter-roberta-base-sentiment-latest';
      if (kIsWeb && _corsProxy.isEmpty) {
        return '🔒 En navegador (web) el análisis puede bloquearse por CORS.\n' 
               'Provee un proxy con --dart-define=CORS_PROXY=https://your-proxy/?url= o ejecuta en Android/iOS.';
      }

      final url = kIsWeb && _corsProxy.isNotEmpty
          ? '$_corsProxy${Uri.encodeFull(target)}'
          : target;

      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: json.encode({
          'inputs': text,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseSentiment(data);
      } else {
        return await _analyzeSentimentWithProxy(text);
      }
    } catch (e) {
      return await _analyzeSentimentWithProxy(text);
    }
  }

  // Sentimientos con proxy CORS
  static Future<String> _analyzeSentimentWithProxy(String text) async {
    try {
      final proxy = _corsProxy.isNotEmpty ? _corsProxy : 'https://corsproxy.io/?';
      final target = '$_baseUrl/cardiffnlp/twitter-roberta-base-sentiment-latest';
      final url = '${proxy}${Uri.encodeFull(target)}';

      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: json.encode({
          'inputs': text,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseSentiment(data);
      } else {
        return '❌ Error analizando sentimiento: ${response.statusCode}';
      }
    } catch (e) {
      return '🔌 Error de conexión en análisis: $e';
    }
  }

  static String _parseSentiment(dynamic data) {
    try {
      // HF inference can return a List<Map> like [{"label":"POSITIVE","score":0.99}, ...]
      if (data is List && data.isNotEmpty) {
        // If the API returns nested lists, normalize to a flat list of maps
        List<dynamic> items = data;
        if (items.length == 1 && items[0] is List) {
          items = List.from(items[0]);
        }

        double bestScore = 0.0;
        String bestLabel = 'neutral';
        for (var item in items) {
          if (item is Map && item['score'] != null) {
            final score = (item['score'] as num).toDouble();
            final label = (item['label'] ?? 'neutral').toString();
            if (score > bestScore) {
              bestScore = score;
              bestLabel = label;
            }
          }
        }

        final confidence = (bestScore * 100).toStringAsFixed(1);
        return '🎭 ANÁLISIS DE SENTIMIENTOS\n'
               '• Resultado: ${_translateSentiment(bestLabel)}\n'
               '• Confianza: $confidence%\n'
               '• Detalles: ${_getSentimentDescription(bestLabel)}';
      }

      return '❌ No se pudo analizar el sentimiento';
    } catch (e) {
      return '❌ Error procesando análisis: $e';
    }
  }

  static String _translateSentiment(String label) {
    switch (label.toLowerCase()) {
      case 'positive': return 'Positivo 🎉';
      case 'negative': return 'Negativo 😞';
      case 'neutral': return 'Neutral 😐';
      default: return label;
    }
  }

  static String _getSentimentDescription(String label) {
    switch (label.toLowerCase()) {
      case 'positive': return 'El texto expresa emociones positivas y optimismo.';
      case 'negative': return 'El texto expresa emociones negativas o pesimismo.';
      case 'neutral': return 'El texto es neutral o objetivo.';
      default: return 'Análisis completado.';
    }
  }
}