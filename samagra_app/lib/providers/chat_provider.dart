import 'dart:io';
import 'package:flutter/material.dart';
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
    if (file == null) {
      _documentState = DocumentState.empty;
    } else {
      _documentState = DocumentState(
        file: file,
        fileName: file.path.split('/').last.split('\\').last,
        filePath: file.path,
        fileSize: file.lengthSync(),
        uploadTime: DateTime.now(),
      );
    }
    notifyListeners();
  }

  void clearDocument() {
    _documentState = DocumentState.empty;
    notifyListeners();
  }

  Future<void> sendMessage(String content, {String? imagePath}) async {
    if (content.trim().isEmpty && imagePath == null) return;

    // Add user message
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      sender: MessageSender.user,
      type: imagePath != null ? MessageType.image : MessageType.text,
      timestamp: DateTime.now(),
      imagePath: imagePath,
    );

    _messages.add(userMessage);
    notifyListeners();

    // Add AI loading message
    final aiMessageId =
        DateTime.now().millisecondsSinceEpoch.toString() + '_ai';
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

    try {
      // Get AI response
      final aiResponse = await _chatService.sendMessage(
        message: content,
        model: _selectedModel,
        documentState: _documentState,
        imagePath: imagePath,
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
