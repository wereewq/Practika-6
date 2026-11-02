import '../models/book.dart';
import '../models/book_query.dart';
import '../models/page_result.dart';
import 'book_repository.dart';
import 'seed_data.dart';

class InMemoryBookRepository implements BookRepository {
  final List<Book> _books = [...seedBooks];
  int _nextId = seedBooks.length + 1;

  @override
  Future<List<Book>> findAll() async {
    return _books.where((b) => !b.isDeleted).toList();
  }

  @override
  Future<PageResult<Book>> find(BookQuery q) async {
    await Future.delayed(const Duration(milliseconds: 250));

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
    await Future.delayed(const Duration(milliseconds: 150));
    final index = _books.indexWhere((b) => b.id == id);
    if (index == -1) return null;
    return _books[index];
  }

  @override
  Future<Book> create(Book book) async {
    final created = book.copyWith();
    final newBook = Book(
      id: _nextId++,
      title: created.title,
      isbn: created.isbn,
      year: created.year,
      pages: created.pages,
      publisherId: created.publisherId,
      authorIds: created.authorIds,
      genreIds: created.genreIds,
      copiesTotal: created.copiesTotal,
      copiesAvailable: created.copiesAvailable,
    );
    _books.add(newBook);
    return newBook;
  }

  @override
  Future<Book> update(Book book) async {
    final index = _books.indexWhere((b) => b.id == book.id);
    if (index == -1) throw StateError('Книга ${book.id} не найдена');
    _books[index] = book;
    return book;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _books.indexWhere((b) => b.id == id);
    if (i == -1) throw StateError('Книга $id не найдена');
    _books[i] = _books[i].copyWith(deletedAt: DateTime.now());
  }

  @override
  Future<void> hardDelete(int id) async {
    _books.removeWhere((b) => b.id == id);
  }

  @override
  Future<void> restore(int id) async {
    final i = _books.indexWhere((b) => b.id == id);
    if (i == -1) throw StateError('Книга $id не найдена');
    _books[i] = _books[i].copyWith(clearDeletedAt: true);
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
    return count;
  }
}
