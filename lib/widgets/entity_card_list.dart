import 'package:flutter/material.dart';

class EntityCardList<T> extends StatelessWidget {
  final List<T> items;
  final int Function(T item) idOf;
  final Set<int> selected;
  final ValueChanged<int>? onToggleSelect;
  final Widget Function(BuildContext context, T item) titleBuilder;
  final Widget Function(BuildContext context, T item)? subtitleBuilder;
  final List<Widget> Function(T item)? actions;
  final VoidCallback? onTapItem;

  const EntityCardList({
    super.key,
    required this.items,
    required this.idOf,
    required this.titleBuilder,
    this.selected = const {},
    this.onToggleSelect,
    this.subtitleBuilder,
    this.actions,
    this.onTapItem,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        final id = idOf(item);
        final isSelected = selected.contains(id);

        return Card(
          elevation: isSelected ? 3 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: isSelected
                ? BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  )
                : BorderSide(color: Theme.of(context).dividerColor),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (onToggleSelect != null)
                      Checkbox(
                        value: isSelected,
                        onChanged: (_) => onToggleSelect!(id),
                      ),
                    Expanded(child: titleBuilder(context, item)),
                  ],
                ),
                if (subtitleBuilder != null) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: EdgeInsets.only(
                      left: onToggleSelect != null ? 48.0 : 0,
                    ),
                    child: subtitleBuilder!(context, item),
                  ),
                ],
                if (actions != null) ...[
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: actions!(item),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
