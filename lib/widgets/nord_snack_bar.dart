import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/routes/router.dart';
import 'package:nordplayer/services/config_service.dart';
import 'package:nordplayer/theming/icon-sets/app_icon_set.dart';
import 'package:nordplayer/theming/theme-extension/nord_snackbar_theme.dart';
import 'package:nordplayer/widgets/app_icon.dart';
import 'package:nordplayer/widgets/frosted_glass.dart';

enum NordSnackBarType { general, info, warning, success, error }

class NordSnackBar extends ConsumerWidget {
  const NordSnackBar({
    super.key,
    required this.message,
    required this.type,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String message;

  /// The type of the snackbar (general, info, success, warning, error)
  final NordSnackBarType type;
  final IconData? icon;
  final String? actionLabel;
  final void Function(BuildContext)? onAction;

  (IconData, Color) _getAccents(AppIconSet appIconSet, NordSnackBarTheme nordSnackBarTheme) {
    switch (type) {
      case NordSnackBarType.general:
        return (appIconSet.general, nordSnackBarTheme.generalColor!);
      case NordSnackBarType.info:
        return (appIconSet.info, nordSnackBarTheme.infoColor!);
      case NordSnackBarType.warning:
        return (appIconSet.warning, nordSnackBarTheme.warningColor!);
      case NordSnackBarType.success:
        return (appIconSet.success, nordSnackBarTheme.successColor!);
      case NordSnackBarType.error:
        return (appIconSet.error, nordSnackBarTheme.errorColor!);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final nordSnackBarTheme = theme.extension<NordSnackBarTheme>()!;

    final appConfig = ref.watch(configServiceProvider).requireValue;
    final appIconSet = ref.watch(appIconProvider);

    final (snackBarIcon, accentColor) = _getAccents(appIconSet, nordSnackBarTheme);

    return Material(
      color: Colors.transparent,
      child: FrostedGlass(
        blurSigma: appConfig.adaptiveBg ? appConfig.adaptiveBgPanelBlur : 0,
        borderRadius: 6,
        backgroundColor: theme.colorScheme.surfaceContainerHigh.withValues(
          alpha: appConfig.adaptiveBg ? appConfig.adaptiveBgThemeOverlay : 1.0,
        ),
        child: Container(
          padding: const EdgeInsets.only(left: 12, right: 8, top: 12, bottom: 12),
          height: 48,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              if (icon != null) ...[
                Icon(icon, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
              ] else ...[
                AppIcon(snackBarIcon, color: accentColor),
                const SizedBox(width: 6),
              ],

              // Message
              // Wrap text in Flexible so it doesn't overflow if there's a button
              Flexible(child: Text(message, style: theme.textTheme.labelLarge)),

              // Action Button
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(width: 16),
                TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => onAction!(context),
                  child: Text(
                    actionLabel!,
                    style: theme.textTheme.labelLarge!.copyWith(
                      color: type == NordSnackBarType.general ? theme.colorScheme.primary : accentColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A model to track each unique snack bar
class ActiveSnackBar {
  ActiveSnackBar({
    required this.id,
    required this.message,
    required this.type,
    this.customIcon,
    this.actionLabel,
    this.onAction,
  });

  final String id;
  final String message;
  final NordSnackBarType type;

  /// The default snack bar icon will be replaced by this
  final IconData? customIcon;
  final String? actionLabel;
  final void Function(BuildContext)? onAction;
}

// The Stateful Manager that lives in the Overlay
class NordSnackBarManager extends StatefulWidget {
  const NordSnackBarManager({super.key});

  @override
  State<NordSnackBarManager> createState() => NordSnackBarManagerState();
}

class NordSnackBarManagerState extends State<NordSnackBarManager> {
  List<ActiveSnackBar> _snackBars = [];

  void addSnackBar(ActiveSnackBar snackBar) {
    setState(() {
      _snackBars.insert(0, snackBar);
      // Enforce the maximum snack bar number to 3
      if (_snackBars.length > 3) {
        _snackBars = _snackBars.sublist(0, 3);
      }
    });

    // Auto-remove this specific snackBar after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _snackBars.removeWhere((t) => t.id == snackBar.id);
        });
      }
    });
  }

  void removeSnackBar(String id) {
    setState(() {
      _snackBars.removeWhere((t) => t.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      // verticalDirection.up ensures index 0 is at the bottom, and older ones push upwards
      verticalDirection: VerticalDirection.up,
      children: List.generate(_snackBars.length, (index) {
        final snackBar = _snackBars[index];

        // The 30% transparency rule
        // Index 0 = 1.0, Index 1 = 0.70, Index 2 = 0.4, and so on.
        final opacity = (1.0 - (index * 0.30)).clamp(0.0, 1.0);

        return AnimatedOpacity(
          key: ValueKey(snackBar.id),
          opacity: opacity,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0), // Gap between stacked snackBars
            child: NordSnackBar(
              message: snackBar.message,
              type: snackBar.type,
              icon: snackBar.customIcon,
              actionLabel: snackBar.actionLabel,
              onAction: snackBar.onAction != null
                  ? (snackBarContext) {
                      // Trigger user's action using the living context
                      snackBar.onAction!(snackBarContext);
                      // Instantly dismiss this snackbar
                      removeSnackBar(snackBar.id);
                    }
                  : null,
            ),
          ),
        );
      }),
    );
  }
}

// Keep global references so we only ever insert the Manager once
OverlayEntry? _globalSnackbarOverlay;
final GlobalKey<NordSnackBarManagerState> _snackbarManagerKey = GlobalKey<NordSnackBarManagerState>();

void showNordSnackBar({
  required String message,
  required NordSnackBarType type,
  IconData? icon,
  String? actionLabel,
  void Function(BuildContext)? onAction,
}) {
  // If the manager isn't on the screen yet, put it there.
  if (_globalSnackbarOverlay == null) {
    // Grab the OverlayState DIRECTLY from the Navigator's current state.
    final overlayState = router.configuration.navigatorKey.currentState?.overlay;

    if (overlayState == null) return; // Safety failsafe

    _globalSnackbarOverlay = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 106, // Player Bar height + gap
        left: 0,
        right: 0,
        child: Center(child: NordSnackBarManager(key: _snackbarManagerKey)),
      ),
    );

    overlayState.insert(_globalSnackbarOverlay!);
  }

  // Create the unique snackbar data
  final snackbar = ActiveSnackBar(
    id: DateTime.now().microsecondsSinceEpoch.toString(),
    message: message,
    type: type,
    customIcon: icon,
    actionLabel: actionLabel,
    onAction: onAction,
  );

  // Send it to the Manager
  // Use addPostFrameCallback to ensure that if the Manager was just got inserted on the lines above, Flutter finishes
  // building it before trying to add data to it.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _snackbarManagerKey.currentState?.addSnackBar(snackbar);
  });
}
