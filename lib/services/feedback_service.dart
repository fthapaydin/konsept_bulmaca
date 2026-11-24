import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Karehane özel ses efektleri + titreşim (haptik) servisi.
/// Test ortamında veya ses kapalıyken güvenle sessiz moda düşer.
class FeedbackService {
  FeedbackService({this.enableAudioEngine = true});

  final bool enableAudioEngine;
  bool soundEnabled = true;
  bool hapticsEnabled = true;

  AudioPlayer? _sfxPlayer;
  AudioPlayer? _accentPlayer;

  AudioPlayer _ensureSfx() {
    final p = _sfxPlayer ??= AudioPlayer();
    return p;
  }

  AudioPlayer _ensureAccent() {
    final p = _accentPlayer ??= AudioPlayer();
    return p;
  }

  void _playAsset(String fileName, {bool accent = false}) {
    if (!soundEnabled || !enableAudioEngine) return;
    unawaited(() async {
      try {
        final player = accent ? _ensureAccent() : _ensureSfx();
        await player.stop();
        await player.play(
          AssetSource('sounds/$fileName'),
          mode: PlayerMode.lowLatency,
        );
      } catch (_) {
        // Test ortamında veya platform kanalı hazır değilken sessizce yut.
      }
    }());
  }

  void keyTap() {
    if (hapticsEnabled) {
      HapticFeedback.selectionClick();
    }
    _playAsset('tap.wav');
  }

  void backspaceTap() {
    if (hapticsEnabled) {
      HapticFeedback.selectionClick();
    }
    _playAsset('backspace.wav');
  }

  void cellSelect() {
    if (hapticsEnabled) {
      HapticFeedback.selectionClick();
    }
  }

  void wordSolved() {
    if (hapticsEnabled) {
      HapticFeedback.mediumImpact();
    }
    _playAsset('word_ok.wav', accent: true);
  }

  void comboSolved() {
    if (hapticsEnabled) {
      HapticFeedback.mediumImpact();
    }
    _playAsset('combo.wav', accent: true);
  }

  void hintUsed() {
    if (hapticsEnabled) {
      HapticFeedback.lightImpact();
    }
    _playAsset('hint.wav', accent: true);
  }

  void puzzleSolved() {
    if (hapticsEnabled) {
      HapticFeedback.heavyImpact();
    }
    _playAsset('victory.wav', accent: true);
  }

  void errorPulse() {
    if (hapticsEnabled) {
      HapticFeedback.vibrate();
    }
    _playAsset('error.wav', accent: true);
  }

  void sprintTick() {
    _playAsset('tick.wav');
  }

  void dispose() {
    _sfxPlayer?.dispose();
    _accentPlayer?.dispose();
  }
}
