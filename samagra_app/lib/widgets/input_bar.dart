import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/chat_provider.dart';
import '../theme/app_theme.dart';

class InputBar extends StatefulWidget {
  const InputBar({super.key});

  @override
  State<InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<InputBar> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isRecording = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = _textController.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Attachment button (paperclip)
              IconButton(
                onPressed: chatProvider.isLoading ? null : _showAttachmentMenu,
                icon: const Icon(Icons.attach_file),
                style: IconButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                ),
                tooltip: 'Attach file or image',
              ),

              // Text input field
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(
                    maxHeight: 120, // Allow multiline with max height
                  ),
                  child: KeyboardListener(
                    focusNode: FocusNode(),
                    onKeyEvent: (KeyEvent event) {
                      if (event is KeyDownEvent) {
                        // Handle Enter key (send message) vs Shift+Enter (new line)
                        if (event.logicalKey == LogicalKeyboardKey.enter) {
                          final isShiftPressed =
                              HardwareKeyboard.instance.isLogicalKeyPressed(
                                LogicalKeyboardKey.shiftLeft,
                              ) ||
                              HardwareKeyboard.instance.isLogicalKeyPressed(
                                LogicalKeyboardKey.shiftRight,
                              );

                          if (!isShiftPressed && !chatProvider.isLoading) {
                            // Send message on Enter (without Shift)
                            _sendMessage(chatProvider);
                          }
                          // Shift+Enter will be handled by the TextField naturally for new lines
                        }
                      }
                    },
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      enabled: !chatProvider.isLoading,
                      maxLines: null, // Allow multiline
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction
                          .newline, // Changed back to newline for better UX
                      decoration: InputDecoration(
                        hintText: chatProvider.isLoading
                            ? 'AI is thinking...'
                            : 'Type your message... (Enter to send, Shift+Enter for new line)',
                        suffixIcon: _buildSendButton(chatProvider),
                      ),
                      onSubmitted:
                          null, // Disabled since we handle with KeyboardListener
                      onTap: () {
                        // Ensure the text field is focused
                      },
                    ),
                  ),
                ),
              ),

              // Microphone button
              const SizedBox(width: 8),
              IconButton(
                onPressed: chatProvider.isLoading ? null : _toggleRecording,
                icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                style: IconButton.styleFrom(
                  foregroundColor: _isRecording
                      ? AppColors.error
                      : AppColors.textSecondary,
                  backgroundColor: _isRecording
                      ? AppColors.error.withOpacity(0.1)
                      : null,
                ),
                tooltip: _isRecording
                    ? 'Stop recording'
                    : 'Start voice recording',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSendButton(ChatProvider chatProvider) {
    return IconButton(
      onPressed: (_hasText && !chatProvider.isLoading)
          ? () => _sendMessage(chatProvider)
          : null,
      icon: Icon(
        Icons.send,
        color: (_hasText && !chatProvider.isLoading)
            ? AppColors.primary
            : AppColors.textHint,
      ),
      tooltip: 'Send message',
    );
  }

  void _sendMessage(ChatProvider chatProvider) {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      chatProvider.sendMessage(text);
      _textController.clear();
      setState(() {
        _hasText = false;
      });
      _focusNode.unfocus();
    }
  }

  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Choose Attachment',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAttachmentOption(
                    icon: Icons.description,
                    label: 'Document',
                    color: AppColors.info,
                    onTap: _pickDocument,
                  ),
                  _buildAttachmentOption(
                    icon: Icons.image,
                    label: 'Image',
                    color: AppColors.success,
                    onTap: _pickImage,
                  ),
                  _buildAttachmentOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    color: AppColors.warning,
                    onTap: _takePhoto,
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'md'],
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        final chatProvider = Provider.of<ChatProvider>(context, listen: false);
        chatProvider.setDocument(file);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Document "${result.files.single.name}" added'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking document: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        await _handleSelectedImage(image.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.camera);

      if (image != null) {
        await _handleSelectedImage(image.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error taking photo: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleSelectedImage(String imagePath) async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    // Show dialog to confirm sending image with optional message
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _ImageConfirmDialog(imagePath: imagePath),
    );

    if (result != null) {
      if (mounted) {
        await chatProvider.sendMessage(
          result['message'] ?? '',
          imagePath: imagePath,
        );
      }
    }
  }

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
    });

    if (_isRecording) {
      // TODO: Start audio recording
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Voice recording feature coming soon!'),
          backgroundColor: AppColors.info,
        ),
      );
      // For now, just toggle back
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _isRecording = false;
          });
        }
      });
    } else {
      // TODO: Stop audio recording and process
    }
  }
}

class _ImageConfirmDialog extends StatefulWidget {
  final String imagePath;

  const _ImageConfirmDialog({required this.imagePath});

  @override
  State<_ImageConfirmDialog> createState() => _ImageConfirmDialogState();
}

class _ImageConfirmDialogState extends State<_ImageConfirmDialog> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Send Image'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image preview
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(File(widget.imagePath), fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 16),
          // Optional message input
          TextField(
            controller: _messageController,
            decoration: const InputDecoration(
              hintText: 'Add a message (optional)...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {'message': _messageController.text.trim()});
          },
          child: const Text('Send'),
        ),
      ],
    );
  }
}
