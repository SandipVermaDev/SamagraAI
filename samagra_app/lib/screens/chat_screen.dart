import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/message_list.dart';
import '../widgets/document_banner.dart';
import '../widgets/model_selector.dart';
import '../widgets/input_area_with_preview.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ChatProvider, ThemeProvider>(
      builder: (context, chatProvider, themeProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('SamagraAI'),
            actions: [
              IconButton(
                icon: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                ),
                onPressed: () {
                  themeProvider.toggleTheme();
                },
                tooltip: 'Toggle Theme',
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.pushNamed(context, '/settings');
                },
              ),
            ],
          ),
          body: Stack(
            children: [
              Column(
                children: [
                  // Messages list
                  const Expanded(child: MessageList()),

                  // Input area with document preview
                  const InputAreaWithPreview(),
                ],
              ),

              // Floating model selector in top-left corner
              const ModelSelector(),

              // Floating document banner in top-right corner
              const DocumentBanner(),
            ],
          ),
        );
      },
    );
  }
}
