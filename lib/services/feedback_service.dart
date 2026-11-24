import 'package:flutter/services.dart';

class FeedbackService {
  bool soundEnabled = true;
  bool hapticsEnabled = true;

  void keyTap() {
    if (hapticsEnabled) {
      HapticFeedback.selectionClick();
    }
    if (soundEnabled) {
      SystemSound.play(SystemSoundType.click);
    }
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
  }

  void puzzleSolved() {
    if (hapticsEnabled) {
      HapticFeedback.heavyImpact();
    }
  }

  void errorPulse() {
    if (hapticsEnabled) {
      HapticFeedback.vibrate();
    }
  }
}
