import 'dart:io';
import 'dart:typed_data';

class DocumentState {
  final File? file;
  final Uint8List? bytes;
  final String? fileName;
  final String? filePath;
  final int? fileSize;
  final DateTime? uploadTime;

  const DocumentState({
    this.file,
    this.bytes,
    this.fileName,
    this.filePath,
    this.fileSize,
    this.uploadTime,
  });

  bool get hasDocument => file != null || bytes != null;

  DocumentState copyWith({
    File? file,
    Uint8List? bytes,
    String? fileName,
    String? filePath,
    int? fileSize,
    DateTime? uploadTime,
  }) {
    return DocumentState(
      file: file ?? this.file,
      bytes: bytes ?? this.bytes,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      uploadTime: uploadTime ?? this.uploadTime,
    );
  }

  static const DocumentState empty = DocumentState();

  String get displayName => fileName ?? 'Unknown Document';

  String get sizeText {
    if (fileSize == null) return '';

    if (fileSize! < 1024) {
      return '${fileSize!} B';
    } else if (fileSize! < 1024 * 1024) {
      return '${(fileSize! / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}
