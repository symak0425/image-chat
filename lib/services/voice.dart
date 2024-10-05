import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:hackaton/main.dart';
import 'package:hackaton/services/sounds.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class VoiceRecorderService {
  final recorder = AudioRecorder();
  final soundsService = SoundsService();

  Future<void> record() async {
    Directory appDocDir = await getApplicationSupportDirectory();
    String appDocPath = appDocDir.path;

    logger.i("Recording...");

    // Check and request permission if needed
    if (await recorder.hasPermission()) {
      await soundsService.playListen();

      HapticFeedback.heavyImpact();

      // Start recording to file
      await recorder.start(const RecordConfig(), path: "$appDocPath/rec.wav");
    }
  }

  Future<void> stop() async {
    await recorder.stop();
    soundsService.playStopListen();

    HapticFeedback.heavyImpact();
    HapticFeedback.heavyImpact();
  }

  Future<void> play() async {
    Directory appDocDir = await getApplicationSupportDirectory();
    String appDocPath = appDocDir.path;

    final player = AudioPlayer();

    await player.play(DeviceFileSource("$appDocPath/rec.wav"));
  }

  Future<bool> hasPermission() async {
    return await recorder.hasPermission();
  }
}
