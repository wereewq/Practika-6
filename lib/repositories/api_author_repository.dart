import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../models/author.dart';
import '../models/author_query.dart';
import '../models/page_result.dart';
import 'author_repository.dart';

class ApiAuthorRepository implements AuthorRepository {
  final Dio _dio;
  CancelToken? _activeFindToken;
  List<Author>? _cachedAuthors;

  ApiAuthorRepository(this._dio);

  @override
  Future<PageResult<Author>> find(AuthorQuery q) => guard(() async {
    _activeFindToken?.cancel('Отменён новым запросом');
    _activeFindToken = CancelToken();

    final response = await _dio.get(
      '/authors',
      queryParameters: {
        if (q.search.trim().isNotEmpty) 'search': q.search.trim(),
        if (q.country != null && q.country!.isNotEmpty) 'country': q.country,
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
        if (item is Map<String, dynamic>) Author.fromJson(item),
    ];

    return PageResult<Author>(
      items: items,
      page: data['page'] as int? ?? 1,
      size: data['size'] as int? ?? q.size,
      total: data['total'] as int? ?? 0,
    );
  });

  @override
  Future<List<Author>> findAll() => guard(() async {
    if (_cachedAuthors != null) return _cachedAuthors!;
    final response = await _dio.get(
      '/authors',
      queryParameters: {'size': 1000},
    );
    final data = response.data as Map<String, dynamic>;
    final rawList = data['items'] as List? ?? const [];
    _cachedAuthors = [
      for (final item in rawList)
        if (item is Map<String, dynamic>) Author.fromJson(item),
    ];
    return _cachedAuthors!;
  });

  @override
  Future<Author?> findById(int id) => guard(() async {
    final response = await _dio.get('/authors/$id');
    if (response.data == null) return null;
    return Author.fromJson(response.data as Map<String, dynamic>);
  });

  @override
  Future<Author> create(Author author) => guard(() async {
    _cachedAuthors = null;
    final response = await _dio.post('/authors', data: author.toJson());
    return Author.fromJson(response.data as Map<String, dynamic>);
  });

  @override
  Future<Author> update(Author author) => guard(() async {
    _cachedAuthors = null;
    final response = await _dio.put(
      '/authors/${author.id}',
      data: author.toJson(),
    );
    return Author.fromJson(response.data as Map<String, dynamic>);
  });

  @override
  Future<void> softDelete(int id) => guard(() async {
    _cachedAuthors = null;
    await _dio.delete('/authors/$id');
  });

  @override
  Future<void> hardDelete(int id) => guard(() async {
    _cachedAuthors = null;
    await _dio.delete('/authors/$id', queryParameters: {'hard': true});
  });

  @override
  Future<void> restore(int id) => guard(() async {
    _cachedAuthors = null;
    await _dio.post('/authors/$id/restore');
  });

  @override
  Future<int> deleteMany(List<int> ids) => guard(() async {
    _cachedAuthors = null;
    final response = await _dio.post(
      '/authors/bulk-delete',
      data: {'ids': ids},
    );
    return (response.data as Map<String, dynamic>)['deleted'] as int? ?? 0;
  });
}
