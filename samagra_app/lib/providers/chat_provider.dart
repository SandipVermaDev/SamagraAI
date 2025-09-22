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

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  AIModel get selectedModel => _selectedModel;
  DocumentState get documentState => _documentState;
  bool get isLoading => _isLoading;
  bool get hasActiveDocument => _documentState.hasDocument;

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
      _documentState = DocumentState(
        file: file,
        fileName: file.path.split('/').last.split('\\').last,
        filePath: file.path,
        fileSize: file.lengthSync(),
        uploadTime: DateTime.now(),
      );
      debugPrint(
        '[ChatProvider] setDocument: fileName=${_documentState.fileName} size=${_documentState.fileSize}',
      );
    }
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
    _documentState = DocumentState(
      bytes: bytes,
      fileName: name,
      filePath: null,
      fileSize: size,
      uploadTime: DateTime.now(),
    );
    notifyListeners();
  }

  void clearDocument() {
    _documentState = DocumentState.empty;
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
          : MessageType.text,
      timestamp: DateTime.now(),
      imagePath: imagePath,
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

    debugPrint(
      '[ChatProvider] sendMessage: message="$content" imagePath=$imagePath imageBytes=${imageBytes?.length} document=${_documentState.fileName}',
    );
    try {
      String? uploadedDocumentName;
      if (_documentState.hasDocument) {
        debugPrint(
          '[ChatProvider] sendMessage: uploading document before sending message',
        );
        uploadedDocumentName = await _chatService.uploadDocument(
          _documentState,
        );
        debugPrint(
          '[ChatProvider] sendMessage: uploadedDocumentName=$uploadedDocumentName',
        );
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
