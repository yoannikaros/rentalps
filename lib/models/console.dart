class Console {
  final int? id;
  final String name;
  final int consoleTypeId;
  final bool isActive;
  final DateTime? createdAt;

  Console({
    this.id,
    required this.name,
    required this.consoleTypeId,
    this.isActive = false,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'console_type_id': consoleTypeId,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt?.millisecondsSinceEpoch,
    };
  }

  factory Console.fromMap(Map<String, dynamic> map) {
    return Console(
      id: map['id'] as int?,
      name: map['name'] as String,
      consoleTypeId: map['console_type_id'] as int,
      isActive: (map['is_active'] as int) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int)
          : null,
    );
  }

  Console copyWith({
    int? id,
    String? name,
    int? consoleTypeId,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Console(
      id: id ?? this.id,
      name: name ?? this.name,
      consoleTypeId: consoleTypeId ?? this.consoleTypeId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}