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

      if (documentState != null && documentState.hasDocument) {
        body['document'] = {
          'fileName': documentState.fileName,
          'fileSize': documentState.fileSize,
        };
      }

      if (uploadedDocumentName != null) {
        body['uploadedDocumentName'] = uploadedDocumentName;
      }

      // Send unprocessed documents to backend
      if (uploadedDocumentName == null &&
          documentState != null &&
          documentState.hasDocument &&
          !documentState.allProcessed) {
        // Find first unprocessed document
        final unprocessedDocs = documentState.documents
            .where((doc) => !doc.isProcessedByBackend)
            .toList();
        final unprocessedDoc = unprocessedDocs.isNotEmpty
            ? unprocessedDocs.first
            : null;

        if (unprocessedDoc != null) {
          try {
            if (unprocessedDoc.bytes != null) {
              final encoded = base64Encode(unprocessedDoc.bytes!);
              body['documentBase64'] = encoded;
              body['documentFilename'] = unprocessedDoc.fileName;
              debugPrint(
                '[ChatService] sendMessage: included documentBase64 (web) size=${unprocessedDoc.bytes!.length}',
              );
            } else if (unprocessedDoc.file != null) {
              try {
                final bytes = await unprocessedDoc.file!.readAsBytes();
                final encoded = base64Encode(bytes);
                body['documentBase64'] = encoded;
                body['documentFilename'] = unprocessedDoc.fileName;
                debugPrint(
                  '[ChatService] sendMessage: included documentBase64 (file) size=${bytes.length}',
                );
              } catch (e) {
                debugPrint(
                  '[ChatService] sendMessage: failed to read file bytes -> $e',
                );
              }
            }
          } catch (e) {
            debugPrint(
              '[ChatService] sendMessage: error encoding document -> $e',
            );
          }
        }
      } else if (documentState != null && documentState.hasDocument) {
        // For subsequent questions, just indicate we have documents but don't send the bytes again
        debugPrint(
          '[ChatService] sendMessage: ${documentState.totalDocuments} document(s) available, using existing processed documents for Q&A',
        );
      }

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

      debugPrint(
        '[ChatService] sendMessage: POST $uri body=${jsonEncode(body)}',
      );

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      debugPrint(
        '[ChatService] sendMessage: status=${response.statusCode} body=${response.body}',
      );

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
