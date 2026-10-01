import 'dart:math';
import 'package:flutter/material.dart';
import 'goal_entry.dart';

const Map<String, IconData> _goalIconMap = {
  'savings': Icons.savings,
  'flag': Icons.flag,
  'home': Icons.home,
  'flight': Icons.flight,
  'school': Icons.school,
  'car': Icons.directions_car,
  'shopping': Icons.shopping_cart,
  'star': Icons.star,
  'favorite': Icons.favorite,
  'attach_money': Icons.attach_money,
};

IconData resolveGoalIcon(String? name) {
  return _goalIconMap[name] ?? Icons.savings;
}

IconData resolveGoalIconByCodePoint(int? codePoint) {
  if (codePoint == null) return Icons.savings;
  for (final icon in _goalIconMap.values) {
    if (icon.codePoint == codePoint) return icon;
  }
  return Icons.savings;
}

String goalIconName(IconData icon) {
  for (final entry in _goalIconMap.entries) {
    if (entry.value.codePoint == icon.codePoint) return entry.key;
  }
  return 'savings';
}

class SavingsGoal {
  final String id;
  final String title;
  final double target;
  double saved;
  final IconData icon;
  final Color color;
  final DateTime? dueDate;
  final String periodType; // 'daily', 'weekly', 'monthly', 'custom'
  final bool isRecurring;
  final String recurrence; // 'none', 'daily', 'weekly', 'monthly'
  bool isCompleted;
  bool isFailed;
  bool isArchived;
  final DateTime createdAt;
  List<GoalEntry> entries;

  SavingsGoal({
    String? id,
    required this.title,
    required this.target,
    this.saved = 0,
    this.icon = Icons.savings,
    this.color = const Color(0xFF8B5CF6),
    this.dueDate,
    this.periodType = 'monthly',
    this.isRecurring = false,
    this.recurrence = 'none',
    this.isCompleted = false,
    this.isFailed = false,
    this.isArchived = false,
    DateTime? createdAt,
    List<GoalEntry>? entries,
  })  : id = id ??
            DateTime.now().millisecondsSinceEpoch.toString() +
                Random().nextInt(1000).toString(),
        createdAt = createdAt ?? DateTime.now(),
        entries = entries ?? [];

  double get progress => (saved / target).clamp(0.0, 1.0);

  /// Remaining amount needed to hit target.
  double get remainingToSave => max(0.0, target - saved);

  /// Days remaining until due date; 0 if no due date or already past.
  int get daysRemaining {
    if (dueDate == null) return 0;
    final now = DateTime.now();
    final diff = dueDate!.difference(DateTime(now.year, now.month, now.day)).inDays;
    return diff < 0 ? 0 : diff;
  }

  /// How much the user needs to save per day to hit the target by the due date.
  double get dailySavingsNeeded {
    final remaining = target - saved;
    if (remaining <= 0) return 0;
    final days = daysRemaining;
    if (days <= 0) return remaining; // All remaining is due today
    return remaining / days;
  }

  /// Weekly savings needed based on daily rate.
  double get weeklySavingsNeeded => dailySavingsNeeded * 7;

  /// Whether the goal has expired (past due date and not yet reached target).
  bool get isExpired =>
      dueDate != null &&
      DateTime.now().isAfter(dueDate!) &&
      saved < target &&
      !isCompleted;

  /// Whether the goal is currently active (not completed, not failed, not archived).
  bool get isActive => !isCompleted && !isFailed && !isArchived;

  SavingsGoal copyWith({
    String? id,
    String? title,
    double? target,
    double? saved,
    IconData? icon,
    Color? color,
    DateTime? dueDate,
    bool clearDueDate = false,
    String? periodType,
    bool? isRecurring,
    String? recurrence,
    bool? isCompleted,
    bool? isFailed,
    bool? isArchived,
    DateTime? createdAt,
    List<GoalEntry>? entries,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      title: title ?? this.title,
      target: target ?? this.target,
      saved: saved ?? this.saved,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      periodType: periodType ?? this.periodType,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrence: recurrence ?? this.recurrence,
      isCompleted: isCompleted ?? this.isCompleted,
      isFailed: isFailed ?? this.isFailed,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      entries: entries ?? List.from(this.entries),
    );
  }

  /// Creates a new cycle goal from a recurring goal that has completed or failed.
  SavingsGoal startNewCycle() {
    return SavingsGoal(
      title: title,
      target: target,
      saved: 0,
      icon: icon,
      color: color,
      dueDate: _computeNextDueDate(),
      periodType: periodType,
      isRecurring: isRecurring,
      recurrence: recurrence,
      isCompleted: false,
      isFailed: false,
      isArchived: false,
    );
  }

  DateTime? _computeNextDueDate() {
    if (dueDate == null) return null;
    final now = DateTime.now();
    switch (recurrence) {
      case 'daily':
        return DateTime(now.year, now.month, now.day + 1);
      case 'weekly':
        return now.add(const Duration(days: 7));
      case 'monthly':
        return DateTime(now.year, now.month + 1, now.day);
      default:
        return null;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'target': target,
        'saved': saved,
        'iconName': goalIconName(icon),
        'colorValue': color.toARGB32(),
        'dueDate': dueDate?.toIso8601String(),
        'periodType': periodType,
        'isRecurring': isRecurring,
        'recurrence': recurrence,
        'isCompleted': isCompleted,
        'isFailed': isFailed,
        'isArchived': isArchived,
        'createdAt': createdAt.toIso8601String(),
        'entries': entries.map((e) => e.toJson()).toList(),
      };

  factory SavingsGoal.fromJson(Map<String, dynamic> json) => SavingsGoal(
        id: json['id'],
        title: json['title'],
        target: json['target'].toDouble(),
        saved: json['saved'].toDouble(),
        icon: resolveGoalIcon(json['iconName']),
        color: Color(json['colorValue'] ?? 0xFF8B5CF6),
        dueDate: json['dueDate'] != null
            ? DateTime.tryParse(json['dueDate'])
            : null,
        periodType: json['periodType'] ?? 'monthly',
        isRecurring: json['isRecurring'] ?? false,
        recurrence: json['recurrence'] ?? 'none',
        isCompleted: json['isCompleted'] ?? false,
        isFailed: json['isFailed'] ?? false,
        isArchived: json['isArchived'] ?? false,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
            : DateTime.now(),
        entries: json['entries'] != null
            ? (json['entries'] as List)
                .map((e) => GoalEntry.fromJson(e as Map<String, dynamic>))
                .toList()
            : [],
      );
}
