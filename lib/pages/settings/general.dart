import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:suara/services/library_service.dart';

class General extends StatefulWidget {
  const General({super.key});

  @override
  State<General> createState() => _GeneralState();
}

class _GeneralState extends State<General> {
  List<String> _musicPaths = [];

  @override
  void initState() {
    super.initState();
    _loadPaths();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('Library'),
        ListTile(
          title: const Text('Music locations'),
          subtitle: const Text("Manage folders to scan for music"),
          trailing: FilledButton.icon(
            onPressed: _addFolder,
            icon: const Icon(Icons.add),
            label: const Text("Add Folder"),
          ),
        ),

        // The List of Folders
        if (_musicPaths.isEmpty)
          Text("No folders added yet", style: TextStyle(color: Colors.grey))
        else
          ..._musicPaths.map(
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

        const SizedBox(height: 16),
        const Divider(),
      ],
    );
  }

  Future<void> _loadPaths() async {
    final paths = await LibraryService().getMusicPaths();
    setState(() {
      _musicPaths = paths;
    });
  }

  Future<void> _addFolder() async {
    final List<String?> selectedPaths = await getDirectoryPaths();

    if (selectedPaths.isNotEmpty) {
      // Create a copy of the current list to modify
      final List<String> updatedPaths = List.from(_musicPaths);

      for (String? path in selectedPaths) {
        // Prevent duplicates
        if (path != null && !updatedPaths.contains(path)) {
          updatedPaths.add(path);
          LibraryService().addPath(path);
        }
      }

      setState(() {
        _musicPaths = updatedPaths;
      });
    }
  }

  Future<void> _removeFolder(String pathToRemove) async {
    final List<String> updatedPaths = List.from(_musicPaths);
    updatedPaths.remove(pathToRemove);

    LibraryService().removePath(pathToRemove);
    setState(() {
      _musicPaths = updatedPaths;
    });
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}
