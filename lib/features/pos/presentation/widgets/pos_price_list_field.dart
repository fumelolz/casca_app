import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/features/pos/presentation/providers/pos_cart_provider.dart';
import 'package:casca_app/features/pos/presentation/providers/pos_price_list_provider.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_icon.dart';
import 'package:casca_app/shared/ui/casca_modal.dart';
import 'package:casca_app/shared/ui/casca_select.dart';
import 'package:casca_app/shared/ui/casca_skeleton.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

const String _public = '';

class PosPriceListField extends ConsumerWidget {
  const PosPriceListField({super.key});

  Future<void> _select(
    BuildContext context,
    WidgetRef ref,
    String? priceListId,
  ) async {
    final cart = ref.read(cartProvider);
    if (priceListId == cart.priceListId) return;
    final controller = ref.read(cartProvider.notifier);

    if (cart.lines.isNotEmpty) {
      final confirmed = await showCascaConfirm(
        context: context,
        title: 'Cambiar lista de precios',
        message: 'El cambio afectará a todos los productos de la venta. Los que tengan lista o precio propio conservarán su configuración.',
        confirmLabel: 'Cambiar lista',
      );
      if (!confirmed) return;
    }
    controller.setPriceList(priceListId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final lists = ref.watch(posPriceListsProvider);
    final selected = ref.watch(cartProvider.select((c) => c.priceListId));
    final value = lists.value;

    if (lists.hasError) {
      return Row(
        children: [
          Expanded(
            child: Text(
              'No fue posible cargar las listas de precios.',
              style: textTheme.bodySmall?.copyWith(color: colors.danger),
            ),
          ),
          CascaButton(
            label: 'Reintentar',
            size: CascaButtonSize.sm,
            variant: CascaButtonVariant.text,
            onPressed: () => ref.invalidate(posPriceListsProvider),
          ),
        ],
      );
    }
    if (value == null) {
      return const CascaSkeleton(height: CascaSpacing.space8);
    }
    if (value.isEmpty) return const SizedBox.shrink();

    return CascaSelect<String>(
      options: [
        const CascaSelectOption(value: _public, label: 'Público'),
        for (final list in value)
          CascaSelectOption(value: list.id, label: list.name),
      ],
      value: selected ?? _public,
      iconStart: CascaIcons.tags,
      hintText: 'Lista de precios',
      onChanged: (id) => _select(context, ref, id == _public ? null : id),
    );
  }
}
