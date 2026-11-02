import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../models/genre.dart';
import '../models/genre_query.dart';
import '../models/page_result.dart';
import 'genre_repository.dart';

class ApiGenreRepository implements GenreRepository {
  final Dio _dio;
  CancelToken? _activeFindToken;
  List<Genre>? _cachedGenres;

  ApiGenreRepository(this._dio);

  @override
  Future<PageResult<Genre>> find(GenreQuery q) => guard(() async {
    _activeFindToken?.cancel('Отменён новым запросом');
    _activeFindToken = CancelToken();

    final response = await _dio.get(
      '/genres',
      queryParameters: {
        if (q.search.trim().isNotEmpty) 'search': q.search.trim(),
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
        if (item is Map<String, dynamic>) Genre.fromJson(item),
    ];

    return PageResult<Genre>(
      items: items,
      page: data['page'] as int? ?? 1,
      size: data['size'] as int? ?? q.size,
      total: data['total'] as int? ?? 0,
    );
  });

  @override
  Future<List<Genre>> findAll() => guard(() async {
    if (_cachedGenres != null) return _cachedGenres!;
    final response = await _dio.get('/genres', queryParameters: {'size': 1000});
    final data = response.data as Map<String, dynamic>;
    final rawList = data['items'] as List? ?? const [];
    _cachedGenres = [
      for (final item in rawList)
        if (item is Map<String, dynamic>) Genre.fromJson(item),
    ];
    return _cachedGenres!;
  });

  @override
  Future<Genre?> findById(int id) => guard(() async {
    final response = await _dio.get('/genres/$id');
    if (response.data == null) return null;
    return Genre.fromJson(response.data as Map<String, dynamic>);
  });

  @override
  Future<Genre> create(Genre genre) => guard(() async {
    _cachedGenres = null;
    final response = await _dio.post('/genres', data: genre.toJson());
    return Genre.fromJson(response.data as Map<String, dynamic>);
  });

  @override
  Future<Genre> update(Genre genre) => guard(() async {
    _cachedGenres = null;
    final response = await _dio.put(
      '/genres/${genre.id}',
      data: genre.toJson(),
    );
    return Genre.fromJson(response.data as Map<String, dynamic>);
  });

  @override
  Future<void> softDelete(int id) => guard(() async {
    _cachedGenres = null;
    await _dio.delete('/genres/$id');
  });

  @override
  Future<void> hardDelete(int id) => guard(() async {
    _cachedGenres = null;
    await _dio.delete('/genres/$id', queryParameters: {'hard': true});
  });

  @override
  Future<void> restore(int id) => guard(() async {
    _cachedGenres = null;
    await _dio.post('/genres/$id/restore');
  });

  @override
  Future<int> deleteMany(List<int> ids) => guard(() async {
    _cachedGenres = null;
    final response = await _dio.post('/genres/bulk-delete', data: {'ids': ids});
    return (response.data as Map<String, dynamic>)['deleted'] as int? ?? 0;
  });
}
