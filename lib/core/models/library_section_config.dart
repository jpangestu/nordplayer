class const LibrarySectionConfig({required final String id, required final bool isVisible}) {
  LibrarySectionConfig copyWith({String? id, bool? isVisible}) {
    return LibrarySectionConfig(id: id ?? this.id, isVisible: isVisible ?? this.isVisible);
  }

  factory fromJson(Map<String, dynamic> json) {
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
