import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:nordplayer/routes/router.dart';
import 'package:nordplayer/services/config_service.dart';
import 'package:nordplayer/theming/icon-sets/app_icon_set.dart';
import 'package:nordplayer/widgets/frosted_glass.dart';
import 'package:nordplayer/widgets/title_bar_button.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:window_manager/window_manager.dart';

class NordplayerTitleBar extends ConsumerStatefulWidget {
  const NordplayerTitleBar({super.key});

  @override
  ConsumerState<NordplayerTitleBar> createState() => _NordplayerTitleBarState();
}

class _NordplayerTitleBarState extends ConsumerState<NordplayerTitleBar> {
  PackageInfo? _packageInfo;

  void _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appConfig = ref.watch(configServiceProvider).requireValue;
    final appIconSet = ref.watch(appIconProvider);

    return DragToMoveArea(
      child: FrostedGlass(
        blurSigma: (appConfig.adaptiveBgPanelBlur + 30).clamp(0, 100),
        backgroundColor: appConfig.adaptiveBg
            ? colorScheme.surfaceContainer.withValues(alpha: appConfig.adaptiveBgThemeOverlay)
            : colorScheme.surfaceContainer,
        child: SizedBox(
          height: 34,
          child: Row(
            children: [
              const SizedBox(width: 0),

              GestureDetector(
                onTap: () async {
                  await windowManager.popUpWindowMenu();
                },
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0, right: 4),
                  child: SvgPicture.asset(
                    'assets/icons/nordplayer_logo_white_transparent.svg',
                    width: 22,
                    height: 22,
                    colorFilter: ColorFilter.mode(colorScheme.onSurface, BlendMode.srcIn),
                  ),
                ),
              ),
              Text('Nordplayer'),

              const Spacer(),

              // Right Side
              if (_packageInfo != null)
                TextButton(
                  onPressed: () {
                    context.go('${Routes.appearancePage}/${Routes.aboutPage}');
                  },
                  child: Text(
                    _packageInfo!.version,
                    style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                  ),
                ),

              TitleBarButton(
                icon: appIconSet.keyboardShortcut,
                iconSize: 18,
                fixedIconColor: colorScheme.onSurface,
                hoverOverlaySize: 28,
                hoverOverlayOpacity: 0.1,
                tooltip: 'Keyboard Shortcuts',
                onTap: () {},
              ),

              SizedBox(width: 16),

              BreezeWindowControl(),
            ],
          ),
        ),
      ),
    );
  }
}

class BreezeWindowControl extends StatefulWidget {
  const BreezeWindowControl({super.key});

  @override
  State<BreezeWindowControl> createState() => _BreezeWindowControlState();
}

class _BreezeWindowControlState extends State<BreezeWindowControl> with WindowListener {
  bool _isMaximized = false;

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

  // Update local state automatically when the OS maximizes/unmaximizes the app
  @override
  void onWindowMaximize() {
    if (mounted) setState(() => _isMaximized = true);
  }

  @override
  void onWindowUnmaximize() {
    if (mounted) setState(() => _isMaximized = false);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TitleBarButton(
          svgPath: 'assets/icons/window_control/breeze/window-minimize.svg',
          buttonSize: 24,
          hoverOverlaySize: 20,
          onTap: () {
            windowManager.minimize();
          },
        ),
        TitleBarButton(
          svgPath: _isMaximized
              ? 'assets/icons/window_control/breeze/window-restore.svg'
              : 'assets/icons/window_control/breeze/window-maximize.svg',
          buttonSize: 24,
          hoverOverlaySize: 20,
          onTap: () {
            if (_isMaximized) {
              windowManager.unmaximize();
            } else {
              windowManager.maximize();
            }
          },
        ),
        TitleBarButton(
          svgPath: 'assets/icons/window_control/breeze/window-close.svg',
          isClose: true,
          buttonSize: 24,
          hoverOverlaySize: 20,
          onTap: () {
            windowManager.close();
          },
        ),
        SizedBox(width: 8),
      ],
    );
  }
}
