import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';

import 'audio_key.dart';

/// Playback: bundled neural MP3 → optional remote CDN → system TTS fallback.
///
/// Today clips live under `assets/audio/`. When a backend exists, set
/// `remoteBaseUrl` in `assets/audio/manifest.json` (or override at runtime via
/// [configureRemoteBaseUrl]) so the same keys load from CDN / API preload.
class TtsService {
  TtsService();

  final AudioPlayer _player = AudioPlayer();
  final FlutterTts _tts = FlutterTts();

  Future<void>? _ready;
  bool _ttsFailed = false;
  String? _remoteBaseUrl;
  final Map<String, _ClipMeta> _clips = {};

  /// Optional override (e.g. after fetching config from your future API).
  void configureRemoteBaseUrl(String? url) {
    final trimmed = url?.trim();
    _remoteBaseUrl = (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  Future<void> _ensureReady() {
    return _ready ??= _init();
  }

  Future<void> _init() async {
    await Future.wait([_loadManifest(), _initSystemTts()]);
  }

  Future<void> _loadManifest() async {
    try {
      final raw = await rootBundle.loadString('assets/audio/manifest.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final remote = json['remoteBaseUrl'];
      if (remote is String && remote.trim().isNotEmpty) {
        _remoteBaseUrl = remote.trim();
      }
      final clips = json['clips'];
      if (clips is Map<String, dynamic>) {
        clips.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            final file = value['file'] as String?;
            if (file != null && file.isNotEmpty) {
              _clips[key] = _ClipMeta(
                file: file,
                text: value['text'] as String? ?? key,
              );
            }
          }
        });
      }
    } catch (e) {
      debugPrint('TtsService: manifest missing or invalid ($e)');
    }
  }

  Future<void> _initSystemTts() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.42);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      try {
        await _tts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.mixWithOthers,
          ],
          IosTextToSpeechAudioMode.voicePrompt,
        );
      } catch (_) {}
    } catch (_) {
      _ttsFailed = true;
    }
  }

  Future<void> speak(String text) async {
    final cleaned = text.trim();
    if (cleaned.isEmpty) return;
    await _ensureReady();

    final key = audioKey(cleaned);
    final clip = _clips[key];

    if (clip != null) {
      if (await _playAsset(clip.file)) return;
      if (await _playRemote(clip.file)) return;
    } else if (_remoteBaseUrl != null) {
      // Future backend may serve keys not yet in the local manifest.
      if (await _playRemote('en-us/$key.mp3')) return;
    }

    await _speakSystem(cleaned);
  }

  Future<bool> _playAsset(String relativeFile) async {
    try {
      await _player.stop();
      await _player.setAsset('assets/audio/$relativeFile');
      await _player.play();
      return true;
    } catch (e) {
      debugPrint('TtsService: asset miss $relativeFile ($e)');
      return false;
    }
  }

  Future<bool> _playRemote(String relativeFile) async {
    final base = _remoteBaseUrl;
    if (base == null) return false;
    final url = base.endsWith('/')
        ? '$base$relativeFile'
        : '$base/$relativeFile';
    try {
      await _player.stop();
      await _player.setUrl(url);
      await _player.play();
      return true;
    } catch (e) {
      debugPrint('TtsService: remote miss $url ($e)');
      return false;
    }
  }

  Future<void> _speakSystem(String text) async {
    if (_ttsFailed) return;
    try {
      await _player.stop();
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {
      _ttsFailed = true;
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
    try {
      await _tts.stop();
    } catch (_) {}
  }
}

class _ClipMeta {
  const _ClipMeta({required this.file, required this.text});

  final String file;
  final String text;
}
