import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/ui/shell/title_bar/window_control/breeze.dart';
import 'package:nordplayer/ui/shell/title_bar/window_control/windows11.dart';
import 'package:window_manager/window_manager.dart';

class NordTitleBar extends ConsumerStatefulWidget {
  const NordTitleBar({super.key});

  @override
  ConsumerState<NordTitleBar> createState() => _NordplayerTitleBarState();
}

class _NordplayerTitleBarState extends ConsumerState<NordTitleBar> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 34,
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Row(
                children: [
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

                  const Expanded(
                    child: DragToMoveArea(child: Row(children: [Text('Nordplayer'), Spacer()])),
                  ),

                  // SizedBox can't be used inside DragToMoveArea because it can be clicked
                  DragToMoveArea(child: Container(width: 8, color: Colors.transparent)),
                ],
              ),
            ),
          ),

          if (Platform.isWindows) ...[
            DragToMoveArea(child: Container(width: 8, color: Colors.transparent)),
            const Windows11WindowControl(),
          ] else if (Platform.isLinux) ...[
            const BreezeWindowControl(),
          ] else ...[
            const Windows11WindowControl(),
          ],
        ],
      ),
    );
  }
}
