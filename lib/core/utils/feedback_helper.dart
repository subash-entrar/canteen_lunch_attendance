import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class FeedbackHelper {
  FeedbackHelper._();

  static final AudioPlayer _player = AudioPlayer();
  static DateTime? _lastSuccessAt;

  static Future<void> success() async {
    final now = DateTime.now();
    if (_lastSuccessAt != null &&
        now.difference(_lastSuccessAt!) < const Duration(milliseconds: 400)) {
      await HapticFeedback.lightImpact();
      return;
    }
    _lastSuccessAt = now;

    try {
      await HapticFeedback.heavyImpact();
      await _player.stop();
      await _player.play(AssetSource('sounds/success_beep.wav'));
    } catch (_) {
      await SystemSound.play(SystemSoundType.click);
    }
  }

  static Future<void> error() async {
    try {
      await HapticFeedback.vibrate();
      await SystemSound.play(SystemSoundType.alert);
    } catch (_) {}
  }
}
