import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/features/pos/data/pos_repository.dart';
import 'package:casca_app/features/pos/domain/cart_rules.dart';
import 'package:casca_app/features/pos/domain/sale_request.dart';
import 'package:casca_app/features/pos/presentation/providers/pos_cart_provider.dart';
import 'package:casca_app/features/pos/presentation/providers/pos_price_list_provider.dart';
import 'package:casca_app/shared/formatters/number_formatters.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_input.dart';
import 'package:casca_app/shared/ui/casca_modal.dart';
import 'package:casca_app/shared/ui/casca_select.dart';
import 'package:casca_app/shared/ui/casca_skeleton.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

const String _saleDefault = '';
const double _priceSkeletonWidth = 80;

class PosPriceModal extends ConsumerStatefulWidget {
  const PosPriceModal({super.key, required this.line});

  final CartLine line;

  @override
  ConsumerState<PosPriceModal> createState() => _PosPriceModalState();
}

class _PosPriceModalState extends ConsumerState<PosPriceModal> {
  late final String? _salePriceListId = ref.read(cartProvider).priceListId;
  late String _selected =
      widget.line.priceListId ?? _salePriceListId ?? _saleDefault;
  late final _price = TextEditingController(
    text: widget.line.customPrice?.toStringAsFixed(2) ?? '',
  );
  late Future<double> _listPrice = _resolve();

  String get _publicValue {
    return _salePriceListId == null ? _saleDefault : publicPriceListId;
  }

  String? get _linePriceListId {
    final isSaleList = _selected == (_salePriceListId ?? _saleDefault);
    return isSaleList ? null : _selected;
  }

  Future<double> _resolve() async {
    final item = widget.line.item;
    final effective = _linePriceListId ?? _salePriceListId;
    if (effective == null && !item.fromPriceList) return item.price;

    final preview = await ref
        .read(posRepositoryProvider)
        .preview(
          previewRequest([
            CartLine(item: item, quantity: 1, priceListId: _linePriceListId),
          ], _salePriceListId),
        );
    return preview.items.first.unitPrice;
  }

  @override
  void dispose() {
    _price.dispose();
    super.dispose();
  }

  void _apply() {
    final typed = double.tryParse(_price.text);
    Navigator.of(context).pop(
      LinePricing(
        customPrice: typed == null ? null : roundTo(typed, 2),
        priceListId: _linePriceListId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final lists = ref.watch(posPriceListsProvider).value ?? const [];
    final canCustom = ref.watch(canCustomPriceProvider);

    return CascaModal(
      title: 'Precio del producto',
      actions: [
        CascaButton(
          label: 'Cancelar',
          variant: CascaButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        CascaButton(label: 'Aplicar', onPressed: _apply),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: CascaSpacing.space3,
        children: [
          Text(widget.line.item.displayName, style: textTheme.titleMedium),
          if (lists.isNotEmpty) ...[
            Text('Lista de precios', style: textTheme.labelMedium),
            CascaSelect<String>(
              options: [
                CascaSelectOption(value: _publicValue, label: 'Público'),
                for (final list in lists)
                  CascaSelectOption(value: list.id, label: list.name),
              ],
              value: _selected,
              onChanged: (value) => setState(() {
                _selected = value;
                _listPrice = _resolve();
              }),
            ),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            spacing: CascaSpacing.space2,
            children: [
              Flexible(
                child: Text('Precio de lista', style: textTheme.bodyMedium),
              ),
              FutureBuilder<double>(
                future: _listPrice,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const CascaSkeleton(width: _priceSkeletonWidth);
                  }
                  final price = snapshot.data;
                  return Text(
                    price == null ? '--' : formatMoney(price),
                    style: textTheme.titleMedium,
                  );
                },
              ),
            ],
          ),
          if (canCustom) ...[
            Text('Precio personalizado', style: textTheme.labelMedium),
            CascaInput(
              controller: _price,
              hintText: '0.00',
              prefixText: r'$',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              onFieldSubmitted: (_) => _apply(),
            ),
            Text(
              'Déjalo vacío para usar el precio de la lista.',
              style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
