enum MessageType { text, image, document, audio }

enum MessageSender { user, ai }

class ChatMessage {
  final String id;
  final String content;
  final MessageSender sender;
  final MessageType type;
  final DateTime timestamp;
  final bool isLoading;
  final String? imagePath;
  final String? documentPath;
  final String? documentName;
  final String? audioPath;
  final List<String>?
  attachedDocuments; // List of document names attached to this message

  ChatMessage({
    required this.id,
    required this.content,
    required this.sender,
    this.type = MessageType.text,
    required this.timestamp,
    this.isLoading = false,
    this.imagePath,
    this.documentPath,
    this.documentName,
    this.audioPath,
    this.attachedDocuments,
  });

  ChatMessage copyWith({
    String? id,
    String? content,
    MessageSender? sender,
    MessageType? type,
    DateTime? timestamp,
    bool? isLoading,
    String? imagePath,
    String? documentPath,
    String? documentName,
    String? audioPath,
    List<String>? attachedDocuments,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      sender: sender ?? this.sender,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isLoading: isLoading ?? this.isLoading,
      imagePath: imagePath ?? this.imagePath,
      documentPath: documentPath ?? this.documentPath,
      documentName: documentName ?? this.documentName,
      audioPath: audioPath ?? this.audioPath,
      attachedDocuments: attachedDocuments ?? this.attachedDocuments,
    );
  }

  bool get hasImage => imagePath != null && imagePath!.isNotEmpty;
  bool get hasDocument => documentPath != null && documentPath!.isNotEmpty;
  bool get hasAudio => audioPath != null && audioPath!.isNotEmpty;
  bool get hasAttachedDocuments =>
      attachedDocuments != null && attachedDocuments!.isNotEmpty;
}
