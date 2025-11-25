class Session {
  final int? id;
  final int consoleId;
  final String? customerName; // Nama customer/atas nama
  final DateTime startTime;
  final DateTime? endTime;
  final int durationMinutes; // Durasi yang ditentukan di awal
  final int? actualDurationMinutes; // Durasi aktual setelah selesai
  final double totalCost;
  final bool isActive;
  final DateTime? createdAt;
  final int originalDurationMinutes; // Durasi asli sebelum extend
  final double originalCost; // Biaya asli sebelum extend
  final int extensionCount; // Jumlah extend yang dilakukan

  Session({
    this.id,
    required this.consoleId,
    this.customerName,
    required this.startTime,
    this.endTime,
    required this.durationMinutes,
    this.actualDurationMinutes,
    required this.totalCost,
    this.isActive = true,
    this.createdAt,
    int? originalDurationMinutes,
    double? originalCost,
    this.extensionCount = 0,
  }) : originalDurationMinutes = originalDurationMinutes ?? durationMinutes,
       originalCost = originalCost ?? totalCost;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'console_id': consoleId,
      'customer_name': customerName,
      'start_time': startTime.millisecondsSinceEpoch,
      'end_time': endTime?.millisecondsSinceEpoch,
      'duration_minutes': durationMinutes,
      'actual_duration_minutes': actualDurationMinutes,
      'total_cost': totalCost,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt?.millisecondsSinceEpoch,
      'original_duration_minutes': originalDurationMinutes,
      'original_cost': originalCost,
      'extension_count': extensionCount,
    };
  }

  factory Session.fromMap(Map<String, dynamic> map) {
    return Session(
      id: map['id'] as int?,
      consoleId: map['console_id'] as int,
      customerName: map['customer_name'] as String?,
      startTime: DateTime.fromMillisecondsSinceEpoch(map['start_time'] as int),
      endTime: map['end_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['end_time'] as int)
          : null,
      durationMinutes: map['duration_minutes'] as int,
      actualDurationMinutes: map['actual_duration_minutes'] as int?,
      totalCost: (map['total_cost'] as num).toDouble(),
      isActive: (map['is_active'] as int) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int)
          : null,
      originalDurationMinutes: (map['original_duration_minutes'] as int?) ?? (map['duration_minutes'] as int),
      originalCost: map['original_cost'] != null
          ? (map['original_cost'] as num).toDouble()
          : (map['total_cost'] as num).toDouble(),
      extensionCount: (map['extension_count'] as int?) ?? 0,
    );
  }

  Session copyWith({
    int? id,
    int? consoleId,
    String? customerName,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
    int? actualDurationMinutes,
    double? totalCost,
    bool? isActive,
    DateTime? createdAt,
    int? originalDurationMinutes,
    double? originalCost,
    int? extensionCount,
  }) {
    return Session(
      id: id ?? this.id,
      consoleId: consoleId ?? this.consoleId,
      customerName: customerName ?? this.customerName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      actualDurationMinutes: actualDurationMinutes ?? this.actualDurationMinutes,
      totalCost: totalCost ?? this.totalCost,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      originalDurationMinutes: originalDurationMinutes ?? this.originalDurationMinutes,
      originalCost: originalCost ?? this.originalCost,
      extensionCount: extensionCount ?? this.extensionCount,
    );
  }

  // Helper methods
  DateTime get expectedEndTime => startTime.add(Duration(minutes: durationMinutes));
  
  Duration get remainingTime {
    final now = DateTime.now();
    final expected = expectedEndTime;
    if (now.isAfter(expected)) {
      return Duration.zero;
    }
    return expected.difference(now);
  }

  bool get isExpired => DateTime.now().isAfter(expectedEndTime);
}