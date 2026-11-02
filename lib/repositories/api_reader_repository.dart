import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../models/page_result.dart';
import '../models/reader.dart';
import '../models/reader_query.dart';
import 'reader_repository.dart';

class ApiReaderRepository implements ReaderRepository {
  final Dio _dio;
  CancelToken? _activeFindToken;

  ApiReaderRepository(this._dio);

  @override
  Future<PageResult<Reader>> find(ReaderQuery q) => guard(() async {
    _activeFindToken?.cancel('Отменён новым запросом');
    _activeFindToken = CancelToken();

    final response = await _dio.get(
      '/readers',
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
        if (item is Map<String, dynamic>) Reader.fromJson(item),
    ];

    return PageResult<Reader>(
      items: items,
      page: data['page'] as int? ?? 1,
      size: data['size'] as int? ?? q.size,
      total: data['total'] as int? ?? 0,
    );
  });

  @override
  Future<Reader?> findById(int id) => guard(() async {
    final response = await _dio.get('/readers/$id');
    if (response.data == null) return null;
    return Reader.fromJson(response.data as Map<String, dynamic>);
  });

  @override
  Future<Reader> create(Reader reader) => guard(() async {
    final response = await _dio.post('/readers', data: reader.toJson());
    return Reader.fromJson(response.data as Map<String, dynamic>);
  });

  @override
  Future<Reader> update(Reader reader) => guard(() async {
    final response = await _dio.put(
      '/readers/${reader.id}',
      data: reader.toJson(),
    );
    return Reader.fromJson(response.data as Map<String, dynamic>);
  });

  @override
  Future<void> softDelete(int id) => guard(() => _dio.delete('/readers/$id'));

  @override
  Future<void> hardDelete(int id) =>
      guard(() => _dio.delete('/readers/$id', queryParameters: {'hard': true}));

  @override
  Future<void> restore(int id) =>
      guard(() => _dio.post('/readers/$id/restore'));

  @override
  Future<int> deleteMany(List<int> ids) => guard(() async {
    final response = await _dio.post(
      '/readers/bulk-delete',
      data: {'ids': ids},
    );
    return (response.data as Map<String, dynamic>)['deleted'] as int? ?? 0;
  });
}
