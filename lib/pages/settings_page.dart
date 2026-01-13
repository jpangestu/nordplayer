import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? musicPath;

  Future<void> savePathForMusic(String pathForMusic) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('music_path', pathForMusic);
  }

  Future<void> getPathForMusic() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      musicPath = prefs.getString('music_path');
    });
  }

  @override
  void initState() {
    super.initState();
    getPathForMusic();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          ListTile(
            title: const Text('Music library location'),
            subtitle: Text(musicPath ?? "Select the folder to scan"),
            trailing: IconButton(
              icon: Icon(Icons.folder_open),
              onPressed: () async {
                final String? selectedPath = await FilePicker.platform
                    .getDirectoryPath();

                if (selectedPath != null) {
                  await savePathForMusic(selectedPath);

                  setState(() {
                    musicPath = selectedPath;
                  });
                }
              },
            ),
          ),
        ],
      ), // Read user input)]),
    );
  }
}
