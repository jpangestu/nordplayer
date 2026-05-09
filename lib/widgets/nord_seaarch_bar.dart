import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/services/config_service.dart';
import 'package:nordplayer/theming/icon-sets/app_icon_set.dart';
import 'package:nordplayer/widgets/shortcuts.dart';

class NordSearchBar extends ConsumerStatefulWidget {
  const NordSearchBar({super.key});

  @override
  ConsumerState<NordSearchBar> createState() => _NordSearchBarState();
}

class _NordSearchBarState extends ConsumerState<NordSearchBar> {
  late FocusNode _focusNode;
  final TextEditingController _textController = TextEditingController();

  // Controls whether the "Ctrl+K" badge is visible
  bool _showShortcut = true;

  @override
  void initState() {
    super.initState();
    _focusNode = ref.read(searchFocusNodeProvider);
    // Listen for focus changes (clicking in/out of the box)
    _focusNode.addListener(_updateShortcutVisibility);
    // Listen for text changes (typing)
    _textController.addListener(_updateShortcutVisibility);
  }

  void _updateShortcutVisibility() {
    // The shortcut should ONLY show if the user hasn't focused the field AND the field is empty
    final shouldShow = !_focusNode.hasFocus && _textController.text.isEmpty;

    if (_showShortcut != shouldShow) {
      setState(() {
        _showShortcut = shouldShow;
      });
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_updateShortcutVisibility);
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appConfig = ref.watch(configServiceProvider).requireValue;
    final appIconSet = ref.watch(appIconProvider);

    // Escape callback set here cause there's no reason for it to be in global shortcut
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () {
          _focusNode.unfocus();
        },
      },
      child: TextField(
        controller: _textController,
        focusNode: _focusNode,
        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface),
        decoration: InputDecoration(
          // Transparent if filled set to false
          filled: appConfig.adaptiveBg ? false : true,
          fillColor: theme.colorScheme.surfaceContainerHigh,
          hintText: 'Search...',
          hintStyle: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          prefixIcon: Padding(
            padding: const .only(left: 10.0),
            child: Icon(appIconSet.search, color: theme.colorScheme.onSurfaceVariant),
          ),
          suffixIcon: showSuffixIcon(transparent: appConfig.adaptiveBg),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            // To make it look like it doesn't have border. If removed, it'll just be a black border.
            borderSide: BorderSide(
              color: appConfig.adaptiveBg ? Colors.transparent : theme.colorScheme.surfaceContainer,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
          ),
        ),
        onSubmitted: (value) {
          _focusNode.unfocus();
        },
      ),
    );
  }

  Widget? showSuffixIcon({required bool transparent}) {
    return _showShortcut
        ? Padding(
            padding: const EdgeInsets.only(right: 18.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min, // Prevents stretching vertically
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHigh.withValues(alpha: transparent ? 0.0 : 1.0),
                    borderRadius: BorderRadius.circular(16),
                    // border: Border.all(
                    //   color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: transparent ? 0.0 : 1.0),
                    //   width: 1.0,
                    // ),
                  ),
                  child: Text(
                    'Ctrl + K',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      letterSpacing: 0.24,
                      fontFamily: 'jetbrains_mono',
                    ),
                  ),
                ),
              ],
            ),
          )
        : null;
  }
}
