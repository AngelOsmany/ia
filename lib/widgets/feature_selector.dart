import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ai_provider.dart';

class FeatureSelector extends StatelessWidget {
  const FeatureSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AIProvider>(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selecciona una función de IA:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // SOLO 3 OPCIONES - SIN TRADUCCIÓN
              _FeatureChip(
                label: '💬 Chat IA',
                value: 'chat',
                currentFeature: provider.currentFeature,
                onSelected: () => provider.setFeature('chat'),
              ),
              _FeatureChip(
                label: '😊 Análisis Sentimientos', 
                value: 'sentiment',
                currentFeature: provider.currentFeature,
                onSelected: () => provider.setFeature('sentiment'),
              ),
              _FeatureChip(
                label: '🖼️ Generar Imagen',
                value: 'image',
                currentFeature: provider.currentFeature,
                onSelected: () => provider.setFeature('image'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final String label;
  final String value;
  final String currentFeature;
  final VoidCallback onSelected;

  const _FeatureChip({
    required this.label,
    required this.value,
    required this.currentFeature,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currentFeature == value;
    
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: Colors.blue[800],
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
      ),
      backgroundColor: Colors.grey[200],
    );
  }
}