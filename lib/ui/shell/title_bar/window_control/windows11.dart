import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/core/window/native_window.dart';
import 'package:nordplayer/ui/shared/base_button.dart';

// Window control icons obtained through downloading segoe fluent icons font
// (https://learn.microsoft.com/en-us/windows/apps/design/downloads/#fonts) and convert it to svg.
// Used icons: E921 (minimize), E922 (maximize), E923 (restore), E8BB (close).

class Windows11WindowControl extends ConsumerWidget {
  const Windows11WindowControl({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nativeWindow = ref.read(nativeWindowProvider);
    final isMaximized = ref.watch(isWindowMaximizedProvider);
    final isFocused = ref.watch(isWindowFocusedProvider);

    final colorScheme = Theme.of(context).colorScheme;
    final defaultIconColor = isFocused
        ? colorScheme.onSurface
        : colorScheme.onSurface.withValues(alpha: 0.45);
    final hoverOverlayColor = colorScheme.onSurface.withValues(alpha: 0.08);
    final clickOverlayColor = colorScheme.onSurface.withValues(alpha: 0.05);

    return Row(
      children: [
        BaseButton(
          svgAssetPath: 'assets/icons/window_control/windows11/e921_chrome_minimize.svg',
          buttonHeight: 34,
          buttonWidth: 47.2,
          enableSplash: false,
          iconSize: 13,
          iconColor: defaultIconColor,
          iconColorOnHover: colorScheme.onSurface,
          overlayShape: .rectangle,
          overlayColor: hoverOverlayColor,
          overlayColorOnClick: clickOverlayColor,
          tooltip: 'Minimize',
          onClick: nativeWindow.minimize,
        ),
        BaseButton(
          svgAssetPath: isMaximized
              ? 'assets/icons/window_control/windows11/e923_chrome_restore.svg'
              : 'assets/icons/window_control/windows11/e922_chrome_maximize.svg',
          buttonHeight: 34,
          buttonWidth: 47.2,
          enableSplash: false,
          iconSize: 13,
          iconColor: defaultIconColor,
          iconColorOnHover: colorScheme.onSurface,
          overlayShape: .rectangle,
          overlayColor: hoverOverlayColor,
          overlayColorOnClick: clickOverlayColor,
          tooltip: isMaximized ? 'Restore' : 'Maximize',
          onClick: isMaximized ? nativeWindow.restore : nativeWindow.maximize,
        ),
        BaseButton(
          svgAssetPath: 'assets/icons/window_control/windows11/e8bb_chrome_close.svg',
          buttonHeight: 34,
          buttonWidth: 47.2,
          enableSplash: false,
          iconSize: 13,
          iconColor: defaultIconColor,
          iconColorOnHover: colorScheme.onSurface,
          overlayShape: .rectangle,
          overlayColor: colorScheme.error,
          overlayColorOnClick: colorScheme.error.withValues(alpha: 0.8),
          tooltip: 'Close',
          onClick: nativeWindow.close,
        ),
      ],
    );
  }
}
