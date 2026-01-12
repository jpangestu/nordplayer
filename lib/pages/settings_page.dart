import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late File file;
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Text('Folder to Scan:'),
          Text('none'),
          IconButton(
            onPressed: () async {
              String? main_path = await FilePicker.platform.getDirectoryPath();

              // if (main_path != null) {
              //   _main_path = main_path;
              // } else {
              //   // User canceled the picker
              // }
            },
            icon: Icon(Icons.add),
          ),
        ],
      ), // Read user input)]),
    );
  }
}
