import 'package:flutter/material.dart';
import '../services/ai_service.dart';

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  final promptController = TextEditingController();
  String _selectedModel = 'weather';
  String _result = '';
  bool _isLoading = false;

  Future<void> _callApi() async {
    if (promptController.text.isEmpty && _selectedModel != 'weather') {
      _showSnackBar('Por favor ingresa un texto');
      return;
    }

    setState(() {
      _isLoading = true;
      _result = 'Procesando...';
    });

    try {
      switch (_selectedModel) {
        case 'weather':
          final response = await AiService.getWeather(
            latitude: 40.7128,
            longitude: -74.0060,
          );
          if (response.success) {
            final data = response.data;
            _result = '''
Clima en Nueva York:
- Temperatura: ${data?['current']?['temperature_2m']}°C
- Código: ${data?['current']?['weather_code']}
''';
          } else {
            _result = response.error ?? 'Error';
          }
          break;

        case 'translate':
          final response = await AiService.translateText(
            text: promptController.text,
            targetLanguage: 'es',
          );
          if (response.success) {
            _result = 'Traducción: ${response.data}';
          } else {
            _result = response.error ?? 'Error';
          }
          break;
      }
    } catch (e) {
      _result = 'Error: ${e.toString()}';
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'APIs Funcionales',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Clima y Traducción',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                DropdownButton<String>(
                  value: _selectedModel,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'weather', child: Text('⛅ Clima - Open-Meteo')),
                    DropdownMenuItem(value: 'translate', child: Text('🌐 Traducir - MyMemory')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedModel = value ?? 'weather';
                      _result = '';
                    });
                  },
                ),
                const SizedBox(height: 12),
                if (_selectedModel != 'weather')
                  TextField(
                    controller: promptController,
                    decoration: InputDecoration(
                      label: const Text('Ingresa texto a traducir'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    maxLines: 3,
                  ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : _callApi,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Ejecutar'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (_result.isNotEmpty)
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Resultado:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(_result),
                ],
              ),
            ),
          ),
        const SizedBox(height: 24),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'APIs Disponibles:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildApiInfo('Open-Meteo', 'Datos climatológicos', 'Sin autenticación'),
                _buildApiInfo('MyMemory', 'Traducción', 'Gratuito'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildApiInfo(String name, String description, String pricing) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(description, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(pricing, style: const TextStyle(fontSize: 12, color: Colors.blue)),
          const Divider(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    promptController.dispose();
    super.dispose();
  }
}
