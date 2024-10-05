import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:hackaton/app.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
//import 'package:hackaton/services/server-requests.dart';

var logger = Logger(
    // printer: PrettyPrinter(
    //     methodCount: 2, // Number of method calls to be displayed
    //     errorMethodCount: 8, // Number of method calls if stacktrace is provided
    //     lineLength: 120, // Width of the output
    //     colors: true, // Colorful log messages
    //     printEmojis: true, // Print an emoji for each log message
    //     printTime: true, // Should each log print contain a timestamp
    // ),
    );

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  final camera = await loadCameras();

  // customize easyloading
  EasyLoading.instance
    ..displayDuration = const Duration(milliseconds: 2000)
    ..indicatorType = EasyLoadingIndicatorType.ring
    ..loadingStyle = EasyLoadingStyle.dark
    ..indicatorSize = 50.0
    ..textStyle = const TextStyle(fontSize: 16.0)
    ..radius = 15.0
    ..progressColor = Colors.yellow
    ..indicatorColor = Colors.yellow
    ..textColor = Colors.yellow
    ..maskColor = Colors.blue.withOpacity(0.5)
    ..userInteractions = true
    ..dismissOnTap = false;

  // runApp(builder: (_)=>App(camera: camera));
  runApp(App(camera: camera));
}

Future<CameraDescription> loadCameras() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  for (var camera in cameras) {
    if (camera.lensDirection == CameraLensDirection.back) {
      logger.i("Camera has been found: $camera");
      return camera;
    }
  }

  logger.e("Back camera not found");
  throw Exception("Back camera not found");
}
