import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class HuggingFaceService {
  static const String _baseUrl = 'https://api-inference.huggingface.co/models';

  // Read token, optional proxy and optional HF Space URL from compile-time environment
  // Use: flutter run -d chrome --dart-define=HF_TOKEN=your_token --dart-define=CORS_PROXY=https://your-proxy/ --dart-define=HF_SPACE_URL=https://hf.space/embed/owner/space/api/predict
  static const String _token = String.fromEnvironment('HF_TOKEN', defaultValue: '');
  static const String _corsProxy = String.fromEnvironment('CORS_PROXY', defaultValue: '');
  static const String _spaceUrl = String.fromEnvironment('HF_SPACE_URL', defaultValue: '');
  // Optional generic API endpoints (allow plugging any public/no-auth API)
  static const String _chatUrl = String.fromEnvironment('AI_CHAT_URL', defaultValue: '');
  static const String _imageUrl = String.fromEnvironment('AI_IMAGE_URL', defaultValue: '');
  static const String _sentimentUrl = String.fromEnvironment('AI_SENTIMENT_URL', defaultValue: '');
  // Optional extra headers in JSON form, e.g. --dart-define=AI_API_HEADERS='{"Authorization":"Bearer ..."}'
  static const String _apiHeadersJson = String.fromEnvironment('AI_API_HEADERS', defaultValue: '');

  static Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (_token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // Helper to POST to a target URL, routing through a proxy endpoint if configured.
  // Supports two proxy styles:
  // - Query-style proxies that expect the target appended after a `?`, e.g. `https://corsproxy.io/?`
  // - JSON proxy endpoint that expects { url: target, data: ..., headers: ... } (our FastAPI proxy)
  static Future<http.Response> _postToTarget(String target, dynamic payload) async {
    // allow user-provided headers (overrides default headers)
    final Map<String, String> extraHeaders = {};
    if (_apiHeadersJson.isNotEmpty) {
      try {
        final parsed = json.decode(_apiHeadersJson);
        if (parsed is Map) {
          parsed.forEach((k, v) {
            if (k != null && v != null) extraHeaders[k.toString()] = v.toString();
          });
        }
      } catch (_) {}
    }

    if (_corsProxy.isNotEmpty) {
      // If proxy appears to be a query-style proxy (contains '?'), append encoded target
      if (_corsProxy.contains('?')) {
        final url = '$_corsProxy${Uri.encodeFull(target)}';
        return await http.post(Uri.parse(url), headers: _headers, body: json.encode(payload));
      }

      // Otherwise assume it's a JSON proxy endpoint (like our FastAPI /proxy)
      final proxyBody = {
        'url': target,
        'data': payload,
        'headers': {..._headers, ...extraHeaders},
      };
      return await http.post(Uri.parse(_corsProxy), headers: {'Content-Type': 'application/json'}, body: json.encode(proxyBody));
    }

    // No proxy: call target directly
    return await http.post(Uri.parse(target), headers: {..._headers, ...extraHeaders}, body: json.encode(payload));
  }

  // CHAT REAL - Con manejo de HF Space, token y fallback mock
  static Future<String> generateText(String prompt) async {
    // If custom chat API URL provided, use it first.
    if (_chatUrl.isNotEmpty) {
      try {
        final response = await _postToTarget(_chatUrl, {'inputs': prompt}).timeout(const Duration(seconds: 30));
        if (response.statusCode == 200) {
          try {
            final data = json.decode(response.body);
            if (data is Map && data.containsKey('generated_text')) return data['generated_text'].toString();
            if (data is Map && data.containsKey('data')) {
              final d = data['data'];
              if (d is List && d.isNotEmpty) return d[0].toString();
            }
          } catch (_) {}
          return response.body;
        }
        return 'Error: chat API returned ${response.statusCode}';
      } catch (e) {
        // fall through to other methods
      }
    }
    // If an HF Space URL is provided, call it (many public Spaces accept {"data":[input]})
    if (_spaceUrl.isNotEmpty) {
      try {
        final resp = await _callSpace(_spaceUrl, [prompt]);
        if (resp is Map && resp.containsKey('data')) {
          final data = resp['data'];
          if (data is List && data.isNotEmpty) {
            final first = data[0];
            if (first is String) return first;
            if (first is Map && first.containsKey('generated_text')) return first['generated_text'].toString();
          }
        }
      } catch (_) {}
    }

    // If token exists, call HF inference API
    if (_token.isNotEmpty) {
      try {
        final target = '$_baseUrl/microsoft/DialoGPT-medium';
        if (kIsWeb && _corsProxy.isEmpty) {
          // On web without a proxy, fallback to mock to avoid exposing CORS messages in UI.
          return _mockChatResponse(prompt);
        }

        final response = await _postToTarget(target, {
          'inputs': prompt,
          'parameters': {
            'max_length': 100,
            'temperature': 0.9,
            'do_sample': true,
          }
        }).timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          return data['generated_text'] ?? '🤖: ¿En qué más puedo ayudarte?';
        } else if (response.statusCode == 503) {
          return '⏳ El modelo de chat se está cargando. Esto es normal en el primer uso. Espera 20-30 segundos y vuelve a intentar.';
        } else {
          return '❌ Error del servidor: ${response.statusCode}. Intenta nuevamente.';
        }
      } catch (e) {
        return '🔌 Error de conexión: $e';
      }
    }

    // Fallback: mock/demo mode
    return _mockChatResponse(prompt);
  }

  // NOTE: _postToTarget ahora maneja el proxy; la lógica previa de proxy queda centralizada.

  // GENERACIÓN DE IMÁGENES REAL con visualización (soporta HF Space, token y mock)
  static Future<List<String>> generateImage(String prompt) async {
    // If custom image API URL provided, use it first.
    if (_imageUrl.isNotEmpty) {
      try {
        final response = await _postToTarget(_imageUrl, {'inputs': prompt}).timeout(const Duration(seconds: 60));
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
              if (imgs is List && imgs.isNotEmpty) return ['data:image/png;base64,${imgs[0]}'];
            }
            if (decoded is List && decoded.isNotEmpty && decoded[0] is String) return ['data:image/png;base64,${decoded[0]}'];
          } catch (_) {}
          return ['${response.body}'];
        }
        return ['Error: image API returned ${response.statusCode}'];
      } catch (e) {
        // fall through
      }
    }
    // Try HF Space first
    if (_spaceUrl.isNotEmpty) {
      try {
        final resp = await _callSpace(_spaceUrl, [prompt]);
        if (resp is Map && resp.containsKey('data')) {
          final data = resp['data'];
          if (data is List && data.isNotEmpty) {
            final first = data[0];
            if (first is String && first.startsWith('data:')) return [first];
            if (first is String) return ['data:image/png;base64,$first'];
          }
        }
      } catch (_) {}
    }

    // If token exists, call HF inference API
    if (_token.isNotEmpty) {
      try {
        final target = '$_baseUrl/runwayml/stable-diffusion-v1-5';
        if (kIsWeb && _corsProxy.isEmpty) {
          // When running on web without proxy, return mock image to avoid UI error spam.
          return _mockImageResponse(prompt);
        }

        final response = await _postToTarget(target, {
          'inputs': prompt,
          'parameters': {
            'num_inference_steps': 20,
          }
        }).timeout(const Duration(seconds: 60));

        if (response.statusCode == 200) {
          final contentType = response.headers['content-type'] ?? '';
          if (contentType.startsWith('image/')) {
            final base64Image = base64Encode(response.bodyBytes);
            return ['data:$contentType;base64,$base64Image'];
          }

          final body = response.body;
          try {
            final decoded = json.decode(body);
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
        } else if (response.statusCode == 503) {
          return ['⏳ El modelo de imágenes se está cargando. Esto puede tomar 30-60 segundos en la primera ejecución.'];
        } else {
          return await _generateImageWithProxy(prompt);
        }
      } catch (e) {
        return await _generateImageWithProxy(prompt);
      }
    }

    // Fallback: mock image
    return _mockImageResponse(prompt);
  }

  // Imágenes con proxy CORS
  static Future<List<String>> _generateImageWithProxy(String prompt) async {
    try {
      final target = '$_baseUrl/runwayml/stable-diffusion-v1-5';
      final response = await _postToTarget(target, {'inputs': prompt}).timeout(const Duration(seconds: 60));

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
    // If custom sentiment API URL provided, use it first.
    if (_sentimentUrl.isNotEmpty) {
      try {
        final response = await _postToTarget(_sentimentUrl, {'inputs': text}).timeout(const Duration(seconds: 30));
        if (response.statusCode == 200) {
          try {
            final data = json.decode(response.body);
            return _parseSentiment(data);
          } catch (_) {
            return response.body;
          }
        }
        return 'Error: sentiment API returned ${response.statusCode}';
      } catch (e) {
        // fall through
      }
    }
    // Try HF Space first
    if (_spaceUrl.isNotEmpty) {
      try {
        final resp = await _callSpace(_spaceUrl, [text]);
        if (resp is Map && resp.containsKey('data')) {
          final data = resp['data'];
          if (data is List && data.isNotEmpty) {
            final first = data[0];
            return _parseSentiment(first is Map ? [first] : data);
          }
        }
      } catch (_) {}
    }

    if (_token.isNotEmpty) {
      try {
        final target = '$_baseUrl/cardiffnlp/twitter-roberta-base-sentiment-latest';
        // If running on web without proxy, use mock to avoid surfacing CORS notices.
        if (kIsWeb && _corsProxy.isEmpty) {
          return _mockSentimentResponse(text);
        }

        final response = await _postToTarget(target, {'inputs': text}).timeout(const Duration(seconds: 30));

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

    // Fallback mock
    return _mockSentimentResponse(text);
  }

  // Sentimientos con proxy CORS
  static Future<String> _analyzeSentimentWithProxy(String text) async {
    try {
      final target = '$_baseUrl/cardiffnlp/twitter-roberta-base-sentiment-latest';
      final response = await _postToTarget(target, {'inputs': text}).timeout(const Duration(seconds: 30));

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

    // Generic caller for public Hugging Face Spaces that accept {"data": [inputs...]}
    static Future<dynamic> _callSpace(String url, List<dynamic> inputs) async {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'data': inputs}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        try {
          return json.decode(response.body);
        } catch (_) {
          return response.body;
        }
      }
      throw Exception('Space call failed: ${response.statusCode}');
    }

    // Mock/demo helpers used when no token/space is provided (useful for web demos)
    static String _mockChatResponse(String prompt) {
        return '🤖 (demo) Respuesta de ejemplo para: "$prompt"';
    }

    static List<String> _mockImageResponse(String prompt) {
      // 1x1 PNG transparent base64 placeholder
      const pixelBase64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR4nGNgYAAAAAMAASsJTYQAAAAASUVORK5CYII=';
      return ['data:image/png;base64,$pixelBase64'];
    }

    static String _mockSentimentResponse(String text) {
      return '🎭 ANÁLISIS DE SENTIMIENTOS\n• Resultado: Neutral 😐\n• Confianza: 50%\n• Detalles: Modo demo.';
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