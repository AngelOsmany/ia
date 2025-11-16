import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/ai_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load .env on native platforms only (web will use Config defaults).
  // Wrapped in try-catch to handle missing .env gracefully.
  if (!identical(0, 0.0)) {  // kIsWeb equivalent
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      // .env not found, continue with defaults from Config/secrets.dart
      print('Warning: .env file not found, using defaults');
    }
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IA & APIs Modernas',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AiScreen(),
    );
  }
}
// Home page replaced by direct AiScreen as the app only exposes Clima/Traducción

