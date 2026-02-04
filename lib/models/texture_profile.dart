import 'dart:convert';

enum TextureType { asset, file }

class TextureProfile {
  final String id;
  final String name;
  final String path;
  final TextureType type;

  const TextureProfile({
    required this.id,
    required this.name,
    required this.path,
    required this.type,
  });

  // Convert Object -> Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'type': type.index,
    };
  }

  // Convert Map -> Object
  factory TextureProfile.fromMap(Map<String, dynamic> map) {
    return TextureProfile(
      id: map['id'],
      name: map['name'],
      path: map['path'],
      type: TextureType.values[map['type']],
    );
  }

  // Helper for JSON encoding
  String toJson() => json.encode(toMap());

  // Helper for JSON decoding
  factory TextureProfile.fromJson(String source) =>
      TextureProfile.fromMap(json.decode(source));

  // Default preset
  static const List<TextureProfile> defaultPresets = [
    TextureProfile(
      id: 'default_glass',
      name: 'Frosted Glass',
      path: 'assets/texture_preset/glass.png',
      type: TextureType.asset,
    ),
    TextureProfile(
      id: 'paper',
      name: 'Crumbled Paper',
      path: 'assets/texture_preset/paper.png',
      type: TextureType.asset,
    ),
    TextureProfile(
      id: 'aged_paper',
      name: 'Aged Paper',
      path: 'assets/texture_preset/old_paper.png',
      type: TextureType.asset,
    ),
    TextureProfile(
      id: 'rain',
      name: 'Rain',
      path: 'assets/texture_preset/rain.png',
      type: TextureType.asset,
    ),
    TextureProfile(
      id: 'rain2',
      name: 'Rain 2',
      path: 'assets/texture_preset/rain2.png',
      type: TextureType.asset,
    ),
    TextureProfile(
      id: 'rough_wall',
      name: 'Rough Wall',
      path: 'assets/texture_preset/rough_wall.png',
      type: TextureType.asset,
    ),
  ];

  // Equality check is vital for Dropdowns to work correctly
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TextureProfile &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
