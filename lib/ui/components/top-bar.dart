import 'package:flutter/material.dart';
import 'package:hackaton/app_config.dart' as env;
import 'package:hackaton/main.dart';

class TopBar extends StatelessWidget {
  TopBar({super.key, this.showLogo = true});
  final bool showLogo;
  final Widget title = const Text(
    "ImageChat",
    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
  );
  Image logo = Image.asset(env.logo_path, width: 10);
  final backgroundColor = Colors.black54;
  final foregroundColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leadingWidth: 40,
      leading: showLogo
          ? DecoratedBox(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                color: Colors.black,
              ),
              child: Container(
                padding: const EdgeInsets.all(3.0),
                child: logo,
              ),
            )
          : null,
      title: title,
      actions: <Widget>[
        Ink(
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: env.config_secondary_background_color),
            child: IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              // backgroundColor: Colors.white,
              onPressed: () => (onSettingsButtonPressed(context)),
            ))
      ],
      // backgroundColor: backgroundColor,
      // foregroundColor: foregroundColor,
    );
  }

  void onSettingsButtonPressed(BuildContext context) {
    logger.i("settings pressed");
    Navigator.pushNamed(context, '/settings');
  }
}
