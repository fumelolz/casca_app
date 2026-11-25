import 'package:material_ui/material_ui.dart';

enum CascaTableAlign { start, center, end }

enum CascaSortDirection { asc, desc }

class CascaTableSort {
  const CascaTableSort(this.columnId, this.direction);

  final String columnId;
  final CascaSortDirection direction;
}

class CascaTableColumn<T> {
  const CascaTableColumn({
    required this.id,
    required this.header,
    required this.cellBuilder,
    this.flex = 1,
    this.width,
    this.align = CascaTableAlign.start,
    this.sortable = false,
    this.showOnCompact = false,
  });

  final String id;
  final String header;
  final Widget Function(BuildContext context, T row) cellBuilder;
  final int flex;
  final double? width;
  final CascaTableAlign align;
  final bool sortable;
  final bool showOnCompact;
}

class CascaTableRowAction<T> {
  const CascaTableRowAction({
    required this.label,
    required this.onSelected,
    this.icon,
    this.danger = false,
  });

  final String label;
  final void Function(T row) onSelected;
  final String? icon;
  final bool danger;
}

class CascaTableBulkAction {
  const CascaTableBulkAction({
    required this.label,
    required this.onPressed,
    this.icon,
    this.danger = false,
  });

  final String label;
  final VoidCallback onPressed;
  final String? icon;
  final bool danger;
}
