import 'package:casca_app/app/theme/casca_radius.dart';
import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/app/theme/casca_typography.dart';
import 'package:casca_app/features/pos/data/models/sale_model.dart';
import 'package:casca_app/features/pos/domain/cart_rules.dart';
import 'package:casca_app/features/pos/presentation/providers/pos_cart_provider.dart';
import 'package:casca_app/features/pos/presentation/providers/pos_catalog_provider.dart';
import 'package:casca_app/features/pos/presentation/providers/pos_price_list_provider.dart';
import 'package:casca_app/features/pos/presentation/widgets/pos_price_list_field.dart';
import 'package:casca_app/features/pos/presentation/widgets/pos_price_modal.dart';
import 'package:casca_app/shared/formatters/number_formatters.dart';
import 'package:casca_app/shared/ui/casca_action_menu.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_icon.dart';
import 'package:casca_app/shared/ui/casca_modal.dart';
import 'package:casca_app/shared/ui/casca_quantity_stepper.dart';
import 'package:casca_app/shared/ui/casca_remote_image.dart';
import 'package:casca_app/shared/ui/casca_skeleton.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

const double _imageSize = 44;
const double _menuSize = 44;
const double _totalSkeletonWidth = 112;
const int _ivaRated = 0;
const int _ivaZero = 1;
const int _ivaExempt = 2;
const int _iepsRate = 1;
const int _iepsFee = 2;

