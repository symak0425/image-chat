import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:hackaton/app.dart';
import 'package:hackaton/main.dart';
import 'package:http/http.dart' as http;
import 'package:hackaton/app_config.dart' as env;
import 'dart:convert';
import 'dart:io';
import 'package:image/image.dart' as img; // Import image library
import 'package:hackaton/services/tts-service.dart';
import 'package:path_provider/path_provider.dart';

TTSService ttsService = TTSService();
bool locked = false;

Future<String> sendPictureAndPrompt(
    AppState state,
    String prompt,
    File imageFile,
    String langIn,
    String langOut,
    int maxLen,
    List<String> promptHistory,
    List<String> agentResponseHistory) async {
  await state.initDeviceID();
  logger.d(state.deviceID);
  locked = true;

  var resizedImage = await resizeImage(imageFile);
  Uint8List resizedBytes = Uint8List.fromList(img.encodeJpg(resizedImage));
  Directory appDocDir = await getApplicationDocumentsDirectory();
  String resizedImagePath = '${appDocDir.path}/resized_image.jpg';
  File resizedImageFile = File(resizedImagePath);
  await resizedImageFile.writeAsBytes(resizedBytes);
  imageFile = File(resizedImagePath);

  List<String> promptHistoryCopy = [...promptHistory];
  promptHistoryCopy.last =
      "${promptHistoryCopy.last} . MAX_LEN_RESPONSE=16_WORDS";
  var imageEncoded = await encodeImageToBase64(imageFile);
  List<Map<String, dynamic>> messages = [];
  messages.add({
    "role": "user",
    "content": [
      {
        "type": "image",
        "source": {
          "type": "base64",
          "media_type": "image/jpeg",
          "data": imageEncoded
        },
      },
      {"type": "text", "text": promptHistoryCopy.last}
    ]
  });
  // for (int i = 0;
  //     i < min(promptHistory.length - 1, agentResponseHistory.length);
  //     i++) {
  //   messages.add({
  //     "role": "assistant",
  //     "content": [
  //       {
  //         "type": "text", "text": agentResponseHistory[i]
  //       }
  //     ]
  //   });
  //   messages.add({
  //     "role": "user",
  //     "content": [
  //       {
  //         "type": "text", "text": promptHistoryCopy[i + 1]
  //       }
  //     ]
  //   });
  // }
  logger.i("Sending messages!");

  HapticFeedback.lightImpact();
  EasyLoading.show(status: "Sending request to server..");

  logger.v(messages);
  var uri = Uri.parse('${env.server_url}/api/v1/process_image');
  var headers = {
    'content-type': 'application/json',
    'Accept': 'application/json',
  };
  var body = {
    "messages": messages,
    "language_in": langIn,
    "language_out": langOut,
    "max_length": maxLen,
    "password": 'bajsdpf4545',
    "deviceID": state.deviceID
  };
  const maxRetries = 3;
  for (int i = 0; i < maxRetries; i++) {
    try {
      var response =
          await http.post(uri, headers: headers, body: json.encode(body));

      // var response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        EasyLoading.dismiss();
        logger.i("Success. ${response.body}");
        var data = await onSuccessfulImagePost(response);
        locked = false;
        return data;
      } else {
        EasyLoading.dismiss();
        EasyLoading.showError("error ${response.body}");
        logger.e("!!!!!!!!!error ${response.body}");
      }
    } catch (e) {
      EasyLoading.dismiss();
      EasyLoading.showError("error $e", duration: const Duration(seconds: 3));
      locked = false;
      rethrow;
    }
  }

  locked = false;

  ttsService.ttsApi("giving up on posting image");
  EasyLoading.showError("Request failed after 3 tries.");
  return "";
}

Future<String> onSuccessfulImagePost(http.Response response) async {
  Map<String, dynamic> data = jsonDecode(response.body);
  var responseMessage = data["content"][0]["text"];

  locked = false;

  await TTSService().ttsApi(responseMessage);
  return responseMessage;
}

Future<String> encodeImageToBase64(File imageFile) async {
  List<int> imageBytes = imageFile.readAsBytesSync();
  String base64Image = base64Encode(imageBytes);
  return base64Image;
}

Future<img.Image> resizeImage(imageFile) async {
  List<int> imageBytes = await imageFile.readAsBytesSync();
  img.Image? image = img.decodeImage(imageBytes);
  image = img.copyResize(image!, width: 1024, height: 1024);
  logger.v("WIDTH ${image.width} , HEIGHT ${image.height}");
  return image;
}
