import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/core/auth/auth_controller.dart';
import 'package:casca_app/core/errors/api_error_message.dart';
import 'package:casca_app/core/layout/page_padding.dart';
import 'package:casca_app/core/routing/app_routes.dart';
import 'package:casca_app/core/routing/unsaved_changes.dart';
import 'package:casca_app/features/price_lists/data/models/price_list_model.dart';
import 'package:casca_app/features/price_lists/presentation/providers/price_editor_provider.dart';
import 'package:casca_app/features/price_lists/presentation/providers/price_list_providers.dart';
import 'package:casca_app/features/price_lists/presentation/widgets/price_list_detail_skeleton.dart';
import 'package:casca_app/features/price_lists/presentation/widgets/price_list_modals.dart';
import 'package:casca_app/shared/formatters/number_formatters.dart';
import 'package:casca_app/shared/ui/casca_action_menu.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_filter_bar.dart';
import 'package:casca_app/shared/ui/casca_icon.dart';
import 'package:casca_app/shared/ui/casca_input.dart';
import 'package:casca_app/shared/ui/casca_modal.dart';
import 'package:casca_app/shared/ui/casca_page_header.dart';
import 'package:casca_app/shared/ui/casca_table.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

const double _menuSize = 44;
const int _nameFlex = 3;
const int _priceFlex = 2;

class PriceListDetailPage extends ConsumerStatefulWidget {
  const PriceListDetailPage({super.key, required this.priceListId});

  final String priceListId;

  @override
  ConsumerState<PriceListDetailPage> createState() =>
      _PriceListDetailPageState();
}

class _PriceListDetailPageState extends ConsumerState<PriceListDetailPage> {
  late final UnsavedChanges _unsavedChanges;
  bool _deleted = false;

  String get _id => widget.priceListId;

  bool _hasUnsavedChanges() {
    return !_deleted && ref.read(priceEditorProvider(_id)).pending.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _unsavedChanges = ref.read(unsavedChangesProvider)
      ..watch(_hasUnsavedChanges);
  }

  @override
  void dispose() {
    _unsavedChanges.release(_hasUnsavedChanges);
    super.dispose();
  }

  void _back() => context.go(AppRoutes.priceLists);

  Future<void> _rename(PriceListModel list) {
    return showCascaModal<PriceListModel>(
      context: context,
      size: CascaModalSize.sm,
      builder: (_) => PriceListNameModal(priceList: list),
    );
  }

  Future<void> _delete(PriceListModel list) async {
    final deleted = await showCascaModal<bool>(
      context: context,
      size: CascaModalSize.sm,
      builder: (_) => PriceListDeleteModal(priceList: list),
    );
    if ((deleted ?? false) && mounted) {
      _deleted = true;
      _back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: _content(context),
    );
  }

