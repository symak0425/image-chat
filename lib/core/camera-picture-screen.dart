import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:hackaton/main.dart';
import 'package:hackaton/ui/pages/voice_record.dart';
import 'package:flutter/services.dart';
import 'package:hackaton/services/tts-service.dart';

import 'package:hackaton/core/jsonHelper.dart';

enum ZoomDirection {
  inZoom,
  outZoom,
}

double zoomLevel = 1.0;
FocusMode focusMode = FocusMode.auto;

// A screen that allows users to take a picture using a given camera.
class CameraPictureScreen extends StatefulWidget {
  final double _targetAspectRatio = 4 / 3; // Golden Ratio: ~1.618

  Size _calculateCameraTargetSize(
      Size screenSize, double controllerAspectRatio) {
    double screenAspectRatio = screenSize.aspectRatio;
    double targetWidth = screenSize.width;
    return Size(targetWidth, targetWidth * _targetAspectRatio);
  }

  const CameraPictureScreen({
    super.key,
    required this.camera,
  });

  final CameraDescription camera;

  @override
  CameraPictureScreenState createState() => CameraPictureScreenState();
}

class CameraPictureScreenState extends State<CameraPictureScreen>
    with WidgetsBindingObserver {
  bool isDisposing = false;
  late CameraController _cam_controller;
  Future<void>? _initializeControllerFuture;
  final TTSService ttsService = TTSService();
  int _retryCount = 0;
  final int _maxRetryCount = 5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initCameraAsync();
  }

  void initCameraAsync() async {
    await Future.delayed(const Duration(milliseconds: 100));
    while (isDisposing) {
      print("WAITING FOR DISPOSE BEFORE INIT CAMERA!!!!!");
      await Future.delayed(const Duration(milliseconds: 200));
    }
    await initializeCamera("Medium");
  }

  Future<void> restartCamera(resolution) async {
    dispose();
    initCameraAsync();
  }

  Future<void> initializeCamera(String resolution) async {
    logger.i("Initializing camera");
    ResolutionPreset preset;
    switch (resolution) {
      case "Low":
        preset = ResolutionPreset.low;
        break;
      case "Medium":
        preset = ResolutionPreset.medium;
        break;
      case "High":
        preset = ResolutionPreset.high;
        break;
      case "Ultra":
        preset = ResolutionPreset.ultraHigh;
        break;
      default:
        preset = ResolutionPreset.medium;
    }
    _cam_controller = CameraController(
      widget.camera,
      preset,
    );
    _initializeControllerFuture = _cam_controller.initialize().then((_) {
      //if (!mounted) return;
      setState(() {});
      _cam_controller.setFlashMode(FlashMode.off);

      _retryCount = 0;
    }).catchError((Object e) async {
      if (e is CameraException) {
        _retryCount++;
        if (_retryCount <= _maxRetryCount) {
          EasyLoading.showError(
            "Failed to initialize camera. Retrying... (attempt $_retryCount)",
          );
          logger.i("Initialization failed, retrying... Attempt: $_retryCount");
          await Future.delayed(const Duration(seconds: 1));
          var json = await jsonSettings;
          restartCamera(json['resolution']);
        } else {
          EasyLoading.showError(
            "Failed to initialize camera after $_maxRetryCount attempts.",
          );
          logger.e("Failed to initialize after $_maxRetryCount attempts.");
          ttsService.ttsApi(
              "Camera could not be initialized after $_maxRetryCount attempts.");
        }
      } else {
        EasyLoading.showError(
          "Failed to initialize camera. An unexpected error occurred",
        );
        logger
            .e("An unexpected error occurred during camera initialization: $e");
      }
    });
  }

  Future<bool> check_camera_gestures() async {
    var localJsonSettings = await jsonSettings;

    return localJsonSettings['cameraGestures'] ?? true;
  }

  String cam_res = 'Medium';
  Future<void> check_reload_quality() async {
    var localJsonSettings = await jsonSettings;
    if (cam_res != localJsonSettings['resolution']) {
      return initializeCamera(localJsonSettings['resolution']);
    }
  }

  void on_focus() async {
    if (!await check_camera_gestures()) return;
    check_reload_quality();

    HapticFeedback.vibrate();
    if (focusMode == FocusMode.auto) {
      focusMode = FocusMode.locked;
      EasyLoading.showToast("Auto focus off");
    } else if (focusMode == FocusMode.locked) {
      focusMode = FocusMode.auto;
      EasyLoading.showToast("Auto focus on");
    }

    await _cam_controller.setFocusMode(focusMode);
    setState(() {});
  }

  void on_flashlight(bool? turnOff) async {
    if (!await check_camera_gestures()) return;

    HapticFeedback.vibrate();
    if (_cam_controller.value.flashMode == FlashMode.always ||
        turnOff == true) {
      await _cam_controller.setFlashMode(FlashMode.off);
      if (turnOff == false) {
        EasyLoading.showToast("Turned off flash");
      }
    } else {
      await _cam_controller.setFlashMode(FlashMode.always);
      EasyLoading.showToast("Turned on flash");
    }
    setState(() {});
  }

  void on_zoom(double zoomDelta) async {
    if (!await check_camera_gestures()) return;

    if (zoomDelta == 0) return;
    if (zoomLevel + -(zoomDelta * 0.1) < -1) return;
    if (zoomLevel + -(zoomDelta * 0.1) > 8) return;

    zoomLevel += -(zoomDelta * 0.1);

    await _cam_controller.setZoomLevel(zoomLevel);

    EasyLoading.showToast("Zoomed ${zoomLevel.toStringAsFixed(1)}x",
        duration: const Duration(seconds: 2),
        toastPosition: EasyLoadingToastPosition.bottom);

    setState(() {});
  }

  void on_take_photo() async {
    HapticFeedback.vibrate();
    await _initializeControllerFuture;
    if (!mounted) return;
    await _cam_controller.setFocusMode(FocusMode.locked);
    await _cam_controller.setExposureMode(ExposureMode.locked);
    EasyLoading.show(status: "Saving photo...");
    setState(() {});
    final image = await _cam_controller.takePicture();
    await _cam_controller.setFocusMode(FocusMode.auto);
    await _cam_controller.setExposureMode(ExposureMode.auto);
    on_flashlight(true);
    EasyLoading.dismiss();

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VoiceRecordPage(imagePath: image.path),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance!.removeObserver(this);
    if (isDisposing || !mounted) {
      return;
    }
    isDisposing = true;

    logger.v("Disposing camera");
    _cam_controller.dispose().then((value) {
      logger.v("Disposing done");
      if (!mounted) return;
      isDisposing = false;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    logger.v("didChangeAppLifecycleState: $state");
    // print("state $state");

    if (state == AppLifecycleState.inactive) {
      if (isDisposing) return;
      _cam_controller.pausePreview();

      // dispose();
    } else if (state == AppLifecycleState.resumed) {
      isDisposing = false;
      setState(() {});
      initCameraAsync();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initializeControllerFuture == null || !mounted) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        width: MediaQuery.of(context).size.width,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (!_cam_controller.value.isInitialized) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        width: MediaQuery.of(context).size.width,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    final targetSize = widget._calculateCameraTargetSize(
        MediaQuery.of(context).size, _cam_controller.value.aspectRatio);
    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return ClipRect(
            child: SizedBox(
                width: targetSize.width,
                height: targetSize.height,
                child: FittedBox(
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: targetSize.width,
                      child: CameraPreview(_cam_controller),
                    ))),
          );
        } else {
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            width: MediaQuery.of(context).size.width,
            child: const Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }
}
