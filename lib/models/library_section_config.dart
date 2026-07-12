class LibrarySectionConfig {
  final String id;
  final bool isVisible;

  const LibrarySectionConfig({required this.id, required this.isVisible});

  LibrarySectionConfig copyWith({String? id, bool? isVisible}) {
    return LibrarySectionConfig(id: id ?? this.id, isVisible: isVisible ?? this.isVisible);
  }

  factory LibrarySectionConfig.fromJson(Map<String, dynamic> json) {
    return LibrarySectionConfig(id: json['id'] as String? ?? '', isVisible: json['visible'] as bool? ?? true);
  }

  Map<String, dynamic> toJson() => {'id': id, 'visible': isVisible};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LibrarySectionConfig &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          isVisible == other.isVisible;

  @override
  int get hashCode => id.hashCode ^ isVisible.hashCode;

  @override
  String toString() {
    return 'LibrarySectionConfig{id: $id, visible: $isVisible}';
  }
}
