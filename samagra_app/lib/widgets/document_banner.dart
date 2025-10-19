import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../providers/chat_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../models/document_state.dart';

class DocumentBanner extends StatefulWidget {
  const DocumentBanner({super.key});

  @override
  State<DocumentBanner> createState() => _DocumentBannerState();
}

class _DocumentBannerState extends State<DocumentBanner> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Consumer2<ChatProvider, ThemeProvider>(
      builder: (context, chatProvider, themeProvider, child) {
        final documentState = chatProvider.documentState;
        final documents = documentState.documentsOnly;
        final images = documentState.imagesOnly;
        final hasDocuments = documents.isNotEmpty;
        final hasImages = images.isNotEmpty;

        // Count total active items (documents + images)
        final totalItems = documents.length + images.length;

        if (totalItems == 0) {
          return const SizedBox.shrink();
        }

        final screenWidth = MediaQuery.of(context).size.width;

        // Responsive sizing based on screen width
        final collapsedWidth = screenWidth < 400 ? 100.0 : 130.0;
        final expandedWidth = screenWidth < 400 ? 240.0 : 280.0;

        return Positioned(
          top: 8,
          right: 8,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(10),
            color: themeProvider.isDarkMode
                ? AppColors.darkDocumentBanner
                : AppColors.lightDocumentBanner,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                constraints: BoxConstraints(
                  maxWidth: _isExpanded ? expandedWidth : collapsedWidth,
                  maxHeight: _isExpanded ? 300 : 40,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: _isExpanded ? 10 : 8,
                  vertical: _isExpanded ? 8 : 6,
                ),
                child: _isExpanded
                    ? _buildExpandedView(
                        chatProvider,
                        themeProvider,
                        documents,
                        images,
                      )
                    : _buildCollapsedView(
                        themeProvider,
                        totalItems,
                        hasDocuments,
                        hasImages,
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCollapsedView(
    ThemeProvider themeProvider,
    int totalItems,
    bool hasDocuments,
    bool hasImages,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: themeProvider.isDarkMode
                ? AppColors.darkDocumentBannerText.withOpacity(0.15)
                : AppColors.lightDocumentBannerText.withOpacity(0.15),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Icon(
            hasDocuments && hasImages
                ? Icons.folder_special
                : hasDocuments
                ? Icons.description
                : Icons.image,
            color: themeProvider.isDarkMode
                ? AppColors.darkDocumentBannerText
                : AppColors.lightDocumentBannerText,
            size: 14,
          ),
        ),
        const SizedBox(width: 6),

        // Text
        Flexible(
          child: Text(
            totalItems == 1 ? '1' : '$totalItems',
            style: TextStyle(
              color: themeProvider.isDarkMode
                  ? AppColors.darkDocumentBannerText
                  : AppColors.lightDocumentBannerText,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 2),

        // Dropdown arrow
        Icon(
          Icons.arrow_drop_down,
          color: themeProvider.isDarkMode
              ? AppColors.darkDocumentBannerText
              : AppColors.lightDocumentBannerText,
          size: 18,
        ),
      ],
    );
  }

  Widget _buildExpandedView(
    ChatProvider chatProvider,
    ThemeProvider themeProvider,
    List<SingleDocument> documents,
    List<SingleDocument> images,
  ) {
    final hasDocuments = documents.isNotEmpty;
    final hasImages = images.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Row(
          children: [
            Icon(
              Icons.folder_open,
              color: themeProvider.isDarkMode
                  ? AppColors.darkDocumentBannerText
                  : AppColors.lightDocumentBannerText,
              size: 16,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Resources',
                style: TextStyle(
                  color: themeProvider.isDarkMode
                      ? AppColors.darkDocumentBannerText
                      : AppColors.lightDocumentBannerText,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            InkWell(
              onTap: () {
                setState(() {
                  _isExpanded = false;
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.close,
                  color: themeProvider.isDarkMode
                      ? AppColors.darkDocumentBannerText
                      : AppColors.lightDocumentBannerText,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Divider(
          color:
              (themeProvider.isDarkMode
                      ? AppColors.darkDocumentBannerText
                      : AppColors.lightDocumentBannerText)
                  .withOpacity(0.3),
          height: 1,
        ),
        const SizedBox(height: 6),

        // List
        Flexible(
          fit: FlexFit.loose,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Documents
                if (hasDocuments)
                  ...documents.map((doc) {
                    return _buildListItem(
                      themeProvider: themeProvider,
                      icon: Icons.description,
                      title: doc.fileName,
                      subtitle: doc.sizeText,
                      onDelete: () {
                        chatProvider.removeDocument(doc.fileName);
                        if (chatProvider.documentState.totalDocuments == 0) {
                          setState(() {
                            _isExpanded = false;
                          });
                        }
                      },
                    );
                  }),

                // Images
                if (hasImages)
                  ...images.map((image) {
                    return _buildListItem(
                      themeProvider: themeProvider,
                      icon: Icons.image,
                      title: image.fileName,
                      subtitle: image.sizeText,
                      isImage: true,
                      imageBytes: image.bytes,
                      imagePath: image.filePath,
                      onDelete: () {
                        chatProvider.removeDocument(image.fileName);
                        if (chatProvider.documentState.totalDocuments == 0) {
                          setState(() {
                            _isExpanded = false;
                          });
                        }
                      },
                    );
                  }),
              ],
            ),
          ),
        ),

        // Actions
        const SizedBox(height: 6),
        Divider(
          color:
              (themeProvider.isDarkMode
                      ? AppColors.darkDocumentBannerText
                      : AppColors.lightDocumentBannerText)
                  .withOpacity(0.3),
          height: 1,
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: () {
                chatProvider.clearDocument();
                chatProvider.clearPendingImage();
                setState(() {
                  _isExpanded = false;
                });
              },
              icon: Icon(Icons.delete_sweep, size: 14, color: AppColors.error),
              label: Text(
                'Clear',
                style: TextStyle(color: AppColors.error, fontSize: 10),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildListItem({
    required ThemeProvider themeProvider,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onDelete,
    bool isImage = false,
    Uint8List? imageBytes,
    String? imagePath,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color:
            (themeProvider.isDarkMode
                    ? AppColors.darkDocumentBannerText
                    : AppColors.lightDocumentBannerText)
                .withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Icon or thumbnail
          if (isImage && (imageBytes != null || imagePath != null))
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: imageBytes != null
                  ? Image.memory(
                      imageBytes,
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                    )
                  : Image.file(
                      File(imagePath!),
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.broken_image,
                          size: 32,
                          color: themeProvider.isDarkMode
                              ? AppColors.darkDocumentBannerText
                              : AppColors.lightDocumentBannerText,
                        );
                      },
                    ),
            )
          else
            Icon(
              icon,
              color: themeProvider.isDarkMode
                  ? AppColors.darkDocumentBannerText
                  : AppColors.lightDocumentBannerText,
              size: 20,
            ),
          const SizedBox(width: 10),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: themeProvider.isDarkMode
                        ? AppColors.darkDocumentBannerText
                        : AppColors.lightDocumentBannerText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color:
                          (themeProvider.isDarkMode
                                  ? AppColors.darkDocumentBannerText
                                  : AppColors.lightDocumentBannerText)
                              .withOpacity(0.7),
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Delete button
          IconButton(
            onPressed: onDelete,
            icon: Icon(
              Icons.close,
              color: themeProvider.isDarkMode
                  ? AppColors.darkDocumentBannerText.withOpacity(0.7)
                  : AppColors.lightDocumentBannerText.withOpacity(0.7),
              size: 16,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          ),
        ],
      ),
    );
  }
}
