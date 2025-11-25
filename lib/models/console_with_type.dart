import 'console.dart';
import 'console_type.dart';

class ConsoleWithType {
  final Console console;
  final ConsoleType consoleType;

  ConsoleWithType({
    required this.console,
    required this.consoleType,
  });

  // Convenience getters for backward compatibility
  int? get id => console.id;
  String get name => console.name;
  int get consoleTypeId => console.consoleTypeId;
  bool get isActive => console.isActive;
  DateTime? get createdAt => console.createdAt;
  
  // Console type information
  String get type => consoleType.name;
  double get hourlyRate => consoleType.hourlyRate;
  String get colorCode => consoleType.colorCode;

  factory ConsoleWithType.fromMap(Map<String, dynamic> map) {
    final console = Console(
      id: map['id'] as int?,
      name: map['name'] as String,
      consoleTypeId: map['console_type_id'] as int,
      isActive: map['is_active'] == 1,
      createdAt: map['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int)
          : null,
    );

    final consoleType = ConsoleType(
      id: map['console_type_id'] as int,
      name: map['type_name'] as String,
      hourlyRate: (map['hourly_rate'] as num).toDouble(),
      colorCode: map['color_code'] as String,
    );

    return ConsoleWithType(
      console: console,
      consoleType: consoleType,
    );
  }

  ConsoleWithType copyWith({
    Console? console,
    ConsoleType? consoleType,
  }) {
    return ConsoleWithType(
      console: console ?? this.console,
      consoleType: consoleType ?? this.consoleType,
    );
  }
}