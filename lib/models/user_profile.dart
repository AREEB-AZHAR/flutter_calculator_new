import 'package:flutter/material.dart';

class UserProfile {
  final String username;
  final String displayName;
  final String bio;
  final String? photoPath;
  final Color primaryColor;
  final Color secondaryColor;
  final Color? textColor;
  final String currency;
  final DateTime createdAt;

  UserProfile({
    required this.username,
    required this.displayName,
    this.bio = '',
    this.photoPath,
    this.primaryColor = const Color(0xFFE4572E),
    this.secondaryColor = const Color(0xFFF6F0E1),
    this.textColor,
    this.currency = '\$',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'display_name': displayName,
      'bio': bio,
      'photo_path': photoPath,
      'primary_color': primaryColor.toARGB32(),
      'secondary_color': secondaryColor.toARGB32(),
      'text_color': textColor?.toARGB32(),
      'currency': currency,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      username: map['username'] as String,
      displayName: (map['display_name'] as String?)?.isNotEmpty == true
          ? map['display_name'] as String
          : (map['username'] as String),
      bio: (map['bio'] as String?) ?? '',
      photoPath: map['photo_path'] as String?,
      primaryColor: map['primary_color'] != null
          ? Color(map['primary_color'] as int)
          : const Color(0xFFE4572E),
      secondaryColor: map['secondary_color'] != null
          ? Color(map['secondary_color'] as int)
          : const Color(0xFFF6F0E1),
      textColor: map['text_color'] != null
          ? Color(map['text_color'] as int)
          : null,
      currency: (map['currency'] as String?) ?? '\$',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  UserProfile copyWith({
    String? displayName,
    String? bio,
    String? photoPath,
    Color? primaryColor,
    Color? secondaryColor,
    Color? textColor,
    bool clearTextColor = false,
    String? currency,
  }) {
    return UserProfile(
      username: username,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      photoPath: photoPath ?? this.photoPath,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      textColor: clearTextColor ? null : (textColor ?? this.textColor),
      currency: currency ?? this.currency,
      createdAt: createdAt,
    );
  }
}
