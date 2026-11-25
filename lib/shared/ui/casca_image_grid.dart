import 'dart:math' as math;

import 'package:casca_app/app/theme/casca_radius.dart';
import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/core/layout/sidebar_controller.dart';
import 'package:casca_app/shared/ui/casca_action_menu.dart';
import 'package:casca_app/shared/ui/casca_icon.dart';
import 'package:casca_app/shared/ui/casca_skeleton.dart';
import 'package:material_ui/material_ui.dart';

const double _mosaicMaxWidth = 720;
const int _mosaicRows = 2;
const int _defaultMaxSecondary = 6;
const double _stripSize = 64;
const double _viewerMaxHeight = 360;
const double _emptyViewerHeight = 200;
const double _optionsSize = 44;
const double _selectedBorderWidth = 2;
const int _loadingTiles = 2;
const Duration _pageDuration = Duration(milliseconds: 250);

typedef CascaImageReorder = void Function(int oldIndex, int newIndex);

class CascaImageItem {
  const CascaImageItem({
    required this.id,
    required this.child,
    this.preview,
    this.actions = const [],
  });

  final String id;
  final Widget child;
  final Widget? preview;
  final List<CascaActionMenuItem> actions;
}

class CascaImageGrid extends StatelessWidget {
  const CascaImageGrid({
    super.key,
    required this.main,
    required this.secondary,
    required this.onAdd,
    this.onReorder,
    this.busy = false,
    this.loading = false,
    this.maxSecondary = _defaultMaxSecondary,
  });

  final int maxSecondary;
  final CascaImageItem? main;
  final List<CascaImageItem> secondary;
  final VoidCallback? onAdd;
  final CascaImageReorder? onReorder;
  final bool busy;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width <= mobileBreakpoint) {
      return _Carousel(this);
    }
    return _Mosaic(this);
  }
}

class _Mosaic extends StatelessWidget {
  const _Mosaic(this.grid);

  final CascaImageGrid grid;

