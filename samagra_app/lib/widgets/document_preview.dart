import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/document_state.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';

class DocumentPreview extends StatelessWidget {
  final List<SingleDocument> documents;
  final bool isCompact;
  final VoidCallback? onRemove;

  const DocumentPreview({
    super.key,
    required this.documents,
    this.isCompact = false,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) return const SizedBox.shrink();

    final themeProvider = Provider.of<ThemeProvider>(context);

    return Container(
      margin: EdgeInsets.all(isCompact ? 4 : 8),
      padding: EdgeInsets.all(isCompact ? 6 : 8),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode
            ? AppColors.darkDocumentBanner.withOpacity(0.5)
            : AppColors.lightDocumentBanner.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: themeProvider.isDarkMode
              ? AppColors.darkDocumentBannerText.withOpacity(0.3)
              : AppColors.lightDocumentBannerText.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with document count and remove button
          Row(
            children: [
              Icon(
                Icons.description,
                size: isCompact ? 14 : 16,
                color: themeProvider.isDarkMode
                    ? AppColors.darkDocumentBannerText
                    : AppColors.lightDocumentBannerText,
              ),
              const SizedBox(width: 4),
              Text(
                documents.length == 1
                    ? 'Document Attached'
                    : '${documents.length} Documents Attached',
                style: TextStyle(
                  fontSize: isCompact ? 11 : 12,
                  fontWeight: FontWeight.w500,
                  color: themeProvider.isDarkMode
                      ? AppColors.darkDocumentBannerText
                      : AppColors.lightDocumentBannerText,
                ),
              ),
              const Spacer(),
              if (onRemove != null)
                GestureDetector(
                  onTap: onRemove,
                  child: Icon(
                    Icons.close,
                    size: isCompact ? 14 : 16,
                    color: themeProvider.isDarkMode
                        ? AppColors.darkDocumentBannerText.withOpacity(0.7)
                        : AppColors.lightDocumentBannerText.withOpacity(0.7),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 4),

          // Document list
          if (isCompact) ...[
            // Compact view - show first few names
            Text(
              _getCompactDocumentList(),
              style: TextStyle(
                fontSize: 10,
                color:
                    (themeProvider.isDarkMode
                            ? AppColors.darkDocumentBannerText
                            : AppColors.lightDocumentBannerText)
                        .withOpacity(0.8),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ] else ...[
            // Full view - show all documents
            ...documents
                .take(3)
                .map(
                  (doc) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Row(
                      children: [
                        Icon(
                          _getFileIcon(doc.fileName),
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
                            doc.fileName,
                            style: TextStyle(
                              fontSize: 11,
                              color:
                                  (themeProvider.isDarkMode
                                          ? AppColors.darkDocumentBannerText
                                          : AppColors.lightDocumentBannerText)
                                      .withOpacity(0.8),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          doc.sizeText,
                          style: TextStyle(
                            fontSize: 9,
                            color:
                                (themeProvider.isDarkMode
                                        ? AppColors.darkDocumentBannerText
                                        : AppColors.lightDocumentBannerText)
                                    .withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

            if (documents.length > 3)
              Text(
                '+${documents.length - 3} more documents',
                style: TextStyle(
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                  color:
                      (themeProvider.isDarkMode
                              ? AppColors.darkDocumentBannerText
                              : AppColors.lightDocumentBannerText)
                          .withOpacity(0.6),
                ),
              ),
          ],
        ],
      ),
    );
  }

  String _getCompactDocumentList() {
    if (documents.isEmpty) return '';
    if (documents.length == 1) return documents.first.fileName;
    if (documents.length <= 2) {
      return documents.map((d) => d.fileName).join(', ');
    }
    return '${documents.take(2).map((d) => d.fileName).join(', ')}, +${documents.length - 2} more';
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
}
