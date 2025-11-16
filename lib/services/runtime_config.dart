import 'package:shared_preferences/shared_preferences.dart';

class RuntimeConfig {
  static Future<SharedPreferences> _prefs() async => await SharedPreferences.getInstance();

  static const _keys = {
    'AI_CHAT_URL': 'runtime_ai_chat_url',
    'AI_IMAGE_URL': 'runtime_ai_image_url',
    'AI_SENTIMENT_URL': 'runtime_ai_sentiment_url',
    'AI_API_HEADERS': 'runtime_ai_api_headers',
    'HF_TOKEN': 'runtime_hf_token',
    'CORS_PROXY': 'runtime_cors_proxy',
  };

  static Future<String?> get(String key) async {
    final prefs = await _prefs();
    final mapped = _keys[key];
    if (mapped == null) return null;
    return prefs.getString(mapped);
  }

  static Future<void> set(String key, String? value) async {
    final prefs = await _prefs();
    final mapped = _keys[key];
    if (mapped == null) return;
    if (value == null || value.isEmpty) {
      await prefs.remove(mapped);
    } else {
      await prefs.setString(mapped, value);
    }
  }
}
