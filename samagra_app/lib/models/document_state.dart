import 'dart:io';
import 'dart:typed_data';

class SingleDocument {
  final File? file;
  final Uint8List? bytes;
  final String fileName;
  final String? filePath;
  final int fileSize;
  final DateTime uploadTime;
  final bool isProcessedByBackend;
  final bool isImage; // Flag to distinguish images from documents

  const SingleDocument({
    this.file,
    this.bytes,
    required this.fileName,
    this.filePath,
    required this.fileSize,
    required this.uploadTime,
    this.isProcessedByBackend = false,
    this.isImage = false,
  });

  bool get hasDocument => file != null || bytes != null;

  SingleDocument copyWith({
    File? file,
    Uint8List? bytes,
    String? fileName,
    String? filePath,
    int? fileSize,
    DateTime? uploadTime,
    bool? isProcessedByBackend,
    bool? isImage,
  }) {
    return SingleDocument(
      file: file ?? this.file,
      bytes: bytes ?? this.bytes,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      uploadTime: uploadTime ?? this.uploadTime,
      isProcessedByBackend: isProcessedByBackend ?? this.isProcessedByBackend,
      isImage: isImage ?? this.isImage,
    );
  }

  String get displayName => fileName;

  String get sizeText {
    final kb = fileSize / 1024;
    if (kb < 1024) {
      return '${kb.toStringAsFixed(1)} KB';
    } else {
      final mb = kb / 1024;
      return '${mb.toStringAsFixed(1)} MB';
    }
  }
}

class DocumentState {
  final List<SingleDocument> documents;

  const DocumentState({this.documents = const []});

  bool get hasDocument => documents.isNotEmpty;

  int get totalDocuments => documents.length;

  int get totalSize => documents.fold(0, (sum, doc) => sum + doc.fileSize);

  List<String> get fileNames => documents.map((doc) => doc.fileName).toList();

  // Get only documents (not images)
  List<SingleDocument> get documentsOnly =>
      documents.where((doc) => !doc.isImage).toList();

  // Get only images
  List<SingleDocument> get imagesOnly =>
      documents.where((doc) => doc.isImage).toList();

  // Count documents and images separately
  int get documentCount => documentsOnly.length;
  int get imageCount => imagesOnly.length;

  bool get allProcessed =>
      documents.isNotEmpty &&
      documents.every((doc) => doc.isProcessedByBackend);

  // Get the first document for backward compatibility
  SingleDocument? get firstDocument =>
      documents.isNotEmpty ? documents.first : null;

  // Backward compatibility getters
  File? get file => firstDocument?.file;
  Uint8List? get bytes => firstDocument?.bytes;
  String? get fileName => firstDocument?.fileName;
  String? get filePath => firstDocument?.filePath;
  int? get fileSize => firstDocument?.fileSize;
  DateTime? get uploadTime => firstDocument?.uploadTime;
  bool get isProcessedByBackend => firstDocument?.isProcessedByBackend ?? false;

  DocumentState copyWith({List<SingleDocument>? documents}) {
    return DocumentState(documents: documents ?? this.documents);
  }

  DocumentState addDocument(SingleDocument document) {
    final updatedDocuments = List<SingleDocument>.from(documents);
    updatedDocuments.add(document);
    return DocumentState(documents: updatedDocuments);
  }

  DocumentState removeDocument(String fileName) {
    final updatedDocuments = documents
        .where((doc) => doc.fileName != fileName)
        .toList();
    return DocumentState(documents: updatedDocuments);
  }

  DocumentState updateDocument(
    String fileName,
    SingleDocument updatedDocument,
  ) {
    final updatedDocuments = documents.map((doc) {
      if (doc.fileName == fileName) {
        return updatedDocument;
      }
      return doc;
    }).toList();
    return DocumentState(documents: updatedDocuments);
  }

  // Mark only a specific document as processed
  DocumentState markDocumentAsProcessed(String fileName) {
    final updatedDocuments = documents.map((doc) {
      if (doc.fileName == fileName) {
        return doc.copyWith(isProcessedByBackend: true);
      }
      return doc;
    }).toList();
    return DocumentState(documents: updatedDocuments);
  }

  // Mark a set of documents as processed
  DocumentState markDocumentsAsProcessed(Iterable<String> fileNames) {
    final set = fileNames.toSet();
    final updatedDocuments = documents.map((doc) {
      if (set.contains(doc.fileName)) {
        return doc.copyWith(isProcessedByBackend: true);
      }
      return doc;
    }).toList();
    return DocumentState(documents: updatedDocuments);
  }

  DocumentState markAllAsProcessed() {
    final updatedDocuments = documents
        .map((doc) => doc.copyWith(isProcessedByBackend: true))
        .toList();
    return DocumentState(documents: updatedDocuments);
  }

  static const DocumentState empty = DocumentState();

  String get displayName {
    if (documents.isEmpty) return 'No Documents';
    if (documents.length == 1) return documents.first.fileName;
    return '${documents.length} documents';
  }

  String get sizeText {
    if (documents.isEmpty) return '';

    final total = totalSize;
    if (total < 1024) {
      return '${total} B';
    } else if (total < 1024 * 1024) {
      return '${(total / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(total / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}
