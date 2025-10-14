import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

class AzureTTSController {
  final AudioPlayer _player = AudioPlayer();
  final String _subscriptionKey = "qJt122z7HesHEfWe7gxjzFpfihHoOxseP8yKXFqmbHxDuXgCqSu7JQQJ99BIACqBBLyXJ3w3AAAYACOGcuGt";
  final String _region = "southeastasia";
  final String _selectedVoice = 'en-GB-SoniaNeural';

  bool _isPlaying = false;
  bool _isLoading = false;
  Timer? _debounceTimer;

  Future<void> speak(String text) async {
    _debounceTimer?.cancel();

    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      await _executeSpeak(text);
    });
  }

  Future<void> _executeSpeak(String text) async {
    if (_isLoading || _isPlaying) {
      debugPrint("TTS: Request skipped - already loading or playing");
      return;
    }

    try {
      _isLoading = true;

      if (_player.playing) {
        await _player.stop();
        await Future.delayed(const Duration(milliseconds: 50));
      }

      final url = Uri.parse('https://$_region.tts.speech.microsoft.com/cognitiveservices/v1');

      final ssml = '''
<speak version='1.0' xml:lang='en-US'>
  <voice name='$_selectedVoice'>
    ${_escapeText(text)}
  </voice>
</speak>
''';

      debugPrint("TTS: Sending request for text: $text");

      final response = await http.post(
        url,
        headers: {
          'Ocp-Apim-Subscription-Key': _subscriptionKey,
          'Content-Type': 'application/ssml+xml',
          'X-Microsoft-OutputFormat': 'audio-16khz-128kbitrate-mono-mp3',
          'User-Agent': 'FlutterNavigationApp',
        },
        body: ssml,
      );

      debugPrint("TTS: Response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        final file = File("${dir.path}/azure_tts_${DateTime.now().millisecondsSinceEpoch}.mp3");
        await file.writeAsBytes(response.bodyBytes);

        debugPrint("TTS: Audio file saved at: ${file.path}");

        _isLoading = false;
        _isPlaying = true;

        _player.playbackEventStream.listen((event) {}, onError: (e) {
          debugPrint("TTS: Playback error: $e");
          _isPlaying = false;
        });

        _player.playerStateStream.listen((state) {
          if (state.processingState == ProcessingState.completed) {
            _isPlaying = false;
            debugPrint("TTS: Playback completed");
          }
        });

        await _player.setFilePath(file.path);
        await _player.play();

      } else {
        _isLoading = false;
        debugPrint("Azure TTS failed with status: ${response.statusCode}");
      }
    } catch (e) {
      _isLoading = false;
      _isPlaying = false;
      debugPrint("Azure TTS error: $e");
    }
  }

  String _escapeText(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  Future<void> stop() async {
    _debounceTimer?.cancel();
    _isLoading = false;
    _isPlaying = false;
    await _player.stop();
  }

  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;

  void dispose() {
    _debounceTimer?.cancel();
    _player.dispose();
  }
}