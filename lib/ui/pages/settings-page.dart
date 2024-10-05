import 'package:flutter/material.dart';
import 'package:hackaton/main.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:hackaton/core/jsonHelper.dart';
import 'package:hackaton/services/util.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  late SharedPreferences prefs;
  int maxTokenLength = 100; // Default value
  List<String> customPrompts = ['Prompt 1', 'Prompt 2', 'Prompt 3', 'Prompt 4'];

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  Future<void> loadSettings() async {
    try {
      final file = await promptsFile;
      if (await file.exists()) {
        String contents = await file.readAsString();
        Map<String, dynamic> json = jsonDecode(contents);
        setState(() {
          maxTokenLength = json['maxTokenLength'] ?? 100;
          customPrompts = List<String>.from(json['prompts']);
          cameraGestures = json['cameraGestures'] ?? true;
          resolution = json['resolution'] ?? 'Medium';
          inputLanguage = json['inputLanguage'] ?? 'en';
          outputLanguage = json['outputLanguage'] ?? 'en';
          resolution = json['resolution'] ?? 'Medium';
        });
      }
    } catch (e) {
      logger.e("Couldn't read settings file: $e");
    }
  }

  Future<void> showTokenLengthDialog() async {
    TextEditingController controller =
        TextEditingController(text: maxTokenLength.toString());
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Set Max Token Length'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration:
                const InputDecoration(hintText: "Enter Max Token Length"),
            onSubmitted: (value) {
              int? newValue = int.tryParse(value);
              if (newValue != null) {
                setState(() {
                  maxTokenLength = newValue;
                });
                saveSettings();
                Navigator.of(context).pop();
              }
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                int? newValue = int.tryParse(controller.text);
                if (newValue != null) {
                  setState(() {
                    maxTokenLength = newValue;
                  });
                  Navigator.of(context).pop();
                  saveSettings();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> showEditPromptsDialog() async {
    List<TextEditingController> controllers = customPrompts
        .map((prompt) => TextEditingController(text: prompt))
        .toList();

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Edit Custom Prompts'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    ...List<Widget>.generate(controllers.length, (index) {
                      return Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: controllers[index],
                              decoration: InputDecoration(
                                  labelText: 'Prompt ${index + 1}'),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              setStateDialog(() {
                                controllers.removeAt(index);
                                customPrompts.removeAt(index);
                              });
                            },
                          ),
                        ],
                      );
                    }),
                    TextButton(
                      onPressed: () {
                        setStateDialog(() {
                          controllers.add(TextEditingController(text: ''));
                          customPrompts.add('');
                        });
                      },
                      child: const Text('Add Prompt'),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    List<String> newPrompts = controllers
                        .map((controller) => controller.text)
                        .toList();
                    newPrompts =
                        newPrompts.map((controller) => controller).toList();
                    Navigator.of(context).pop();
                    setState(() {
                      customPrompts = newPrompts;
                    });
                    saveSettings();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> saveSettings() async {
    final file = await promptsFile;
    Map<String, dynamic> json = {
      'maxTokenLength': maxTokenLength,
      'cameraGestures': cameraGestures,
      'prompts': customPrompts,
      'resolution': resolution,
      'outputLanguage': outputLanguage,
      'inputLanguage': inputLanguage
    };
    String jsonString = jsonEncode(json);
    await file.writeAsString(jsonString);
  }

  void saveMaxTokenLength(int value) async {
    int? newValue = value;
  }

  String inputLanguage = 'cs';
  String outputLanguage = 'cs';
  String? resolution;
  bool cameraGestures = true;
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getCurrentVersionNumber(),
      builder: (context, snapshot) {
        final String? version = snapshot.data;

        return Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: Column(
            children: [
              Expanded(child: (getSettingsList)),
              Text("Version: $version",
                  style: const TextStyle(
                      fontSize: 11, backgroundColor: Colors.transparent)),
            ],
          ),
        );
      },
    );

    // Scaffold(
    //   appBar: AppBar(title: Text('Settings')),
    //   body: Container(
    //       child: Column(
    //     children: [
    //       const Text("Version: $", style: TextStyle(fontSize: 11)),
    //       Expanded(child: getSettingsList),
    //     ],
    //   )),
    // );
  }

  @override
  Size get preferredSize =>
      const Size.fromHeight(kToolbarHeight); // Standard AppBar height

  SettingsList get getSettingsList {
    return SettingsList(
      sections: [
        SettingsSection(
          title: const Text('Common settings'),
          tiles: [
            SettingsTile.navigation(
              leading: const Icon(Icons.numbers),
              title: const Text('Max token response length'),
              value: Text(maxTokenLength.toString()),
              onPressed: (context) {
                showTokenLengthDialog();
              },
            ),
            SettingsTile.switchTile(
              initialValue: cameraGestures,
              leading: const Icon(Icons.gesture_rounded),
              title: const Text('Camera gestures'),
              onToggle: (context) {
                setState(() {
                  cameraGestures = !cameraGestures;
                });
                saveSettings();
              },
            ),
            SettingsTile.navigation(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Custom Prompts'),
              onPressed: (context) {
                showEditPromptsDialog();
              },
            ),
            SettingsTile.navigation(
              leading: const Icon(Icons.aspect_ratio),
              title: const Text('Resolution'),
              trailing: Container(
                width: 150, // Set desired width here
                padding: const EdgeInsets.only(
                    right: 16), // Add right-side padding here
                child: DropdownButton<String>(
                  value: resolution,
                  icon: const Icon(Icons.arrow_downward),
                  items: const [
                    DropdownMenuItem<String>(
                      value: 'Low',
                      child: Text('Low'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'Medium',
                      child: Text('Medium'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'High',
                      child: Text('High'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'Ultra',
                      child: Text('Ultra'),
                    )
                  ],
                  onChanged: (String? value) {
                    setState(() {
                      resolution = value!;
                    });

                    saveSettings();
                  },
                ),
              ),
            ),
          ],
        ),
        SettingsSection(
          title: const Text('Language settings'),
          tiles: [
            SettingsTile.navigation(
              leading: const Icon(Icons.input),
              title: const Text('Input language'),
              trailing: Container(
                width: 150, // Set desired width here
                padding: const EdgeInsets.only(
                    right: 16), // Add right-side padding here
                child: DropdownButton<String>(
                  value: inputLanguage,
                  icon: const Icon(Icons.arrow_downward),
                  items: const [
                    DropdownMenuItem<String>(
                      value: 'cs',
                      child: Text('Czech'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'en',
                      child: Text('English'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'de',
                      child: Text('German'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'pl',
                      child: Text('Polish'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'es',
                      child: Text('Spanish'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'fr',
                      child: Text('French'),
                    )
                  ],
                  onChanged: (String? value) {
                    setState(() {
                      inputLanguage = value!;
                    });
                    saveSettings();
                  },
                ),
              ),
            ),
            SettingsTile.navigation(
              leading: const Icon(Icons.output),
              title: const Text('Output language'),
              trailing: Container(
                width: 150, // Set desired width here
                padding: const EdgeInsets.only(
                    right: 16), // Add right-side padding here
                child: DropdownButton<String>(
                  value: outputLanguage,
                  icon: const Icon(Icons.arrow_downward),
                  items: const [
                    DropdownMenuItem<String>(
                      value: 'cs',
                      child: Text('Czech'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'en',
                      child: Text('English'),
                    ),
                    // DropdownMenuItem<String>(
                    //   value: 'de',
                    //   child: Text('German'),
                    // ),
                    // DropdownMenuItem<String>(
                    //   value: 'pl',
                    //   child: Text('Polish'),
                    // ),
                    // DropdownMenuItem<String>(
                    //   value: 'es',
                    //   child: Text('Spanish'),
                    // ),
                    // DropdownMenuItem<String>(
                    //   value: 'fr',
                    //   child: Text('French'),
                    // )
                  ],
                  onChanged: (String? value) {
                    setState(() {
                      outputLanguage = value!;
                    });
                    saveSettings();
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
