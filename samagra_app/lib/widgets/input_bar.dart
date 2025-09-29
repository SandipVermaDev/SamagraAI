import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../providers/chat_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../utils/web_speech.dart';

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
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  String _preMicText = '';
  WebSpeechRecognizer? _webSpeech; // Web fallback
  bool _usingWebSpeech = false;
  bool _isStarting = false;

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

  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _speech.initialize(
        onStatus: _onSpeechStatus,
        onError: _onSpeechError,
        debugLogging: false,
      );
    } catch (e) {
      debugPrint('[InputBar] Speech init error: $e');
      _speechAvailable = false;
    }
    // On web, if plugin isn't available, try Web Speech API fallback
    if (kIsWeb && !_speechAvailable) {
      _webSpeech ??= WebSpeechRecognizer();
      try {
        await _webSpeech!.initialize();
      } catch (e) {
        debugPrint('[InputBar] WebSpeech init error: $e');
      }
    }
    if (mounted) setState(() {});
  }

  void _onSpeechStatus(String status) {
    debugPrint('[InputBar] Speech status: $status');
    // Keep icon in sync with plugin status
    if (!_usingWebSpeech && mounted) {
      final isNowListening = status == 'listening';
      if (_isRecording != isNowListening) {
        setState(() => _isRecording = isNowListening);
      }
    }
  }

  void _onSpeechError(dynamic error) {
    try {
      debugPrint('[InputBar] Speech error: ${error.errorMsg}');
    } catch (_) {
      debugPrint('[InputBar] Speech error: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ChatProvider, ThemeProvider>(
      builder: (context, chatProvider, themeProvider, child) {
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
                  foregroundColor: themeProvider.getTextSecondary(context),
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
                            : 'Type your message... ',
                        suffixIcon: _buildSendButton(
                          chatProvider,
                          themeProvider,
                        ),
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
                      : themeProvider.getTextSecondary(context),
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

  Widget _buildSendButton(
    ChatProvider chatProvider,
    ThemeProvider themeProvider,
  ) {
    return IconButton(
      onPressed: (_hasText && !chatProvider.isLoading)
          ? () => _sendMessage(chatProvider)
          : null,
      icon: Icon(
        Icons.send,
        color: (_hasText && !chatProvider.isLoading)
            ? AppColors.mediumPurple
            : themeProvider.getTextHint(context),
      ),
      tooltip: 'Send message',
    );
  }

  void _sendMessage(ChatProvider chatProvider) {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      if (_isRecording) {
        _stopListening();
      }
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
                    label: kIsWeb ? 'Gallery' : 'Image',
                    color: AppColors.success,
                    onTap: _pickImage,
                  ),
                  _buildAttachmentOption(
                    icon: Icons.camera_alt,
                    label: kIsWeb ? 'Camera' : 'Camera',
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
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDocument() async {
    try {
      debugPrint('[InputBar] _pickDocument: opening file picker...');
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'md'],
        allowMultiple: true, // Enable multiple file selection
      );

      if (!mounted) return;

      debugPrint('[InputBar] _pickDocument: picker result: ${result != null}');

      if (result != null && result.files.isNotEmpty) {
        final chatProvider = Provider.of<ChatProvider>(context, listen: false);

        if (kIsWeb) {
          // Web: FilePicker returns bytes
          final webFiles = <Map<String, dynamic>>[];

          for (final platformFile in result.files) {
            if (platformFile.bytes != null) {
              webFiles.add({
                'bytes': platformFile.bytes!,
                'name': platformFile.name,
                'size': platformFile.bytes!.length,
              });
              debugPrint(
                '[InputBar] _pickDocument: web file name=${platformFile.name} size=${platformFile.bytes!.length}',
              );
            } else {
              debugPrint(
                '[InputBar] _pickDocument: web file bytes are null for ${platformFile.name}',
              );
            }
          }

          if (webFiles.isNotEmpty) {
            chatProvider.addMultipleDocumentsFromWeb(webFiles);
          }
        } else {
          // Mobile/desktop: use path
          final files = <File>[];

          for (final platformFile in result.files) {
            if (platformFile.path != null) {
              final file = File(platformFile.path!);
              files.add(file);
              debugPrint(
                '[InputBar] _pickDocument: selected file path=${file.path} size=${file.lengthSync()}',
              );
            } else {
              debugPrint(
                '[InputBar] _pickDocument: platform file path is null for ${platformFile.name}',
              );
            }
          }

          if (files.isNotEmpty) {
            chatProvider.addMultipleDocuments(files);
            debugPrint(
              '[InputBar] _pickDocument: chatProvider.addMultipleDocuments called',
            );
          }
        }
      } else {
        debugPrint('[InputBar] _pickDocument: no file selected');
      }
    } catch (e, st) {
      debugPrint('[InputBar] _pickDocument: error -> $e');
      debugPrint(st.toString());
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
      debugPrint('[InputBar] _pickImage: opening gallery picker...');
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (!mounted) return;
      debugPrint('[InputBar] _pickImage: picked=${image != null}');

      if (image != null) {
        final chatProvider = Provider.of<ChatProvider>(context, listen: false);
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          chatProvider.setPendingImageFromBytes(bytes, image.name);
        } else {
          chatProvider.setPendingImageFromPath(image.path, image.name);
        }
        // No popup; image now appears above the input like documents
      }
    } catch (e, st) {
      debugPrint('[InputBar] _pickImage: error -> $e');
      debugPrint(st.toString());
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
      debugPrint('[InputBar] _takePhoto: launching camera...');
      final picker = ImagePicker();

      if (kIsWeb) {
        // On web, show user that this will open camera if available
        final shouldProceed = await _showWebCameraDialog();
        if (!shouldProceed) return;
      }
      final image = await picker.pickImage(source: ImageSource.camera);
      if (!mounted) return;
      debugPrint('[InputBar] _takePhoto: captured=${image != null}');

      if (image != null) {
        final chatProvider = Provider.of<ChatProvider>(context, listen: false);
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          chatProvider.setPendingImageFromBytes(bytes, image.name);
        } else {
          chatProvider.setPendingImageFromPath(image.path, image.name);
        }
        // No popup; image now appears above the input like documents
      }
    } catch (e, st) {
      debugPrint('[InputBar] _takePhoto: error -> $e');
      debugPrint(st.toString());
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

  Future<bool> _showWebCameraDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Camera Access'),
            content: const Text(
              'This will attempt to access your camera. On some browsers, this might open a file picker instead. Grant camera permissions for the best experience.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Continue'),
              ),
            ],
          ),
        ) ??
        false;
  }

  // No confirm dialog flow for images; staged image shows above input until message is sent.

  void _toggleRecording() {
    if (_isRecording) {
      _stopListening();
      return;
    }
    _startListening();
  }

  Future<void> _startListening() async {
    if (_isStarting) return; // Prevent re-entrancy
    // Ensure speech is initialized
    if (!_speechAvailable) {
      await _initSpeech();
    }

    // Choose provider: prefer plugin when available; else use web fallback (on web)
    if (kIsWeb && !_speechAvailable) {
      // Try web fallback
      _webSpeech ??= WebSpeechRecognizer();
      await _webSpeech!.initialize();
      if (!(_webSpeech!.isSupported)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Speech recognition is not available here. On web, only some browsers support it.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    // Request microphone permission (mobile/desktop)
    if (!kIsWeb) {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission is required.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    // If plugin already listening, just reflect UI
    if (_speechAvailable && _speech.isListening) {
      if (mounted) {
        setState(() {
          _isRecording = true;
          _usingWebSpeech = false;
        });
      }
      return;
    }

    _preMicText = _textController.text;
    _isStarting = true;
    if (kIsWeb && !_speechAvailable && (_webSpeech?.isSupported ?? false)) {
      final didStart = await _webSpeech!.start(
        onResult: _onWebSpeechResult,
        maxListen: const Duration(minutes: 2),
        pauseFor: const Duration(seconds: 3),
      );
      if (didStart == true && mounted) {
        setState(() {
          _isRecording = true;
          _usingWebSpeech = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Listening… (Web Speech API)'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } else {
      final didStart = await _speech.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(minutes: 2),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.dictation,
      );
      if (didStart == true && mounted) {
        setState(() {
          _isRecording = true;
          _usingWebSpeech = false;
        });
      }
    }
    _isStarting = false;
  }

  void _onSpeechResult(dynamic result) {
    String spoken = '';
    try {
      spoken = result.recognizedWords as String;
    } catch (_) {
      try {
        spoken = result.toString();
      } catch (_) {}
    }
    if (spoken.isEmpty) return;
    final prefix = _preMicText.trim();
    final text = prefix.isEmpty ? spoken : '$prefix ${spoken.trim()}';
    _textController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    if (mounted && !_isRecording && (_speech.isListening)) {
      setState(() => _isRecording = true);
    }
  }

  Future<void> _stopListening() async {
    try {
      if (_usingWebSpeech) {
        await _webSpeech?.stop();
      } else {
        await _speech.stop();
      }
    } catch (_) {}
    _isStarting = false;
    if (mounted) setState(() => _isRecording = false);
  }

  void _onWebSpeechResult(String text, bool isFinal) {
    if (text.isEmpty) return;
    final prefix = _preMicText.trim();
    final combined = prefix.isEmpty ? text : '$prefix ${text.trim()}';
    _textController.value = TextEditingValue(
      text: combined,
      selection: TextSelection.collapsed(offset: combined.length),
    );
    // If result is final and there was no prior text, keep listening until user stops
  }
}

// Removed image confirm dialog; images follow the same staging UX as documents.
