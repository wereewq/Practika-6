import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/genre.dart';
import '../models/genre_query.dart';
import '../models/page_result.dart';
import 'genre_repository.dart';
import 'seed_data.dart';

class PersistentGenreRepository implements GenreRepository {
  static const _key = 'genres_v1';
  final SharedPreferences _prefs;
  List<Genre> _genres = [];
  int _nextId = 1;

  PersistentGenreRepository(this._prefs) {
    _restore();
  }

  void _restore() {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      _genres = [...seedGenres];
      _persist();
    } else {
      try {
        final list = jsonDecode(raw) as List;
        _genres = list
            .map((e) => Genre.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        _genres = [...seedGenres];
        _persist();
      }
    }
    _nextId =
        (_genres.map((g) => g.id).fold(0, (max, id) => id > max ? id : max)) +
        1;
  }

  Future<void> _persist() async {
    await _prefs.setString(
      _key,
      jsonEncode(_genres.map((g) => g.toJson()).toList()),
    );
  }

  @override
  Future<List<Genre>> findAll() async {
    return _genres.where((g) => !g.isDeleted).toList();
  }

  @override
  Future<PageResult<Genre>> find(GenreQuery q) async {
    await Future.delayed(const Duration(milliseconds: 100));
    var rows = _genres.where((g) => q.includeDeleted || !g.isDeleted).toList();

    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where(
            (g) =>
                g.name.toLowerCase().contains(needle) ||
                g.description.toLowerCase().contains(needle),
          )
          .toList();
    }

    rows.sort((a, b) {
      final result = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      return q.sortAscending ? result : -result;
    });

    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <Genre>[] : rows.sublist(from, to);

    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<Genre?> findById(int id) async {
    final index = _genres.indexWhere((g) => g.id == id);
    if (index == -1) return null;
    return _genres[index];
  }

  @override
  Future<Genre> create(Genre genre) async {
    final created = Genre(
      id: _nextId++,
      name: genre.name,
      description: genre.description,
    );
    _genres.add(created);
    await _persist();
    return created;
  }

  @override
  Future<Genre> update(Genre genre) async {
    final index = _genres.indexWhere((g) => g.id == genre.id);
    if (index == -1) throw StateError('Жанр ${genre.id} не найден');
    _genres[index] = genre;
    await _persist();
    return genre;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _genres.indexWhere((g) => g.id == id);
    if (i == -1) throw StateError('Жанр $id не найден');
    _genres[i] = _genres[i].copyWith(deletedAt: DateTime.now());
    await _persist();
  }

  @override
  Future<void> hardDelete(int id) async {
    _genres.removeWhere((g) => g.id == id);
    await _persist();
  }

  @override
  Future<void> restore(int id) async {
    final i = _genres.indexWhere((g) => g.id == id);
    if (i == -1) throw StateError('Жанр $id не найден');
    _genres[i] = _genres[i].copyWith(clearDeletedAt: true);
    await _persist();
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = _genres.indexWhere((g) => g.id == id && !g.isDeleted);
      if (i != -1) {
        _genres[i] = _genres[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    await _persist();
    return count;
  }
}
