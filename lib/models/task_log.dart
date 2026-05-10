import 'dart:convert';

/// Represents a single historical record of a completed task.
class TaskLog {
  final String id;
  final DateTime completedDate;
  final String note;

  TaskLog({
    required this.id,
    required this.completedDate,
    this.note = '',
  });

  factory TaskLog.create({
    required DateTime completedDate,
    String note = '',
  }) {
    return TaskLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      completedDate: completedDate,
      note: note,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'completedDate': completedDate.toIso8601String(),
      'note': note,
    };
  }

  factory TaskLog.fromJson(Map<String, dynamic> json) {
    return TaskLog(
      id: json['id'] as String,
      completedDate: DateTime.parse(json['completedDate'] as String),
      note: json['note'] as String? ?? '',
    );
  }

  String encode() => jsonEncode(toJson());

  factory TaskLog.decode(String source) =>
      TaskLog.fromJson(jsonDecode(source) as Map<String, dynamic>);
}
