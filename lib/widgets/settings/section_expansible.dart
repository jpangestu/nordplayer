import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/theming/icon-sets/app_icon_set.dart';
import 'package:nordplayer/widgets/app_icon.dart';

class SectionExpansible extends ConsumerStatefulWidget {
  final String title;
  final String? subtitle;
  final Widget body;
  final VoidCallback? onTitleClick;

  const SectionExpansible({super.key, required this.title, this.subtitle, required this.body, this.onTitleClick});

  @override
  ConsumerState<SectionExpansible> createState() => _SectionExpansibleState();
}

class _SectionExpansibleState extends ConsumerState<SectionExpansible> {
  final _controller = ExpansibleController();
  bool _isTitleHovered = false;

  @override
  Widget build(BuildContext context) {
    final appIconSet = ref.watch(appIconProvider);
    final theme = Theme.of(context);

    return Expansible(
      controller: _controller,
      headerBuilder: (context, animation) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: _controller.isExpanded
                ? const BorderRadius.vertical(top: Radius.circular(8))
                : BorderRadius.circular(8),
            onTap: () => _controller.isExpanded ? _controller.collapse() : _controller.expand(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
              child: Row(
                children: [
                  if (widget.onTitleClick == null) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title, style: theme.textTheme.titleMedium),
                        widget.subtitle != null
                            ? Text(
                                widget.subtitle!,
                                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              )
                            : const SizedBox.shrink(),
                      ],
                    ),
                  ] else ...[
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      onEnter: (_) => setState(() => _isTitleHovered = true),
                      onExit: (_) => setState(() => _isTitleHovered = false),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: widget.onTitleClick,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8.0, right: 4.0, top: 4.0, bottom: 4.0),
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: widget.title,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    decoration: _isTitleHovered ? TextDecoration.underline : TextDecoration.none,
                                  ),
                                ),
                                const TextSpan(text: ' '),
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: AnimatedSlide(
                                    offset: _isTitleHovered ? const Offset(0.1, 0) : Offset.zero,
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeOutCubic,
                                    child: AppIcon(appIconSet.navigationRight, size: 20),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],

                  const Spacer(),

                  RotationTransition(
                    turns: Tween<double>(begin: 0.0, end: 0.5).animate(animation),
                    child: AppIcon(appIconSet.navigationDown),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      bodyBuilder: (context, animation) => widget.body,
    );
  }
}
