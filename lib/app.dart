import 'dart:io';

import 'package:advertising_id/advertising_id.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:hackaton/main.dart';
import 'package:hackaton/ui/pages/home-page.dart';
import 'package:hackaton/ui/components/top-bar.dart';
import 'package:camera/camera.dart';
import 'package:hackaton/ui/pages/settings-page.dart';
import 'package:provider/provider.dart';

class App extends StatefulWidget {
  const App({super.key, required this.camera});
  final CameraDescription camera;

  @override
  AppState createState() => AppState();
}

class AppState extends State<App> with ChangeNotifier {
  String deviceID = "anonymous";
  @override
  void initState() {
    super.initState();

    initDeviceID();
  }

  Future<void> initDeviceID() async {
    if (Platform.isAndroid) {
      String? deviceIDLoc = await AdvertisingId.id(true);
      if (deviceIDLoc != null) {
        deviceID = deviceIDLoc;
      } else {
        deviceID = "anonymous android";
      }
      logger.d("ANDROID SETING ID: $deviceID");
    }
    // DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    // DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    // if (Platform.isAndroid) {
    //   AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    //   logger.i("ANDROID INFO $androidInfo");
    //   String? adv_id = await AdvertisingId.id(true);
    //   logger.i("ANDROID ID $adv_id");
    // } else {
    //   IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
    //   logger.i("IOSRINFO $iosInfo");
    // }
  }

  MaterialApp get app {
    return MaterialApp(
      title: 'Flutter Demo dz',
      theme: ThemeData(
        useMaterial3: true,
        // colorScheme: color_theme,
        // scaffoldBackgroundColor: Colors.black54,
        brightness: Brightness.dark,
      ),
      initialRoute: "/",
      routes: {
        '/settings': (context) => const SettingsPage(),
      },
      builder: EasyLoading.init(),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(55.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TopBar(),
          ),
        ),
        body: HomePage(camera: widget.camera),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      builder: (context, child) {
        return app;
      },
    );
  }
}
