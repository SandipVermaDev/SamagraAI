import 'dart:convert';
import 'package:flutter/foundation.dart';
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
    Uint8List? imageBytes,
    String? imageName,
    String? uploadedDocumentName,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/chat');

      // Prepare the request body to match backend schema
      Map<String, dynamic> body = {'message': message, 'model': model.id};

      // Keep request lean; backend will use session/cumulative store.
      if (documentState != null && documentState.hasDocument) {
        body['documentsCount'] = documentState.totalDocuments;
        body['documents'] = documentState.fileNames;
      }

      if (uploadedDocumentName != null) {
        body['uploadedDocumentName'] = uploadedDocumentName;
      }

      // Send unprocessed documents to backend
      // No longer bundle document bytes in chat payload; uploads handled via uploadSingleDocument.

      if (imagePath != null) {
        body['imagePath'] = imagePath;
      }

      if (imageBytes != null) {
        // For web, we have image bytes instead of a file path
        // TODO: Implement image processing in backend
        debugPrint(
          '[ChatService] sendMessage: including image bytes size=${imageBytes.length}',
        );
        // For now, just inform that we have image data
        // Match backend schema: send imageBase64 and imageName
        body['imageBase64'] = base64Encode(imageBytes);
        body['imageName'] = imageName ?? 'capture.png';
      }

      debugPrint('[ChatService] sendMessage: POST $uri');
      debugPrint(
        '  payload: messageLen=${message.length}, model=${model.id}, docs=${documentState?.totalDocuments ?? 0}, hasImage=${imagePath != null || imageBytes != null}',
      );

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      debugPrint('[ChatService] sendMessage: status=${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['reply'] as String? ?? 'No response from AI';
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('[ChatService] sendMessage: error -> $e');
      throw Exception('Error sending message: $e');
    }
  }

  /// Uploads a document. Supports both dart:io File (desktop/mobile) and
  /// in-memory bytes (web). Returns the uploaded filename (as returned by
  /// the server) on success, or null on failure.
  Future<String?> uploadDocument(DocumentState doc) async {
    try {
      final uri = Uri.parse('$baseUrl/documents/upload');
      final request = http.MultipartRequest('POST', uri);

      debugPrint(
        '[ChatService] uploadDocument: preparing upload for ${doc.fileName}',
      );

      if (doc.bytes != null) {
        // Web: bytes available
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            doc.bytes!,
            filename: doc.fileName ?? 'upload',
          ),
        );
      } else if (doc.file != null) {
        // Mobile/desktop: file path available
        debugPrint(
          '[ChatService] uploadDocument: uploading file path=${doc.file!.path}',
        );
        request.files.add(
          await http.MultipartFile.fromPath('file', doc.file!.path),
        );
      } else {
        debugPrint('[ChatService] uploadDocument: no file or bytes to upload');
        return null;
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      debugPrint(
        '[ChatService] uploadDocument: status=${response.statusCode} body=${response.body}',
      );

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          // Try common keys for uploaded filename
          final uploadedName =
              data['filename'] ?? data['fileName'] ?? data['name'];
          if (uploadedName != null && uploadedName is String) {
            return uploadedName;
          }
        } catch (_) {
          // ignore parse errors
        }
        // Fallback to original name
        return doc.fileName;
      }

      return null;
    } catch (e) {
      debugPrint('[ChatService] uploadDocument: error -> $e');
      return null;
    }
  }

  /// Upload a single document (SingleDocument) and return the uploaded filename.
  Future<String?> uploadSingleDocument(SingleDocument doc) async {
    try {
      final uri = Uri.parse('$baseUrl/documents/upload');
      final request = http.MultipartRequest('POST', uri);

      debugPrint('[ChatService] uploadSingleDocument: ${doc.fileName}');

      if (doc.bytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            doc.bytes!,
            filename: doc.fileName,
          ),
        );
      } else if (doc.file != null) {
        request.files.add(
          await http.MultipartFile.fromPath('file', doc.file!.path),
        );
      } else {
        debugPrint('[ChatService] uploadSingleDocument: no file/bytes');
        return null;
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      debugPrint(
        '[ChatService] uploadSingleDocument: status=${response.statusCode}',
      );

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          final uploadedName =
              data['filename'] ?? data['fileName'] ?? data['name'];
          if (uploadedName is String) return uploadedName;
        } catch (_) {}
        return doc.fileName;
      }
      return null;
    } catch (e) {
      debugPrint('[ChatService] uploadSingleDocument: error -> $e');
      return null;
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

  /// Send message with streaming response
  Stream<String> sendMessageStream({
    required String message,
    required AIModel model,
    DocumentState? documentState,
    String? imagePath,
    Uint8List? imageBytes,
    String? imageName,
    String? uploadedDocumentName,
  }) async* {
    try {
      final uri = Uri.parse('$baseUrl/chat/stream');

      // Prepare the request body
      Map<String, dynamic> body = {'message': message, 'model': model.id};

      if (documentState != null && documentState.hasDocument) {
        body['documentsCount'] = documentState.totalDocuments;
        body['documents'] = documentState.fileNames;
      }

      if (uploadedDocumentName != null) {
        body['uploadedDocumentName'] = uploadedDocumentName;
      }

      if (imagePath != null) {
        body['imagePath'] = imagePath;
      }

      if (imageBytes != null) {
        body['imageBase64'] = base64Encode(imageBytes);
        body['imageName'] = imageName ?? 'capture.png';
      }

      debugPrint('[ChatService] sendMessageStream: POST $uri');

      final request = http.Request('POST', uri);
      request.headers['Content-Type'] = 'application/json';
      request.headers['Accept'] = 'text/event-stream';
      request.body = jsonEncode(body);

      final client = http.Client();
      final streamedResponse = await client.send(request);

      debugPrint(
        '[ChatService] sendMessageStream: status=${streamedResponse.statusCode}',
      );

      if (streamedResponse.statusCode == 200) {
        // Parse SSE stream
        await for (var chunk in streamedResponse.stream.transform(
          utf8.decoder,
        )) {
          // Split by lines for SSE format
          final lines = chunk.split('\n');
          for (var line in lines) {
            if (line.startsWith('data: ')) {
              final jsonStr = line.substring(6); // Remove 'data: ' prefix
              try {
                final data = jsonDecode(jsonStr);
                if (data['content'] != null) {
                  yield data['content'] as String;
                }
                if (data['done'] == true) {
                  debugPrint(
                    '[ChatService] sendMessageStream: stream complete',
                  );
                  break;
                }
                if (data['clear'] == true) {
                  // Signal to clear previous content
                  yield '\u0000CLEAR\u0000';
                }
              } catch (e) {
                debugPrint(
                  '[ChatService] sendMessageStream: parse error -> $e',
                );
              }
            }
          }
        }
      } else {
        throw Exception('HTTP ${streamedResponse.statusCode}');
      }
    } catch (e) {
      debugPrint('[ChatService] sendMessageStream: error -> $e');
      yield 'Error: $e';
    }
  }
}
