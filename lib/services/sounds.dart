import 'package:audioplayers/audioplayers.dart';

class SoundsService {
  final player = AudioPlayer();
  double volume = 0.3;

  Future<void> playListen() async {
    await player.setVolume(volume);
    await player.play(AssetSource("sounds/listen.wav"));
  }

  Future<void> playStopListen() async {
    await player.setVolume(volume);
    await player.play(AssetSource("sounds/stop_listen.wav"));
  }
}
