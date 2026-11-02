import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/breakpoints.dart';
import '../models/genre.dart';
import '../models/genre_query.dart';
import '../state/genre_list_notifier.dart';
import '../widgets/debounced_search_field.dart';
import '../widgets/entity_card_list.dart';
import '../widgets/entity_table.dart';
import '../widgets/pagination_bar.dart';

class GenreListScreen extends StatefulWidget {
  final GenreQuery initialQuery;

  const GenreListScreen({super.key, required this.initialQuery});

  @override
  State<GenreListScreen> createState() => _GenreListScreenState();
}

class _GenreListScreenState extends State<GenreListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GenreListNotifier>().applyQuery(widget.initialQuery);
    });
  }

  void _pushQuery(GenreQuery q) {
    context.read<GenreListNotifier>().applyQuery(q);
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<GenreListNotifier>();
    final q = notifier.query;
    final isCompact = screenSizeOf(context) == ScreenSize.compact;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Жанры литературы'),
        actions: [
          FilledButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Добавить жанр'),
            onPressed: () => context.go('/genres/new'),
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
                    hintText: 'Поиск по жанрам...',
                    initialValue: q.search,
                    onChanged: (val) => _pushQuery(q.copyWith(search: val)),
                  ),
                ),
                FilterChip(
                  label: const Text('Включая удалённые'),
                  selected: q.includeDeleted,
                  onSelected: (val) =>
                      _pushQuery(q.copyWith(includeDeleted: val)),
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
                child: Text(notifier.error ?? 'Ошибка'),
              ),
              LoadStatus.success when notifier.result.items.isEmpty =>
                const Center(child: Text('Жанры не найдены')),
              LoadStatus.success =>
                isCompact
                    ? EntityCardList<Genre>(
                        items: notifier.result.items,
                        idOf: (g) => g.id,
                        selected: notifier.selected,
                        onToggleSelect: notifier.toggleSelection,
                        titleBuilder: (ctx, g) => Text(
                          g.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            decoration: g.isDeleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        subtitleBuilder: (ctx, g) => Text(g.description),
                        actions: (g) => [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => context.go('/genres/${g.id}/edit'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => notifier.softDelete(g.id),
                          ),
                        ],
                      )
                    : EntityTable<Genre>(
                        items: notifier.result.items,
                        idOf: (g) => g.id,
                        selected: notifier.selected,
                        onToggleSelect: notifier.toggleSelection,
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
                            label: 'Название',
                            sortField: 'name',
                            build: (g) => Text(
                              g.name,
                              style: TextStyle(
                                decoration: g.isDeleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                          TableColumnSpec(
                            label: 'Описание',
                            build: (g) => Text(g.description),
                          ),
                        ],
                        actions: (g) => [
                          IconButton(
                            tooltip: 'Подробнее',
                            icon: const Icon(Icons.info_outline),
                            onPressed: () => context.go('/genres/${g.id}'),
                          ),
                          IconButton(
                            tooltip: 'Редактировать',
                            icon: const Icon(Icons.edit),
                            onPressed: () => context.go('/genres/${g.id}/edit'),
                          ),
                          if (g.isDeleted)
                            IconButton(
                              tooltip: 'Восстановить',
                              icon: const Icon(
                                Icons.restore_from_trash,
                                color: Colors.green,
                              ),
                              onPressed: () => notifier.restore(g.id),
                            )
                          else
                            IconButton(
                              tooltip: 'Удалить',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => notifier.softDelete(g.id),
                            ),
                        ],
                      ),
            },
          ),
          PaginationBar(
            page: notifier.result.page,
            size: notifier.result.size,
            total: notifier.result.total,
            onPageChanged: (p) => _pushQuery(q.copyWith(page: p)),
            onSizeChanged: (s) => _pushQuery(q.copyWith(size: s, page: 1)),
          ),
        ],
      ),
    );
  }
}
