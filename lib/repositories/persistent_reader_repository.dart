import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/validators.dart';
import '../models/page_result.dart';
import '../models/reader.dart';
import '../models/reader_query.dart';
import 'reader_repository.dart';
import 'seed_data.dart';

class PersistentReaderRepository implements ReaderRepository {
  static const _key = 'readers_v1';
  final SharedPreferences _prefs;
  List<Reader> _readers = [];
  int _nextId = 1;

  PersistentReaderRepository(this._prefs) {
    _restore();
  }

  void _restore() {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      _readers = [...seedReaders];
      _persist();
    } else {
      try {
        final list = jsonDecode(raw) as List;
        _readers = list
            .map((e) => Reader.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        _readers = [...seedReaders];
        _persist();
      }
    }
    _nextId =
        (_readers.map((r) => r.id).fold(0, (max, id) => id > max ? id : max)) +
        1;
  }

  Future<void> _persist() async {
    await _prefs.setString(
      _key,
      jsonEncode(_readers.map((r) => r.toJson()).toList()),
    );
  }

  void _checkUniqueEmail(String email, {int? excludeId}) {
    final normalized = email.trim().toLowerCase();
    final duplicate = _readers.any(
      (r) => r.id != excludeId && r.email.trim().toLowerCase() == normalized,
    );
    if (duplicate) {
      throw const ValidationException('Ошибка валидации', {
        'email': 'Читатель с таким адресом почты уже зарегистрирован',
      });
    }
  }

  @override
  Future<PageResult<Reader>> find(ReaderQuery q) async {
    await Future.delayed(const Duration(milliseconds: 100));
    var rows = _readers.where((r) => q.includeDeleted || !r.isDeleted).toList();

    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where(
            (r) =>
                r.fullName.toLowerCase().contains(needle) ||
                r.email.toLowerCase().contains(needle) ||
                r.card.cardNumber.toLowerCase().contains(needle),
          )
          .toList();
    }

    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'email' => a.email.toLowerCase().compareTo(b.email.toLowerCase()),
        _ => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });

    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <Reader>[] : rows.sublist(from, to);

    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<Reader?> findById(int id) async {
    final index = _readers.indexWhere((r) => r.id == id);
    if (index == -1) return null;
    return _readers[index];
  }

  @override
  Future<Reader> create(Reader reader) async {
    _checkUniqueEmail(reader.email);
    final created = Reader(
      id: _nextId++,
      fullName: reader.fullName,
      email: reader.email,
      phone: reader.phone,
      card: reader.card,
    );
    _readers.add(created);
    await _persist();
    return created;
  }

  @override
  Future<Reader> update(Reader reader) async {
    _checkUniqueEmail(reader.email, excludeId: reader.id);
    final index = _readers.indexWhere((r) => r.id == reader.id);
    if (index == -1) throw StateError('Читатель ${reader.id} не найден');
    _readers[index] = reader;
    await _persist();
    return reader;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _readers.indexWhere((r) => r.id == id);
    if (i == -1) throw StateError('Читатель $id не найден');
    _readers[i] = _readers[i].copyWith(deletedAt: DateTime.now());
    await _persist();
  }

  @override
  Future<void> hardDelete(int id) async {
    _readers.removeWhere((r) => r.id == id);
    await _persist();
  }

  @override
  Future<void> restore(int id) async {
    final i = _readers.indexWhere((r) => r.id == id);
    if (i == -1) throw StateError('Читатель $id не найден');
    _readers[i] = _readers[i].copyWith(clearDeletedAt: true);
    await _persist();
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = _readers.indexWhere((r) => r.id == id && !r.isDeleted);
      if (i != -1) {
        _readers[i] = _readers[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    await _persist();
    return count;
  }
}
