import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:hackaton/app.dart';
import 'dart:io';
import 'dart:convert';
import 'package:hackaton/app_config.dart' as env;
import 'package:hackaton/main.dart';
import 'package:hackaton/services/server-requests.dart';
import 'package:hackaton/core/jsonHelper.dart';
import 'package:provider/provider.dart';

class PromptsTable extends StatelessWidget {
  PromptsTable({super.key, required this.imagePath});
  final String imagePath;

  List<String> prompt_cache = [];
  List<String> agent_response_cache = [];

  Function onPressedPrompt = (
    AppState appState,
    String imagePath,
    int index,
    List<dynamic> prompts,
    int maxLen,
    String langIn,
    String langOut,
    List<String> prompt_cache,
    List<String> agent_response_cache,
  ) {
    return () async {
      if (locked) {
        EasyLoading.showError("Other prompt is being processed. Please wait.");
        return;
      }
      File imageFile = File(imagePath);
      prompt_cache.add(prompts[index]);
      var response = await sendPictureAndPrompt(
          appState,
          prompts[index],
          imageFile,
          langIn,
          langOut,
          maxLen,
          prompt_cache,
          agent_response_cache);
      agent_response_cache.add(response);
    };
  };

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, AppState appState, child) {
      return FutureBuilder(
        future: promptsFile,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            var json = jsonDecode(snapshot.data!.readAsStringSync());
            var prompts = json['prompts'];
            var maxLen = json['maxTokenLength'];
            var langIn = json["inputLanguage"];
            var langOut = json["outputLanguage"];
            var promptLen = prompts.length;
            logger.v("Input lang: $langIn\nOutput lang: $langOut");
            List<Widget> gridChildren = List.generate(promptLen, (int index) {
              return SizedBox(
                width: MediaQuery.of(context).size.width,
                child: ElevatedButton(
                  onPressed: onPressedPrompt(
                    appState,
                    imagePath,
                    index,
                    prompts,
                    maxLen,
                    langIn,
                    langOut,
                    prompt_cache,
                    agent_response_cache,
                  ),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    constraints: const BoxConstraints(
                      minHeight: 80.0,
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: 15.0, horizontal: 10.0),
                    child: Text(
                      style: const TextStyle(
                          color: env.config_foreground_color, fontSize: 20),
                      "${prompts[index]}",
                    ),
                  ),
                ),
              );
            });
            return Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListView.builder(
                  itemCount: gridChildren.length,
                  itemBuilder: (context, index) {
                    final tileModel = gridChildren[index];
                    return Column(
                      children: [const SizedBox(height: 10), tileModel],
                    );
                  },
                ));
          }
          return const CircularProgressIndicator();
        },
      );
    });
  }
}
