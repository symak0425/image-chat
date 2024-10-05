import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:hackaton/app_config.dart' as env;
import 'package:hackaton/core/camera-picture-screen.dart';
import 'package:hackaton/services/tts-service.dart';

class HomePage extends StatelessWidget {
  final CameraDescription camera;
  final TTSService ttsService = TTSService();
  bool dragging = false;
  HomePage({super.key, required this.camera});

  @override
  Widget build(BuildContext context) {
    var camscreenKey = GlobalKey<CameraPictureScreenState>();

    camscreenKey.currentState?.initState();

    var camScreen = CameraPictureScreen(
      key: camscreenKey,
      camera: camera,
    );

    void takePhoto() async {
      camscreenKey.currentState?.on_take_photo();
    }

    return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onLongPress: () {
              if (!dragging) {
                camscreenKey.currentState?.on_flashlight(false);
              }
            },
            onVerticalDragStart: (DragStartDetails details) {
              dragging = true;
            },
            onVerticalDragUpdate: (DragUpdateDetails details) async {
              camscreenKey.currentState?.on_zoom(details.delta.dy);
            },
            onVerticalDragEnd: (DragEndDetails details) {
              dragging = false;
            },
            onHorizontalDragEnd: (DragEndDetails details) {
              camscreenKey.currentState?.on_focus();
              dragging = false;
            },
            child: camScreen,
          ),
          Expanded(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Center(
                child: Semantics(
                  label: 'Tlačítko na focení',
                  button: true,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.16),
                    child: FilledButton(
                        onPressed: takePhoto,
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          backgroundColor: env.config_accent2_color,
                          foregroundColor: env.config_foreground_color,
                          // padding: EdgeInsets.all(20),
                        ),
                        child: const Stack(
                          children: <Widget>[
                            Text(
                              'Capture',
                              style: TextStyle(color: Colors.transparent),
                              semanticsLabel: 'Tlačítko pro focení',
                            ),
                            Icon(Icons.camera_alt, size: 40),
                          ],
                        )),
                  ),
                ),
              ),
            ],
          ))
        ]);
  }
}
