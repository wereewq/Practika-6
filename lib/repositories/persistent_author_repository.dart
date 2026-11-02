import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/author.dart';
import '../models/author_query.dart';
import '../models/page_result.dart';
import 'author_repository.dart';
import 'seed_data.dart';

class PersistentAuthorRepository implements AuthorRepository {
  static const _key = 'authors_v1';
  final SharedPreferences _prefs;
  List<Author> _authors = [];
  int _nextId = 1;

  PersistentAuthorRepository(this._prefs) {
    _restore();
  }

  void _restore() {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      _authors = [...seedAuthors];
      _persist();
    } else {
      try {
        final list = jsonDecode(raw) as List;
        _authors = list
            .map((e) => Author.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        _authors = [...seedAuthors];
        _persist();
      }
    }
    _nextId =
        (_authors.map((a) => a.id).fold(0, (max, id) => id > max ? id : max)) +
        1;
  }

  Future<void> _persist() async {
    await _prefs.setString(
      _key,
      jsonEncode(_authors.map((a) => a.toJson()).toList()),
    );
  }

  @override
  Future<List<Author>> findAll() async {
    return _authors.where((a) => !a.isDeleted).toList();
  }

  @override
  Future<PageResult<Author>> find(AuthorQuery q) async {
    await Future.delayed(const Duration(milliseconds: 100));
    var rows = _authors.where((a) => q.includeDeleted || !a.isDeleted).toList();

    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where(
            (a) =>
                a.lastName.toLowerCase().contains(needle) ||
                a.firstName.toLowerCase().contains(needle) ||
                a.country.toLowerCase().contains(needle),
          )
          .toList();
    }
    if (q.country != null && q.country!.isNotEmpty) {
      rows = rows.where((a) => a.country == q.country).toList();
    }

    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'birthYear' => a.birthYear.compareTo(b.birthYear),
        'country' => a.country.toLowerCase().compareTo(b.country.toLowerCase()),
        _ => a.lastName.toLowerCase().compareTo(b.lastName.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });

    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <Author>[] : rows.sublist(from, to);

    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<Author?> findById(int id) async {
    final index = _authors.indexWhere((a) => a.id == id);
    if (index == -1) return null;
    return _authors[index];
  }

  @override
  Future<Author> create(Author author) async {
    final created = Author(
      id: _nextId++,
      firstName: author.firstName,
      lastName: author.lastName,
      country: author.country,
      birthYear: author.birthYear,
    );
    _authors.add(created);
    await _persist();
    return created;
  }

  @override
  Future<Author> update(Author author) async {
    final index = _authors.indexWhere((a) => a.id == author.id);
    if (index == -1) throw StateError('Автор ${author.id} не найден');
    _authors[index] = author;
    await _persist();
    return author;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _authors.indexWhere((a) => a.id == id);
    if (i == -1) throw StateError('Автор $id не найден');
    _authors[i] = _authors[i].copyWith(deletedAt: DateTime.now());
    await _persist();
  }

  @override
  Future<void> hardDelete(int id) async {
    _authors.removeWhere((a) => a.id == id);
    await _persist();
  }

  @override
  Future<void> restore(int id) async {
    final i = _authors.indexWhere((a) => a.id == id);
    if (i == -1) throw StateError('Автор $id не найден');
    _authors[i] = _authors[i].copyWith(clearDeletedAt: true);
    await _persist();
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = _authors.indexWhere((a) => a.id == id && !a.isDeleted);
      if (i != -1) {
        _authors[i] = _authors[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    await _persist();
    return count;
  }
}
