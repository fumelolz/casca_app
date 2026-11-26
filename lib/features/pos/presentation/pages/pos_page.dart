import 'package:casca_app/app/theme/casca_radius.dart';
import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/core/errors/api_error_message.dart';
import 'package:casca_app/features/pos/data/models/pos_catalog_model.dart';
import 'package:casca_app/features/pos/domain/payment_rules.dart';
import 'package:casca_app/features/pos/presentation/providers/pos_cart_provider.dart';
import 'package:casca_app/features/pos/presentation/providers/pos_catalog_provider.dart';
import 'package:casca_app/features/pos/presentation/providers/pos_sale_provider.dart';
import 'package:casca_app/features/pos/presentation/widgets/pos_cart_view.dart';
import 'package:casca_app/features/pos/presentation/widgets/pos_payment_modal.dart';
import 'package:casca_app/features/pos/presentation/widgets/pos_product_grid.dart';
import 'package:casca_app/features/pos/presentation/widgets/pos_quantity_modal.dart';
import 'package:casca_app/features/pos/presentation/widgets/pos_success_modal.dart';
import 'package:casca_app/shared/formatters/number_formatters.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_icon.dart';
import 'package:casca_app/shared/ui/casca_input.dart';
import 'package:casca_app/shared/ui/casca_modal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

const double _sidePanelBreakpoint = 840;
const double _panelWidth = 360;

class PosPage extends ConsumerStatefulWidget {
  const PosPage({super.key});

  @override
  ConsumerState<PosPage> createState() => _PosPageState();
}

class _PosPageState extends ConsumerState<PosPage> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _add(PosCatalogItemModel item) async {
    final cart = ref.read(cartProvider.notifier);
    if (!item.allowsDecimalQuantity) return cart.add(item);

    final quantity = await showCascaModal<double>(
      context: context,
      size: CascaModalSize.sm,
      builder: (_) => PosQuantityModal(item: item),
    );
    if (quantity != null && mounted) cart.add(item, quantity);
  }

  Future<void> _openCart() async {
    final checkout = await showCascaModal<bool>(
      context: context,
      builder: (sheetContext) =>
          _CartSheet(onCheckout: () => Navigator.of(sheetContext).pop(true)),
    );
    if ((checkout ?? false) && mounted) await _checkout();
  }

  Future<void> _checkout() async {
    final total = ref.read(cartProvider).payableTotal;
    if (total == null) return;
    ref.read(saleProvider.notifier).reset();

    final completed = await showCascaModal<CompletedSale>(
      context: context,
      dismissible: false,
      builder: (_) => PosPaymentModal(totalCents: toCents(total)),
    );
    if (!mounted) return;
    ref.read(posCatalogProvider.notifier).reload();
    ref.invalidate(activeShiftProvider);

    if (completed != null) {
      await showCascaModal<void>(
        context: context,
        builder: (_) => PosSuccessModal(completed: completed),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final catalog = ref.watch(posCatalogProvider);
    final cart = ref.watch(cartProvider);
    final controller = ref.read(posCatalogProvider.notifier);

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= _sidePanelBreakpoint;
        final error = catalog.error;

        final products = Padding(
          padding: const EdgeInsets.all(CascaSpacing.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: CascaSpacing.space3,
            children: [
              const _ShiftNotice(),
              CascaInput(
                controller: _search,
                hintText: 'Buscar por nombre, SKU o código de barras',
                iconStart: CascaIcons.magnifyingGlass,
                clearable: true,
                textInputAction: TextInputAction.search,
                onChanged: controller.setSearch,
              ),
              if (!wide && cart.notice != null)
                Text(
                  cart.notice!,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: colors.warning),
                ),
              if (error != null) ...[
                Text(
                  apiErrorMessage(error, 'No fue posible obtener el catálogo.'),
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: colors.danger),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: CascaButton(
                    label: 'Reintentar',
                    variant: CascaButtonVariant.secondary,
                    onPressed: controller.reload,
                  ),
                ),
              ],
              Expanded(
                child: catalog.items.isEmpty && !catalog.loading
                    ? error != null
                          ? const SizedBox.shrink()
                          : Center(
                              child: Text(
                                catalog.search.isEmpty
                                    ? 'Aún no hay productos en tu catálogo.'
                                    : 'No se encontraron productos.',
                                textAlign: TextAlign.center,
                              ),
                            )
                    : PosProductGrid(
                        items: catalog.items,
                        loading: catalog.loading,
                        hasNextPage: catalog.hasNextPage,
                        quantityOf: cart.quantityOf,
                        onAdd: _add,
                        onLoadMore: controller.loadMore,
                      ),
              ),
            ],
          ),
        );

        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: products),
              _CartPanel(onCheckout: _checkout),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: products),
            if (cart.lines.isNotEmpty) _CartBar(onPressed: _openCart),
          ],
        );
      },
    );
  }
}

