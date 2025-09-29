import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../models/ai_model.dart';
import '../models/document_state.dart';
import '../services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  final List<ChatMessage> _messages = [];
  AIModel _selectedModel = AIModel.getDefault();
  DocumentState _documentState = DocumentState.empty;
  bool _isLoading = false;
  bool _showInputPreview =
      true; // Controls visibility of document preview above input bar

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  AIModel get selectedModel => _selectedModel;
  DocumentState get documentState => _documentState;
  bool get isLoading => _isLoading;
  bool get hasActiveDocument => _documentState.hasDocument;
  bool get showInputPreview => _showInputPreview && _documentState.hasDocument;

  /// Test backend connectivity
  Future<bool> testBackendConnection() async {
    return await _chatService.testConnection();
  }

  void setSelectedModel(AIModel model) {
    _selectedModel = model;
    notifyListeners();
  }

  void setDocument(File? file) {
    debugPrint('[ChatProvider] setDocument called with file=${file?.path}');
    if (file == null) {
      _documentState = DocumentState.empty;
      debugPrint('[ChatProvider] setDocument: cleared document');
    } else {
      final document = SingleDocument(
        file: file,
        fileName: file.path.split('/').last.split('\\').last,
        filePath: file.path,
        fileSize: file.lengthSync(),
        uploadTime: DateTime.now(),
        isProcessedByBackend: false, // Reset processing flag for new document
      );
      _documentState = _documentState.addDocument(document);
      debugPrint(
        '[ChatProvider] setDocument: fileName=${document.fileName} size=${document.fileSize}',
      );
    }
    _showInputPreview = true; // Show preview when new document is set
    notifyListeners();
  }

  void addMultipleDocuments(List<File> files) {
    debugPrint(
      '[ChatProvider] addMultipleDocuments called with ${files.length} files',
    );
    for (final file in files) {
      final document = SingleDocument(
        file: file,
        fileName: file.path.split('/').last.split('\\').last,
        filePath: file.path,
        fileSize: file.lengthSync(),
        uploadTime: DateTime.now(),
        isProcessedByBackend: false,
      );
      _documentState = _documentState.addDocument(document);
      debugPrint('[ChatProvider] Added document: ${document.fileName}');
    }
    _showInputPreview = true; // Show preview when new documents are added
    notifyListeners();
  }

  /// On web, files may be provided as bytes. Use this helper to set document from bytes
  void setDocumentFromWeb({
    required Uint8List bytes,
    required String name,
    required int size,
  }) {
    debugPrint(
      '[ChatProvider] setDocumentFromWeb called name=$name size=$size',
    );
    final document = SingleDocument(
      bytes: bytes,
      fileName: name,
      filePath: null,
      fileSize: size,
      uploadTime: DateTime.now(),
      isProcessedByBackend: false, // Reset processing flag for new document
    );
    _documentState = _documentState.addDocument(document);
    notifyListeners();
  }

  void addMultipleDocumentsFromWeb(List<Map<String, dynamic>> files) {
    debugPrint(
      '[ChatProvider] addMultipleDocumentsFromWeb called with ${files.length} files',
    );
    for (final fileData in files) {
      final document = SingleDocument(
        bytes: fileData['bytes'] as Uint8List,
        fileName: fileData['name'] as String,
        filePath: null,
        fileSize: fileData['size'] as int,
        uploadTime: DateTime.now(),
        isProcessedByBackend: false,
      );
      _documentState = _documentState.addDocument(document);
      debugPrint('[ChatProvider] Added web document: ${document.fileName}');
    }
    _showInputPreview = true; // Show preview when new documents are added
    notifyListeners();
  }

  void removeDocument(String fileName) {
    _documentState = _documentState.removeDocument(fileName);
    notifyListeners();
  }

  void clearDocument() {
    _documentState = DocumentState.empty;
    _showInputPreview =
        true; // Reset preview visibility when clearing documents
    notifyListeners();
  }

  void hideInputPreview() {
    _showInputPreview = false;
    notifyListeners();
  }

  void resetInputPreview() {
    _showInputPreview = true;
    notifyListeners();
  }

  Future<void> sendMessage(
    String content, {
    String? imagePath,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    if (content.trim().isEmpty && imagePath == null && imageBytes == null) {
      return;
    }

    // Add user message
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      sender: MessageSender.user,
      type: (imagePath != null || imageBytes != null)
          ? MessageType.image
          : _documentState.hasDocument
          ? MessageType.document
          : MessageType.text,
      timestamp: DateTime.now(),
      imagePath: imagePath,
      // Attach documents to THIS message only when the input preview
      // is currently being shown (i.e., user just selected them).
      attachedDocuments: (_documentState.hasDocument && _showInputPreview)
          ? _documentState.fileNames
          : null,
    );

    _messages.add(userMessage);
    notifyListeners();

    // Add AI loading message
    final aiMessageId = '${DateTime.now().millisecondsSinceEpoch}_ai';
    final aiMessage = ChatMessage(
      id: aiMessageId,
      content: '',
      sender: MessageSender.ai,
      type: MessageType.text,
      timestamp: DateTime.now(),
      isLoading: true,
    );

    _messages.add(aiMessage);
    _isLoading = true;
    notifyListeners();

    debugPrint('[ChatProvider] sendMessage:');
    debugPrint('  message="${content.replaceAll('\n', ' ')}"');
    if (imagePath != null) debugPrint('  imagePath=$imagePath');
    if (imageBytes != null) debugPrint('  imageBytes=${imageBytes.length}');
    if (_documentState.hasDocument) {
      final pending = _documentState.documents
          .where((d) => !d.isProcessedByBackend)
          .map((d) => d.fileName)
          .toList();
      debugPrint('  documents total=${_documentState.totalDocuments}');
      debugPrint(
        '  pendingProcess=${pending.isEmpty ? 'none' : pending.join(', ')}',
      );
    }
    try {
      // Upload any unprocessed documents first (support multiple)
      String? uploadedDocumentName; // kept for backward compatibility
      if (_documentState.hasDocument && !_documentState.allProcessed) {
        final unprocessedDocs = _documentState.documents
            .where((d) => !d.isProcessedByBackend)
            .toList();
        for (final doc in unprocessedDocs) {
          debugPrint('  uploading doc: ${doc.fileName}');
          final uploaded = await _chatService.uploadSingleDocument(doc);
          if (uploaded != null) {
            uploadedDocumentName = uploaded; // last uploaded name
            _documentState = _documentState.markDocumentAsProcessed(
              doc.fileName,
            );
          }
        }
      }
      // Get AI response
      final aiResponse = await _chatService.sendMessage(
        message: content,
        model: _selectedModel,
        documentState: _documentState,
        imagePath: imagePath,
        imageBytes: imageBytes,
        imageName: imageName,
        uploadedDocumentName: uploadedDocumentName,
      );

      // Update the AI message with the response
      final messageIndex = _messages.indexWhere((msg) => msg.id == aiMessageId);
      if (messageIndex != -1) {
        _messages[messageIndex] = _messages[messageIndex].copyWith(
          content: aiResponse,
          isLoading: false,
        );

        // If the response indicates document was processed successfully, mark all as processed
        // No longer infer processing from response; processing is tracked
        // when uploads succeed above. Left here intentionally minimal.

        // Hide input preview after successful message send (keep documents for top banner)
        if (_documentState.hasDocument && _showInputPreview) {
          hideInputPreview();
          debugPrint(
            '[ChatProvider] sendMessage: hid input preview after successful send',
          );
        }

        notifyListeners();
      }
    } catch (e) {
      // Handle error
      debugPrint('[ChatProvider] sendMessage: error -> $e');
      final messageIndex = _messages.indexWhere((msg) => msg.id == aiMessageId);
      if (messageIndex != -1) {
        _messages[messageIndex] = _messages[messageIndex].copyWith(
          content: 'Sorry, I encountered an error: ${e.toString()}',
          isLoading: false,
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearChat() {
    _messages.clear();
    notifyListeners();
  }

  void addMessage(ChatMessage message) {
    _messages.add(message);
    notifyListeners();
  }

  void removeMessage(String messageId) {
    _messages.removeWhere((msg) => msg.id == messageId);
    notifyListeners();
  }
}
