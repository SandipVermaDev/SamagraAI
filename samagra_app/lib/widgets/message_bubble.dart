import 'dart:io';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/chat_message.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isLastMessage;

  const MessageBubble({
    super.key,
    required this.message,
    this.isLastMessage = false,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == MessageSender.user;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Row(
      mainAxisAlignment: isUser
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        if (!isUser) ...[
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.mediumPurple,
            child: Icon(Icons.smart_toy, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Container(
            margin: EdgeInsets.only(
              left: isUser ? 32 : 0,
              right: isUser ? 0 : 32,
            ),
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isUser
                        ? themeProvider.getUserMessageBg(context)
                        : themeProvider.getAiMessageBg(context),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Attached documents preview
                      if (message.hasAttachedDocuments)
                        _buildAttachedDocuments(context, themeProvider),

                      // Message content
                      if (message.content.isNotEmpty)
                        _buildMessageContent(context, isUser, themeProvider),

                      // Image preview if present
                      if (message.hasImage)
                        _buildImagePreview(context),

                      // Loading indicator for AI messages
                      if (message.isLoading)
                        _buildLoadingIndicator(context, themeProvider),
                    ],
                  ),
                ),
                // Timestamp
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _formatTimestamp(message.timestamp),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: themeProvider.getTextHint(context),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isUser) ...[
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.mediumPurple,
            child: Icon(Icons.person, color: Colors.white, size: 16),
          ),
        ],
      ],
    );
  }

  Widget _buildImageErrorPlaceholder() {
    return Container(
      height: 200,
      width: 200,
      color: Colors.grey[300],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.broken_image,
            color: Colors.grey,
            size: 48,
          ),
          SizedBox(height: 8),
          Text(
            'Failed to load image',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _showImageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final isAiGeneratedImage =
            message.sender != MessageSender.user && message.imageBytes != null;
        final Widget? enlargedImage = message.imageBytes != null
            ? Image.memory(
                message.imageBytes!,
                fit: BoxFit.contain,
              )
            : (!kIsWeb && message.imagePath != null)
                ? Image.file(
                    File(message.imagePath!),
                    fit: BoxFit.contain,
                  )
                : null;

    final canDownload = message.imageBytes != null ||
      (!kIsWeb && message.imagePath != null && message.imagePath!.isNotEmpty);

    final size = MediaQuery.of(dialogContext).size;
        final dialogWidth = size.width * 0.9 > 600 ? 600.0 : size.width * 0.9;
        final dialogHeight = size.height * 0.8 > 700 ? 700.0 : size.height * 0.8;

        return Dialog(
          backgroundColor: Theme.of(dialogContext).dialogBackgroundColor,
          child: SizedBox(
            width: dialogWidth,
            height: dialogHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: enlargedImage != null
                        ? InteractiveViewer(
                            maxScale: 5,
                            minScale: 0.8,
                            child: Center(child: enlargedImage),
                          )
                        : Center(child: _buildImageErrorPlaceholder()),
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: const Text('Close'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: canDownload
                            ? () async {
                                await _downloadImage(dialogContext);
                              }
                            : null,
                        icon: const Icon(Icons.download),
                        label: Text(isAiGeneratedImage ? 'Download' : 'Save'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _downloadImage(BuildContext context) async {
    final snackBarMessenger = ScaffoldMessenger.maybeOf(context);

    try {
      final Uint8List? bytes = await _resolveImageBytes();
      if (bytes == null) {
        snackBarMessenger?.showSnackBar(
          const SnackBar(content: Text('Unable to access image data.')),
        );
        return;
      }

      final String originalName = _resolveFileName();
      final String extension = _extractExtension(originalName);
      final String extForSave = extension.isEmpty ? 'png' : extension;
      final String baseName = extension.isEmpty
          ? originalName.replaceAll(RegExp(r'\.+$'), '')
          : originalName.substring(0, originalName.length - extension.length - 1);
      final String sanitizedBaseName = baseName.isEmpty
          ? 'generated_image_${DateTime.now().millisecondsSinceEpoch}'
          : baseName;
      final String savedFileName = '$sanitizedBaseName.$extForSave';

      await FileSaver.instance.saveFile(
        name: sanitizedBaseName,
        bytes: bytes,
        ext: extForSave,
      );

      snackBarMessenger?.showSnackBar(
        SnackBar(content: Text('Image saved as $savedFileName')),
      );
    } catch (_) {
      snackBarMessenger?.showSnackBar(
        const SnackBar(content: Text('Failed to save image.')),
      );
    }
  }

  Future<Uint8List?> _resolveImageBytes() async {
    if (message.imageBytes != null) {
      return message.imageBytes;
    }

    if (message.imagePath != null && message.imagePath!.isNotEmpty) {
      if (kIsWeb) {
        return null;
      }

      try {
        return await File(message.imagePath!).readAsBytes();
      } catch (_) {
        return null;
      }
    }

    return null;
  }

  String _resolveFileName() {
    if (message.imageName != null && message.imageName!.isNotEmpty) {
      return message.imageName!;
    }

    if (message.imagePath != null && message.imagePath!.isNotEmpty) {
      return p.basename(message.imagePath!);
    }

    return 'generated_image_${DateTime.now().millisecondsSinceEpoch}.png';
  }

  String _extractExtension(String fileName) {
    final parts = fileName.split('.');
    if (parts.length < 2) {
      return '';
    }
    return parts.last.toLowerCase();
  }

  Widget _buildImagePreview(BuildContext context) {
    final isUser = message.sender == MessageSender.user;
    final bool isAiGeneratedImage = !isUser && message.imageBytes != null;

    final imageWidget = message.imageBytes != null
        ? Image.memory(
            message.imageBytes!,
            fit: isAiGeneratedImage ? BoxFit.contain : BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildImageErrorPlaceholder();
            },
          )
        : Image.file(
            File(message.imagePath!),
            height: 200,
            width: 200,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildImageErrorPlaceholder();
            },
          );

    return GestureDetector(
      onTap: () => _showImageDialog(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: isAiGeneratedImage ? 400 : 200,
          maxHeight: isAiGeneratedImage ? 400 : 200,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: imageWidget,
        ),
      ),
    );
  }

  Widget _buildMessageContent(
    BuildContext context,
    bool isUser,
    ThemeProvider themeProvider,
  ) {
    // For AI messages, render markdown
    if (!isUser) {
      return MarkdownBody(
        data: message.content,
        selectable: true,
        styleSheet: MarkdownStyleSheet(
          p: TextStyle(
            color: themeProvider.getAiMessageText(context),
            fontSize: 14,
            height: 1.5,
          ),
          h1: TextStyle(
            color: themeProvider.getAiMessageText(context),
            fontSize: 24,
            fontWeight: FontWeight.bold,
            height: 1.5,
          ),
          h2: TextStyle(
            color: themeProvider.getAiMessageText(context),
            fontSize: 20,
            fontWeight: FontWeight.bold,
            height: 1.5,
          ),
          h3: TextStyle(
            color: themeProvider.getAiMessageText(context),
            fontSize: 18,
            fontWeight: FontWeight.bold,
            height: 1.5,
          ),
          h4: TextStyle(
            color: themeProvider.getAiMessageText(context),
            fontSize: 16,
            fontWeight: FontWeight.bold,
            height: 1.5,
          ),
          h5: TextStyle(
            color: themeProvider.getAiMessageText(context),
            fontSize: 14,
            fontWeight: FontWeight.bold,
            height: 1.5,
          ),
          h6: TextStyle(
            color: themeProvider.getAiMessageText(context),
            fontSize: 14,
            fontWeight: FontWeight.bold,
            height: 1.5,
          ),
          em: TextStyle(
            color: themeProvider.getAiMessageText(context),
            fontStyle: FontStyle.italic,
          ),
          strong: TextStyle(
            color: themeProvider.getAiMessageText(context),
            fontWeight: FontWeight.bold,
          ),
          code: TextStyle(
            color: themeProvider.getAiMessageText(context),
            backgroundColor: themeProvider.isDarkMode
                ? Colors.grey[800]
                : Colors.grey[200],
            fontFamily: 'monospace',
            fontSize: 13,
          ),
          codeblockDecoration: BoxDecoration(
            color: themeProvider.isDarkMode
                ? Colors.grey[900]
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: themeProvider.isDarkMode
                  ? Colors.grey[700]!
                  : Colors.grey[300]!,
            ),
          ),
          codeblockPadding: const EdgeInsets.all(12),
          blockquote: TextStyle(
            color: themeProvider.getAiMessageText(context).withOpacity(0.8),
            fontStyle: FontStyle.italic,
          ),
          blockquoteDecoration: BoxDecoration(
            color: themeProvider.isDarkMode
                ? Colors.grey[800]!.withOpacity(0.3)
                : Colors.grey[200]!.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
            border: Border(
              left: BorderSide(color: AppColors.mediumPurple, width: 4),
            ),
          ),
          blockquotePadding: const EdgeInsets.all(10),
          listBullet: TextStyle(
            color: themeProvider.getAiMessageText(context),
            fontSize: 14,
          ),
          listIndent: 24,
          a: TextStyle(
            color: AppColors.mediumPurple,
            decoration: TextDecoration.underline,
          ),
          horizontalRuleDecoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: themeProvider.isDarkMode
                    ? Colors.grey[700]!
                    : Colors.grey[300]!,
                width: 1,
              ),
            ),
          ),
        ),
        onTapLink: (text, href, title) {
          if (href != null) {
            _launchURL(href);
          }
        },
      );
    }

    // For user messages, use regular text
    return SelectableText(
      message.content,
      style: TextStyle(
        color: themeProvider.getUserMessageText(context),
        fontSize: 14,
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildLoadingIndicator(
    BuildContext context,
    ThemeProvider themeProvider,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              themeProvider.getAiMessageText(context),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'AI is thinking...',
          style: TextStyle(
            color: themeProvider.getAiMessageText(context),
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildAttachedDocuments(
    BuildContext context,
    ThemeProvider themeProvider,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color:
            (themeProvider.isDarkMode
                    ? AppColors.darkDocumentBanner
                    : AppColors.lightDocumentBanner)
                .withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              (themeProvider.isDarkMode
                      ? AppColors.darkDocumentBannerText
                      : AppColors.lightDocumentBannerText)
                  .withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.description,
                size: 14,
                color: themeProvider.isDarkMode
                    ? AppColors.darkDocumentBannerText
                    : AppColors.lightDocumentBannerText,
              ),
              const SizedBox(width: 4),
              Text(
                message.attachedDocuments!.length == 1
                    ? 'Document Attached'
                    : '${message.attachedDocuments!.length} Documents Attached',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: themeProvider.isDarkMode
                      ? AppColors.darkDocumentBannerText
                      : AppColors.lightDocumentBannerText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...message.attachedDocuments!
              .take(3)
              .map(
                (docName) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    children: [
                      Icon(
                        _getFileIcon(docName),
                        size: 12,
                        color:
                            (themeProvider.isDarkMode
                                    ? AppColors.darkDocumentBannerText
                                    : AppColors.lightDocumentBannerText)
                                .withOpacity(0.7),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          docName,
                          style: TextStyle(
                            fontSize: 10,
                            color:
                                (themeProvider.isDarkMode
                                        ? AppColors.darkDocumentBannerText
                                        : AppColors.lightDocumentBannerText)
                                    .withOpacity(0.8),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          if (message.attachedDocuments!.length > 3)
            Text(
              '+${message.attachedDocuments!.length - 3} more',
              style: TextStyle(
                fontSize: 9,
                fontStyle: FontStyle.italic,
                color:
                    (themeProvider.isDarkMode
                            ? AppColors.darkDocumentBannerText
                            : AppColors.lightDocumentBannerText)
                        .withOpacity(0.6),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    final ext = fileName.toLowerCase().split('.').last;
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.article;
      case 'txt':
        return Icons.text_snippet;
      case 'md':
        return Icons.notes;
      default:
        return Icons.description;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
