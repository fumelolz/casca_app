import 'package:casca_app/app/theme/casca_radius.dart';
import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/app/theme/casca_typography.dart';
import 'package:casca_app/features/pos/data/models/sale_model.dart';
import 'package:casca_app/features/pos/domain/cart_rules.dart';
import 'package:casca_app/features/pos/presentation/providers/pos_cart_provider.dart';
import 'package:casca_app/features/pos/presentation/providers/pos_catalog_provider.dart';
import 'package:casca_app/shared/formatters/number_formatters.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_icon.dart';
import 'package:casca_app/shared/ui/casca_input.dart';
import 'package:casca_app/shared/ui/casca_remote_image.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

const double _imageSize = 44;
const double _stepSize = 44;
const double _quantityWidth = 84;
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
    final notice = cart.notice;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (notice != null)
          Padding(
            padding: const EdgeInsets.only(bottom: CascaSpacing.space2),
            child: Text(
              notice,
              style: textTheme.bodySmall?.copyWith(color: colors.warning),
            ),
          ),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.copyWith(color: colors.textSecondary);
    final controller = ref.read(cartProvider.notifier);
    final canIncrease = controller.canIncrease(line);
    final name = line.item.displayName;
    final error = this.error;
    final total = preview?.lineTotal;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: CascaSpacing.space3),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: CascaSpacing.space2,
        children: [
          Row(
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: CascaFontWeight.medium,
                      ),
                    ),
                    Text(
                      '${formatMoney(preview?.unitPrice ?? line.item.price)} c/u',
                      style: muted,
                    ),
                    for (final tax in _taxes()) Text(tax, style: muted),
                  ],
                ),
              ),
              _IconAction(
                label: 'Quitar $name',
                icon: CascaIcons.trash,
                onPressed: () => controller.remove(line),
              ),
            ],
          ),
          Row(
            children: [
              _IconAction(
                label: 'Disminuir cantidad de $name',
                icon: CascaIcons.minus,
                onPressed: () => controller.decrease(line),
              ),
              SizedBox(
                width: _quantityWidth,
                child: _QuantityField(line: line),
              ),
              _IconAction(
                label: 'Aumentar cantidad de $name',
                icon: CascaIcons.plus,
                onPressed: canIncrease ? () => controller.increase(line) : null,
              ),
              Expanded(
                child: Text(
                  total == null ? '--' : formatMoney(total),
                  textAlign: TextAlign.end,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: CascaFontWeight.semibold,
                  ),
                ),
              ),
            ],
          ),
          if (error != null)
            Text(
              error,
              style: textTheme.bodySmall?.copyWith(color: colors.danger),
            ),
        ],
      ),
    );
  }
}

class _QuantityField extends ConsumerStatefulWidget {
  const _QuantityField({required this.line});

  final CartLine line;

  @override
  ConsumerState<_QuantityField> createState() => _QuantityFieldState();
}

class _QuantityFieldState extends ConsumerState<_QuantityField> {
  late final _controller = TextEditingController(
    text: _format(widget.line.quantity),
  );
  bool _focused = false;

  static String _format(double quantity) {
    return formatQuantity(quantity).replaceAll(',', '');
  }

  void _sync() {
    final text = _format(widget.line.quantity);
    if (_controller.text != text) _controller.text = text;
  }

  void _changed(String text) {
    final quantity = double.tryParse(text);
    if (quantity == null || quantity <= 0) return;
    final controller = ref.read(cartProvider.notifier);
    controller.setQuantity(widget.line, quantity);

    for (final line in ref.read(cartProvider).lines) {
      if (line.key == widget.line.key && line.quantity < quantity) {
        _controller.text = _format(line.quantity);
      }
    }
  }

  @override
  void didUpdateWidget(_QuantityField oldWidget) {
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
    final decimals = widget.line.item.allowsDecimalQuantity;

    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (focused) {
        _focused = focused;
        if (!focused) _sync();
      },
      child: Semantics(
        label: 'Cantidad de ${widget.line.item.displayName}',
        child: CascaInput(
          controller: _controller,
          keyboardType: TextInputType.numberWithOptions(decimal: decimals),
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              RegExp(decimals ? r'[0-9.]' : r'[0-9]'),
            ),
          ],
          onChanged: _changed,
        ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final String icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;

    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onPressed,
        radius: _stepSize / 2,
        child: SizedBox.square(
          dimension: _stepSize,
          child: Center(
            child: CascaIcon(
              icon,
              size: CascaSpacing.space4,
              color: onPressed == null ? colors.border : colors.textSecondary,
            ),
          ),
        ),
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
          Text('Calculando total...', style: textTheme.bodySmall),
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
