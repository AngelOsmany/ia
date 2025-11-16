import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/api_response.dart';

/// Servicio de APIs funcionales - Clima y Traducción
class AiService {
  
  // Open-Meteo API - Datos de clima (REAL - sin API key)
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

  // MyMemory - Traducción REAL (sin autenticación)
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
}
