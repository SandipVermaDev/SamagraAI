// Conditional export for Web Speech API wrapper
export 'web_speech_stub.dart' if (dart.library.html) 'web_speech_web.dart';
