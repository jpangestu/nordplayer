import 'dart:io';
import 'package:flutter/material.dart';

class AlbumArt extends StatelessWidget {
  final String? artPath;
  final double size;
  final double borderRadius;

  const AlbumArt({
    super.key,
    required this.artPath,
    this.size = 50,
    this.borderRadius = 3,
  });

  @override
  Widget build(BuildContext context) {
    // Define the Fallback (Placeholder)
    final placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Icon(Icons.music_note, color: Colors.white24, size: size * 0.5),
    );

    // Check Valid Path
    if (artPath == null || artPath!.isEmpty) {
      return placeholder;
    }

    // Calculate the exact pixel size needed for the screen
    // Multiply by devicePixelRatio (e.g., x2 or x3) to keep it crisp on Retina screens
    final pixelSize = (size * MediaQuery.of(context).devicePixelRatio).toInt();

    // Render Image
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.file(
        File(artPath!),
        width: size,
        height: size,
        fit: BoxFit.cover,

        // --- OPTIMIZATION 1: MEMORY ---
        // Only decode it to the size we actually need.
        // This makes the image tiny in memory, so the cache can hold 500+ of them easily.
        cacheWidth: pixelSize, 
        
        // --- OPTIMIZATION 2: FLICKER ---
        // Keeps the old image visible while the new one loads (if refreshing)
        // preventing white flashes during fast scrolls.
        gaplessPlayback: true,
        
        // Error Builder: If the JPG file is corrupted or deleted
        errorBuilder: (context, error, stackTrace) => placeholder,
      ),
    );
  }
}