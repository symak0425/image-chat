import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:hackaton/app.dart';
import 'package:hackaton/main.dart';
import 'package:hackaton/ui/components/prompts-table.dart';
import 'package:hackaton/app_config.dart' as env;
import 'package:hackaton/ui/components/top-bar.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:io';
import 'package:hackaton/services/server-requests.dart';
import 'package:hackaton/core/jsonHelper.dart' as json_helper;

class VoiceRecordPage extends StatefulWidget {
  const VoiceRecordPage({super.key, required this.imagePath});
  final String imagePath;

  @override
  _VoiceRecordPageState createState() => _VoiceRecordPageState();
}

class _VoiceRecordPageState extends State<VoiceRecordPage> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _lastWords = ""; // Variable to store the last recognized words
  Timer? _holdTimer;
  List<String> promptCache = []; // Cache for prompts
  List<String> responseCache = []; // Cache for responses
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (context, appState, child) {
      return Scaffold(
        key: _scaffoldKey,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(55),
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: TopBar(
              showLogo: false,
            ),
          ),
        ),
        body: Column(
          children: [
            // The prompts table widget
            Expanded(child: PromptsTable(imagePath: widget.imagePath)),
            // The section for the voice recording button
            Container(
              margin: const EdgeInsets.all(15),
              height: 90,
              width: double.infinity,
              child: GestureDetector(
                onLongPressStart: (details) => _manageRecording(appState, true),
                onLongPressEnd: (details) => _manageRecording(appState, false),
                child: FilledButton(
                  onPressed: () {
                    EasyLoading.showInfo("Please hold the button",
                        duration: const Duration(seconds: 3),
                        dismissOnTap: true);
                  }, // This function is required but we handle press via GestureDetector
                  style: FilledButton.styleFrom(
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    padding: const EdgeInsets.all(20),
                    foregroundColor: env.config_foreground_color,
                    backgroundColor: _isListening
                        ? env.config_accent_color
                        : env.config_accent2_color,
                  ),
                  child: _isListening
                      ? const Icon(Icons.stop, size: 40)
                      : const Icon(Icons.mic, size: 40),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  void _manageRecording(AppState appState, bool start) {
    if (start) {
      HapticFeedback.heavyImpact();
      _startRecording();
      // Check every 300ms if the button is still being pressed.
      _holdTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (!_isListening) {
          HapticFeedback.lightImpact();
          timer.cancel(); // Stop the timer if recording has stopped
        }
      });
    } else {
      // After release, add an additional delay of 3 seconds before stopping the recording.
      Future.delayed(const Duration(milliseconds: 1500), () {
        _holdTimer?.cancel(); // Stop the periodic check
        if (_isListening) {
          _stopRecording(appState);
        }
      });
    }
  }

  final ValueNotifier<String> snackMsg = ValueNotifier("");
  void _startRecording() async {
    var json = await json_helper.jsonSettings;

    final available = await _speech.initialize(
        // onStatus: (val) => print('onStatus: $val'),
        // onError: (val) => print('onError: $val'),
        // finalTimeout: const Duration(seconds: 10),
        // debugLogging: true
        );

    if (available) {
      setState(() => _isListening = true);
      ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(SnackBar(
        content: SnackContent(snackMsg: snackMsg),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 100.0),
        // animation: const AlwaysStoppedAnimation(0),
        duration: const Duration(days: 365),
      ));
      // EasyLoading.showToast(,
      //     duration: const Duration(seconds: 30));

      _speech.listen(
        // listenFor: null,
        // listenOptions: stt.SpeechListenOptions(
        //     cancelOnError: false,
        //     listenMode: stt.ListenMode.dictation,
        //     partialResults: true),
        onResult: (val) {
          _lastWords = val.recognizedWords;
          snackMsg.value = _lastWords;
        },
        localeId: json['outputLanguage'],
      );
    } else {
      // setState(() => _isListening = false);
      // print(_lastWords);
    }
  }

  void _stopRecording(AppState appState) async {
    logger.i("Stopping recording!");
    ScaffoldMessenger.of(_scaffoldKey.currentContext!).removeCurrentSnackBar();
    var json = await json_helper.jsonSettings;
    _speech.stop();
    setState(() => _isListening = false);
    File imageFile = File(widget.imagePath);
    logger.v("last words: $_lastWords");
    if (_lastWords.isEmpty) {
      EasyLoading.showError("Please hold the button and say something",
          duration: const Duration(seconds: 2), dismissOnTap: true);
      return;
    }

    promptCache.add(_lastWords);
    if (!mounted) return;
    var response = await sendPictureAndPrompt(
        appState,
        _lastWords,
        imageFile,
        json['inputLanguage'],
        json['outputLanguage'],
        json['maxTokenLength'],
        promptCache,
        responseCache);

    // Cache the new prompt and its response
    responseCache.add(response);
    logger.i("Response: $response");
  }
}

class SnackContent extends StatelessWidget {
  final ValueNotifier<String> snackMsg;
  const SnackContent({super.key, required this.snackMsg});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: snackMsg,
      builder: (context, String value, _) => Text(value),
    );
  }
}
