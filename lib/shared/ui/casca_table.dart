import 'package:casca_app/app/theme/casca_radius.dart';
import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/app/theme/casca_typography.dart';
import 'package:casca_app/shared/ui/casca_action_menu.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_checkbox.dart';
import 'package:casca_app/shared/ui/casca_icon.dart';
import 'package:casca_app/shared/ui/casca_skeleton.dart';
import 'package:casca_app/shared/ui/casca_table_bulk_bar.dart';
import 'package:casca_app/shared/ui/casca_table_footer.dart';
import 'package:casca_app/shared/ui/casca_table_models.dart';
import 'package:material_ui/material_ui.dart';

export 'package:casca_app/shared/ui/casca_table_models.dart';

const double cascaTableCompactBreakpoint = 640;
const double _selectionCellWidth = 48;
const double _actionsCellWidth = 88;
const double _headerHeight = 44;
const double _rowMinHeight = 56;
const double _skeletonBarHeight = 12;
const int _skeletonRows = 5;

class CascaTable<T> extends StatelessWidget {
  const CascaTable({
    super.key,
    required this.columns,
    required this.rows,
    required this.rowKey,
    this.loading = false,
    this.errorMessage,
    this.onRetry,
    this.emptyTitle = 'Sin registros',
    this.emptyMessage,
    this.selectedKeys,
    this.onSelectionChanged,
    this.sort,
    this.onSortChanged,
    this.rowActions = const [],
    this.bulkActions = const [],
    this.onRowTap,
    this.page = 1,
    this.pageSize = 10,
    this.totalItems,
    this.onPageChanged,
  });

  final List<CascaTableColumn<T>> columns;
  final List<T> rows;
  final String Function(T row) rowKey;
  final bool loading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final String emptyTitle;
  final String? emptyMessage;
  final Set<String>? selectedKeys;
  final ValueChanged<Set<String>>? onSelectionChanged;
  final CascaTableSort? sort;
  final ValueChanged<CascaTableSort?>? onSortChanged;
  final List<CascaTableRowAction<T>> rowActions;
  final List<CascaTableBulkAction> bulkActions;
  final void Function(T row)? onRowTap;
  final int page;
  final int pageSize;
  final int? totalItems;
  final ValueChanged<int>? onPageChanged;

  bool get _selectable => selectedKeys != null && onSelectionChanged != null;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < cascaTableCompactBreakpoint;
        final visible = compact
            ? columns.where((column) => column.showOnCompact).toList()
            : columns;
        final selected = selectedKeys ?? const <String>{};
        final showBulkBar =
            _selectable && selected.isNotEmpty && bulkActions.isNotEmpty;

