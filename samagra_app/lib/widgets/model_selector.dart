import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/theme_provider.dart';
import '../models/ai_model.dart';
import '../theme/app_theme.dart';

class ModelSelector extends StatefulWidget {
  const ModelSelector({super.key});

  @override
  State<ModelSelector> createState() => _ModelSelectorState();
}

class _ModelSelectorState extends State<ModelSelector> {
  bool _isExpanded = false;
  ModelMode _selectedMode = ModelMode.text;

  @override
  Widget build(BuildContext context) {
    return Consumer2<ChatProvider, ThemeProvider>(
      builder: (context, chatProvider, themeProvider, child) {
        final currentModel = chatProvider.selectedModel;
        final screenWidth = MediaQuery.of(context).size.width;

        // Sync mode with current model
        if (currentModel.mode != _selectedMode) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _selectedMode = currentModel.mode;
              });
            }
          });
        }

        // Responsive sizing based on screen width
        final collapsedWidth = screenWidth < 400 ? 110.0 : 140.0;
        final expandedWidth = screenWidth < 400 ? 240.0 : 260.0;

        return Positioned(
          top: 8,
          left: 8,
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
                  maxHeight: _isExpanded ? 280 : 40,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: _isExpanded ? 10 : 8,
                  vertical: _isExpanded ? 8 : 6,
                ),
                child: _isExpanded
                    ? _buildExpandedView(
                        chatProvider,
                        themeProvider,
                        currentModel,
                      )
                    : _buildCollapsedView(themeProvider, currentModel),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCollapsedView(
    ThemeProvider themeProvider,
    AIModel currentModel,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: themeProvider.isDarkMode
                ? AppColors.darkDocumentBannerText.withValues(alpha: 0.15)
                : AppColors.lightDocumentBannerText.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Icon(
            Icons.psychology,
            color: themeProvider.isDarkMode
                ? AppColors.darkDocumentBannerText
                : AppColors.lightDocumentBannerText,
            size: 14,
          ),
        ),
        const SizedBox(width: 6),

        // Model name
        Flexible(
          child: Text(
            currentModel.name,
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
    AIModel currentModel,
  ) {
    // Filter models based on selected mode
    final displayModels = _selectedMode == ModelMode.text
        ? AIModel.textModels
        : AIModel.imageModels;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Row(
          children: [
            Icon(
              Icons.psychology,
              color: themeProvider.isDarkMode
                  ? AppColors.darkDocumentBannerText
                  : AppColors.lightDocumentBannerText,
              size: 16,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Model',
                style: TextStyle(
                  color: themeProvider.isDarkMode
                      ? AppColors.darkDocumentBannerText
                      : AppColors.lightDocumentBannerText,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Mode Selector Dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color:
                    (themeProvider.isDarkMode
                            ? AppColors.darkDocumentBannerText
                            : AppColors.lightDocumentBannerText)
                        .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: DropdownButton<ModelMode>(
                value: _selectedMode,
                underline: const SizedBox(),
                isDense: true,
                icon: Icon(
                  Icons.arrow_drop_down,
                  size: 16,
                  color: themeProvider.isDarkMode
                      ? AppColors.darkDocumentBannerText
                      : AppColors.lightDocumentBannerText,
                ),
                dropdownColor: themeProvider.isDarkMode
                    ? AppColors.darkDocumentBanner
                    : AppColors.lightDocumentBanner,
                style: TextStyle(
                  color: themeProvider.isDarkMode
                      ? AppColors.darkDocumentBannerText
                      : AppColors.lightDocumentBannerText,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                items: const [
                  DropdownMenuItem(value: ModelMode.text, child: Text('Text')),
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
                        chatProvider.setSelectedModel(AIModel.textModels.first);
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
            const SizedBox(width: 4),
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
                  .withValues(alpha: 0.3),
          height: 1,
        ),
        const SizedBox(height: 6),

        // Model list - using Flexible with proper sizing
        Flexible(
          fit: FlexFit.loose,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: displayModels.map((model) {
                final isSelected = model.id == currentModel.id;
                return _buildModelItem(
                  themeProvider: themeProvider,
                  model: model,
                  isSelected: isSelected,
                  onTap: () {
                    chatProvider.setSelectedModel(model);
                    setState(() {
                      _isExpanded = false;
                    });
                  },
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModelItem({
    required ThemeProvider themeProvider,
    required AIModel model,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.mediumPurple.withValues(alpha: 0.15)
              : (themeProvider.isDarkMode
                        ? AppColors.darkDocumentBannerText
                        : AppColors.lightDocumentBannerText)
                    .withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppColors.mediumPurple : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    model.name,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.mediumPurple
                          : (themeProvider.isDarkMode
                                ? AppColors.darkDocumentBannerText
                                : AppColors.lightDocumentBannerText),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: AppColors.mediumPurple,
                    size: 14,
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              model.description,
              style: TextStyle(
                color:
                    (themeProvider.isDarkMode
                            ? AppColors.darkDocumentBannerText
                            : AppColors.lightDocumentBannerText)
                        .withValues(alpha: 0.7),
                fontSize: 9,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
