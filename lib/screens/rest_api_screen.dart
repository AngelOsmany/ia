import 'package:flutter/material.dart';
import '../services/rest_api_service.dart';
import '../models/rest_models.dart';

class RestApiScreen extends StatefulWidget {
  const RestApiScreen({super.key});

  @override
  State<RestApiScreen> createState() => _RestApiScreenState();
}

class _RestApiScreenState extends State<RestApiScreen> {
  late Future<List<Post>> _postsFuture;
  final titleController = TextEditingController();
  final bodyController = TextEditingController();
  List<Post> _localPosts = [];
  int _nextId = 101; // JSONPlaceholder tiene posts hasta 100

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  void _loadPosts() {
    setState(() {
      _postsFuture = _getPosts();
    });
  }

  Future<List<Post>> _getPosts() async {
    try {
      final response = await RestApiService.getAllPosts();
      if (response.success && response.data != null) {
        // Combinar posts del servidor con posts locales creados
        final serverPosts = response.data!.take(10).toList();
        return [..._localPosts, ...serverPosts];
      } else {
        throw Exception(response.error ?? 'Error desconocido');
      }
    } catch (e) {
      return _localPosts;
    }
  }

  void _createPost() async {
    if (titleController.text.isEmpty || bodyController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor completa todos los campos')),
        );
      }
      return;
    }

    // Crear post localmente primero (feedback inmediato)
    final newPost = Post(
      id: _nextId,
      title: titleController.text,
      body: bodyController.text,
      userId: 1,
    );
    _nextId++;

    // Actualizar lista local
    setState(() {
      _localPosts.insert(0, newPost);
    });

    // Intentar crear en el servidor también
    final response = await RestApiService.createPost(
      title: titleController.text,
      body: bodyController.text,
      userId: 1,
    );

    if (mounted) {
      titleController.clear();
      bodyController.clear();
      
      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Post creado exitosamente en el servidor'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠ Post creado localmente (error servidor: ${response.error})'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _deletePost(int index) {
    setState(() {
      _localPosts.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Post eliminado')),
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
                  'REST API - JSONPlaceholder',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'API Gratuita para pruebas CRUD. No requiere autenticación.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    label: const Text('Título'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bodyController,
                  decoration: InputDecoration(
                    label: const Text('Contenido'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _createPost,
                  child: const Text('Crear Post'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Posts Recientes (${_localPosts.length} nuevos)',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<Post>>(
          future: _postsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No hay posts'));
            }

            final allPosts = snapshot.data!;
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: allPosts.length,
              itemBuilder: (context, index) {
                final post = allPosts[index];
                final isLocal = index < _localPosts.length;
                
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  color: isLocal ? Colors.blue[50] : null,
                  child: ListTile(
                    title: Text(post.title),
                    subtitle: Text(post.body),
                    trailing: isLocal
                        ? IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deletePost(index),
                          )
                        : Icon(
                            Icons.check_circle,
                            color: Colors.green[300],
                          ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    bodyController.dispose();
    super.dispose();
  }
}
