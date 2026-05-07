import 'dart:convert';

class Task {
  final String id;
  String name;
  DateTime dateDone;
  int reminderDays;
  String? photoBase64;
  String note;

  Task({
    required this.id,
    required this.name,
    required this.dateDone,
    required this.reminderDays,
    this.photoBase64,
    this.note = '',
  });

  /// Create a Task with an auto-generated ID.
  factory Task.create({
    required String name,
    required DateTime dateDone,
    required int reminderDays,
    String? photoBase64,
    String note = '',
  }) {
    return Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      dateDone: dateDone,
      reminderDays: reminderDays,
      photoBase64: photoBase64,
      note: note,
    );
  }

  /// Calculate the next due date.
  DateTime get nextDueDate => dateDone.add(Duration(days: reminderDays));

  /// Whether the task is overdue.
  bool get isOverdue => DateTime.now().isAfter(nextDueDate);

  /// Days until next due (negative = overdue).
  int get daysUntilDue => nextDueDate.difference(DateTime.now()).inDays;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dateDone': dateDone.toIso8601String(),
      'reminderDays': reminderDays,
      'photoBase64': photoBase64,
      'note': note,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      name: json['name'] as String,
      dateDone: DateTime.parse(json['dateDone'] as String? ?? json['date'] as String),
      reminderDays: json['reminderDays'] as int? ?? 30,
      photoBase64: json['photoBase64'] as String?,
      note: json['note'] as String? ?? '',
    );
  }

  String encode() => jsonEncode(toJson());

  factory Task.decode(String source) =>
      Task.fromJson(jsonDecode(source) as Map<String, dynamic>);
}
