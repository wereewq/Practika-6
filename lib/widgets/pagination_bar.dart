import 'package:flutter/material.dart';

class PaginationBar extends StatelessWidget {
  final int page;
  final int size;
  final int total;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onSizeChanged;

  const PaginationBar({
    super.key,
    required this.page,
    required this.size,
    required this.total,
    required this.onPageChanged,
    required this.onSizeChanged,
  });

  int get totalPages => total == 0 ? 1 : (total / size).ceil();
  bool get hasPrevious => page > 1;
  bool get hasNext => page < totalPages;

  @override
  Widget build(BuildContext context) {
    final from = total == 0 ? 0 : (page - 1) * size + 1;
    final to = (page * size) > total ? total : (page * size);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 8,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Строк на странице:'),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: size,
                isDense: true,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 10, child: Text('10')),
                  DropdownMenuItem(value: 25, child: Text('25')),
                  DropdownMenuItem(value: 50, child: Text('50')),
                ],
                onChanged: (newSize) {
                  if (newSize != null && newSize != size) {
                    onSizeChanged(newSize);
                  }
                },
              ),
              const SizedBox(width: 16),
              Text(
                '$from–$to из $total',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Первая страница',
                icon: const Icon(Icons.first_page),
                onPressed: hasPrevious ? () => onPageChanged(1) : null,
              ),
              IconButton(
                tooltip: 'Предыдущая',
                icon: const Icon(Icons.chevron_left),
                onPressed: hasPrevious ? () => onPageChanged(page - 1) : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '$page / $totalPages',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                tooltip: 'Следующая',
                icon: const Icon(Icons.chevron_right),
                onPressed: hasNext ? () => onPageChanged(page + 1) : null,
              ),
              IconButton(
                tooltip: 'Последняя страница',
                icon: const Icon(Icons.last_page),
                onPressed: hasNext ? () => onPageChanged(totalPages) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
