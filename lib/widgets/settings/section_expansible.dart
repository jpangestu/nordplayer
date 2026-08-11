import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nordplayer/theming/icon-sets/app_icon_set.dart';
import 'package:nordplayer/widgets/app_icon.dart';

enum InitialState { collapsed, expanded }

class SectionExpansible extends ConsumerStatefulWidget {
  final InitialState? initialState;
  final String title;
  final TextStyle? titleStyle;
  final VoidCallback? onTitleClick;
  final String? subtitle;
  final Widget body;

  const SectionExpansible({
    super.key,
    this.initialState,
    required this.title,
    this.titleStyle,
    this.onTitleClick,
    this.subtitle,
    required this.body,
  });

  @override
  ConsumerState<SectionExpansible> createState() => _SectionExpansibleState();
}

class _SectionExpansibleState extends ConsumerState<SectionExpansible> {
  final _controller = ExpansibleController();
  bool _isTitleHovered = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialState != null) {
      widget.initialState == InitialState.expanded ? _controller.expand() : _controller.collapse();
    }
  }

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
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Row(
                children: [
                  if (widget.onTitleClick == null) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(widget.title, style: widget.titleStyle ?? theme.textTheme.titleMedium),
                        ),
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
                          padding: const EdgeInsets.only(left: 0.0, right: 0.0, top: 4.0, bottom: 4.0),
                          child: Row(
                            mainAxisSize: .min,
                            children: [
                              Text(
                                widget.title,
                                style: (widget.titleStyle ?? theme.textTheme.titleMedium!).copyWith(
                                  decoration: _isTitleHovered ? TextDecoration.underline : TextDecoration.none,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 2.0, top: 2.5),
                                child: AnimatedSlide(
                                  offset: _isTitleHovered ? const Offset(0.1, 0) : Offset.zero,
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOutCubic,
                                  child: AppIcon(
                                    LucideIcons.chevronRight500,
                                    size: 22,
                                    color: widget.titleStyle?.color ?? theme.textTheme.titleMedium!.color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],

                  const Spacer(),

                  RotationTransition(
                    turns: Tween<double>(begin: 0.0, end: 0.5).animate(animation),
                    child: AppIcon(
                      appIconSet.navigationDown,
                      color: widget.titleStyle?.color ?? theme.textTheme.titleMedium!.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      bodyBuilder: (context, animation) =>
          Padding(padding: const EdgeInsets.symmetric(horizontal: 12.0), child: widget.body),
    );
  }
}
