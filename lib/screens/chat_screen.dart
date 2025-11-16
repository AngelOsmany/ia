import 'package:flutter/material.dart';
import '../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
  }

  Future<void> _connectWebSocket() async {
    final connected = await _chatService.connect();
    setState(() {
      _isConnected = connected;
    });

    if (connected) {
      _chatService.messageStream.listen((message) {
        setState(() {
          _messages.add(message);
        });
      }, onError: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      });
    }
  }

  void _sendMessage() {
    if (messageController.text.isEmpty) return;

    final message = ChatMessage(
      sender: 'Yo',
      message: messageController.text,
      timestamp: DateTime.now(),
      isUser: true,
    );

    setState(() {
      _messages.add(message);
    });

    _chatService.sendMessage('User', messageController.text);
    messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: _isConnected ? Colors.green : Colors.red,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 6,
                backgroundColor: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                _isConnected ? 'Conectado' : 'Desconectado',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            reverse: true,
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[_messages.length - 1 - index];
              return _buildMessageBubble(message);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: messageController,
                  decoration: InputDecoration(
                    hintText: 'Escribe un mensaje...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FloatingActionButton(
                onPressed: _isConnected ? _sendMessage : null,
                child: const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.sender,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isUser ? Colors.white : Colors.black,
              ),
            ),
            Text(
              message.message,
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    messageController.dispose();
    _chatService.disconnect();
    super.dispose();
  }
}
