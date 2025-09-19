import 'package:flutter/material.dart';
import 'dart:io';
import '../models/chat_message.dart';
import '../theme/app_theme.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isLastMessage;

  const MessageBubble({
    super.key,
    required this.message,
    this.isLastMessage = false,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == MessageSender.user;

    return Row(
      mainAxisAlignment: isUser
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        if (!isUser) ...[
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary,
            child: Icon(Icons.smart_toy, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Container(
            margin: EdgeInsets.only(
              left: isUser ? 32 : 0,
              right: isUser ? 0 : 32,
            ),
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppColors.userMessageBg
                        : AppColors.aiMessageBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image preview if present
                      if (message.hasImage) _buildImagePreview(),

                      // Message content
                      if (message.content.isNotEmpty)
                        _buildMessageContent(isUser),

                      // Loading indicator for AI messages
                      if (message.isLoading) _buildLoadingIndicator(),
                    ],
                  ),
                ),
                // Timestamp
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _formatTimestamp(message.timestamp),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isUser) ...[
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary,
            child: Icon(Icons.person, color: Colors.white, size: 16),
          ),
        ],
      ],
    );
  }

  Widget _buildImagePreview() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(message.imagePath!),
          height: 200,
          width: 200,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 200,
              width: 200,
              color: Colors.grey[300],
              child: const Icon(
                Icons.broken_image,
                color: Colors.grey,
                size: 48,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMessageContent(bool isUser) {
    return SelectableText(
      message.content,
      style: TextStyle(
        color: isUser ? AppColors.userMessageText : AppColors.aiMessageText,
        fontSize: 14,
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.aiMessageText),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'AI is thinking...',
          style: TextStyle(
            color: AppColors.aiMessageText,
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
