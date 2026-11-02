import 'package:flutter/material.dart';

class TableColumnSpec<T> {
  final String label;
  final String? sortField;
  final bool numeric;
  final Widget Function(T item) build;

  const TableColumnSpec({
    required this.label,
    required this.build,
    this.sortField,
    this.numeric = false,
  });
}

class EntityTable<T> extends StatelessWidget {
  final List<TableColumnSpec<T>> columns;
  final List<T> items;
  final int Function(T item) idOf;
  final Set<int> selected;
  final ValueChanged<int>? onToggleSelect;
  final VoidCallback? onToggleSelectAll;
  final bool isAllSelected;
  final String? sortField;
  final bool sortAscending;
  final void Function(String field)? onSort;
  final List<Widget> Function(T item)? actions;

  const EntityTable({
    super.key,
    required this.columns,
    required this.items,
    required this.idOf,
    this.selected = const {},
    this.onToggleSelect,
    this.onToggleSelectAll,
    this.isAllSelected = false,
    this.sortField,
    this.sortAscending = true,
    this.onSort,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    // Находим индекс колонки, по которой сейчас выполняется сортировка
    int? sortColumnIndex;
    if (sortField != null) {
      final index = columns.indexWhere((c) => c.sortField == sortField);
      if (index != -1) {
        sortColumnIndex = index;
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.sizeOf(context).width,
          ),
          child: DataTable(
            sortColumnIndex: sortColumnIndex,
            sortAscending: sortAscending,
            showCheckboxColumn: onToggleSelect != null,
            onSelectAll: onToggleSelectAll != null
                ? (_) => onToggleSelectAll!()
                : null,
            columns: [
              for (final col in columns)
                DataColumn(
                  label: Text(
                    col.label,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  numeric: col.numeric,
                  onSort: (col.sortField != null && onSort != null)
                      ? (_, _) => onSort!(col.sortField!)
                      : null,
                ),
              if (actions != null)
                const DataColumn(
                  label: Text(
                    'Действия',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
            ],
            rows: [
              for (final item in items)
                DataRow(
                  selected: selected.contains(idOf(item)),
                  onSelectChanged: onToggleSelect != null
                      ? (_) => onToggleSelect!(idOf(item))
                      : null,
                  cells: [
                    for (final col in columns) DataCell(col.build(item)),
                    if (actions != null)
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: actions!(item),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
