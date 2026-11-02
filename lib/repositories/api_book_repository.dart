import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../models/book.dart';
import '../models/book_query.dart';
import '../models/page_result.dart';
import 'book_repository.dart';

class ApiBookRepository implements BookRepository {
  final Dio _dio;
  CancelToken? _activeFindToken;

  ApiBookRepository(this._dio);

  @override
  Future<PageResult<Book>> find(BookQuery q) => guard(() async {
    _activeFindToken?.cancel('Отменён новым запросом');
    _activeFindToken = CancelToken();

    final response = await _dio.get(
      '/books',
      queryParameters: {
        if (q.search.trim().isNotEmpty) 'search': q.search.trim(),
        if (q.genreId != null) 'genreId': q.genreId,
        if (q.publisherId != null) 'publisherId': q.publisherId,
        if (q.yearFrom != null) 'yearFrom': q.yearFrom,
        if (q.yearTo != null) 'yearTo': q.yearTo,
        'sort': '${q.sortField},${q.sortAscending ? 'asc' : 'desc'}',
        'page': q.page,
        'size': q.size,
        if (q.includeDeleted) 'includeDeleted': true,
      },
      cancelToken: _activeFindToken,
    );

    final data = response.data as Map<String, dynamic>;
    final rawList = data['items'] as List? ?? const [];
    final items = [
      for (final item in rawList)
        if (item is Map<String, dynamic>) Book.fromJson(item),
    ];

    return PageResult<Book>(
      items: items,
      page: data['page'] as int? ?? 1,
      size: data['size'] as int? ?? q.size,
      total: data['total'] as int? ?? 0,
    );
  });

  @override
  Future<List<Book>> findAll() => guard(() async {
    final response = await _dio.get('/books', queryParameters: {'size': 1000});
    final data = response.data as Map<String, dynamic>;
    final rawList = data['items'] as List? ?? const [];
    return [
      for (final item in rawList)
        if (item is Map<String, dynamic>) Book.fromJson(item),
    ];
  });

  @override
  Future<Book?> findById(int id) => guard(() async {
    final response = await _dio.get('/books/$id');
    if (response.data == null) return null;
    return Book.fromJson(response.data as Map<String, dynamic>);
  });

  @override
  Future<Book> create(Book book) => guard(() async {
    final response = await _dio.post(
      '/books',
      data: {
        'title': book.title,
        'isbn': book.isbn,
        'year': book.year,
        'pages': book.pages,
        'publisherId': book.publisherId,
        'authorIds': book.authorIds,
        'genreIds': book.genreIds,
        'copiesTotal': book.copiesTotal,
        'copiesAvailable': book.copiesAvailable,
      },
    );
    return Book.fromJson(response.data as Map<String, dynamic>);
  });

  @override
  Future<Book> update(Book book) => guard(() async {
    final response = await _dio.put(
      '/books/${book.id}',
      data: {
        'title': book.title,
        'isbn': book.isbn,
        'year': book.year,
        'pages': book.pages,
        'publisherId': book.publisherId,
        'authorIds': book.authorIds,
        'genreIds': book.genreIds,
        'copiesTotal': book.copiesTotal,
        'copiesAvailable': book.copiesAvailable,
      },
    );
    return Book.fromJson(response.data as Map<String, dynamic>);
  });

  @override
  Future<void> softDelete(int id) => guard(() => _dio.delete('/books/$id'));

  @override
  Future<void> hardDelete(int id) =>
      guard(() => _dio.delete('/books/$id', queryParameters: {'hard': true}));

  @override
  Future<void> restore(int id) => guard(() => _dio.post('/books/$id/restore'));

  @override
  Future<int> deleteMany(List<int> ids) => guard(() async {
    final response = await _dio.post('/books/bulk-delete', data: {'ids': ids});
    return (response.data as Map<String, dynamic>)['deleted'] as int? ?? 0;
  });
}
