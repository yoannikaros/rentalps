import 'package:flutter/material.dart';

class ConsoleType {
  final int? id;
  final String name;
  final double hourlyRate;
  final String colorCode;
  final DateTime? createdAt;

  ConsoleType({
    this.id,
    required this.name,
    required this.hourlyRate,
    required this.colorCode,
    this.createdAt,
  });

  // Convert ConsoleType to Map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'hourly_rate': hourlyRate,
      'color_code': colorCode,
      'created_at': createdAt?.millisecondsSinceEpoch,
    };
  }

  // Create ConsoleType from Map (database result)
  factory ConsoleType.fromMap(Map<String, dynamic> map) {
    return ConsoleType(
      id: map['id'] as int?,
      name: map['name'] as String,
      hourlyRate: (map['hourly_rate'] as num).toDouble(),
      colorCode: map['color_code'] as String,
      createdAt: map['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int)
          : null,
    );
  }

  // Create a copy with modified fields
  ConsoleType copyWith({
    int? id,
    String? name,
    double? hourlyRate,
    String? colorCode,
    DateTime? createdAt,
  }) {
    return ConsoleType(
      id: id ?? this.id,
      name: name ?? this.name,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      colorCode: colorCode ?? this.colorCode,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Get Color from hex string
  Color get color {
    try {
      return Color(int.parse(colorCode.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.blue; // Default color if parsing fails
    }
  }

  // Format currency
  String get formattedRate {
    return 'Rp ${hourlyRate.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}/jam';
  }

  @override
  String toString() {
    return 'ConsoleType{id: $id, name: $name, hourlyRate: $hourlyRate, colorCode: $colorCode}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConsoleType &&
        other.id == id &&
        other.name == name &&
        other.hourlyRate == hourlyRate &&
        other.colorCode == colorCode;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        hourlyRate.hashCode ^
        colorCode.hashCode;
  }
}