  @override
  Widget build(BuildContext context) {
    const gap = CascaSpacing.space3;
    final slots = math.max(grid.maxSecondary, grid.secondary.length);
    final columns = (slots / _mosaicRows).ceil();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.min(constraints.maxWidth, _mosaicMaxWidth);
        final mainSize =
            (width - columns * gap / _mosaicRows) / (1 + columns / _mosaicRows);
        final size = (mainSize - gap) / _mosaicRows;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: gap,
          children: [
            _main(mainSize),
            Column(
              spacing: gap,
              children: [
                for (var row = 0; row < _mosaicRows; row++)
                  Row(
                    spacing: gap,
                    children: [
                      for (var column = 0; column < columns; column++)
                        _slot(context, row * columns + column, size),
                    ],
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _main(double size) {
    final main = grid.main;
    if (main != null) {
      return _ImageTile(
        item: main,
        size: size,
        badge: 'Principal',
        large: true,
      );
    }
    return _AddTile(
      width: size,
      height: size,
      label: 'Agregar foto',
      busy: grid.busy,
      onTap: grid.busy ? null : grid.onAdd,
    );
  }

  Widget _slot(BuildContext context, int index, double size) {
    if (index < grid.secondary.length) {
      final item = grid.secondary[index];
      return _Reorderable(
        key: ValueKey(item.id),
        index: index,
        size: size,
        preview: item.child,
        onReorder: grid.busy ? null : grid.onReorder,
        child: _ImageTile(item: item, size: size),
      );
    }
    if (grid.loading) {
      return CascaSkeleton(
        width: size,
        height: size,
        borderRadius: CascaRadius.md,
      );
    }
    final addsHere =
        index == grid.secondary.length &&
        grid.main != null &&
        grid.onAdd != null;
    if (addsHere) {
      return _AddTile(
        width: size,
        height: size,
        label: 'Agregar imagen',
        showLabel: false,
        busy: grid.busy,
        onTap: grid.busy ? null : grid.onAdd,
      );
    }
    return Container(
      key: ValueKey('image-slot-empty-$index'),
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: CascaRadius.md,
        border: Border.all(color: context.casca.border),
      ),
    );
  }
}

class _Carousel extends StatefulWidget {
  const _Carousel(this.grid);

  final CascaImageGrid grid;

  @override
  State<_Carousel> createState() => _CarouselState();
}

class _CarouselState extends State<_Carousel> {
  final _pages = PageController();
  final _strip = ScrollController();
  int _index = 0;

  static List<CascaImageItem> _itemsOf(CascaImageGrid grid) {
    final main = grid.main;
    return [?main, ...grid.secondary];
  }

  @override
  void didUpdateWidget(_Carousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final before = [for (final item in _itemsOf(oldWidget.grid)) item.id];
    final after = [for (final item in _itemsOf(widget.grid)) item.id];
    if (after.isEmpty) {
      _index = 0;
      return;
    }

    final galleryArrived = oldWidget.grid.loading;
    final added = galleryArrived
        ? -1
        : after.indexWhere((id) => !before.contains(id));
    final followed = _index < before.length
        ? after.indexOf(before[_index])
        : -1;
    final target = added >= 0
        ? added
        : followed >= 0
        ? followed
        : math.min(_index, after.length - 1);
    if (target == _index) return;

    _index = target;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_pages.hasClients) _pages.jumpToPage(_index);
      _revealThumbnail();
    });
  }

  @override
  void dispose() {
    _pages.dispose();
    _strip.dispose();
    super.dispose();
  }

  void _show(int index) {
    if (MediaQuery.disableAnimationsOf(context)) {
      _pages.jumpToPage(index);
      return;
    }
    _pages.animateToPage(index, duration: _pageDuration, curve: Curves.ease);
  }

  void _onPageChanged(int index) {
    setState(() => _index = index);
    _revealThumbnail();
  }

  void _revealThumbnail() {
    if (!_strip.hasClients) return;
    final position = _strip.position;
    const step = _stripSize + CascaSpacing.space3;
    final centered =
        _index * step - (position.viewportDimension - _stripSize) / 2;
    _strip.jumpTo(centered.clamp(0, position.maxScrollExtent));
  }

  @override
  Widget build(BuildContext context) {
    final grid = widget.grid;
    final add = grid.busy ? null : grid.onAdd;
    final items = _itemsOf(grid);

    if (items.isEmpty) {
      return _AddTile(
        width: double.infinity,
        height: _emptyViewerHeight,
        label: 'Agregar foto',
        busy: grid.busy,
        onTap: add,
      );
    }

    final index = math.min(_index, items.length - 1);
    final offset = items.length - grid.secondary.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _viewer(context, items, index),
        const SizedBox(height: CascaSpacing.space3),
        SingleChildScrollView(
          controller: _strip,
          scrollDirection: Axis.horizontal,
          child: Row(
            spacing: CascaSpacing.space3,
            children: [
              if (offset > 0) _thumbnail(items, 0, index),
              for (final (position, item) in grid.secondary.indexed)
                _Reorderable(
                  key: ValueKey(item.id),
                  index: position,
                  size: _stripSize,
                  preview: item.child,
                  onReorder: grid.busy ? null : grid.onReorder,
                  child: _thumbnail(items, position + offset, index),
                ),
              if (grid.loading)
                for (var i = 0; i < _loadingTiles; i++)
                  const CascaSkeleton(
                    width: _stripSize,
                    height: _stripSize,
                    borderRadius: CascaRadius.md,
                  ),
              if (grid.onAdd != null && !grid.loading)
                _AddTile(
                  width: _stripSize,
                  height: _stripSize,
                  label: 'Agregar imagen',
                  showLabel: false,
                  busy: grid.busy,
                  onTap: add,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _viewer(BuildContext context, List<CascaImageItem> items, int index) {
    final colors = context.casca;
    final current = items[index];

    return LayoutBuilder(
      builder: (context, constraints) => Container(
        key: const Key('image-viewer'),
        height: math.min(constraints.maxWidth, _viewerMaxHeight),
        decoration: BoxDecoration(
          color: colors.backgroundHover,
          borderRadius: CascaRadius.lg,
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: CascaRadius.lg,
          border: Border.all(color: colors.border),
        ),
        child: ClipRRect(
          borderRadius: CascaRadius.lg,
          child: Stack(
            fit: StackFit.expand,
            children: [
              PageView(
                controller: _pages,
                onPageChanged: _onPageChanged,
                children: [
                  for (final item in items)
                    KeyedSubtree(
                      key: ValueKey(item.id),
                      child: item.preview ?? item.child,
                    ),
                ],
              ),
              if (index == 0 && widget.grid.main != null)
                const Positioned(
                  left: CascaSpacing.space3,
                  top: CascaSpacing.space3,
                  child: _Label('Principal'),
                ),
              if (items.length > 1)
                Positioned(
                  right: CascaSpacing.space3,
                  bottom: CascaSpacing.space3,
                  child: _Label('${index + 1} / ${items.length}'),
                ),
              if (current.actions.isNotEmpty)
                Positioned(
                  right: CascaSpacing.space2,
                  top: CascaSpacing.space2,
                  child: CascaActionMenu(
                    key: ValueKey('options-${current.id}'),
                    semanticLabel: 'Opciones de la imagen',
                    sections: [CascaActionMenuSection(items: current.actions)],
                    child: const _OptionsButton(),
                  ),
                ),
              if (widget.grid.busy)
                const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumbnail(List<CascaImageItem> items, int position, int selected) {
    final colors = context.casca;
    final isSelected = position == selected;

    return Semantics(
      button: true,
      selected: isSelected,
      label: 'Ver imagen ${position + 1}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _show(position),
        child: Container(
          width: _stripSize,
          height: _stripSize,
          decoration: BoxDecoration(
            color: colors.backgroundHover,
            borderRadius: CascaRadius.md,
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: CascaRadius.md,
            border: Border.all(
              color: isSelected ? colors.primary : colors.border,
              width: isSelected ? _selectedBorderWidth : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: CascaRadius.md,
            child: items[position].child,
          ),
        ),
      ),
    );
  }
}

class _Reorderable extends StatelessWidget {
  const _Reorderable({
    super.key,
    required this.index,
    required this.size,
    required this.preview,
    required this.onReorder,
    required this.child,
  });

  final int index;
  final double size;
  final Widget preview;
  final CascaImageReorder? onReorder;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reorder = onReorder;
    if (reorder == null) return child;

    return DragTarget<int>(
      onWillAcceptWithDetails: (details) => details.data != index,
      onAcceptWithDetails: (details) => reorder(details.data, index),
      builder: (context, candidates, rejected) => LongPressDraggable<int>(
        data: index,
        feedback: Opacity(
          opacity: 0.85,
          child: SizedBox.square(
            dimension: size,
            child: ClipRRect(borderRadius: CascaRadius.md, child: preview),
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.4, child: child),
        child: Opacity(opacity: candidates.isEmpty ? 1 : 0.6, child: child),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: CascaSpacing.space2),
      decoration: BoxDecoration(
        color: context.casca.surface,
        borderRadius: CascaRadius.sm,
      ),
      child: Text(text, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

class _OptionsButton extends StatelessWidget {
  const _OptionsButton();

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;

    return Container(
      width: _optionsSize,
      height: _optionsSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.surface,
        border: Border.all(color: colors.border),
      ),
      child: CascaIcon(
        CascaIcons.dotsThree,
        size: CascaSpacing.space5,
        color: colors.text,
      ),
    );
  }
}

class _ImageTile extends StatelessWidget {
  const _ImageTile({
    required this.item,
    required this.size,
    this.badge,
    this.large = false,
  });

  final CascaImageItem item;
  final double size;
  final String? badge;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final label = badge;

    final image = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.backgroundHover,
        borderRadius: CascaRadius.md,
        border: Border.all(color: colors.border),
      ),
      child: ClipRRect(
        borderRadius: CascaRadius.md,
        child: Stack(
          fit: StackFit.expand,
          children: [
            large ? item.preview ?? item.child : item.child,
            if (label != null)
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.all(CascaSpacing.space2),
                  child: _Label(label),
                ),
              ),
          ],
        ),
      ),
    );

    if (item.actions.isEmpty) return image;
    return CascaActionMenu(
      semanticLabel: 'Opciones de la imagen',
      sections: [CascaActionMenuSection(items: item.actions)],
      child: image,
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({
    required this.width,
    required this.height,
    required this.label,
    required this.busy,
    required this.onTap,
    this.showLabel = true,
  });

  final double width;
  final double height;
  final String label;
  final bool busy;
  final VoidCallback? onTap;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;

    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            width: width,
            height: height,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.backgroundHover,
              borderRadius: CascaRadius.md,
              border: Border.all(color: colors.border),
            ),
            child: busy
                ? const CircularProgressIndicator()
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CascaIcon(
                        CascaIcons.plus,
                        size: CascaSpacing.space5,
                        color: colors.textSecondary,
                      ),
                      if (showLabel) ...[
                        const SizedBox(height: CascaSpacing.space1),
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
