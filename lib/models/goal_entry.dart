import 'dart:math';

/// Represents a single deposit/contribution entry towards a savings goal.
class GoalEntry {
  final String id;
  final String goalId;
  final double amount;
  final DateTime date;
  final String? note;
  final DateTime createdAt;

  GoalEntry({
    String? id,
    required this.goalId,
    required this.amount,
    DateTime? date,
    this.note,
    DateTime? createdAt,
  })  : id = id ??
            '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(99999)}',
        date = date ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  GoalEntry copyWith({
    String? id,
    String? goalId,
    double? amount,
    DateTime? date,
    String? note,
    DateTime? createdAt,
  }) {
    return GoalEntry(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'goalId': goalId,
        'amount': amount,
        'date': date.toIso8601String(),
        'note': note,
        'createdAt': createdAt.toIso8601String(),
      };

  factory GoalEntry.fromJson(Map<String, dynamic> json) => GoalEntry(
        id: json['id'] as String,
        goalId: json['goalId'] ?? json['goal_id'] as String,
        amount: (json['amount'] as num).toDouble(),
        date: DateTime.parse(json['date'] as String),
        note: json['note'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : (json['created_at'] != null
                ? DateTime.parse(json['created_at'] as String)
                : DateTime.now()),
      );

  @override
  String toString() =>
      'GoalEntry(id: $id, goalId: $goalId, amount: $amount, date: $date, note: $note)';
}