class _ShiftNotice extends ConsumerWidget {
  const _ShiftNotice();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final shift = ref.watch(activeShiftProvider);
    if (shift.isLoading || shift.value == true) return const SizedBox.shrink();
    final failed = shift.hasError;

    return Container(
      padding: const EdgeInsets.all(CascaSpacing.space3),
      decoration: BoxDecoration(
        color: colors.warningSoft,
        borderRadius: CascaRadius.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: CascaSpacing.space2,
        children: [
          Text(
            failed
                ? 'No fue posible verificar el turno de caja.'
                : 'No hay un turno de caja abierto',
            style: textTheme.titleSmall,
          ),
          if (!failed)
            Text(
              'Inicia tu turno desde la web para poder registrar ventas.',
              style: textTheme.bodySmall,
            ),
          CascaButton(
            label: failed ? 'Reintentar' : 'Ya lo inicié',
            size: CascaButtonSize.sm,
            variant: CascaButtonVariant.secondary,
            onPressed: () => ref.invalidate(activeShiftProvider),
          ),
        ],
      ),
    );
  }
}

class _CartPanel extends ConsumerWidget {
  const _CartPanel({required this.onCheckout});

  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.casca;
    final hasLines = ref.watch(cartProvider.select((c) => c.lines.isNotEmpty));

    return Container(
      width: _panelWidth,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(left: BorderSide(color: colors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(CascaSpacing.space4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Venta actual',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (hasLines)
                  CascaButton(
                    label: 'Vaciar',
                    size: CascaButtonSize.sm,
                    variant: CascaButtonVariant.text,
                    onPressed: ref.read(cartProvider.notifier).clear,
                  ),
              ],
            ),
          ),
          const Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: CascaSpacing.space4),
              child: PosCartLines(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(CascaSpacing.space4),
            child: PosCartFooter(onCheckout: onCheckout),
          ),
        ],
      ),
    );
  }
}

class _CartSheet extends ConsumerWidget {
  const _CartSheet({required this.onCheckout});

  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasLines = ref.watch(cartProvider.select((c) => c.lines.isNotEmpty));

    return CascaModal(
      title: 'Venta actual',
      actions: [
        if (hasLines)
          CascaButton(
            label: 'Vaciar',
            variant: CascaButtonVariant.text,
            onPressed: ref.read(cartProvider.notifier).clear,
          ),
        SizedBox(
          width: double.infinity,
          child: PosCartFooter(onCheckout: onCheckout),
        ),
      ],
      child: const PosCartLines(),
    );
  }
}

class _CartBar extends ConsumerWidget {
  const _CartBar({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.casca;
    final cart = ref.watch(cartProvider);
    final count = cart.lines.length;
    final total = cart.preview?.finalTotal;
    final summary =
        '$count ${count == 1 ? 'producto' : 'productos'}'
        '${total == null ? '' : ' · ${formatMoney(total)}'}';

    return Container(
      padding: const EdgeInsets.all(CascaSpacing.space3),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: CascaButton(
        label: 'Ver venta · $summary',
        size: CascaButtonSize.lg,
        fullWidth: true,
        onPressed: onPressed,
      ),
    );
  }
}
