import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ai_provider.dart';
import '../models/ai_models.dart';
import 'message_bubble.dart';

class ChatWidget extends StatelessWidget {
  const ChatWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AIProvider>(context);

    return Column(
      children: [
        // Lista de mensajes
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            reverse: false,
            itemCount: provider.messages.length,
            itemBuilder: (context, index) {
              final message = provider.messages[index];
              return MessageBubble(message: message);
            },
          ),
        ),

        // Indicador de carga
        if (provider.isLoading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text('La IA está pensando...'),
              ],
            ),
          ),

        // Input de mensaje
        _MessageInput(provider: provider),
      ],
    );
  }
}

class _MessageInput extends StatefulWidget {
  final AIProvider provider;

  const _MessageInput({required this.provider});

  @override
  State<_MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<_MessageInput> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      widget.provider.sendMessage(text);
      _textController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        children: [
          // Botón para limpiar chat
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: widget.provider.clearMessages,
            tooltip: 'Limpiar chat',
          ),
          
          // Campo de texto
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: _getHintText(widget.provider.currentFeature),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          
          // Botón enviar
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _sendMessage,
            color: Colors.blue[800],
            tooltip: 'Enviar mensaje',
          ),
        ],
      ),
    );
  }

  String _getHintText(String feature) {
    switch (feature) {
      case 'chat':
        return 'Escribe un mensaje para chatear...';
      case 'sentiment':
        return 'Escribe texto para analizar sentimientos...';
      case 'image':
        return 'Describe la imagen que quieres generar...';
      default:
        return 'Escribe tu mensaje...';
    }
  }
}