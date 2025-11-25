class SessionExtension {
  final int? id;
  final int sessionId; // ID dari session utama
  final int extensionNumber; // Nomor extend (1, 2, 3, dst)
  final DateTime extensionTime; // Waktu ketika extend dilakukan
  final int additionalMinutes; // Durasi tambahan dalam menit
  final double additionalCost; // Biaya tambahan
  final DateTime? createdAt;

  SessionExtension({
    this.id,
    required this.sessionId,
    required this.extensionNumber,
    required this.extensionTime,
    required this.additionalMinutes,
    required this.additionalCost,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'extension_number': extensionNumber,
      'extension_time': extensionTime.millisecondsSinceEpoch,
      'additional_minutes': additionalMinutes,
      'additional_cost': additionalCost,
      'created_at': createdAt?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
    };
  }

  factory SessionExtension.fromMap(Map<String, dynamic> map) {
    return SessionExtension(
      id: map['id'] as int?,
      sessionId: map['session_id'] as int,
      extensionNumber: map['extension_number'] as int,
      extensionTime: DateTime.fromMillisecondsSinceEpoch(map['extension_time'] as int),
      additionalMinutes: map['additional_minutes'] as int,
      additionalCost: (map['additional_cost'] as num).toDouble(),
      createdAt: map['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int)
          : null,
    );
  }

  SessionExtension copyWith({
    int? id,
    int? sessionId,
    int? extensionNumber,
    DateTime? extensionTime,
    int? additionalMinutes,
    double? additionalCost,
    DateTime? createdAt,
  }) {
    return SessionExtension(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      extensionNumber: extensionNumber ?? this.extensionNumber,
      extensionTime: extensionTime ?? this.extensionTime,
      additionalMinutes: additionalMinutes ?? this.additionalMinutes,
      additionalCost: additionalCost ?? this.additionalCost,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}