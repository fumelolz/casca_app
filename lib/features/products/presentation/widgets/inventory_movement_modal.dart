import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/core/errors/api_error_message.dart';
import 'package:casca_app/features/products/domain/inventory_movement_rules.dart';
import 'package:casca_app/features/products/domain/product_form_rules.dart';
import 'package:casca_app/features/products/presentation/providers/product_detail_providers.dart';
import 'package:casca_app/features/products/presentation/widgets/product_form_fields.dart';
import 'package:casca_app/shared/formatters/number_formatters.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_modal.dart';
import 'package:casca_app/shared/ui/casca_segmented_control.dart';
import 'package:casca_app/shared/ui/casca_select.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class InventoryMovementModal extends ConsumerStatefulWidget {
  const InventoryMovementModal({
    super.key,
    required this.productId,
    required this.name,
    required this.currentStock,
    required this.allowsDecimals,
    this.variantId,
  });

  final String productId;
  final String? variantId;
  final String name;
  final double currentStock;
  final bool allowsDecimals;

  @override
  ConsumerState<InventoryMovementModal> createState() =>
      _InventoryMovementModalState();
}

class _InventoryMovementModalState
    extends ConsumerState<InventoryMovementModal> {
  final _formKey = GlobalKey<FormState>();
  final _quantity = TextEditingController();
  final _unitCost = TextEditingController();
  MovementDirection _direction = MovementDirection.entry;
  MovementReason _reason = MovementReason.purchase;

  @override
  void dispose() {
    _quantity.dispose();
    _unitCost.dispose();
    super.dispose();
  }

  void _changeDirection(MovementDirection direction) {
    if (direction == _direction) return;
    setState(() {
      _direction = direction;
      _reason = reasonsFor(direction).first;
    });
  }

  String? _validateQuantity(String? text) {
    final error = validateMovementQuantity(
      parseAmount(text),
      direction: _direction,
      currentStock: widget.currentStock,
      allowsDecimals: widget.allowsDecimals,
    );
    return switch (error) {
      null => null,
      MovementQuantityError.required => 'Ingresa la cantidad',
      MovementQuantityError.notPositive =>
        'Ingresa una cantidad mayor a cero',
      MovementQuantityError.decimals => 'Este producto se maneja por piezas',
      MovementQuantityError.exceedsStock =>
        'La cantidad supera la existencia actual',
    };
  }

  String? _validateUnitCost(String? text) {
    final cost = parseAmount(text);
    if (cost == null) return 'Ingresa el costo unitario';
    return cost <= 0 ? 'Ingresa un costo mayor a cero' : null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final saved = await ref
        .read(inventoryMovementControllerProvider(widget.productId).notifier)
        .save(
          toMovementRequest(
            reason: _reason,
            quantity: parseAmount(_quantity.text)!,
            unitCost: parseAmount(_unitCost.text),
          ),
          variantId: widget.variantId,
        );
    if (saved && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final state = ref.watch(
      inventoryMovementControllerProvider(widget.productId),
    );
    final saving = state.isLoading;
    final error = state.error;
    final muted = textTheme.bodySmall?.copyWith(color: colors.textSecondary);

    return CascaModal(
      title: 'Ajustar existencias',
      actions: [
        CascaButton(
          label: 'Cancelar',
          variant: CascaButtonVariant.secondary,
          onPressed: saving ? null : () => Navigator.of(context).pop(false),
        ),
        CascaButton(label: 'Guardar', loading: saving, onPressed: _save),
      ],
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: CascaSpacing.space4,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: CascaSpacing.space1,
              children: [
                Text(widget.name, style: textTheme.titleMedium),
                Text(
                  'Existencia actual: ${formatQuantity(widget.currentStock)}',
                  style: muted,
                ),
              ],
            ),
            CascaSegmentedControl<MovementDirection>(
              segments: const [
                CascaSegment(value: MovementDirection.entry, label: 'Entrada'),
                CascaSegment(value: MovementDirection.exit, label: 'Salida'),
              ],
              value: _direction,
              enabled: !saving,
              onChanged: _changeDirection,
            ),
            ProductField(
              label: 'Motivo',
              child: CascaSelect<MovementReason>(
                key: ValueKey(_direction),
                options: [
                  for (final reason in reasonsFor(_direction))
                    CascaSelectOption(value: reason, label: reason.label),
                ],
                value: _reason,
                onChanged: (reason) => setState(() => _reason = reason),
              ),
            ),
            ProductField(
              label: 'Cantidad',
              child: ProductAmountInput(
                controller: _quantity,
                hintText: '0',
                validator: _validateQuantity,
              ),
            ),
            if (requiresUnitCost(_reason))
              ProductField(
                label: 'Costo unitario',
                child: ProductAmountInput(
                  controller: _unitCost,
                  hintText: '0.00',
                  money: true,
                  validator: _validateUnitCost,
                ),
              ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _quantity,
              builder: (context, value, _) {
                final stock = resultingStock(
                  widget.currentStock,
                  _direction,
                  parseAmount(value.text) ?? 0,
                );
                return Text(
                  'Existencia después del ajuste: ${formatQuantity(stock)}',
                  style: textTheme.bodyMedium?.copyWith(
                    color: stock < 0 ? colors.danger : null,
                  ),
                );
              },
            ),
            if (error != null)
              Text(
                apiErrorMessage(
                  error,
                  'No fue posible registrar el movimiento.',
                  forbidden: 'No tienes permiso para ajustar existencias.',
                ),
                style: textTheme.bodyMedium?.copyWith(color: colors.danger),
              ),
          ],
        ),
      ),
    );
  }
}
