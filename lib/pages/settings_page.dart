import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  List<String> musicPath = [];

  @override
  void initState() {
    super.initState();
    _loadPaths();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: .start,
        children: [
          ListTile(
            title: const Text('Music library locations'),
            subtitle: Text("Manage folders to scan for music"),
            trailing: FilledButton.icon(
              onPressed: _addFolder,
              icon: const Icon(Icons.add),
              label: const Text("Add Folder"),
            ),
          ),

          const Divider(),

          // The List of Folders
          if (musicPath.isEmpty)
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                "No folders added yet",
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ...musicPath.map(
              (path) => ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: Text(path),
                trailing: IconButton(
                  onPressed: () => _removeFolder(path),
                  icon: const Icon(Icons.delete_outline),
                  tooltip: "Remove folder",
                ),
                dense: true,
              ),
            ),
        ],
      ), // Read user input)]),
    );
  }

  Future<void> _loadPaths() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      musicPath = prefs.getStringList('music_path') ?? [];
    });
  }

  Future<void> _savePaths(List<String> paths) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('music_path', paths);
  }

  Future<void> _addFolder() async {
    final List<String?> selectedPaths = await getDirectoryPaths();

    if (selectedPaths.isNotEmpty) {
      // Create a copy of the current list to modify
      final List<String> updatedPaths = List.from(musicPath);

      for (String? path in selectedPaths) {
        // Prevent duplicates
        if (path != null && !updatedPaths.contains(path)) {
          updatedPaths.add(path);
        }
      }

      await _savePaths(updatedPaths);
      setState(() {
        musicPath = updatedPaths;
      });
    }
  }

  Future<void> _removeFolder(String pathToRemove) async {
    final List<String> updatedPaths = List.from(musicPath);
    updatedPaths.remove(pathToRemove);

    await _savePaths(updatedPaths);
    setState(() {
      musicPath = updatedPaths;
    });
  }
}
