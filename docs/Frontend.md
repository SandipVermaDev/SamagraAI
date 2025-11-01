# Frontend (Flutter) 🎨

> Prev: [Backend](Backend.md) · Next: [API](API.md)

## Overview
- Material 3 app with `ThemeProvider` for light/dark modes and `ChatProvider` for chat state.
- Two main screens: `ChatScreen` (default) and `SettingsScreen` (model selection, preferences).
- Streaming markdown display for AI messages; attachments preview above input.

## Key Files
- `lib/main.dart`: `MultiProvider` setup, routes.
- `providers/chat_provider.dart`:
  - Manages messages list, selected model, staged documents/images.
  - Sends messages via `services/chat_service.dart` using SSE.
  - Handles upload of documents before sending chat (marks processed).
  - Streams AI chunks (text or image markers) and updates the last AI message progressively.
- `providers/theme_provider.dart`: theme mode + helpers for bubble colors.
- `services/chat_service.dart` (Dart):
  - `sendMessageStream(...)` posts to `/chat/stream`, parses `data:` lines, emits content or image markers `\u0000IMAGE|{mime}|{base64}\u0000` and a clear signal `\u0000CLEAR\u0000`.
  - `uploadSingleDocument(...)` posts multipart to `/documents/upload`.
- `widgets/message_bubble.dart`: markdown rendering for AI, image dialog/download, document chips, typing indicator.
- `widgets/input_bar.dart`: text input, image/document attach, speech recording; web speech fallback on browsers.
- `screens/settings_screen.dart`: choose model (maps to backend model ids), tweak toggles.

## UI Flow
1. User types or dictates a message; optionally attaches PDFs/images.
2. On send:
   - Any new documents are uploaded first; state marks them processed.
   - Starts SSE; shows a loading AI message.
   - As chunks arrive, the AI bubble updates; image responses render as previews.
3. After completion, staged attachments are cleared from the preview (documents remain indexed for future turns until cleared in backend).

## Theming & Markdown
- `AppTheme` defines color schemes; `MessageBubble` applies a markdown stylesheet for readability and code blocks.

## Speech Input
- `speech_to_text` plugin on mobile/desktop; web-only fallback recognizer when plugin unavailable (`WebSpeechRecognizer`).

## Error Handling

---
- Snackbars for mic permission issues and unsupported web speech.
- Graceful fallback if SSE parsing errors occur.

Prev: [Backend](Backend.md) · Next: [API](API.md)