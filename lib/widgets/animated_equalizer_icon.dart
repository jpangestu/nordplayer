import 'dart:math' as math;

import 'package:flutter/material.dart';

class AnimatedEqualizerIcon extends StatefulWidget {
  final Color color;
  final double size;
  final bool isPlaying;

  const AnimatedEqualizerIcon({super.key, required this.color, this.size = 16.0, this.isPlaying = true});

  @override
  State<AnimatedEqualizerIcon> createState() => _AnimatedEqualizerIconState();
}

class _AnimatedEqualizerIconState extends State<AnimatedEqualizerIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // A 2-second continuous loop for the math functions
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2));

    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(AnimatedEqualizerIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final time = _controller.value * 2 * math.pi;

          // Calculate independent wave heights (0.0 to 1.0) for 4 bars
          // Multiplying the time makes them move at different speeds,
          // and adding an offset (+ 1.5) changes their starting phase.
          final h1 = (math.sin(time * 3.0) + 1) / 2;
          final h2 = (math.sin(time * 4.0 + 1.5) + 1) / 2;
          final h3 = (math.sin(time * 2.5 + 3.0) + 1) / 2;
          final h4 = (math.sin(time * 5.0 + 4.5) + 1) / 2;

          // Map those values to the actual pixel height
          final minHeight = widget.size * 0.2; // 20% minimum height
          final range = widget.size * 0.8;

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end, // Anchor to bottom
            children: [
              _buildBar(widget.isPlaying ? minHeight + (h1 * range) : minHeight),
              _buildBar(widget.isPlaying ? minHeight + (h2 * range) : minHeight),
              _buildBar(widget.isPlaying ? minHeight + (h3 * range) : minHeight),
              _buildBar(widget.isPlaying ? minHeight + (h4 * range) : minHeight),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBar(double height) {
    return AnimatedContainer(
      // Smoothly drop to minHeight when paused
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      width: widget.size * 0.16, // Proportional bar width
      height: height,
      decoration: BoxDecoration(color: widget.color, borderRadius: BorderRadius.circular(2)),
    );
  }
}
