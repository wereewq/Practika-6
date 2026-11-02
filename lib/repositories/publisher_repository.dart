import '../models/page_result.dart';
import '../models/publisher.dart';
import '../models/publisher_query.dart';

abstract interface class PublisherRepository {
  Future<PageResult<Publisher>> find(PublisherQuery query);
  Future<List<Publisher>> findAll();
  Future<Publisher?> findById(int id);
  Future<Publisher> create(Publisher publisher);
  Future<Publisher> update(Publisher publisher);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
}
