import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/validators.dart';
import '../models/page_result.dart';
import '../models/publisher.dart';
import '../models/publisher_query.dart';
import 'book_repository.dart';
import 'publisher_repository.dart';
import 'seed_data.dart';

class PersistentPublisherRepository implements PublisherRepository {
  static const _key = 'publishers_v1';
  final SharedPreferences _prefs;
  final BookRepository _bookRepository;
  List<Publisher> _publishers = [];
  int _nextId = 1;

  PersistentPublisherRepository(this._prefs, this._bookRepository) {
    _restore();
  }

  void _restore() {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      _publishers = [...seedPublishers];
      _persist();
    } else {
      try {
        final list = jsonDecode(raw) as List;
        _publishers = list
            .map((e) => Publisher.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        _publishers = [...seedPublishers];
        _persist();
      }
    }
    _nextId =
        (_publishers
            .map((p) => p.id)
            .fold(0, (max, id) => id > max ? id : max)) +
        1;
  }

  Future<void> _persist() async {
    await _prefs.setString(
      _key,
      jsonEncode(_publishers.map((p) => p.toJson()).toList()),
    );
  }

  Future<void> _assertNoLinkedBooks(int publisherId) async {
    final allBooks = await _bookRepository.findAll();
    final linkedCount = allBooks
        .where((b) => b.publisherId == publisherId)
        .length;
    if (linkedCount > 0) {
      throw CascadeDeleteException(
        'Невозможно удалить издательство: к нему привязано $linkedCount книг(и). Сначала измените или удалите связанные книги.',
        linkedCount,
      );
    }
  }

  @override
  Future<List<Publisher>> findAll() async {
    return _publishers.where((p) => !p.isDeleted).toList();
  }

  @override
  Future<PageResult<Publisher>> find(PublisherQuery q) async {
    await Future.delayed(const Duration(milliseconds: 100));
    var rows = _publishers
        .where((p) => q.includeDeleted || !p.isDeleted)
        .toList();

    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where(
            (p) =>
                p.name.toLowerCase().contains(needle) ||
                p.city.toLowerCase().contains(needle),
          )
          .toList();
    }

    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'city' => a.city.toLowerCase().compareTo(b.city.toLowerCase()),
        _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });

    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <Publisher>[] : rows.sublist(from, to);

    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<Publisher?> findById(int id) async {
    final index = _publishers.indexWhere((p) => p.id == id);
    if (index == -1) return null;
    return _publishers[index];
  }

  @override
  Future<Publisher> create(Publisher publisher) async {
    final created = Publisher(
      id: _nextId++,
      name: publisher.name,
      city: publisher.city,
      website: publisher.website,
    );
    _publishers.add(created);
    await _persist();
    return created;
  }

  @override
  Future<Publisher> update(Publisher publisher) async {
    final index = _publishers.indexWhere((p) => p.id == publisher.id);
    if (index == -1) {
      throw StateError('Издательство ${publisher.id} не найдено');
    }
    _publishers[index] = publisher;
    await _persist();
    return publisher;
  }

  @override
  Future<void> softDelete(int id) async {
    await _assertNoLinkedBooks(id);
    final i = _publishers.indexWhere((p) => p.id == id);
    if (i == -1) throw StateError('Издательство $id не найдено');
    _publishers[i] = _publishers[i].copyWith(deletedAt: DateTime.now());
    await _persist();
  }

  @override
  Future<void> hardDelete(int id) async {
    await _assertNoLinkedBooks(id);
    _publishers.removeWhere((p) => p.id == id);
    await _persist();
  }

  @override
  Future<void> restore(int id) async {
    final i = _publishers.indexWhere((p) => p.id == id);
    if (i == -1) throw StateError('Издательство $id не найдено');
    _publishers[i] = _publishers[i].copyWith(clearDeletedAt: true);
    await _persist();
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    for (final id in ids) {
      await _assertNoLinkedBooks(id);
    }
    var count = 0;
    for (final id in ids) {
      final i = _publishers.indexWhere((p) => p.id == id && !p.isDeleted);
      if (i != -1) {
        _publishers[i] = _publishers[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    await _persist();
    return count;
  }
}
