// Web implementation using the Web Speech API via dart:html
import 'dart:async';
import 'dart:html' as html;

typedef WebSpeechCallback = void Function(String text, bool isFinal);

class WebSpeechRecognizer {
  dynamic
  _recognition; // html.SpeechRecognition is not typed in dart:html for all channels
  bool _isSupported = false;
  bool _isListening = false;
  StreamSubscription? _onEndTimer;

  bool get isSupported => _isSupported;
  bool get isListening => _isListening;

  Future<bool> initialize() async {
    // Check for native SpeechRecognition or prefixed webkitSpeechRecognition
    final win = html.window;
    final dynamic speechRecognition =
        (win as dynamic).SpeechRecognition ??
        (win as dynamic).webkitSpeechRecognition;
    if (speechRecognition == null) {
      _isSupported = false;
      return false;
    }
    _recognition = speechRecognition();
    try {
      _recognition.continuous = true;
      _recognition.interimResults = true;
      final String? lang = html.window.navigator.language;
      _recognition.lang = (lang != null && lang.isNotEmpty) ? lang : 'en-US';
      _isSupported = true;
      return true;
    } catch (_) {
      _isSupported = false;
      return false;
    }
  }

  Future<bool> start({
    required WebSpeechCallback onResult,
    Duration? maxListen,
    Duration? pauseFor,
  }) async {
    if (!_isSupported) {
      final ok = await initialize();
      if (!ok) return false;
    }
    if (_isListening) return true;

    _recognition.onresult = (dynamic event) {
      try {
        final results = event.results;
        if (results == null) return;
        final length = results.length as int;
        if (length == 0) return;
        final last = results.item(length - 1);
        final transcript = last[0].transcript as String? ?? '';
        final isFinal = last.isFinal as bool? ?? false;
        if (transcript.isNotEmpty) onResult(transcript, isFinal);
      } catch (_) {}
    };

    _recognition.onerror = (dynamic event) {
      // Ignore for now; consumer can handle via start() return
    };

    _recognition.onend = (dynamic _) {
      _isListening = false;
    };

    try {
      _recognition.start();
      _isListening = true;

      if (maxListen != null) {
        _onEndTimer?.cancel();
        _onEndTimer = Future<void>.delayed(maxListen).asStream().listen((
          _,
        ) async {
          await stop();
        });
      }
      return true;
    } catch (_) {
      _isListening = false;
      return false;
    }
  }

  Future<void> stop() async {
    _onEndTimer?.cancel();
    _onEndTimer = null;
    try {
      if (_recognition != null) {
        _recogninationStopSafe(_recognition);
      }
    } catch (_) {}
    _isListening = false;
  }

  void _recogninationStopSafe(dynamic rec) {
    try {
      rec.stop();
    } catch (_) {}
  }
}