        return DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: CascaRadius.md,
            border: Border.all(color: colors.border),
          ),
          child: ClipRRect(
            borderRadius: CascaRadius.md,
            child: Material(
              type: MaterialType.transparency,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header(context, visible),
                  Stack(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: showBulkBar
                              ? cascaTableBulkBarHeight +
                                    CascaSpacing.space3 * 2
                              : 0,
                        ),
                        child: _body(context, visible),
                      ),
                      if (showBulkBar)
                        Positioned(
                          left: CascaSpacing.space3,
                          right: CascaSpacing.space3,
                          bottom: CascaSpacing.space3,
                          child: CascaTableBulkBar(
                            selectedCount: selected.length,
                            actions: bulkActions,
                          ),
                        ),
                    ],
                  ),
                  CascaTableFooter(
                    selectedCount: bulkActions.isEmpty ? selected.length : 0,
                    page: page,
                    pageSize: pageSize,
                    totalItems: totalItems,
                    onPageChanged: onPageChanged,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _header(BuildContext context, List<CascaTableColumn<T>> visible) {
    final colors = context.casca;
    final selected = selectedKeys ?? const <String>{};
    final pageKeys = rows.map(rowKey).toList();
    final selectedOnPage = pageKeys.where(selected.contains).length;
    final bool? headerValue = pageKeys.isEmpty || selectedOnPage == 0
        ? false
        : (selectedOnPage == pageKeys.length ? true : null);

    return Container(
      height: _headerHeight,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: _RowFrame<T>(
        columns: visible,
        selectionCell: _selectable
            ? CascaCheckbox(
                value: headerValue,
                semanticLabel: 'Seleccionar todos',
                onChanged: pageKeys.isEmpty
                    ? null
                    : (_) => _toggleAll(pageKeys, headerValue == true),
              )
            : null,
        actionsCell: rowActions.isNotEmpty ? const _ActionsHeader() : null,
        cellFor: (column) => _HeaderCell(
          column: column,
          sort: sort,
          onTap: column.sortable && onSortChanged != null
              ? () => onSortChanged!(_nextSort(column.id))
              : null,
        ),
      ),
    );
  }

  Widget _body(BuildContext context, List<CascaTableColumn<T>> visible) {
    final error = errorMessage;
    if (error != null) {
      return _Message(
        title: error,
        action: onRetry == null
            ? null
            : CascaButton(
                label: 'Reintentar',
                variant: CascaButtonVariant.secondary,
                onPressed: onRetry,
              ),
      );
    }
    if (loading && rows.isEmpty) {
      return _Skeleton<T>(
        columns: visible,
        selectable: _selectable,
        hasActions: rowActions.isNotEmpty,
      );
    }
    if (rows.isEmpty) {
      return _Message(title: emptyTitle, message: emptyMessage);
    }

    final selected = selectedKeys ?? const <String>{};
    final list = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows.length; i++)
          _buildRow(
            context,
            visible,
            rows[i],
            selected,
            isLast: i == rows.length - 1,
          ),
      ],
    );

    if (!loading) return list;
    return IgnorePointer(child: Opacity(opacity: 0.5, child: list));
  }

  Widget _buildRow(
    BuildContext context,
    List<CascaTableColumn<T>> visible,
    T row,
    Set<String> selected, {
    required bool isLast,
  }) {
    final colors = context.casca;
    final key = rowKey(row);
    final isSelected = selected.contains(key);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isSelected ? colors.primarySoft : null,
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: colors.border)),
      ),
      child: InkWell(
        onTap: onRowTap == null ? null : () => onRowTap!(row),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _rowMinHeight),
          child: _RowFrame<T>(
            columns: visible,
            selectionCell: _selectable
                ? CascaCheckbox(
                    value: isSelected,
                    semanticLabel: 'Seleccionar fila',
                    onChanged: (_) => _toggleRow(key, isSelected),
                  )
                : null,
            actionsCell: rowActions.isNotEmpty
                ? _RowActionsMenu<T>(row: row, actions: rowActions)
                : null,
            cellFor: (column) => column.cellBuilder(context, row),
          ),
        ),
      ),
    );
  }

  void _toggleRow(String key, bool isSelected) {
    final next = {...?selectedKeys};
    isSelected ? next.remove(key) : next.add(key);
    onSelectionChanged!(next);
  }

  void _toggleAll(List<String> pageKeys, bool allSelected) {
    final next = {...?selectedKeys};
    allSelected ? next.removeAll(pageKeys) : next.addAll(pageKeys);
    onSelectionChanged!(next);
  }

  CascaTableSort? _nextSort(String columnId) {
    final current = sort;
    if (current == null || current.columnId != columnId) {
      return CascaTableSort(columnId, CascaSortDirection.asc);
    }
    return current.direction == CascaSortDirection.asc
        ? CascaTableSort(columnId, CascaSortDirection.desc)
        : null;
  }
}

class _RowFrame<T> extends StatelessWidget {
  const _RowFrame({
    required this.columns,
    required this.cellFor,
    this.selectionCell,
    this.actionsCell,
  });

