import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';

class DocumentBanner extends StatelessWidget {
  const DocumentBanner({super.key});

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
                      'Document Active',
                      style: TextStyle(
                        color: themeProvider.isDarkMode
                            ? AppColors.darkDocumentBannerText
                            : AppColors.lightDocumentBannerText,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
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
                  ],
                ),
              ),

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
                tooltip: 'Remove document',
              ),
            ],
          ),
        );
      },
    );
  }
}
