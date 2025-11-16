// Config wrapper: prefer `.env` variables (via flutter_dotenv), then `--dart-define`,
// then fall back to `lib/secrets.dart` for web builds.
import 'package:flutter_dotenv/flutter_dotenv.dart' as dotenv;
import 'secrets.dart' as secrets;

class Config {
  static String get geminiKey {
    final env = dotenv.dotenv.env['GEMINI_API_KEY'];
    if (env != null && env.isNotEmpty) return env;
    final define = const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
    return define.isNotEmpty ? define : secrets.Secrets.geminiKey;
  }

  static String get cohereKey {
    final env = dotenv.dotenv.env['COHERE_API_KEY'];
    if (env != null && env.isNotEmpty) return env;
    final define = const String.fromEnvironment('COHERE_API_KEY', defaultValue: '');
    return define.isNotEmpty ? define : secrets.Secrets.cohereKey;
  }

  static String get hfKey {
    final env = dotenv.dotenv.env['HF_API_KEY'];
    if (env != null && env.isNotEmpty) return env;
    final define = const String.fromEnvironment('HF_API_KEY', defaultValue: '');
    return define.isNotEmpty ? define : secrets.Secrets.hfKey;
  }

  static String get stabilityKey {
    final env = dotenv.dotenv.env['STABILITY_API_KEY'];
    if (env != null && env.isNotEmpty) return env;
    final define = const String.fromEnvironment('STABILITY_API_KEY', defaultValue: '');
    return define.isNotEmpty ? define : secrets.Secrets.stabilityKey;
  }
}