class PosCartLines extends ConsumerWidget {
  const PosCartLines({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final cart = ref.watch(cartProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PosPriceListField(),
        if (cart.lines.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: CascaSpacing.space7),
            child: Column(
              spacing: CascaSpacing.space2,
              children: [
                CascaIcon(
                  CascaIcons.basketShopping,
                  size: CascaSpacing.space7,
                  color: colors.textMuted,
                ),
                Text('Tu venta está vacía', style: textTheme.titleMedium),
                Text(
                  'Agrega productos para iniciar la venta.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          )
        else
          for (final line in cart.lines)
            _CartLineTile(
              key: ValueKey('cart-line-${line.key}'),
              line: line,
              preview: cart.previewFor(line),
              error: cart.lineErrors[line.key],
            ),
      ],
    );
  }
}

class _CartLineTile extends ConsumerWidget {
  const _CartLineTile({
    super.key,
    required this.line,
    required this.preview,
    required this.error,
  });

  final CartLine line;
  final SalePreviewLineModel? preview;
  final String? error;

  List<String> _taxes() {
    final preview = this.preview;
    if (preview == null) return const [];
    final iva = formatMoney(preview.lineIva);
    final ieps = formatMoney(preview.lineIeps);
    final ivaRate = formatQuantity((preview.ivaRateValue ?? 0) * 100);

    return [
      if (preview.ivaType == _ivaRated) 'IVA $ivaRate% · $iva',
      if (preview.ivaType == _ivaZero) 'IVA tasa cero · $iva',
      if (preview.ivaType == _ivaExempt) 'IVA exento · $iva',
      if (preview.iepsFactorType == _iepsRate)
        'IEPS ${formatQuantity((preview.iepsRateValue ?? 0) * 100)}% · $ieps',
      if (preview.iepsFactorType == _iepsFee)
        'IEPS cuota ${formatMoney(preview.iepsRateValue ?? 0)} · $ieps',
    ];
  }

  Future<void> _changePrice(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(cartProvider.notifier);
    final pricing = await showCascaModal<LinePricing>(
      context: context,
      size: CascaModalSize.sm,
      builder: (_) => PosPriceModal(line: line),
    );
    if (pricing != null) controller.setLinePricing(line, pricing);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.copyWith(color: colors.textSecondary);
    final controller = ref.read(cartProvider.notifier);
    final lists = ref.watch(posPriceListsProvider).value ?? const [];
    final canEditPrice = ref.watch(canCustomPriceProvider) || lists.isNotEmpty;
    final salePriceListId = ref.watch(
      cartProvider.select((cart) => cart.priceListId),
    );
    final priceListId = line.priceListId ?? salePriceListId;
    final priceLabel = line.customPrice != null
        ? 'Personalizado'
        : priceListId == publicPriceListId
        ? 'Público'
        : lists.where((list) => list.id == priceListId).firstOrNull?.name;
    final name = line.item.displayName;
    final error = this.error;
    final total = preview?.lineTotal;
    final unitPrice = preview?.unitPrice ?? line.customPrice ?? line.item.price;
    final atStockLimit =
        line.item.affectsInventory && !controller.canIncrease(line);

    final price = Text.rich(
      TextSpan(
        text: '${formatMoney(unitPrice)} c/u',
        children: [
          if (priceLabel != null)
            TextSpan(
              text: ' · $priceLabel',
              style: TextStyle(
                color: colors.info,
                fontWeight: CascaFontWeight.medium,
              ),
            ),
        ],
      ),
      style: muted,
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: CascaSpacing.space4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: CascaSpacing.space3,
        children: [
          ClipRRect(
            borderRadius: CascaRadius.sm,
            child: SizedBox.square(
              dimension: _imageSize,
              child: ColoredBox(
                color: colors.backgroundHover,
                child: CascaRemoteImage(paths: line.item.thumbnailPaths),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: CascaSpacing.space3,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: CascaSpacing.space1,
                        children: [
                          Text(
                            name,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: CascaFontWeight.medium,
                            ),
                          ),
                          if (canEditPrice)
                            Semantics(
                              button: true,
                              label: 'Cambiar precio de $name',
                              value: [
                                '${formatMoney(unitPrice)} por unidad',
                                ?priceLabel,
                              ].join(', '),
                              onTap: () => _changePrice(context, ref),
                              excludeSemantics: true,
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => _changePrice(context, ref),
                                  child: price,
                                ),
                              ),
                            )
                          else
                            price,
                          for (final tax in _taxes()) Text(tax, style: muted),
                        ],
                      ),
                    ),
                    CascaActionMenu(
                      semanticLabel: 'Acciones de $name',
                      sections: [
                        CascaActionMenuSection(
                          items: [
                            if (canEditPrice)
                              CascaActionMenuItem(
                                id: 'price',
                                label: 'Cambiar precio',
                                icon: CascaIcons.pencilSimple,
                                onSelected: () => _changePrice(context, ref),
                              ),
                            CascaActionMenuItem(
                              id: 'remove',
                              label: 'Quitar',
                              icon: CascaIcons.trash,
                              danger: true,
                              onSelected: () => controller.remove(line),
                            ),
                          ],
                        ),
                      ],
                      child: SizedBox.square(
                        dimension: _menuSize,
                        child: Center(
                          child: CascaIcon(
                            CascaIcons.dotsThree,
                            size: CascaSpacing.space5,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  spacing: CascaSpacing.space3,
                  children: [
                    CascaQuantityStepper(
                      value: line.quantity,
                      subject: name,
                      decimals: line.item.allowsDecimalQuantity,
                      removesOnDecrease: line.quantity <= 1,
                      onChanged: (typed) => controller.type(line, typed),
                      onDecrease: () => controller.decrease(line),
                      onIncrease: controller.canIncrease(line)
                          ? () => controller.increase(line)
                          : null,
                    ),
                    Expanded(
                      child: Text(
                        total == null ? '--' : formatMoney(total),
                        textAlign: TextAlign.end,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: CascaFontWeight.semibold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (atStockLimit)
                  Text(
                    'Máximo disponible',
                    style: textTheme.bodySmall?.copyWith(color: colors.warning),
                  ),
                if (error != null)
                  Text(
                    error,
                    style: textTheme.bodySmall?.copyWith(color: colors.danger),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PosCartFooter extends ConsumerWidget {
  const PosCartFooter({super.key, required this.onCheckout});

  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final cart = ref.watch(cartProvider);
    final taxesShown =
        cart.preview != null &&
        (cart.preview!.ivaTotal != 0 || cart.preview!.iepsTotal != 0);
    final shiftOpen = ref.watch(activeShiftProvider).value ?? false;
    final preview = cart.preview;
    final total = cart.payableTotal;

    Widget row(String label, double amount, {bool strong = false}) {
      final style = strong
          ? textTheme.titleLarge
          : textTheme.bodySmall?.copyWith(color: colors.textSecondary);
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(formatMoney(amount), style: style),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: CascaSpacing.space2,
      children: [
        if (cart.calculating)
          Semantics(
            label: 'Calculando total',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: textTheme.titleLarge),
                const CascaSkeleton(
                  width: _totalSkeletonWidth,
                  height: CascaSpacing.space6,
                ),
              ],
            ),
          ),
        if (cart.previewError != null) ...[
          Text(
            'No fue posible calcular el total.',
            style: textTheme.bodySmall?.copyWith(color: colors.danger),
          ),
          CascaButton(
            label: 'Reintentar',
            variant: CascaButtonVariant.secondary,
            onPressed: ref.read(cartProvider.notifier).retryPreview,
          ),
        ],
        if (preview != null) ...[
          if (taxesShown) ...[
            row('Subtotal', preview.subtotal),
            if (preview.discountTotal != 0)
              row('Descuento', preview.discountTotal),
            row('IVA', preview.ivaTotal),
            if (preview.iepsTotal != 0) row('IEPS', preview.iepsTotal),
            if (preview.roundingAdjustment != 0)
              row('Ajuste por redondeo', preview.roundingAdjustment),
          ],
          row('Total', preview.finalTotal, strong: true),
        ],
        CascaButton(
          label: total == null ? 'Cobrar' : 'Cobrar ${formatMoney(total)}',
          size: CascaButtonSize.lg,
          fullWidth: true,
          onPressed: total == null || !shiftOpen ? null : onCheckout,
        ),
      ],
    );
  }
}
