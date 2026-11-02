import 'package:flutter/foundation.dart';
import '../models/author.dart';
import '../models/author_query.dart';
import '../models/page_result.dart';
import '../repositories/author_repository.dart';

enum LoadStatus { idle, loading, success, error }

class AuthorListNotifier extends ChangeNotifier {
  final AuthorRepository _repository;
  bool _disposed = false;

  AuthorListNotifier(this._repository);

  AuthorQuery _query = const AuthorQuery();
  PageResult<Author> _result = PageResult.empty();
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  final Set<int> _selected = {};

  AuthorQuery get query => _query;
  PageResult<Author> get result => _result;
  LoadStatus get status => _status;
  String? get error => _error;
  Set<int> get selected => Set.unmodifiable(_selected);
  bool get hasSelection => _selected.isNotEmpty;
  bool get isAllSelected =>
      _result.items.isNotEmpty &&
      _result.items.every((a) => _selected.contains(a.id));

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> load() async {
    _status = LoadStatus.loading;
    _error = null;
    _safeNotify();

    try {
      _result = await _repository.find(_query);
      _status = LoadStatus.success;
    } catch (e) {
      _error = 'Не удалось загрузить авторов: $e';
      _status = LoadStatus.error;
    }
    _safeNotify();
  }

  Future<void> applyQuery(AuthorQuery next) async {
    _query = next;
    _selected.clear();
    await load();
  }

  void toggleSelection(int id) {
    if (_selected.contains(id)) {
      _selected.remove(id);
    } else {
      _selected.add(id);
    }
    _safeNotify();
  }

  void toggleSelectAll() {
    if (isAllSelected) {
      _selected.clear();
    } else {
      for (final author in _result.items) {
        _selected.add(author.id);
      }
    }
    _safeNotify();
  }

  void clearSelection() {
    _selected.clear();
    _safeNotify();
  }

  Future<void> deleteSelected() async {
    if (_selected.isEmpty) return;
    await _repository.deleteMany(_selected.toList());
    _selected.clear();
    await load();
  }

  Future<void> softDelete(int id) async {
    await _repository.softDelete(id);
    _selected.remove(id);
    await load();
  }

  Future<void> hardDelete(int id) async {
    await _repository.hardDelete(id);
    _selected.remove(id);
    await load();
  }

  Future<void> restore(int id) async {
    await _repository.restore(id);
    await load();
  }

  Future<void> toggleIncludeDeleted(bool value) async {
    await applyQuery(_query.copyWith(includeDeleted: value));
  }
}
