import 'package:flutter/material.dart';
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
                child: DocumentPreview(
                  documents: chatProvider.documentState.documents,
                  isCompact: true,
                  onRemove: () {
                    _showRemoveDocumentsDialog(context, chatProvider);
                  },
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
