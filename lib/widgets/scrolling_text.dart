import 'dart:async';

import 'package:flutter/material.dart';

class ScrollingText extends StatefulWidget {
  final InlineSpan textSpan;
  final TextStyle? style;

  const ScrollingText({super.key, required this.textSpan, this.style});

  @override
  State<ScrollingText> createState() => _ScrollingTextState();
}

class _ScrollingTextState extends State<ScrollingText> {
  late ScrollController _scrollController;
  Timer? _timer;
  bool _isHovered = false;
  bool _forward = true;
  DateTime? _pauseUntil;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    _scrollController.dispose();
    super.dispose();
  }

  void _startScrolling() {
    const pps = 25.0;
    const intervalMs = 16;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: intervalMs), (_) {
      if (!mounted || _isHovered) return;
      if (!_scrollController.hasClients) return;

      // If in a pause window, do nothing
      if (_pauseUntil != null && DateTime.now().isBefore(_pauseUntil!)) return;

      final current = _scrollController.offset;
      final max = _scrollController.position.maxScrollExtent;
      const step = pps * intervalMs / 1000;

      if (_forward) {
        if (current >= max) {
          _forward = false;
          _pauseUntil = DateTime.now().add(const Duration(milliseconds: 800));
        } else {
          _scrollController.jumpTo((current + step).clamp(0, max));
        }
      } else {
        if (current <= 0) {
          _forward = true;
          _pauseUntil = DateTime.now().add(const Duration(milliseconds: 800));
        } else {
          _scrollController.jumpTo((current - step).clamp(0, max));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScaler = MediaQuery.textScalerOf(context);

        final painter = TextPainter(
          text: widget.textSpan,
          maxLines: 1,
          textDirection: TextDirection.ltr,
          textScaler: textScaler,
        );
        painter.layout();

        final isOverflowing = painter.width > constraints.maxWidth;

        if (isOverflowing) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _startScrolling();
          });

          return MouseRegion(
            onEnter: (_) => _isHovered = true,
            onExit: (_) => _isHovered = false,
            child: SizedBox(
              height: painter.height,
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: RichText(
                  text: widget.textSpan,
                  maxLines: 1,
                  textScaler: textScaler,
                ),
              ),
            ),
          );
        } else {
          _timer?.cancel();
          return RichText(
            text: widget.textSpan,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textScaler: textScaler,
          );
        }
      },
    );
  }
}
