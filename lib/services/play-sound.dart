import 'package:audioplayers/audioplayers.dart';

class PlaySoundService {
  final AudioPlayer audioPlayer = AudioPlayer();

  Future<void> playSoundEffect(filepath) async {
    // Play a sound effect
    await audioPlayer.play(AssetSource(filepath));
  }
}
