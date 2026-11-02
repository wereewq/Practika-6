// lib/models/reader.dart
import 'library_card.dart';

class Reader {
  final int id;
  final String fullName;
  final String email;
  final String phone;
  final LibraryCard card;
  final DateTime? deletedAt;

  const Reader({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.card,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Reader copyWith({
    String? fullName,
    String? email,
    String? phone,
    LibraryCard? card,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Reader(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      card: card ?? this.card,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'email': email,
    'phone': phone,
    'card': card.toJson(),
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Reader.fromJson(Map<String, dynamic> json) => Reader(
    id: json['id'] as int? ?? 0,
    fullName: json['fullName'] as String? ?? '',
    email: json['email'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    card: LibraryCard.fromJson(json['card'] as Map<String, dynamic>? ?? {}),
    deletedAt: json['deletedAt'] == null
        ? null
        : DateTime.tryParse(json['deletedAt'] as String),
  );
}
