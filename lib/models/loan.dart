import 'dart:math';

class Loan {
  final String id;
  final String title;
  final String personName;
  final double amount;
  final DateTime dueDate;
  final String type; // 'receivable' (money owed to user) or 'payable' (user owes)
  final bool isSettled;
  final String? notes;
  final String account;
  final DateTime createdAt;

  Loan({
    String? id,
    required this.title,
    required this.personName,
    required this.amount,
    required this.dueDate,
    required this.type,
    this.isSettled = false,
    this.notes,
    this.account = 'Main',
    DateTime? createdAt,
  })  : id = id ?? 'loan_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}',
        createdAt = createdAt ?? DateTime.now();

  bool get isReceivable => type == 'receivable';
  bool get isPayable => type == 'payable';

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'personName': personName,
    'amount': amount,
    'dueDate': dueDate.toIso8601String(),
    'type': type,
    'isSettled': isSettled ? 1 : 0,
    'notes': notes,
    'account': account,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Loan.fromJson(Map<String, dynamic> json) => Loan(
    id: json['id'],
    title: json['title'] ?? 'Loan',
    personName: json['personName'] ?? json['person_name'] ?? 'Contact',
    amount: (json['amount'] as num).toDouble(),
    dueDate: DateTime.parse(json['dueDate'] ?? json['due_date']),
    type: json['type'] ?? 'receivable',
    isSettled: json['isSettled'] == 1 || json['isSettled'] == true || json['is_settled'] == 1,
    notes: json['notes'],
    account: json['account'] ?? 'Main',
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'])
        : (json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now()),
  );

  Loan copyWith({
    String? id,
    String? title,
    String? personName,
    double? amount,
    DateTime? dueDate,
    String? type,
    bool? isSettled,
    String? notes,
    String? account,
    DateTime? createdAt,
  }) {
    return Loan(
      id: id ?? this.id,
      title: title ?? this.title,
      personName: personName ?? this.personName,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      type: type ?? this.type,
      isSettled: isSettled ?? this.isSettled,
      notes: notes ?? this.notes,
      account: account ?? this.account,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
