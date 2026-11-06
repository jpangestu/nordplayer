import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/core/window/native_window.dart';
import 'package:nordplayer/ui/shared/base_button.dart';

// Window control icons obtained from copying the included breeze icons in usr/share/icons/ (CachyOS KDE).

class BreezeWindowControl extends ConsumerWidget {
  const BreezeWindowControl({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMaximized = ref.watch(isWindowMaximizedProvider);
    final isFocused = ref.watch(isWindowFocusedProvider);
    final nativeWindow = ref.read(nativeWindowProvider);

    final colorScheme = Theme.of(context).colorScheme;
    final defaultIconColor = isFocused
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
          onClick: nativeWindow.minimize,
        ),
        const SizedBox(width: 4.0),
        BaseButton(
          svgAssetPath: isMaximized
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
          tooltip: isMaximized ? 'Restore' : 'Maximize',
          onClick: nativeWindow.toggleMaximize,
        ),
        const SizedBox(width: 4.0),
        BaseButton(
          svgAssetPath: 'assets/icons/window_control/kde_breeze/window-close.svg',
          buttonHeight: 24,
          buttonWidth: 24,
          enableSplash: false,
          iconSize: 16,
          iconColor: isFocused ? Colors.white : Colors.white70,
          overlayShape: BoxShape.circle,
          overlayColor: colorScheme.error,
          tooltip: 'Close',
          onClick: nativeWindow.close,
        ),
        const SizedBox(width: 8.0),
      ],
    );
  }
}