  final List<CascaTableColumn<T>> columns;
  final Widget Function(CascaTableColumn<T> column) cellFor;
  final Widget? selectionCell;
  final Widget? actionsCell;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: selectionCell == null ? CascaSpacing.space4 : 0,
        right: actionsCell == null ? CascaSpacing.space4 : 0,
      ),
      child: Row(
        children: [
          if (selectionCell != null)
            SizedBox(width: _selectionCellWidth, child: selectionCell),
          for (final column in columns) _slot(column),
          if (actionsCell != null)
            SizedBox(
              width: _actionsCellWidth,
              child: Center(child: actionsCell),
            ),
        ],
      ),
    );
  }

  Widget _slot(CascaTableColumn<T> column) {
    final cell = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CascaSpacing.space2,
        vertical: CascaSpacing.space2,
      ),
      child: Align(alignment: _alignment(column.align), child: cellFor(column)),
    );
    final width = column.width;
    return width != null
        ? SizedBox(width: width, child: cell)
        : Expanded(flex: column.flex, child: cell);
  }

  static Alignment _alignment(CascaTableAlign align) {
    return switch (align) {
      CascaTableAlign.start => Alignment.centerLeft,
      CascaTableAlign.center => Alignment.center,
      CascaTableAlign.end => Alignment.centerRight,
    };
  }
}

class _HeaderCell<T> extends StatelessWidget {
  const _HeaderCell({
    required this.column,
    required this.sort,
    required this.onTap,
  });

  final CascaTableColumn<T> column;
  final CascaTableSort? sort;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final active = sort?.columnId == column.id;
    final icon = !column.sortable
        ? null
        : !active
        ? CascaIcons.arrowsDownUp
        : sort!.direction == CascaSortDirection.asc
        ? CascaIcons.sortAscending
        : CascaIcons.sortDescending;

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            column.header,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: active ? colors.text : colors.textMuted,
              fontWeight: CascaFontWeight.semibold,
            ),
          ),
        ),
        if (icon != null) ...[
          const SizedBox(width: CascaSpacing.space2),
          CascaIcon(
            icon,
            size: CascaFontSize.md,
            color: active ? colors.text : colors.textMuted,
          ),
        ],
      ],
    );

    if (onTap == null) return content;
    return Semantics(
      button: true,
      label: 'Ordenar por ${column.header}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: content,
      ),
    );
  }
}

class _ActionsHeader extends StatelessWidget {
  const _ActionsHeader();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Acciones',
      maxLines: 1,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: context.casca.textMuted,
        fontWeight: CascaFontWeight.semibold,
      ),
    );
  }
}

class _RowActionsMenu<T> extends StatelessWidget {
  const _RowActionsMenu({required this.row, required this.actions});

  final T row;
  final List<CascaTableRowAction<T>> actions;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;

    return CascaActionMenu(
      semanticLabel: 'Acciones de la fila',
      sections: [
        CascaActionMenuSection(
          items: [
            for (final action in actions)
              CascaActionMenuItem(
                id: action.label,
                label: action.label,
                icon: action.icon,
                danger: action.danger,
                onSelected: () => action.onSelected(row),
              ),
          ],
        ),
      ],
      child: SizedBox(
        width: _selectionCellWidth,
        height: _selectionCellWidth,
        child: Center(
          child: CascaIcon(
            CascaIcons.dotsThree,
            size: CascaSpacing.space5,
            color: colors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _Skeleton<T> extends StatelessWidget {
  const _Skeleton({
    required this.columns,
    required this.selectable,
    required this.hasActions,
  });

  final List<CascaTableColumn<T>> columns;
  final bool selectable;
  final bool hasActions;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Cargando',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < _skeletonRows; i++)
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: _rowMinHeight),
              child: _RowFrame<T>(
                columns: columns,
                selectionCell: selectable ? const SizedBox.shrink() : null,
                actionsCell: hasActions ? const SizedBox.shrink() : null,
                cellFor: (_) => const FractionallySizedBox(
                  widthFactor: 0.7,
                  child: CascaSkeleton(height: _skeletonBarHeight),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.title, this.message, this.action});

  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(CascaSpacing.space6),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: textTheme.titleSmall,
            ),
            if (message != null) ...[
              const SizedBox(height: CascaSpacing.space1),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(color: colors.textMuted),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: CascaSpacing.space4),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class CascaTableTwoLineCell extends StatelessWidget {
  const CascaTableTwoLineCell({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodyMedium,
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall,
          ),
      ],
    );
  }
}
