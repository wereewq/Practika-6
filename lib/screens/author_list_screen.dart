// lib/screens/author_list_screen.dar
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/breakpoints.dart';
import '../core/router.dart';
import '../models/author.dart';
import '../models/author_query.dart';
import '../state/author_list_notifier.dart';
import '../widgets/debounced_search_field.dart';
import '../widgets/entity_card_list.dart';
import '../widgets/entity_table.dart';
import '../widgets/pagination_bar.dart';

class AuthorListScreen extends StatefulWidget {
  final AuthorQuery initialQuery;

  const AuthorListScreen({super.key, required this.initialQuery});

  @override
  State<AuthorListScreen> createState() => _AuthorListScreenState();
}

class _AuthorListScreenState extends State<AuthorListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthorListNotifier>().applyQuery(widget.initialQuery);
    });
  }

  @override
  void didUpdateWidget(covariant AuthorListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialQuery != widget.initialQuery) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<AuthorListNotifier>().applyQuery(widget.initialQuery);
      });
    }
  }

  void _pushQuery(AuthorQuery nextQuery) {
    final params = authorQueryToParams(nextQuery);
    final uri = Uri(
      path: '/authors',
      queryParameters: params.isEmpty ? null : params,
    );
    context.go(uri.toString());
  }

  Future<void> _confirmDeleteSelected(
    BuildContext context,
    AuthorListNotifier notifier,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удаление авторов'),
        content: Text(
          'Удалить выбранных авторов (${notifier.selected.length} чел.)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await notifier.deleteSelected();
    }
  }

  Future<void> _confirmHardDelete(
    BuildContext context,
    AuthorListNotifier notifier,
    Author a,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Физическое удаление'),
        content: Text(
          'Автор «${a.fullName}» будет стёрт навсегда. Продолжить?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Стереть'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await notifier.hardDelete(a.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<AuthorListNotifier>();
    final q = notifier.query;
    final isCompact = screenSizeOf(context) == ScreenSize.compact;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Каталог авторов'),
        actions: [
          if (notifier.hasSelection) ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('Выбрано: ${notifier.selected.length}'),
              ),
            ),
            IconButton(
              tooltip: 'Удалить выбранные',
              icon: const Icon(Icons.delete_sweep),
              onPressed: () => _confirmDeleteSelected(context, notifier),
            ),
            IconButton(
              tooltip: 'Снять выделение',
              icon: const Icon(Icons.close),
              onPressed: notifier.clearSelection,
            ),
          ],
          FilledButton.icon(
            icon: const Icon(Icons.person_add),
            label: const Text('Новый автор'),
            onPressed: () => context.go('/authors/new'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 250,
                  child: DebouncedSearchField(
                    hintText: 'Поиск по фамилии, имени, стране...',
                    initialValue: q.search,
                    onChanged: (val) => _pushQuery(q.copyWith(search: val)),
                  ),
                ),
                SizedBox(
                  width: 190,
                  child: DropdownButtonFormField<String?>(
                    isExpanded: true,
                    initialValue: q.country,
                    decoration: const InputDecoration(
                      labelText: 'Страна',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: null,
                        child: Text(
                          'Все страны',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Россия',
                        child: Text('Россия', overflow: TextOverflow.ellipsis),
                      ),
                      DropdownMenuItem(
                        value: 'Великобритания',
                        child: Text(
                          'Великобритания',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Германия',
                        child: Text(
                          'Германия',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'США',
                        child: Text('США', overflow: TextOverflow.ellipsis),
                      ),
                      DropdownMenuItem(
                        value: 'Франция',
                        child: Text('Франция', overflow: TextOverflow.ellipsis),
                      ),
                      DropdownMenuItem(
                        value: 'Колумбия',
                        child: Text(
                          'Колумбия',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Австро-Венгрия',
                        child: Text(
                          'Австро-Венгрия',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    onChanged: (val) => _pushQuery(q.copyWith(country: val)),
                  ),
                ),
                FilterChip(
                  label: const Text('Включая удалённых'),
                  selected: q.includeDeleted,
                  onSelected: (val) =>
                      _pushQuery(q.copyWith(includeDeleted: val)),
                ),
                if (q.search.isNotEmpty || q.country != null)
                  TextButton.icon(
                    icon: const Icon(Icons.filter_alt_off),
                    label: const Text('Сбросить'),
                    onPressed: () => _pushQuery(const AuthorQuery()),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: switch (notifier.status) {
              LoadStatus.idle || LoadStatus.loading => const Center(
                child: CircularProgressIndicator(),
              ),
              LoadStatus.error => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 8),
                    Text(notifier.error ?? 'Произошла ошибка'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: notifier.load,
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              ),
              LoadStatus.success when notifier.result.items.isEmpty => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_off, size: 48, color: Colors.grey),
                    const SizedBox(height: 8),
                    const Text('Авторов по заданным критериям не найдено'),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => _pushQuery(const AuthorQuery()),
                      child: const Text('Очистить фильтры'),
                    ),
                  ],
                ),
              ),
              LoadStatus.success =>
                isCompact
                    ? EntityCardList<Author>(
                        items: notifier.result.items,
                        idOf: (a) => a.id,
                        selected: notifier.selected,
                        onToggleSelect: notifier.toggleSelection,
                        titleBuilder: (ctx, a) => Row(
                          children: [
                            Expanded(
                              child: Text(
                                a.fullName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  decoration: a.isDeleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                            if (a.isDeleted)
                              const Chip(
                                label: Text(
                                  'Удалён',
                                  style: TextStyle(fontSize: 10),
                                ),
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                          ],
                        ),
                        subtitleBuilder: (ctx, a) => Text(
                          'Страна: ${a.country} | Год рожд.: ${a.birthYear}',
                        ),
                        actions: (a) =>
                            _buildAuthorActions(context, notifier, a),
                      )
                    : EntityTable<Author>(
                        items: notifier.result.items,
                        idOf: (a) => a.id,
                        selected: notifier.selected,
                        onToggleSelect: notifier.toggleSelection,
                        onToggleSelectAll: notifier.toggleSelectAll,
                        isAllSelected: notifier.isAllSelected,
                        sortField: q.sortField,
                        sortAscending: q.sortAscending,
                        onSort: (field) {
                          final asc = field == q.sortField
                              ? !q.sortAscending
                              : true;
                          _pushQuery(
                            q.copyWith(sortField: field, sortAscending: asc),
                          );
                        },
                        columns: [
                          TableColumnSpec(
                            label: 'Фамилия',
                            sortField: 'lastName',
                            build: (a) => Text(
                              a.lastName,
                              style: TextStyle(
                                decoration: a.isDeleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                          TableColumnSpec(
                            label: 'Имя',
                            build: (a) => Text(a.firstName),
                          ),
                          TableColumnSpec(
                            label: 'Страна',
                            sortField: 'country',
                            build: (a) => Text(a.country),
                          ),
                          TableColumnSpec(
                            label: 'Год рождения',
                            sortField: 'birthYear',
                            numeric: true,
                            build: (a) => Text('${a.birthYear}'),
                          ),
                        ],
                        actions: (a) =>
                            _buildAuthorActions(context, notifier, a),
                      ),
            },
          ),
          PaginationBar(
            page: notifier.result.page,
            size: notifier.result.size,
            total: notifier.result.total,
            onPageChanged: (newPage) => _pushQuery(q.copyWith(page: newPage)),
            onSizeChanged: (newSize) =>
                _pushQuery(q.copyWith(size: newSize, page: 1)),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAuthorActions(
    BuildContext context,
    AuthorListNotifier notifier,
    Author a,
  ) {
    return [
      IconButton(
        tooltip: 'Карточка автора',
        icon: const Icon(Icons.info_outline),
        onPressed: () => context.go('/authors/${a.id}'),
      ),
      if (a.isDeleted) ...[
        IconButton(
          tooltip: 'Восстановить',
          icon: const Icon(Icons.restore_from_trash, color: Colors.green),
          onPressed: () => notifier.restore(a.id),
        ),
        IconButton(
          tooltip: 'Стереть навсегда',
          icon: const Icon(Icons.delete_forever, color: Colors.red),
          onPressed: () => _confirmHardDelete(context, notifier, a),
        ),
      ] else
        IconButton(
          tooltip: 'В корзину (мягкое удаление)',
          icon: const Icon(Icons.delete_outline),
          onPressed: () => notifier.softDelete(a.id),
        ),
    ];
  }
}
