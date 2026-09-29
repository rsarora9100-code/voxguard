import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/transcript_entry.dart';
import 'api_service.dart';

class AudioStreamEvent {
  final String type; // audio_classification, transcript_update, assistant_reply, pong
  final Map<String, dynamic> data;

  AudioStreamEvent({required this.type, required this.data});
}

class WebSocketAudioService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  final _eventController = StreamController<AudioStreamEvent>.broadcast();
  Stream<AudioStreamEvent> get eventStream => _eventController.stream;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  /// Connects to the full-duplex call stream for a specific call ID
  Future<void> connectCallStream(String callId, {String? phoneNumber}) async {
    disconnect();

    final wsHost = ApiService.baseUrl.replaceFirst('http://', 'ws://').replaceFirst('https://', 'wss://');
    final uri = Uri.parse('$wsHost/ws/call-stream/$callId');

    try {
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;
      _isConnected = true;

      // Send initial hand-shake
      if (phoneNumber != null) {
        _channel!.sink.add(jsonEncode({
          'action': 'init',
          'phone_number': phoneNumber,
        }));
      }

      _subscription = _channel!.stream.listen(
        (message) {
          try {
            final Map<String, dynamic> parsed = jsonDecode(message);
            final eventType = parsed['type'] ?? 'unknown';
            _eventController.add(AudioStreamEvent(type: eventType, data: parsed));
          } catch (e) {
            print('Error parsing WebSocket message: $e');
          }
        },
        onError: (err) {
          print('WebSocket error: $err');
          _isConnected = false;
        },
        onDone: () {
          print('WebSocket closed');
          _isConnected = false;
        },
      );
    } catch (e) {
      print('Failed to connect to call stream: $e');
      _isConnected = false;
    }
  }

  /// Sends raw 16kHz PCM audio bytes directly over WebSocket sink
  void sendAudioBytes(Uint8List audioBytes) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(audioBytes);
    }
  }

  /// Sends base64-encoded audio chunk JSON
  void sendAudioBase64(String base64Chunk, {String? phoneNumber}) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(jsonEncode({
        'action': 'audio_chunk',
        'audio_base64': base64Chunk,
        'phone_number': phoneNumber,
      }));
    }
  }

  /// Sends spoken speech text (e.g. from local STT or manual simulation)
  void sendCallerSpeech(String text, {String language = 'en', String? phoneNumber}) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(jsonEncode({
        'action': 'caller_speech',
        'text': text,
        'language': language,
        'phone_number': phoneNumber,
      }));
    }
  }

  void disconnect() {
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
  }

  void dispose() {
    disconnect();
    _eventController.close();
  }
}
