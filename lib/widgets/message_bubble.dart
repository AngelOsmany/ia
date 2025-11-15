import 'dart:convert';

import 'package:flutter/material.dart';
import '../models/ai_models.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: message.isUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        children: [
          if (!message.isUser)
            const CircleAvatar(
              radius: 16,
              child: Icon(Icons.smart_toy, size: 18),
            ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isUser 
                    ? Colors.blue[800] 
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: _buildContent(),
            ),
          ),
          const SizedBox(width: 8),
          if (message.isUser)
            const CircleAvatar(
              radius: 16,
              child: Icon(Icons.person, size: 18),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    // Detect data URL images
    if (message.text.startsWith('data:')) {
      try {
        final commaIndex = message.text.indexOf(',');
        final meta = message.text.substring(5, commaIndex); // e.g. image/png;base64
        final isBase64 = meta.contains('base64');
        final dataPart = message.text.substring(commaIndex + 1);
        if (isBase64) {
          final bytes = base64Decode(dataPart);
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              bytes,
              width: 200,
              fit: BoxFit.cover,
            ),
          );
        }
      } catch (_) {
        // Fall back to text if anything fails
      }
    }

    return Text(
      message.text,
      style: TextStyle(
        color: message.isUser ? Colors.white : Colors.black87,
      ),
    );
  }
}