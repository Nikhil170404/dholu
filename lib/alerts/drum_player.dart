import 'package:audioplayers/audioplayers.dart';

import '../native/native_bridge.dart';

abstract class DrumPlayer {
  /// Plays the drum roll unless the phone is silent / in Do Not Disturb.
  Future<void> play();
}

class AssetDrumPlayer implements DrumPlayer {
  AssetDrumPlayer(this._bridge);
  final NativeBridge _bridge;
  final AudioPlayer _p = AudioPlayer();

  @override
  Future<void> play() async {
    if (await _bridge.isSilentMode()) {
      return;
    }
    try {
      await _p.setAudioContext(
        AudioContextConfig(
          route: AudioContextConfigRoute.system,
          focus: AudioContextConfigFocus.mixWithOthers,
        ).build(),
      );
      await _p.play(AssetSource('audio/drumroll.wav'), volume: 0.8);
    } on Object {
      // sound is a nicety; never break the alert
    }
  }
}

class NoopDrumPlayer implements DrumPlayer {
  int plays = 0;
  @override
  Future<void> play() async => plays++;
}
