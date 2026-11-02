import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/breakpoints.dart';
import '../models/reader.dart';
import '../models/reader_query.dart';
import '../state/reader_list_notifier.dart';
import '../widgets/debounced_search_field.dart';
import '../widgets/entity_card_list.dart';
import '../widgets/entity_table.dart';
import '../widgets/pagination_bar.dart';

class ReaderListScreen extends StatefulWidget {
  final ReaderQuery initialQuery;

  const ReaderListScreen({super.key, required this.initialQuery});

  @override
  State<ReaderListScreen> createState() => _ReaderListScreenState();
}

class _ReaderListScreenState extends State<ReaderListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReaderListNotifier>().applyQuery(widget.initialQuery);
    });
  }

  void _pushQuery(ReaderQuery q) {
    context.read<ReaderListNotifier>().applyQuery(q);
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ReaderListNotifier>();
    final q = notifier.query;
    final isCompact = screenSizeOf(context) == ScreenSize.compact;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Читатели библиотеки'),
        actions: [
          FilledButton.icon(
            icon: const Icon(Icons.person_add),
            label: const Text('Новый читатель'),
            onPressed: () => context.go('/readers/new'),
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
                    hintText: 'Поиск по ФИО, Email, билету...',
                    initialValue: q.search,
                    onChanged: (val) => _pushQuery(q.copyWith(search: val)),
                  ),
                ),
                FilterChip(
                  label: const Text('Включая удалённых'),
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
                const Center(child: Text('Читатели не найдены')),
              LoadStatus.success =>
                isCompact
                    ? EntityCardList<Reader>(
                        items: notifier.result.items,
                        idOf: (r) => r.id,
                        selected: notifier.selected,
                        onToggleSelect: notifier.toggleSelection,
                        titleBuilder: (ctx, r) => Text(
                          r.fullName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            decoration: r.isDeleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        subtitleBuilder: (ctx, r) => Text(
                          'Email: ${r.email}\nБилет: ${r.card.cardNumber} (${r.card.isActive ? 'Активен' : 'Заблокирован'})',
                        ),
                        actions: (r) => [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () =>
                                context.go('/readers/${r.id}/edit'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => notifier.softDelete(r.id),
                          ),
                        ],
                      )
                    : EntityTable<Reader>(
                        items: notifier.result.items,
                        idOf: (r) => r.id,
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
                            label: 'ФИО читателя',
                            sortField: 'fullName',
                            build: (r) => Text(
                              r.fullName,
                              style: TextStyle(
                                decoration: r.isDeleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                          TableColumnSpec(
                            label: 'Email',
                            sortField: 'email',
                            build: (r) => Text(r.email),
                          ),
                          TableColumnSpec(
                            label: 'Телефон',
                            build: (r) => Text(r.phone),
                          ),
                          TableColumnSpec(
                            label: 'Читательский билет (1-к-1)',
                            build: (r) => Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(r.card.cardNumber),
                                const SizedBox(width: 8),
                                Icon(
                                  r.card.isActive
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  size: 16,
                                  color: r.card.isActive
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ],
                            ),
                          ),
                        ],
                        actions: (r) => [
                          IconButton(
                            tooltip: 'Карточка читателя',
                            icon: const Icon(Icons.info_outline),
                            onPressed: () => context.go('/readers/${r.id}'),
                          ),
                          IconButton(
                            tooltip: 'Редактировать',
                            icon: const Icon(Icons.edit),
                            onPressed: () =>
                                context.go('/readers/${r.id}/edit'),
                          ),
                          if (r.isDeleted)
                            IconButton(
                              tooltip: 'Восстановить',
                              icon: const Icon(
                                Icons.restore_from_trash,
                                color: Colors.green,
                              ),
                              onPressed: () => notifier.restore(r.id),
                            )
                          else
                            IconButton(
                              tooltip: 'Удалить',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => notifier.softDelete(r.id),
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
