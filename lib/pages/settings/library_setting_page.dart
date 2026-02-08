import 'package:flutter/material.dart';
import 'package:nordplayer/widgets/section_header.dart';

class LibrarySettingPage extends StatelessWidget {
  const LibrarySettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> musicPaths = [];

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const .all(16),
              children: [
                const SectionHeader(label: 'Library'),
                ListTile(
                  title: const Text('Music locations'),
                  subtitle: const Text("Manage folders to scan for music"),
                  trailing: FilledButton.icon(
                    // onPressed: (_addFolder),
                    onPressed: () {},
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
                      style: TextStyle(color: Theme.of(context).disabledColor),
                    ),
                  )
                else
                  ...musicPaths.map(
                    (path) => ListTile(
                      leading: const Icon(Icons.folder_outlined),
                      title: Text(path),
                      trailing: IconButton(
                        // onPressed: () => _removeFolder(path),
                        onPressed: () {},
                        icon: const Icon(Icons.delete_outline),
                        tooltip: "Remove folder",
                      ),
                      dense: true,
                    ),
                  ),
                  
                SizedBox(height: 8),
                const Divider(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