  Widget _content(BuildContext context) {
    final detail = ref.watch(priceListProvider(_id));
    final editor = ref.watch(priceEditorProvider(_id));
    final items = ref.watch(priceItemsProvider);
    final query = ref.watch(priceItemsQueryProvider);
    final session = ref.watch(authControllerProvider.select((s) => s.session));
    final canEdit = session?.hasPermission('pricelist.update') ?? false;
    final canDelete = session?.hasPermission('pricelist.delete') ?? false;
    final list = detail.value;
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;

    if (list == null) {
      final error = detail.error;
      if (error == null) {
        return const PriceListDetailSkeleton();
      }
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: CascaSpacing.space3,
          children: [
            Text(
              apiErrorMessage(error, 'No fue posible obtener la lista.'),
              textAlign: TextAlign.center,
            ),
            CascaButton(
              label: 'Reintentar',
              variant: CascaButtonVariant.secondary,
              onPressed: () => ref.invalidate(priceListProvider(_id)),
            ),
            CascaButton(
              label: 'Volver a las listas',
              variant: CascaButtonVariant.text,
              onPressed: _back,
            ),
          ],
        ),
      );
    }

    final saved = editor.saved;
    final pending = editor.pending.length;
    final saveError = editor.saveError;
    final itemsError = items.error;
    final failure = itemsError ?? (saved == null ? editor.loadError : null);

    final columns = <CascaTableColumn<PriceListItemModel>>[
      CascaTableColumn(
        id: 'product',
        header: 'Producto',
        flex: _nameFlex,
        showOnCompact: true,
        cellBuilder: (context, item) => CascaTableTwoLineCell(
          title: item.displayName,
          subtitle: [
            if (editor.pending.containsKey(item.sellableItemId)) 'Sin guardar',
            'Público ${formatMoney(item.price)}',
            if (item.sku.isNotEmpty) item.sku,
          ].join(' · '),
        ),
      ),
      CascaTableColumn(
        id: 'listPrice',
        header: 'Precio en esta lista',
        flex: _priceFlex,
        showOnCompact: true,
        cellBuilder: (context, item) => _PriceCell(
          key: ValueKey('list-price-${item.sellableItemId}'),
          label: 'Precio de ${item.displayName} en ${list.name}',
          value: editor.pending.containsKey(item.sellableItemId)
              ? editor.pending[item.sellableItemId]
              : saved?[item.sellableItemId],
          enabled: canEdit && !editor.saving,
          onChanged: (price) => ref
              .read(priceEditorProvider(_id).notifier)
              .setPrice(item.sellableItemId, price),
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: pagePadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: CascaSpacing.space4,
              children: [
                CascaPageHeader(
                  title: list.name,
                  subtitle: 'Escribe el precio solo en los productos que cambian. Si lo dejas vacío, se vende al precio público.',
                  action: canEdit || canDelete
                      ? CascaActionMenu(
                          semanticLabel: 'Acciones de la lista',
                          sections: [
                            CascaActionMenuSection(
                              items: [
                                if (canEdit)
                                  CascaActionMenuItem(
                                    id: 'rename',
                                    label: 'Renombrar',
                                    icon: CascaIcons.pencilSimple,
                                    onSelected: () => _rename(list),
                                  ),
                                if (canDelete)
                                  CascaActionMenuItem(
                                    id: 'delete',
                                    label: 'Eliminar',
                                    icon: CascaIcons.trash,
                                    danger: true,
                                    onSelected: () => _delete(list),
                                  ),
                              ],
                            ),
                          ],
                          child: SizedBox.square(
                            dimension: _menuSize,
                            child: Center(
                              child: CascaIcon(
                                CascaIcons.dotsThree,
                                size: CascaSpacing.space6,
                                color: colors.textSecondary,
                              ),
                            ),
                          ),
                        )
                      : null,
                ),
                CascaFilterBar(
                  searchHint: 'Buscar por nombre, SKU o código de barras',
                  onSearchChanged: ref
                      .read(priceItemsQueryProvider.notifier)
                      .setSearch,
                ),
                CascaTable<PriceListItemModel>(
                  columns: columns,
                  rows: saved == null
                      ? const []
                      : items.value?.items ?? const [],
                  rowKey: (item) => item.sellableItemId,
                  loading: items.isLoading || saved == null,
                  errorMessage: failure == null
                      ? null
                      : apiErrorMessage(
                          failure,
                          'No fue posible obtener los productos y sus precios.',
                        ),
                  onRetry: () {
                    ref.invalidate(priceItemsProvider);
                    ref.read(priceEditorProvider(_id).notifier).load();
                  },
                  emptyTitle: 'No hay productos.',
                  page: query.page,
                  pageSize: priceItemsPageSize,
                  totalItems: items.value?.totalCount,
                  onPageChanged: ref
                      .read(priceItemsQueryProvider.notifier)
                      .setPage,
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(
            CascaSpacing.space4,
            CascaSpacing.space3,
            CascaSpacing.space4,
            CascaSpacing.space3 + MediaQuery.paddingOf(context).bottom,
          ),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(top: BorderSide(color: colors.border)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: CascaSpacing.space2,
            children: [
              if (saveError != null)
                Text(
                  apiErrorMessage(
                    saveError,
                    'No fue posible guardar los precios.',
                    forbidden: 'No tienes permiso para editar esta lista.',
                  ),
                  textAlign: TextAlign.end,
                  style: textTheme.bodyMedium?.copyWith(color: colors.danger),
                ),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: CascaSpacing.space3,
                runSpacing: CascaSpacing.space2,
                children: [
                  CascaButton(
                    label: 'Volver',
                    variant: CascaButtonVariant.secondary,
                    onPressed: editor.saving ? null : _back,
                  ),
                  if (pending > 0)
                    CascaButton(
                      label: 'Descartar',
                      variant: CascaButtonVariant.text,
                      onPressed: editor.saving
                          ? null
                          : ref.read(priceEditorProvider(_id).notifier).discard,
                    ),
                  if (canEdit)
                    CascaButton(
                      label: pending > 0
                          ? 'Guardar cambios ($pending)'
                          : 'Guardar cambios',
                      loading: editor.saving,
                      onPressed: pending == 0
                          ? null
                          : ref.read(priceEditorProvider(_id).notifier).save,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PriceCell extends StatefulWidget {
  const _PriceCell({
    super.key,
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final double? value;
  final bool enabled;
  final ValueChanged<double?> onChanged;

  @override
  State<_PriceCell> createState() => _PriceCellState();
}

class _PriceCellState extends State<_PriceCell> {
  late final _controller = TextEditingController(text: _format(widget.value));
  bool _focused = false;

  static String _format(double? value) {
    return value == null ? '' : formatQuantity(value).replaceAll(',', '');
  }

  void _sync() {
    if (double.tryParse(_controller.text) != widget.value) {
      _controller.text = _format(widget.value);
    }
  }

  @override
  void didUpdateWidget(_PriceCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_focused) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_focused) _sync();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (focused) {
        _focused = focused;
        if (!focused) _sync();
      },
      child: Semantics(
        label: widget.label,
        child: CascaInput(
          controller: _controller,
          enabled: widget.enabled,
          hintText: 'Público',
          prefixText: r'$',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.next,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          onChanged: (text) => widget.onChanged(double.tryParse(text)),
        ),
      ),
    );
  }
}
