// Stub implementation used for non-web platforms
class WebSpeechRecognizer {
  bool get isSupported => false;
  bool get isListening => false;

  Future<bool> initialize() async => false;
  Future<bool> start({
    required void Function(String text, bool isFinal) onResult,
    Duration? maxListen,
    Duration? pauseFor,
  }) async => false;
  Future<void> stop() async {}
}
