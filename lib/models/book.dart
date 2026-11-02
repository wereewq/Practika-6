class Book {
  final int id;
  final String title;
  final String isbn;
  final int year;
  final int pages;
  final int publisherId;
  final List<int> authorIds;
  final List<int> genreIds;
  final int copiesTotal;
  final int copiesAvailable;
  final DateTime? deletedAt;

  const Book({
    required this.id,
    required this.title,
    required this.isbn,
    required this.year,
    required this.pages,
    required this.publisherId,
    required this.authorIds,
    required this.genreIds,
    required this.copiesTotal,
    required this.copiesAvailable,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Book copyWith({
    String? title,
    String? isbn,
    int? year,
    int? pages,
    int? publisherId,
    List<int>? authorIds,
    List<int>? genreIds,
    int? copiesTotal,
    int? copiesAvailable,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Book(
      id: id,
      title: title ?? this.title,
      isbn: isbn ?? this.isbn,
      year: year ?? this.year,
      pages: pages ?? this.pages,
      publisherId: publisherId ?? this.publisherId,
      authorIds: authorIds ?? this.authorIds,
      genreIds: genreIds ?? this.genreIds,
      copiesTotal: copiesTotal ?? this.copiesTotal,
      copiesAvailable: copiesAvailable ?? this.copiesAvailable,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'isbn': isbn,
    'year': year,
    'pages': pages,
    'publisherId': publisherId,
    'authorIds': authorIds,
    'genreIds': genreIds,
    'copiesTotal': copiesTotal,
    'copiesAvailable': copiesAvailable,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Book.fromJson(Map<String, dynamic> json) {
    // Разбор publisherId: число или вложенный объект publisher
    int pubId = 0;
    if (json['publisherId'] is int) {
      pubId = json['publisherId'] as int;
    } else if (json['publisher'] is Map) {
      pubId = (json['publisher'] as Map)['id'] as int? ?? 0;
    }

    // Разбор authorIds: массив чисел или массив объектов authors
    List<int> authIds = [];
    if (json['authorIds'] is List) {
      authIds = (json['authorIds'] as List)
          .map((e) => e is int ? e : ((e is Map) ? e['id'] as int? ?? 0 : 0))
          .where((id) => id > 0)
          .toList();
    } else if (json['authors'] is List) {
      authIds = (json['authors'] as List)
          .map((e) => (e is Map) ? e['id'] as int? ?? 0 : 0)
          .where((id) => id > 0)
          .toList();
    }

    // Разбор genreIds: массив чисел или массив объектов genres
    List<int> genIds = [];
    if (json['genreIds'] is List) {
      genIds = (json['genreIds'] as List)
          .map((e) => e is int ? e : ((e is Map) ? e['id'] as int? ?? 0 : 0))
          .where((id) => id > 0)
          .toList();
    } else if (json['genres'] is List) {
      genIds = (json['genres'] as List)
          .map((e) => (e is Map) ? e['id'] as int? ?? 0 : 0)
          .where((id) => id > 0)
          .toList();
    }

    return Book(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      isbn: json['isbn'] as String? ?? '',
      year: json['year'] as int? ?? 0,
      pages: json['pages'] as int? ?? 0,
      publisherId: pubId,
      authorIds: authIds,
      genreIds: genIds,
      copiesTotal: json['copiesTotal'] as int? ?? 0,
      copiesAvailable: json['copiesAvailable'] as int? ?? 0,
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.tryParse(json['deletedAt'] as String),
    );
  }
}
