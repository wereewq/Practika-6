class Publisher {
  final int id;
  final String name;
  final String city;
  final String website;
  final DateTime? deletedAt;

  const Publisher({
    required this.id,
    required this.name,
    required this.city,
    required this.website,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Publisher copyWith({
    String? name,
    String? city,
    String? website,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Publisher(
      id: id,
      name: name ?? this.name,
      city: city ?? this.city,
      website: website ?? this.website,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'city': city,
    'website': website,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Publisher.fromJson(Map<String, dynamic> json) => Publisher(
    id: json['id'] as int? ?? 0,
    name: json['name'] as String? ?? '',
    city: json['city'] as String? ?? '',
    website: json['website'] as String? ?? '',
    deletedAt: json['deletedAt'] == null
        ? null
        : DateTime.tryParse(json['deletedAt'] as String),
  );
}
