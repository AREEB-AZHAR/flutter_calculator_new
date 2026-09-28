import 'dart:math';
import 'transaction.dart';

class PlannedTransaction {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final bool isIncome;
  final String category;
  final String account;
  final String recurrence;
  final bool isProcessed;
  final DateTime createdAt;

  PlannedTransaction({
    String? id,
    required this.title,
    required this.amount,
    required this.date,
    required this.isIncome,
    this.category = 'Other',
    this.account = 'Main',
    this.recurrence = 'None',
    this.isProcessed = false,
    DateTime? createdAt,
  })  : id = id ?? 'plan_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}',
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'amount': amount,
    'date': date.toIso8601String(),
    'isIncome': isIncome ? 1 : 0,
    'category': category,
    'account': account,
    'recurrence': recurrence,
    'isProcessed': isProcessed ? 1 : 0,
    'createdAt': createdAt.toIso8601String(),
  };

  factory PlannedTransaction.fromJson(Map<String, dynamic> json) => PlannedTransaction(
    id: json['id'],
    title: json['title'] ?? 'Planned Transaction',
    amount: (json['amount'] as num).toDouble(),
    date: DateTime.parse(json['date']),
    isIncome: json['isIncome'] == 1 || json['isIncome'] == true || json['is_income'] == 1,
    category: json['category'] ?? 'Other',
    account: json['account'] ?? 'Main',
    recurrence: json['recurrence'] ?? 'None',
    isProcessed: json['isProcessed'] == 1 || json['isProcessed'] == true || json['is_processed'] == 1,
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'])
        : (json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now()),
  );

  Transaction toActiveTransaction() {
    return Transaction(
      id: id,
      title: title,
      amount: amount,
      date: date,
      isIncome: isIncome,
      category: category,
      account: account,
      recurrence: recurrence,
    );
  }

  PlannedTransaction copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? date,
    bool? isIncome,
    String? category,
    String? account,
    String? recurrence,
    bool? isProcessed,
    DateTime? createdAt,
  }) {
    return PlannedTransaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      isIncome: isIncome ?? this.isIncome,
      category: category ?? this.category,
      account: account ?? this.account,
      recurrence: recurrence ?? this.recurrence,
      isProcessed: isProcessed ?? this.isProcessed,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
