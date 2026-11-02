import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../models/page_result.dart';
import '../models/publisher.dart';
import '../models/publisher_query.dart';
import 'publisher_repository.dart';

class ApiPublisherRepository implements PublisherRepository {
  final Dio _dio;
  CancelToken? _activeFindToken;
  List<Publisher>? _cachedPublishers;

  ApiPublisherRepository(this._dio);

  @override
  Future<PageResult<Publisher>> find(PublisherQuery q) => guard(() async {
    _activeFindToken?.cancel('Отменён новым запросом');
    _activeFindToken = CancelToken();

    final response = await _dio.get(
      '/publishers',
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
        if (item is Map<String, dynamic>) Publisher.fromJson(item),
    ];

    return PageResult<Publisher>(
      items: items,
      page: data['page'] as int? ?? 1,
      size: data['size'] as int? ?? q.size,
      total: data['total'] as int? ?? 0,
    );
  });

  @override
  Future<List<Publisher>> findAll() => guard(() async {
    if (_cachedPublishers != null) return _cachedPublishers!;
    final response = await _dio.get(
      '/publishers',
      queryParameters: {'size': 1000},
    );
    final data = response.data as Map<String, dynamic>;
    final rawList = data['items'] as List? ?? const [];
    _cachedPublishers = [
      for (final item in rawList)
        if (item is Map<String, dynamic>) Publisher.fromJson(item),
    ];
    return _cachedPublishers!;
  });

  @override
  Future<Publisher?> findById(int id) => guard(() async {
    final response = await _dio.get('/publishers/$id');
    if (response.data == null) return null;
    return Publisher.fromJson(response.data as Map<String, dynamic>);
  });

  @override
  Future<Publisher> create(Publisher publisher) => guard(() async {
    _cachedPublishers = null;
    final response = await _dio.post('/publishers', data: publisher.toJson());
    return Publisher.fromJson(response.data as Map<String, dynamic>);
  });

  @override
  Future<Publisher> update(Publisher publisher) => guard(() async {
    _cachedPublishers = null;
    final response = await _dio.put(
      '/publishers/${publisher.id}',
      data: publisher.toJson(),
    );
    return Publisher.fromJson(response.data as Map<String, dynamic>);
  });

  @override
  Future<void> softDelete(int id) => guard(() async {
    _cachedPublishers = null;
    await _dio.delete('/publishers/$id');
  });

  @override
  Future<void> hardDelete(int id) => guard(() async {
    _cachedPublishers = null;
    await _dio.delete('/publishers/$id', queryParameters: {'hard': true});
  });

  @override
  Future<void> restore(int id) => guard(() async {
    _cachedPublishers = null;
    await _dio.post('/publishers/$id/restore');
  });

  @override
  Future<int> deleteMany(List<int> ids) => guard(() async {
    _cachedPublishers = null;
    final response = await _dio.post(
      '/publishers/bulk-delete',
      data: {'ids': ids},
    );
    return (response.data as Map<String, dynamic>)['deleted'] as int? ?? 0;
  });
}
