import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/breakpoints.dart';
import '../models/publisher.dart';
import '../models/publisher_query.dart';
import '../state/publisher_list_notifier.dart';
import '../widgets/debounced_search_field.dart';
import '../widgets/entity_card_list.dart';
import '../widgets/entity_table.dart';
import '../widgets/pagination_bar.dart';

class PublisherListScreen extends StatefulWidget {
  final PublisherQuery initialQuery;

  const PublisherListScreen({super.key, required this.initialQuery});

  @override
  State<PublisherListScreen> createState() => _PublisherListScreenState();
}

class _PublisherListScreenState extends State<PublisherListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PublisherListNotifier>().applyQuery(widget.initialQuery);
    });
  }

  void _pushQuery(PublisherQuery q) {
    context.read<PublisherListNotifier>().applyQuery(q);
  }

  Future<void> _handleDelete(
    Publisher p,
    PublisherListNotifier notifier,
  ) async {
    final error = await notifier.softDelete(p.id);
    if (error != null && mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
            size: 48,
          ),
          title: const Text('Отказ в удалении'),
          content: Text(error),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Понятно'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<PublisherListNotifier>();
    final q = notifier.query;
    final isCompact = screenSizeOf(context) == ScreenSize.compact;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Издательства'),
        actions: [
          FilledButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Добавить издательство'),
            onPressed: () => context.go('/publishers/new'),
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
                    hintText: 'Поиск по названию или городу...',
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
                const Center(child: Text('Издательства не найдены')),
              LoadStatus.success =>
                isCompact
                    ? EntityCardList<Publisher>(
                        items: notifier.result.items,
                        idOf: (p) => p.id,
                        selected: notifier.selected,
                        onToggleSelect: notifier.toggleSelection,
                        titleBuilder: (ctx, p) => Text(
                          p.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            decoration: p.isDeleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        subtitleBuilder: (ctx, p) =>
                            Text('Город: ${p.city} | Сайт: ${p.website}'),
                        actions: (p) => [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () =>
                                context.go('/publishers/${p.id}/edit'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _handleDelete(p, notifier),
                          ),
                        ],
                      )
                    : EntityTable<Publisher>(
                        items: notifier.result.items,
                        idOf: (p) => p.id,
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
                            build: (p) => Text(
                              p.name,
                              style: TextStyle(
                                decoration: p.isDeleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                          TableColumnSpec(
                            label: 'Город',
                            sortField: 'city',
                            build: (p) => Text(p.city),
                          ),
                          TableColumnSpec(
                            label: 'Веб-сайт',
                            build: (p) => Text(p.website),
                          ),
                        ],
                        actions: (p) => [
                          IconButton(
                            tooltip: 'Подробнее',
                            icon: const Icon(Icons.info_outline),
                            onPressed: () => context.go('/publishers/${p.id}'),
                          ),
                          IconButton(
                            tooltip: 'Редактировать',
                            icon: const Icon(Icons.edit),
                            onPressed: () =>
                                context.go('/publishers/${p.id}/edit'),
                          ),
                          if (p.isDeleted)
                            IconButton(
                              tooltip: 'Восстановить',
                              icon: const Icon(
                                Icons.restore_from_trash,
                                color: Colors.green,
                              ),
                              onPressed: () => notifier.restore(p.id),
                            )
                          else
                            IconButton(
                              tooltip: 'Удалить',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _handleDelete(p, notifier),
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
