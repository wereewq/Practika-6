import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/breakpoints.dart';
import '../core/router.dart';
import '../models/book.dart';
import '../models/book_query.dart';
import '../state/book_list_notifier.dart';
import '../widgets/debounced_search_field.dart';
import '../widgets/entity_card_list.dart';
import '../widgets/entity_table.dart';
import '../widgets/pagination_bar.dart';

class BookListScreen extends StatefulWidget {
  final BookQuery initialQuery;

  const BookListScreen({super.key, required this.initialQuery});

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookListNotifier>().applyQuery(widget.initialQuery);
    });
  }

  @override
  void didUpdateWidget(covariant BookListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialQuery != widget.initialQuery) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<BookListNotifier>().applyQuery(widget.initialQuery);
      });
    }
  }

  void _pushQuery(BookQuery nextQuery) {
    final params = bookQueryToParams(nextQuery);
    final uri = Uri(
      path: '/books',
      queryParameters: params.isEmpty ? null : params,
    );
    context.go(uri.toString());
  }

  Future<void> _confirmDeleteSelected(
    BuildContext context,
    BookListNotifier notifier,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удаление записей'),
        content: Text(
          'Удалить выбранные книги (${notifier.selected.length} шт.)?',
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
    BookListNotifier notifier,
    Book book,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Физическое удаление'),
        content: Text(
          'Книга «${book.title}» будет стёрта из памяти навсегда. Продолжить?',
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
      await notifier.hardDelete(book.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<BookListNotifier>();
    final q = notifier.query;
    final isCompact = screenSizeOf(context) == ScreenSize.compact;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Каталог книг'),
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
            icon: const Icon(Icons.add),
            label: const Text('Новая книга'),
            onPressed: () => context.go('/books/new'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          // Панель фильтров
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 240,
                  child: DebouncedSearchField(
                    hintText: 'Поиск по названию, ISBN...',
                    initialValue: q.search,
                    onChanged: (val) => _pushQuery(q.copyWith(search: val)),
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<int?>(
                    isExpanded: true,
                    initialValue: q.genreId,
                    decoration: const InputDecoration(
                      labelText: 'Жанр',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: null,
                        child: Text(
                          'Все жанры',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DropdownMenuItem(
                        value: 1,
                        child: Text(
                          'Роман / Проза',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DropdownMenuItem(
                        value: 2,
                        child: Text(
                          'Детектив',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DropdownMenuItem(
                        value: 3,
                        child: Text(
                          'Антиутопия / Фантастика',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DropdownMenuItem(
                        value: 4,
                        child: Text(
                          'Философская притча',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    onChanged: (val) => _pushQuery(q.copyWith(genreId: val)),
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<int?>(
                    isExpanded: true,
                    initialValue: q.publisherId,
                    decoration: const InputDecoration(
                      labelText: 'Издательство',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: null,
                        child: Text(
                          'Все издательства',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DropdownMenuItem(
                        value: 1,
                        child: Text('Азбука', overflow: TextOverflow.ellipsis),
                      ),
                      DropdownMenuItem(
                        value: 2,
                        child: Text('АСТ', overflow: TextOverflow.ellipsis),
                      ),
                      DropdownMenuItem(
                        value: 3,
                        child: Text('Эксмо', overflow: TextOverflow.ellipsis),
                      ),
                    ],
                    onChanged: (val) =>
                        _pushQuery(q.copyWith(publisherId: val)),
                  ),
                ),
                SizedBox(
                  width: 110,
                  child: TextFormField(
                    initialValue: q.yearFrom?.toString() ?? '',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Год от',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onFieldSubmitted: (v) =>
                        _pushQuery(q.copyWith(yearFrom: int.tryParse(v))),
                  ),
                ),
                SizedBox(
                  width: 110,
                  child: TextFormField(
                    initialValue: q.yearTo?.toString() ?? '',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Год до',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onFieldSubmitted: (v) =>
                        _pushQuery(q.copyWith(yearTo: int.tryParse(v))),
                  ),
                ),
                FilterChip(
                  label: const Text('Включая удалённые'),
                  selected: q.includeDeleted,
                  onSelected: (val) =>
                      _pushQuery(q.copyWith(includeDeleted: val)),
                ),
                if (q.search.isNotEmpty ||
                    q.genreId != null ||
                    q.publisherId != null ||
                    q.yearFrom != null ||
                    q.yearTo != null)
                  TextButton.icon(
                    icon: const Icon(Icons.filter_alt_off),
                    label: const Text('Сбросить'),
                    onPressed: () => _pushQuery(const BookQuery()),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Обработка 4 состояний
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
                    const Icon(Icons.search_off, size: 48, color: Colors.grey),
                    const SizedBox(height: 8),
                    const Text('Книг по заданным критериям не найдено'),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => _pushQuery(const BookQuery()),
                      child: const Text('Очистить фильтры'),
                    ),
                  ],
                ),
              ),
              LoadStatus.success =>
                isCompact
                    ? EntityCardList<Book>(
                        items: notifier.result.items,
                        idOf: (b) => b.id,
                        selected: notifier.selected,
                        onToggleSelect: notifier.toggleSelection,
                        titleBuilder: (ctx, b) => Row(
                          children: [
                            Expanded(
                              child: Text(
                                b.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  decoration: b.isDeleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                            if (b.isDeleted)
                              const Chip(
                                label: Text(
                                  'Удалена',
                                  style: TextStyle(fontSize: 10),
                                ),
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                          ],
                        ),
                        subtitleBuilder: (ctx, b) => Text(
                          'ISBN: ${b.isbn} | Год: ${b.year} | Стр: ${b.pages}\nЭкз: ${b.copiesAvailable}/${b.copiesTotal}',
                        ),
                        actions: (b) => _buildActions(context, notifier, b),
                      )
                    : EntityTable<Book>(
                        items: notifier.result.items,
                        idOf: (b) => b.id,
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
                            label: 'Название',
                            sortField: 'title',
                            build: (b) => Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  b.title,
                                  style: TextStyle(
                                    decoration: b.isDeleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                                if (b.isDeleted)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 6),
                                    child: Chip(
                                      label: Text(
                                        'Удалена',
                                        style: TextStyle(fontSize: 10),
                                      ),
                                      padding: EdgeInsets.zero,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          TableColumnSpec(
                            label: 'ISBN',
                            build: (b) => Text(b.isbn),
                          ),
                          TableColumnSpec(
                            label: 'Год',
                            sortField: 'year',
                            numeric: true,
                            build: (b) => Text('${b.year}'),
                          ),
                          TableColumnSpec(
                            label: 'Страниц',
                            sortField: 'pages',
                            numeric: true,
                            build: (b) => Text('${b.pages}'),
                          ),
                          TableColumnSpec(
                            label: 'Доступно экз.',
                            numeric: true,
                            build: (b) =>
                                Text('${b.copiesAvailable} / ${b.copiesTotal}'),
                          ),
                        ],
                        actions: (b) => _buildActions(context, notifier, b),
                      ),
            },
          ),

          // Панель пагинации
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

  List<Widget> _buildActions(
    BuildContext context,
    BookListNotifier notifier,
    Book b,
  ) {
    return [
      IconButton(
        tooltip: 'Карточка книги',
        icon: const Icon(Icons.info_outline),
        onPressed: () => context.go('/books/${b.id}'),
      ),
      if (b.isDeleted) ...[
        IconButton(
          tooltip: 'Восстановить',
          icon: const Icon(Icons.restore_from_trash, color: Colors.green),
          onPressed: () => notifier.restore(b.id),
        ),
        IconButton(
          tooltip: 'Стереть навсегда',
          icon: const Icon(Icons.delete_forever, color: Colors.red),
          onPressed: () => _confirmHardDelete(context, notifier, b),
        ),
        IconButton(
          tooltip: 'Редактировать',
          icon: const Icon(Icons.edit),
          onPressed: () => context.go('/books/${b.id}/edit'),
        ),
      ] else
        IconButton(
          tooltip: 'В корзину (мягкое удаление)',
          icon: const Icon(Icons.delete_outline),
          onPressed: () => notifier.softDelete(b.id),
        ),
    ];
  }
}
