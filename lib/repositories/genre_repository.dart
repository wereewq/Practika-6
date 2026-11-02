import '../models/genre.dart';
import '../models/genre_query.dart';
import '../models/page_result.dart';

abstract interface class GenreRepository {
  Future<PageResult<Genre>> find(GenreQuery query);
  Future<List<Genre>> findAll();
  Future<Genre?> findById(int id);
  Future<Genre> create(Genre genre);
  Future<Genre> update(Genre genre);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
}
