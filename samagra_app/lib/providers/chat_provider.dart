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
  // File names of documents staged for the next message (UI preview above input)
  final List<String> _pendingAttachmentNames = [];
  // Pending image (for next message only)
  String? _pendingImagePath;
  Uint8List? _pendingImageBytes;
  String? _pendingImageName;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  AIModel get selectedModel => _selectedModel;
  DocumentState get documentState => _documentState;
  bool get isLoading => _isLoading;
  bool get hasActiveDocument => _documentState.hasDocument;
  bool get hasPendingImage =>
      _pendingImagePath != null || _pendingImageBytes != null;
  bool get showInputPreview =>
      _showInputPreview &&
      (_pendingAttachmentNames.isNotEmpty || hasPendingImage);
  List<SingleDocument> get pendingDocuments => _documentState.documents
      .where((d) => _pendingAttachmentNames.contains(d.fileName))
      .toList();
  String? get pendingImagePath => _pendingImagePath;
  Uint8List? get pendingImageBytes => _pendingImageBytes;
  String? get pendingImageName => _pendingImageName;

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
      if (!_pendingAttachmentNames.contains(document.fileName)) {
        _pendingAttachmentNames.add(document.fileName);
      }
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
      if (!_pendingAttachmentNames.contains(document.fileName)) {
        _pendingAttachmentNames.add(document.fileName);
      }
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
    if (!_pendingAttachmentNames.contains(document.fileName)) {
      _pendingAttachmentNames.add(document.fileName);
    }
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
      if (!_pendingAttachmentNames.contains(document.fileName)) {
        _pendingAttachmentNames.add(document.fileName);
      }
      debugPrint('[ChatProvider] Added web document: ${document.fileName}');
    }
    _showInputPreview = true; // Show preview when new documents are added
    notifyListeners();
  }

  void removeDocument(String fileName) {
    _documentState = _documentState.removeDocument(fileName);
    _pendingAttachmentNames.remove(fileName);
    notifyListeners();
  }

  void clearDocument() {
    _documentState = DocumentState.empty;
    _showInputPreview =
        true; // Reset preview visibility when clearing documents
    _pendingAttachmentNames.clear();
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

  // Clear only the staged (pending) attachments but keep the indexed documents
  void clearPendingAttachments() {
    _pendingAttachmentNames.clear();
    _showInputPreview = false; // hide preview since nothing staged
    notifyListeners();
  }

  // Pending image controls
  void setPendingImageFromPath(String path, String name) {
    _pendingImagePath = path;
    _pendingImageBytes = null;
    _pendingImageName = name;
    _showInputPreview = true;
    notifyListeners();
  }

  void setPendingImageFromBytes(Uint8List bytes, String name) {
    _pendingImageBytes = bytes;
    _pendingImagePath = null;
    _pendingImageName = name;
    _showInputPreview = true;
    notifyListeners();
  }

  void clearPendingImage() {
    _pendingImagePath = null;
    _pendingImageBytes = null;
    _pendingImageName = null;
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
    final bool includeImage = hasPendingImage;
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
      imagePath: includeImage ? _pendingImagePath : null,
      imageBytes: includeImage ? _pendingImageBytes : null,
      imageName: includeImage ? _pendingImageName : null,
      // Attach only currently staged documents to THIS message
      attachedDocuments: (_documentState.hasDocument && _showInputPreview)
          ? List<String>.from(_pendingAttachmentNames)
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
    if (includeImage) {
      if (_pendingImagePath != null)
        debugPrint('  imagePath=$_pendingImagePath');
      if (_pendingImageBytes != null)
        debugPrint('  imageBytes=${_pendingImageBytes!.length}');
    }
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

      // Get AI response via streaming
      final messageIndex = _messages.indexWhere((msg) => msg.id == aiMessageId);
      if (messageIndex == -1) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      String accumulatedResponse = '';

      await for (final chunk in _chatService.sendMessageStream(
        message: content,
        model: _selectedModel,
        documentState: _documentState,
        imagePath: includeImage ? _pendingImagePath : null,
        imageBytes: includeImage ? _pendingImageBytes : null,
        imageName: includeImage ? _pendingImageName : null,
        uploadedDocumentName: uploadedDocumentName,
      )) {
        // Check for clear signal
        if (chunk == '\u0000CLEAR\u0000') {
          accumulatedResponse = '';
          _messages[messageIndex] = _messages[messageIndex].copyWith(
            content: '',
            isLoading: true,
          );
          notifyListeners();
          continue;
        }

        // Accumulate the response
        accumulatedResponse += chunk;

        // Update the AI message with streaming content
        _messages[messageIndex] = _messages[messageIndex].copyWith(
          content: accumulatedResponse,
          isLoading: true, // Keep loading indicator during streaming
        );
        notifyListeners();
      }

      // Mark as complete
      _messages[messageIndex] = _messages[messageIndex].copyWith(
        content: accumulatedResponse,
        isLoading: false,
      );

      // Hide input preview after successful message send
      if (_showInputPreview) {
        hideInputPreview();
        _pendingAttachmentNames.clear();
        clearPendingImage();
        debugPrint(
          '[ChatProvider] sendMessage: cleared staged docs/images and hid preview after successful send',
        );
      }

      notifyListeners();
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
