import 'dart:math';

class Transaction {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final bool isIncome;
  final String category;
  final String account;
  final String recurrence;

  Transaction({
    String? id,
    required this.title,
    required this.amount,
    required this.date,
    required this.isIncome,
    this.category = 'Other',
    this.account = 'Main',
    this.recurrence = 'None',
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString() + Random().nextInt(1000).toString();

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'amount': amount,
    'date': date.toIso8601String(),
    'isIncome': isIncome,
    'category': category,
    'account': account,
    'recurrence': recurrence,
  };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString() + Random().nextInt(1000).toString(),
    title: json['title'],
    amount: json['amount'].toDouble(),
    date: DateTime.parse(json['date']),
    isIncome: json['isIncome'],
    category: json['category'] ?? 'Other',
    account: json['account'] ?? 'Main',
    recurrence: json['recurrence'] ?? 'None',
  );
}
