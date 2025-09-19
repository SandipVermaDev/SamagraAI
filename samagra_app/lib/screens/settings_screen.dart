import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../models/ai_model.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // AI Model Selection Section
              _buildSectionTitle('AI Model'),
              const SizedBox(height: 12),
              _buildModelSelection(chatProvider),

              const SizedBox(height: 32),

              // App Information Section
              _buildSectionTitle('About'),
              const SizedBox(height: 12),
              _buildAppInfo(),

              const SizedBox(height: 32),

              // Reset Section
              _buildSectionTitle('Data'),
              const SizedBox(height: 12),
              _buildDataOptions(context, chatProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildModelSelection(ChatProvider chatProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select AI Model',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose the AI model for your conversations',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<AIModel>(
              initialValue: chatProvider.selectedModel,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: AIModel.availableModels.map((model) {
                return DropdownMenuItem<AIModel>(
                  value: model,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        model.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        model.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (AIModel? newModel) {
                if (newModel != null) {
                  chatProvider.setSelectedModel(newModel);
                }
              },
              isExpanded: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.smart_toy, color: AppColors.primary, size: 32),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SamagraAI',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Text(
                      'Version 1.0.0',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'A multimodal AI chatbot that supports text, images, and document analysis.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            _buildInfoRow('Features', 'Chat, Document Q&A, Image Analysis'),
            const SizedBox(height: 8),
            _buildInfoRow('Supported Files', 'PDF, DOC, DOCX, TXT, MD'),
            const SizedBox(height: 8),
            _buildInfoRow('Image Formats', 'JPG, PNG, WebP'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildDataOptions(BuildContext context, ChatProvider chatProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Data Management',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.clear_all, color: AppColors.warning),
              title: const Text('Clear Chat History'),
              subtitle: const Text('Remove all chat messages'),
              onTap: () => _showClearChatDialog(context, chatProvider),
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.file_present, color: AppColors.error),
              title: const Text('Remove Active Document'),
              subtitle: const Text('Clear currently uploaded document'),
              onTap: chatProvider.hasActiveDocument
                  ? () => _showRemoveDocumentDialog(context, chatProvider)
                  : null,
              contentPadding: EdgeInsets.zero,
              enabled: chatProvider.hasActiveDocument,
            ),
          ],
        ),
      ),
    );
  }

  void _showClearChatDialog(BuildContext context, ChatProvider chatProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear Chat History'),
          content: const Text(
            'Are you sure you want to clear all chat messages? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                chatProvider.clearChat();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Chat history cleared'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
              ),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
  }

  void _showRemoveDocumentDialog(
    BuildContext context,
    ChatProvider chatProvider,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove Document'),
          content: Text(
            'Remove "${chatProvider.documentState.displayName}" from the current session?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                chatProvider.clearDocument();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Document removed'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }
}
