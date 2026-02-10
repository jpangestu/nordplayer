import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nordplayer/services/config_service.dart';
import 'package:file_selector/file_selector.dart';

import 'package:nordplayer/widgets/section_header.dart';

class LibrarySettingPage extends StatelessWidget {
  const LibrarySettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListenableBuilder(
              listenable: ConfigService(),
              builder: (context, _) {
                List<String> musicPaths = ConfigService().appConfig.musicPath;

                return ListView(
                  padding: const .all(16),
                  children: [
                    const SectionHeader(label: 'Library'),
                    ListTile(
                      title: const Text('Music locations'),
                      subtitle: const Text("Manage folders to scan for music"),
                      trailing: FilledButton.icon(
                        onPressed: () => _addFolder(),
                        icon: const Icon(Icons.add),
                        label: const Text("Add Folder"),
                      ),
                    ),

                    if (musicPaths.isEmpty)
                      Padding(
                        padding: const .symmetric(
                          horizontal: 16.0,
                          vertical: 8,
                        ),
                        child: Text(
                          "No folders added yet",
                          style: TextStyle(
                            color: Theme.of(context).disabledColor,
                          ),
                        ),
                      )
                    else
                      ...musicPaths.map(
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

                    SizedBox(height: 8),
                    const Divider(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addFolder() async {
    final selectedPaths = await getDirectoryPaths();

    if (selectedPaths.isNotEmpty) {
      final currentPaths = ConfigService().appConfig.musicPath;
      // Make sure to pass by value
      final List<String> updatedPaths = List<String>.from(currentPaths);
      
      bool hasChanges = false;

      for (String? path in selectedPaths) {
        if (path != null && path.isNotEmpty && !updatedPaths.contains(path)) {
          updatedPaths.add(path);
          hasChanges = true;
        }
      }

      if (hasChanges) {
        ConfigService().update(musicPath: updatedPaths);
      }
    }
  }

  void _removeFolder(String path) {
    List<String> currentPaths = ConfigService().appConfig.musicPath;
    currentPaths.remove(path);
    ConfigService().update(musicPath: currentPaths);
  }
}
