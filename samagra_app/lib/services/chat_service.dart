import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/ai_model.dart';
import '../models/document_state.dart';

class ChatService {
  static const String baseUrl = 'http://localhost:8000'; // Your backend URL

  /// Test if the backend is reachable
  Future<bool> testConnection() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<String> sendMessage({
    required String message,
    required AIModel model,
    DocumentState? documentState,
    String? imagePath,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/chat');

      // Prepare the request body to match backend schema
      Map<String, dynamic> body = {'message': message};

      // TODO: Add support for document and image when backend supports it
      // For now, just send the basic message

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['reply'] as String? ?? 'No response from AI';
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error sending message: $e');
    }
  }

  Future<bool> uploadDocument(File file) async {
    try {
      final uri = Uri.parse('$baseUrl/documents/upload');
      final request = http.MultipartRequest('POST', uri);

      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List<String>> getDocumentContent(String filename) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/documents/$filename'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['content'] ?? []);
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
