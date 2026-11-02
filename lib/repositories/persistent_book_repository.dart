import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/validators.dart';
import '../models/book.dart';
import '../models/book_query.dart';
import '../models/page_result.dart';
import 'book_repository.dart';
import 'seed_data.dart';

class PersistentBookRepository implements BookRepository {
  static const _key = 'books_v1';
  final SharedPreferences _prefs;
  List<Book> _books = [];
  int _nextId = 1;

  PersistentBookRepository(this._prefs) {
    _restore();
  }

  void _restore() {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      _books = [...seedBooks];
      _persist();
    } else {
      try {
        final list = jsonDecode(raw) as List;
        _books = list
            .map((e) => Book.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        _books = [...seedBooks];
        _persist();
      }
    }
    _nextId =
        (_books.map((b) => b.id).fold(0, (max, id) => id > max ? id : max)) + 1;
  }

  Future<void> _persist() async {
    await _prefs.setString(
      _key,
      jsonEncode(_books.map((b) => b.toJson()).toList()),
    );
  }

  void _checkUniqueIsbn(String isbn, {int? excludeId}) {
    final normalized = isbn.replaceAll(RegExp(r'[-\s]'), '').toLowerCase();
    final duplicate = _books.any(
      (b) =>
          b.id != excludeId &&
          b.isbn.replaceAll(RegExp(r'[-\s]'), '').toLowerCase() == normalized,
    );
    if (duplicate) {
      throw const ValidationException('Ошибка валидации', {
        'isbn': 'Книга с таким ISBN уже существует',
      });
    }
  }

  @override
  Future<List<Book>> findAll() async {
    return _books.where((b) => !b.isDeleted).toList();
  }

  @override
  Future<PageResult<Book>> find(BookQuery q) async {
    await Future.delayed(const Duration(milliseconds: 100));
    var rows = _books.where((b) => q.includeDeleted || !b.isDeleted).toList();

    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where(
            (b) =>
                b.title.toLowerCase().contains(needle) ||
                b.isbn.toLowerCase().contains(needle),
          )
          .toList();
    }
    if (q.genreId != null) {
      rows = rows.where((b) => b.genreIds.contains(q.genreId)).toList();
    }
    if (q.publisherId != null) {
      rows = rows.where((b) => b.publisherId == q.publisherId).toList();
    }
    if (q.yearFrom != null) {
      rows = rows.where((b) => b.year >= q.yearFrom!).toList();
    }
    if (q.yearTo != null) {
      rows = rows.where((b) => b.year <= q.yearTo!).toList();
    }

    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'year' => a.year.compareTo(b.year),
        'pages' => a.pages.compareTo(b.pages),
        _ => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });

    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <Book>[] : rows.sublist(from, to);

    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<Book?> findById(int id) async {
    final index = _books.indexWhere((b) => b.id == id);
    if (index == -1) return null;
    return _books[index];
  }

  @override
  Future<Book> create(Book book) async {
    _checkUniqueIsbn(book.isbn);
    final newBook = book.copyWith(pages: book.pages);
    final created = Book(
      id: _nextId++,
      title: newBook.title,
      isbn: newBook.isbn,
      year: newBook.year,
      pages: newBook.pages,
      publisherId: newBook.publisherId,
      authorIds: newBook.authorIds,
      genreIds: newBook.genreIds,
      copiesTotal: newBook.copiesTotal,
      copiesAvailable: newBook.copiesAvailable,
    );
    _books.add(created);
    await _persist();
    return created;
  }

  @override
  Future<Book> update(Book book) async {
    _checkUniqueIsbn(book.isbn, excludeId: book.id);
    final index = _books.indexWhere((b) => b.id == book.id);
    if (index == -1) throw StateError('Книга ${book.id} не найдена');
    _books[index] = book;
    await _persist();
    return book;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _books.indexWhere((b) => b.id == id);
    if (i == -1) throw StateError('Книга $id не найдена');
    _books[i] = _books[i].copyWith(deletedAt: DateTime.now());
    await _persist();
  }

  @override
  Future<void> hardDelete(int id) async {
    _books.removeWhere((b) => b.id == id);
    await _persist();
  }

  @override
  Future<void> restore(int id) async {
    final i = _books.indexWhere((b) => b.id == id);
    if (i == -1) throw StateError('Книга $id не найдена');
    _books[i] = _books[i].copyWith(clearDeletedAt: true);
    await _persist();
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = _books.indexWhere((b) => b.id == id && !b.isDeleted);
      if (i != -1) {
        _books[i] = _books[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    await _persist();
    return count;
  }
}
