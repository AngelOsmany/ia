import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/api_response.dart';
import '../models/rest_models.dart';

/// Servicio REST API - JSONPlaceholder (API gratuita de prueba)
/// No requiere autenticación
class RestApiService {
  static const String baseUrl = 'https://jsonplaceholder.typicode.com';

  // GET - Obtener todos los posts
  static Future<ApiResponse<List<Post>>> getAllPosts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/posts'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        final posts = jsonList.map((p) => Post.fromJson(p)).toList();
        return ApiResponse.success(posts);
      } else {
        return ApiResponse.error(
          'Error: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Error en la conexión: ${e.toString()}');
    }
  }

  // GET - Obtener un post por ID
  static Future<ApiResponse<Post>> getPostById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/posts/$id'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final post = Post.fromJson(jsonDecode(response.body));
        return ApiResponse.success(post);
      } else {
        return ApiResponse.error('Post no encontrado');
      }
    } catch (e) {
      return ApiResponse.error('Error: ${e.toString()}');
    }
  }

  // GET - Obtener usuarios
  static Future<ApiResponse<List<User>>> getAllUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        final users = jsonList.map((u) => User.fromJson(u)).toList();
        return ApiResponse.success(users);
      } else {
        return ApiResponse.error('Error al obtener usuarios');
      }
    } catch (e) {
      return ApiResponse.error('Error: ${e.toString()}');
    }
  }

  // POST - Crear un nuevo post
  static Future<ApiResponse<Post>> createPost({
    required String title,
    required String body,
    required int userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/posts'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'body': body,
          'userId': userId,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        final post = Post.fromJson(jsonDecode(response.body));
        return ApiResponse.success(post);
      } else {
        return ApiResponse.error('Error al crear post');
      }
    } catch (e) {
      return ApiResponse.error('Error: ${e.toString()}');
    }
  }

  // PUT - Actualizar un post
  static Future<ApiResponse<Post>> updatePost({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/posts/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'body': body,
          'id': id,
          'userId': 1,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final post = Post.fromJson(jsonDecode(response.body));
        return ApiResponse.success(post);
      } else {
        return ApiResponse.error('Error al actualizar');
      }
    } catch (e) {
      return ApiResponse.error('Error: ${e.toString()}');
    }
  }

  // DELETE - Eliminar un post
  static Future<ApiResponse<String>> deletePost(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/posts/$id'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return ApiResponse.success('Post eliminado correctamente');
      } else {
        return ApiResponse.error('Error al eliminar');
      }
    } catch (e) {
      return ApiResponse.error('Error: ${e.toString()}');
    }
  }
}
