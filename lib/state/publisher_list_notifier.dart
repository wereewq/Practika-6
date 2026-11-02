import 'package:flutter/foundation.dart';
import '../core/validators.dart';
import '../models/page_result.dart';
import '../models/publisher.dart';
import '../models/publisher_query.dart';
import '../repositories/publisher_repository.dart';

enum LoadStatus { idle, loading, success, error }

class PublisherListNotifier extends ChangeNotifier {
  final PublisherRepository _repository;
  bool _disposed = false;

  PublisherListNotifier(this._repository);

  PublisherQuery _query = const PublisherQuery();
  PageResult<Publisher> _result = PageResult.empty();
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  final Set<int> _selected = {};

  PublisherQuery get query => _query;
  PageResult<Publisher> get result => _result;
  LoadStatus get status => _status;
  String? get error => _error;
  Set<int> get selected => Set.unmodifiable(_selected);
  bool get hasSelection => _selected.isNotEmpty;
  bool get isAllSelected =>
      _result.items.isNotEmpty &&
      _result.items.every((p) => _selected.contains(p.id));

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
      _error = 'Не удалось загрузить издательства: $e';
      _status = LoadStatus.error;
    }
    _safeNotify();
  }

  Future<void> applyQuery(PublisherQuery next) async {
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
      for (final pub in _result.items) {
        _selected.add(pub.id);
      }
    }
    _safeNotify();
  }

  void clearSelection() {
    _selected.clear();
    _safeNotify();
  }

  Future<String?> deleteSelected() async {
    if (_selected.isEmpty) return null;
    try {
      await _repository.deleteMany(_selected.toList());
      _selected.clear();
      await load();
      return null;
    } on CascadeDeleteException catch (e) {
      return e.message;
    } catch (e) {
      return 'Ошибка удаления: $e';
    }
  }

  Future<String?> softDelete(int id) async {
    try {
      await _repository.softDelete(id);
      _selected.remove(id);
      await load();
      return null;
    } on CascadeDeleteException catch (e) {
      return e.message;
    } catch (e) {
      return 'Ошибка удаления: $e';
    }
  }

  Future<String?> hardDelete(int id) async {
    try {
      await _repository.hardDelete(id);
      _selected.remove(id);
      await load();
      return null;
    } on CascadeDeleteException catch (e) {
      return e.message;
    } catch (e) {
      return 'Ошибка удаления: $e';
    }
  }

  Future<void> restore(int id) async {
    await _repository.restore(id);
    await load();
  }

  Future<void> toggleIncludeDeleted(bool value) async {
    await applyQuery(_query.copyWith(includeDeleted: value));
  }
}
