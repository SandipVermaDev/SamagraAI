import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/theme_provider.dart';
import '../models/ai_model.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  ModelMode _selectedMode = ModelMode.text;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Consumer2<ChatProvider, ThemeProvider>(
        builder: (context, chatProvider, themeProvider, child) {
          // Sync mode with current model
          if (chatProvider.selectedModel.mode != _selectedMode) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _selectedMode = chatProvider.selectedModel.mode;
                });
              }
            });
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildThemeSection(context, themeProvider),
              const SizedBox(height: 16),
              _buildModelSection(context, chatProvider, themeProvider),
              const SizedBox(height: 16),
              _buildConnectionSection(context, chatProvider, themeProvider),
              const SizedBox(height: 16),
              _buildChatSection(context, chatProvider, themeProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildThemeSection(BuildContext context, ThemeProvider themeProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Appearance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: themeProvider.getTextPrimary(context),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildThemeButton(
                    context,
                    themeProvider,
                    'Light',
                    Icons.light_mode,
                    ThemeMode.light,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildThemeButton(
                    context,
                    themeProvider,
                    'Dark',
                    Icons.dark_mode,
                    ThemeMode.dark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildThemeButton(
                    context,
                    themeProvider,
                    'System',
                    Icons.brightness_auto,
                    ThemeMode.system,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeButton(
    BuildContext context,
    ThemeProvider themeProvider,
    String label,
    IconData icon,
    ThemeMode mode,
  ) {
    final isSelected = themeProvider.themeMode == mode;
    return GestureDetector(
      onTap: () => themeProvider.setThemeMode(mode),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.mediumPurple.withOpacity(0.1) : null,
          border: Border.all(
            color: isSelected ? AppColors.mediumPurple : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.mediumPurple : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.mediumPurple : Colors.grey,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelSection(
    BuildContext context,
    ChatProvider chatProvider,
    ThemeProvider themeProvider,
  ) {
    // Filter models based on selected mode
    final displayModels = _selectedMode == ModelMode.text
        ? AIModel.textModels
        : AIModel.imageModels;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'AI Model',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: themeProvider.getTextPrimary(context),
                  ),
                ),
                // Mode selector
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: themeProvider.isDarkMode
                        ? Colors.grey[800]
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<ModelMode>(
                    value: _selectedMode,
                    underline: const SizedBox(),
                    isDense: true,
                    icon: const Icon(Icons.arrow_drop_down, size: 18),
                    style: TextStyle(
                      color: themeProvider.getTextPrimary(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: ModelMode.text,
                        child: Text('Text'),
                      ),
                      DropdownMenuItem(
                        value: ModelMode.image,
                        child: Text('Image'),
                      ),
                    ],
                    onChanged: (ModelMode? newMode) {
                      if (newMode != null) {
                        setState(() {
                          _selectedMode = newMode;
                          // Auto-select first model of the new mode
                          if (newMode == ModelMode.text) {
                            chatProvider.setSelectedModel(
                              AIModel.textModels.first,
                            );
                          } else {
                            chatProvider.setSelectedModel(
                              AIModel.imageModels.first,
                            );
                          }
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 60,
              child: DropdownButtonFormField<AIModel>(
                initialValue: displayModels.contains(chatProvider.selectedModel)
                    ? chatProvider.selectedModel
                    : displayModels.first,
                isExpanded: true,
                isDense: false,
                itemHeight: null,
                items: displayModels.map((model) {
                  return DropdownMenuItem<AIModel>(
                    value: model,
                    alignment: AlignmentDirectional.centerStart,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          model.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          model.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: themeProvider.getTextSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                selectedItemBuilder: (context) {
                  return displayModels.map((model) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            model.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            model.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: themeProvider.getTextSecondary(context),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList();
                },
                onChanged: (model) {
                  if (model != null) {
                    chatProvider.setSelectedModel(model);
                  }
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionSection(
    BuildContext context,
    ChatProvider chatProvider,
    ThemeProvider themeProvider,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Connection',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: themeProvider.getTextPrimary(context),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Test your backend connection to ensure everything is working properly.',
              style: TextStyle(
                fontSize: 14,
                color: themeProvider.getTextSecondary(context),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _testConnection(context, chatProvider),
                icon: const Icon(Icons.wifi),
                label: const Text('Test Backend Connection'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mediumPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatSection(
    BuildContext context,
    ChatProvider chatProvider,
    ThemeProvider themeProvider,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chat History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: themeProvider.getTextPrimary(context),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Delete all messages from your current chat session. This action cannot be undone.',
              style: TextStyle(
                fontSize: 14,
                color: themeProvider.getTextSecondary(context),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showClearChatDialog(context, chatProvider),
                icon: const Icon(Icons.delete_sweep),
                label: const Text('Clear Chat History'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
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
