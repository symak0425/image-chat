import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'package:hackaton/core/jsonHelper.dart' as json_helper;
import 'package:hackaton/main.dart';

// List<bool> TTSClearHistory = [false];
AudioPlayer audioPlayer = AudioPlayer();
bool ttsLocked = false;

class TTSService {
  Future<FlutterTts> setupFlutterTts() async {
    FlutterTts flutterTts = FlutterTts();
    Map<String, dynamic> jsonSettings = await json_helper.jsonSettings;
    logger.v("lang: ${jsonSettings["outputLanguage"]}");
    List<dynamic> languages = await flutterTts.getLanguages;

    logger.v("$languages LANGS");
    await flutterTts.setLanguage(jsonSettings["outputLanguage"]);

    await flutterTts.setSpeechRate(1.0);

    await flutterTts.setVolume(1.0);
    await flutterTts.setSpeechRate(0.6);

    await flutterTts.setPitch(1.0);

    return flutterTts;
  }

  Future<void> ttsApi(String text) async {
    ttsLocked = true;

    FlutterTts flutterTts = await setupFlutterTts();
    await flutterTts.awaitSpeakCompletion(true);

    HapticFeedback.lightImpact();
    EasyLoading.showToast("Answer: $text",
        toastPosition: EasyLoadingToastPosition.center,
        maskType: EasyLoadingMaskType.custom,
        duration: const Duration(seconds: 10000),
        dismissOnTap: true);
    var result = await flutterTts.speak(text);
    EasyLoading.dismiss();

    if (result == 0) {
      EasyLoading.showError("Failed to synthesize audio",
          duration: const Duration(seconds: 5));
    }
    ttsLocked = false;
    // EasyLoading.showSuccess("Playing");

    // if (== 200) {
    //   // Get the temporary directory of the device
    //   var tempDir = await getApplicationSupportDirectory();
    //   filePath = '${tempDir.path}/tempAudio.wav';
    //
    //   // Write the file
    //   var file = File(filePath);
    //   await file.writeAsBytes(response.bodyBytes);
    //
    //   // Clear any other audio first
    //   audioPlayer.stop();
    //
    //   // Wait for 100 ms
    //   await Future.delayed(const Duration(milliseconds: 100));
    //
    //   HapticFeedback.heavyImpact();
    //
    //   EasyLoading.showSuccess("Playing");
    //
    //   // Set the audio source to the file and play
    //   await audioPlayer.play(DeviceFileSource(filePath));
    //
    //   ttsLocked = false;
    //
    //   // costantly check if ttsClear is true
    //   // await Isolate.spawn(TTSCheckHistory, ["this must be here"]);
    //
    //   print("Successfully synthesized and playing from file.");
    // } else {
    //   ttsLocked = false;
    //   print("Failed to save file. Status code: ${response.statusCode}");
    //   EasyLoading.showError(
    //       "Failed to save file. Status code: ${response.statusCode}");
    // }
  }

  // void TTSCheckHistory(List<String> randomThing) async {
  //   while (true) {
  //     await Future.delayed(const Duration(milliseconds: 100));
  //     if (_audioPlayer.playing && TTSClearHistory != localTTSClearHistory) {
  //       _audioPlayer.stop();
  //       localTTSClearHistory = TTSClearHistory;
  //       print("TTS cleared");
  //       break;
  //     }
  //   }
  // }
}
