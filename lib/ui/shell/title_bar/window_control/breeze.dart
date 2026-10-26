import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/ui/shared/base_button.dart';
import 'package:window_manager/window_manager.dart';

// Window control icons obtained from copying the included breeze icons in usr/share/icons/ (CachyOS KDE).

class BreezeWindowControl extends StatefulWidget {
  const BreezeWindowControl({super.key});

  @override
  State<BreezeWindowControl> createState() => _BreezeWindowControlState();
}

class _BreezeWindowControlState extends State<BreezeWindowControl> with WindowListener {
  bool _isMaximized = false;
  bool _isFocused = true;

  Future<void> _initWindowState() async {
    bool isMax = await windowManager.isMaximized();
    bool isFoc = await windowManager.isFocused();
    if (mounted) {
      setState(() {
        _isMaximized = isMax;
        _isFocused = isFoc;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _initWindowState();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowMaximize() {
    if (mounted) setState(() => _isMaximized = true);
  }

  @override
  void onWindowUnmaximize() {
    if (mounted) setState(() => _isMaximized = false);
  }

  @override
  void onWindowFocus() {
    if (mounted) setState(() => _isFocused = true);
  }

  @override
  void onWindowBlur() {
    if (mounted) setState(() => _isFocused = false);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final defaultIconColor = _isFocused
        ? colorScheme.onSurface
        : colorScheme.onSurface.withValues(alpha: 0.45);

    return Row(
      children: [
        BaseButton(
          svgAssetPath: 'assets/icons/window_control/kde_breeze/window-minimize.svg',
          buttonHeight: 24,
          buttonWidth: 24,
          enableSplash: false,
          iconSize: 16,
          iconColor: defaultIconColor,
          iconColorOnHover: colorScheme.surface,
          overlayShape: BoxShape.circle,
          overlayColor: colorScheme.onSurface,
          tooltip: 'Minimize',
          onClick: () {
            windowManager.minimize();
          },
        ),

        const SizedBox(width: 4.0),

        BaseButton(
          svgAssetPath: _isMaximized
              ? 'assets/icons/window_control/kde_breeze/window-restore.svg'
              : 'assets/icons/window_control/kde_breeze/window-maximize.svg',
          buttonHeight: 24,
          buttonWidth: 24,
          enableSplash: false,
          iconSize: 16,
          iconColor: defaultIconColor,
          iconColorOnHover: colorScheme.surface,
          overlayShape: BoxShape.circle,
          overlayColor: colorScheme.onSurface,
          tooltip: _isMaximized ? 'Restore' : 'Maximize',
          onClick: () {
            if (_isMaximized) {
              windowManager.unmaximize();
            } else {
              windowManager.maximize();
            }
          },
        ),

        const SizedBox(width: 4.0),

        BaseButton(
          svgAssetPath: 'assets/icons/window_control/kde_breeze/window-close.svg',
          buttonHeight: 24,
          buttonWidth: 24,
          enableSplash: false,
          iconSize: 16,
          iconColor: _isFocused ? Colors.white : Colors.white70,
          overlayShape: BoxShape.circle,
          overlayColor: colorScheme.error,
          tooltip: 'Close',
          onClick: () {
            windowManager.close();
          },
        ),

        const SizedBox(width: 8.0),
      ],
    );
  }
}
