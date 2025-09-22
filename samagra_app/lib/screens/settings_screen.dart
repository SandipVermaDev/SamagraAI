import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/theme_provider.dart';
import '../models/ai_model.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Consumer2<ChatProvider, ThemeProvider>(
        builder: (context, chatProvider, themeProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildThemeSection(context, themeProvider),
              const SizedBox(height: 24),
              _buildModelSection(context, chatProvider, themeProvider),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Model',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: themeProvider.getTextPrimary(context),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<AIModel>(
              initialValue: chatProvider.selectedModel,
              items: AIModel.availableModels.map((model) {
                return DropdownMenuItem<AIModel>(
                  value: model,
                  child: Text(model.name),
                );
              }).toList(),
              onChanged: (model) {
                if (model != null) {
                  chatProvider.setSelectedModel(model);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
