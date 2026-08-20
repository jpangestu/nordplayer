import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/widgets/title_bar/base_button.dart';
import 'package:window_manager/window_manager.dart';

// Window control icons obtained through downloading segoe fluent icons font
// (https://learn.microsoft.com/en-us/windows/apps/design/downloads/#fonts) and convert it to svg.
// Used icons: E921 (minimize), E922 (maximize), E923 (restore), E8BB (close).

class Windows11WindowControl extends StatefulWidget {
  const Windows11WindowControl({super.key});

  @override
  State<Windows11WindowControl> createState() => _Windows11WindowControlState();
}

class _Windows11WindowControlState extends State<Windows11WindowControl> with WindowListener {
  bool _isMaximized = false;
  bool _isFocused = true;

  Future<void> _initWindowState() async {
    bool isMax = await windowManager.isMaximized();
    if (mounted) {
      setState(() {
        _isMaximized = isMax;
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
    return Row(
      children: [
        BaseButton(
          svgAssetPath: 'assets/icons/window_control/windows11/e921_chrome_minimize.svg',
          buttonHeight: 34,
          buttonWidth: 46,
          enableSplash: false,
          iconSize: 13,
          iconColor: _isFocused ? Colors.white : Colors.grey,
          iconColorOnHover: Colors.white,
          overlayShape: .rectangle,
          overlayColor: Colors.white.withValues(alpha: 0.1),
          overlayColorOnClick: Colors.white.withValues(alpha: 0.05),
          tooltip: 'Minimize',
          onClick: () {
            windowManager.minimize();
          },
        ),

        BaseButton(
          svgAssetPath: _isMaximized
              ? 'assets/icons/window_control/windows11/e923_chrome_restore.svg'
              : 'assets/icons/window_control/windows11/e922_chrome_maximize.svg',
          buttonHeight: 34,
          buttonWidth: 46,
          enableSplash: false,
          iconSize: 13,
          iconColor: _isFocused ? Colors.white : Colors.grey,
          iconColorOnHover: Colors.white,
          overlayShape: .rectangle,
          overlayColor: Colors.white.withValues(alpha: 0.1),
          overlayColorOnClick: Colors.white.withValues(alpha: 0.05),
          tooltip: _isMaximized ? 'Restore' : 'Maximize',
          onClick: () {
            if (_isMaximized) {
              windowManager.unmaximize();
            } else {
              windowManager.maximize();
            }
          },
        ),
        BaseButton(
          svgAssetPath: 'assets/icons/window_control/windows11/e8bb_chrome_close.svg',
          buttonHeight: 34,
          buttonWidth: 46,
          enableSplash: false,
          iconSize: 13,
          iconColor: _isFocused ? Colors.white : Colors.grey,
          iconColorOnHover: Colors.white,
          overlayShape: .rectangle,
          overlayColor: const Color.fromARGB(255, 196, 43, 28),
          overlayColorOnClick: const Color.fromARGB(255, 196, 43, 28).withValues(alpha: 0.9),
          tooltip: 'Close',
          onClick: () {
            windowManager.close();
          },
        ),
      ],
    );
  }
}
