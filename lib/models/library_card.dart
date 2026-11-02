class LibraryCard {
  final String cardNumber;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final bool isActive;

  const LibraryCard({
    required this.cardNumber,
    required this.issuedAt,
    required this.expiresAt,
    this.isActive = true,
  });

  LibraryCard copyWith({
    String? cardNumber,
    DateTime? issuedAt,
    DateTime? expiresAt,
    bool? isActive,
  }) {
    return LibraryCard(
      cardNumber: cardNumber ?? this.cardNumber,
      issuedAt: issuedAt ?? this.issuedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
    'cardNumber': cardNumber,
    'issuedAt': issuedAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
    'isActive': isActive,
  };

  factory LibraryCard.fromJson(Map<String, dynamic> json) => LibraryCard(
    cardNumber: json['cardNumber'] as String? ?? '',
    issuedAt:
        DateTime.tryParse(json['issuedAt'] as String? ?? '') ?? DateTime.now(),
    expiresAt:
        DateTime.tryParse(json['expiresAt'] as String? ?? '') ??
        DateTime.now().add(const Duration(days: 365)),
    isActive: json['isActive'] as bool? ?? true,
  );
}
