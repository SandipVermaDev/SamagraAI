import 'package:flutter/material.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/document_preview.dart';
import '../widgets/input_bar.dart';

class InputAreaWithPreview extends StatelessWidget {
  const InputAreaWithPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ChatProvider, ThemeProvider>(
      builder: (context, chatProvider, themeProvider, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Document preview area (compact version above input)
            if (chatProvider.showInputPreview)
              Container(
                decoration: BoxDecoration(
                  color: themeProvider.isDarkMode
                      ? const Color(0xFF2A2A2A)
                      : const Color(0xFFF5F5F5),
                  border: Border(
                    bottom: BorderSide(
                      color:
                          (themeProvider.isDarkMode
                                  ? Colors.white
                                  : Colors.black)
                              .withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (chatProvider.pendingDocuments.isNotEmpty)
                      DocumentPreview(
                        documents: chatProvider.pendingDocuments,
                        isCompact: true,
                        onRemove: () {
                          _showRemoveDocumentsDialog(context, chatProvider);
                        },
                      ),
                    if (chatProvider.hasPendingImage) _PendingImageChip(),
                  ],
                ),
              ),

            // Input bar
            const InputBar(),
          ],
        );
      },
    );
  }

  void _showRemoveDocumentsDialog(
    BuildContext context,
    ChatProvider chatProvider,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove Documents'),
          content: Text(
            'Remove ${chatProvider.documentState.totalDocuments} attached document(s)?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                chatProvider.clearDocument();
                Navigator.of(context).pop();
              },
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }
}

class _PendingImageChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    final borderColor = (themeProvider.isDarkMode ? Colors.white : Colors.black)
        .withOpacity(0.1);

    Widget imageWidget;
    if (chatProvider.pendingImageBytes != null) {
      imageWidget = Image.memory(
        chatProvider.pendingImageBytes!,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
      );
    } else if (chatProvider.pendingImagePath != null) {
      imageWidget = Image.file(
        File(chatProvider.pendingImagePath!),
        width: 40,
        height: 40,
        fit: BoxFit.cover,
      );
    } else {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            clipBehavior: Clip.antiAlias,
            child: imageWidget,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              chatProvider.pendingImageName ?? 'Image',
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () {
              chatProvider.clearPendingImage();
            },
            tooltip: 'Remove',
          ),
        ],
      ),
    );
  }
}
