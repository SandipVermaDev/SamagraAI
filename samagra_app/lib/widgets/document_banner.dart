import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';

class DocumentBanner extends StatelessWidget {
  const DocumentBanner({super.key});

  void _showDocumentList(
    BuildContext context,
    ChatProvider chatProvider,
    ThemeProvider themeProvider,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: themeProvider.isDarkMode
              ? AppColors.darkBackground
              : AppColors.lightBackground,
          title: Text(
            'Uploaded Documents (${chatProvider.documentState.totalDocuments})',
            style: TextStyle(
              color: themeProvider.isDarkMode
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: chatProvider.documentState.documents.length,
              itemBuilder: (context, index) {
                final document = chatProvider.documentState.documents[index];
                return ListTile(
                  leading: Icon(
                    Icons.description,
                    color: themeProvider.isDarkMode
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                  title: Text(
                    document.fileName,
                    style: TextStyle(
                      color: themeProvider.isDarkMode
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  subtitle: Text(
                    document.sizeText,
                    style: TextStyle(
                      color:
                          (themeProvider.isDarkMode
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary)
                              .withOpacity(0.6),
                    ),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: AppColors.error),
                    onPressed: () {
                      chatProvider.removeDocument(document.fileName);
                      Navigator.of(context).pop();
                    },
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Close',
                style: TextStyle(
                  color: themeProvider.isDarkMode
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                chatProvider.clearDocument();
                Navigator.of(context).pop();
              },
              child: Text(
                'Remove All',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ChatProvider, ThemeProvider>(
      builder: (context, chatProvider, themeProvider, child) {
        final documentState = chatProvider.documentState;
        debugPrint(
          '[DocumentBanner] build: hasDocument=${documentState.hasDocument} file=${documentState.fileName}',
        );

        if (!documentState.hasDocument) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: themeProvider.isDarkMode
              ? AppColors.darkDocumentBanner
              : AppColors.lightDocumentBanner,
          child: Row(
            children: [
              // Document icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: themeProvider.isDarkMode
                      ? AppColors.darkDocumentBannerText.withOpacity(0.1)
                      : AppColors.lightDocumentBannerText.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.description,
                  color: themeProvider.isDarkMode
                      ? AppColors.darkDocumentBannerText
                      : AppColors.lightDocumentBannerText,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Document info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      documentState.totalDocuments == 1
                          ? 'Document Active'
                          : '${documentState.totalDocuments} Documents Active',
                      style: TextStyle(
                        color: themeProvider.isDarkMode
                            ? AppColors.darkDocumentBannerText
                            : AppColors.lightDocumentBannerText,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (documentState.totalDocuments == 1) ...[
                      // Single document display
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              documentState.displayName,
                              style: TextStyle(
                                color:
                                    (themeProvider.isDarkMode
                                            ? AppColors.darkDocumentBannerText
                                            : AppColors.lightDocumentBannerText)
                                        .withOpacity(0.8),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (documentState.sizeText.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              '(${documentState.sizeText})',
                              style: TextStyle(
                                color:
                                    (themeProvider.isDarkMode
                                            ? AppColors.darkDocumentBannerText
                                            : AppColors.lightDocumentBannerText)
                                        .withOpacity(0.6),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ] else ...[
                      // Multiple documents display
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              documentState.fileNames.take(2).join(', ') +
                                  (documentState.totalDocuments > 2
                                      ? ', +${documentState.totalDocuments - 2} more'
                                      : ''),
                              style: TextStyle(
                                color:
                                    (themeProvider.isDarkMode
                                            ? AppColors.darkDocumentBannerText
                                            : AppColors.lightDocumentBannerText)
                                        .withOpacity(0.8),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (documentState.sizeText.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              '(${documentState.sizeText} total)',
                              style: TextStyle(
                                color:
                                    (themeProvider.isDarkMode
                                            ? AppColors.darkDocumentBannerText
                                            : AppColors.lightDocumentBannerText)
                                        .withOpacity(0.6),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // View details button (for multiple documents)
              if (documentState.totalDocuments > 1) ...[
                IconButton(
                  onPressed: () {
                    _showDocumentList(context, chatProvider, themeProvider);
                  },
                  icon: Icon(
                    Icons.list,
                    color: themeProvider.isDarkMode
                        ? AppColors.darkDocumentBannerText
                        : AppColors.lightDocumentBannerText,
                    size: 20,
                  ),
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  tooltip: 'View all documents',
                ),
              ],

              // Close button
              IconButton(
                onPressed: () {
                  chatProvider.clearDocument();
                },
                icon: Icon(
                  Icons.close,
                  color: themeProvider.isDarkMode
                      ? AppColors.darkDocumentBannerText
                      : AppColors.lightDocumentBannerText,
                  size: 20,
                ),
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                tooltip: 'Remove all documents',
              ),
            ],
          ),
        );
      },
    );
  }
}
