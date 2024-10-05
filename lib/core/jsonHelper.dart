import 'package:hackaton/main.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';

// class JsonHelper(){
List<String> get defaultPrompts {
  return [
    "What is in the image?",
    "What is on the left side of the image?",
    "What is on the right side of the image?",
    "What's in the foreground of the image?",
    "What's in the background of the image?",
    "What colors are in the image?"
  ];
}

Map<String, dynamic> get defaultConfig {
  return {
    "prompts": defaultPrompts,
    "maxTokenLength": 100,
    "cameraGestures": true,
    "outputLanguage": "en",
    "inputLanguage": "en",
    "resolution": "High"
  };
}

Future<String> get _localPath async {
  final directory = await getApplicationDocumentsDirectory();
  return directory.path;
}

Future<File> get promptsFile async {
  final path = await _localPath;
  var f = File('$path/config.json');

  if (!f.existsSync()) {
    logger.i("CREATING FILE: $path/config.json");
    await f.create();

    await f.writeAsString(jsonEncode(defaultConfig));
  }
  return f;
}

Future<Map<String, dynamic>> get jsonSettings async {
  try {
    File f = await promptsFile;
    return jsonDecode(await f.readAsString());
  } catch (e) {
    logger.e("FAILED TO LOAD FILE PROMPTS_FILE: $e");
    return {};
  }
}

// }
