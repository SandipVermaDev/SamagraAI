import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/message_list.dart';
import '../widgets/document_banner.dart';
import '../widgets/input_bar.dart';
import '../theme/app_theme.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('SamagraAI'),
            actions: [
              IconButton(
                icon: const Icon(Icons.wifi),
                onPressed: () {
                  _testConnection(context, chatProvider);
                },
                tooltip: 'Test Backend Connection',
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.pushNamed(context, '/settings');
                },
              ),
              IconButton(
                icon: const Icon(Icons.clear_all),
                onPressed: () {
                  _showClearChatDialog(context, chatProvider);
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // Document banner (shown when document is active)
              if (chatProvider.hasActiveDocument) const DocumentBanner(),

              // Messages list
              const Expanded(child: MessageList()),

              // Input bar
              const InputBar(),
            ],
          ),
        );
      },
    );
  }

  void _testConnection(BuildContext context, ChatProvider chatProvider) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text('Testing Connection'),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Connecting to backend...'),
          ],
        ),
      ),
    );

    try {
      final isConnected = await chatProvider.testBackendConnection();

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              isConnected ? 'Connection Successful' : 'Connection Failed',
            ),
            content: Text(
              isConnected
                  ? 'Backend is reachable and working properly.'
                  : 'Cannot connect to backend. Make sure the server is running on localhost:8000.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Connection Error'),
            content: Text('Error testing connection: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _showClearChatDialog(BuildContext context, ChatProvider chatProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear Chat'),
          content: const Text('Are you sure you want to clear all messages?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                chatProvider.clearChat();
                Navigator.of(context).pop();
              },
              child: Text('Clear', style: TextStyle(color: AppColors.error)),
            ),
          ],
        );
      },
    );
  }
}
