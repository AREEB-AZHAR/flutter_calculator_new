import 'dart:math';
import 'package:flutter/material.dart';

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

  SavingsGoal({
    String? id,
    required this.title,
    required this.target,
    this.saved = 0,
    this.icon = Icons.savings,
    this.color = const Color(0xFF8B5CF6),
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString() + Random().nextInt(1000).toString();

  double get progress => (saved / target).clamp(0.0, 1.0);

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'target': target,
    'saved': saved,
    'iconName': goalIconName(icon),
    'colorValue': color.toARGB32(),
  };

  factory SavingsGoal.fromJson(Map<String, dynamic> json) => SavingsGoal(
    id: json['id'],
    title: json['title'],
    target: json['target'].toDouble(),
    saved: json['saved'].toDouble(),
    icon: resolveGoalIcon(json['iconName']),
    color: Color(json['colorValue'] ?? 0xFF8B5CF6),
  );
}
