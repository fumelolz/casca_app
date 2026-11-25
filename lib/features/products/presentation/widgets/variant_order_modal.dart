import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/app/theme/casca_typography.dart';
import 'package:casca_app/core/errors/api_error_message.dart';
import 'package:casca_app/features/products/domain/product_variant_view_rules.dart';
import 'package:casca_app/features/products/presentation/providers/product_variant_actions_provider.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_icon.dart';
import 'package:casca_app/shared/ui/casca_modal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

const double _moveSize = 44;

class VariantOrderModal extends ConsumerStatefulWidget {
  const VariantOrderModal({
    super.key,
    required this.productId,
    required this.groups,
  });

  final String productId;
  final List<VariantOptionGroup> groups;

  @override
  ConsumerState<VariantOrderModal> createState() => _VariantOrderModalState();
}

class _VariantOrderModalState extends ConsumerState<VariantOrderModal> {
  late final List<VariantOptionGroup> _groups = [
    for (final group in widget.groups)
      VariantOptionGroup(name: group.name, values: [...group.values]),
  ];

  void _move<T>(List<T> items, int index, int offset) {
    setState(() => items.insert(index + offset, items.removeAt(index)));
  }

  Future<void> _save() async {
    final saved = await ref
        .read(
          variantActionProvider((widget.productId, VariantAction.order))
              .notifier,
        )
        .reorder(_groups);
    if (saved && mounted) Navigator.of(context).pop(true);
  }

  Widget _row<T>(List<T> items, int index, String label, {bool title = false}) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(left: title ? 0 : CascaSpacing.space4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: title
                  ? textTheme.bodyMedium?.copyWith(
                      fontWeight: CascaFontWeight.semibold,
                    )
                  : textTheme.bodyMedium,
            ),
          ),
          _MoveButton(
            label: 'Subir $label',
            up: true,
            onPressed: index == 0 ? null : () => _move(items, index, -1),
          ),
          _MoveButton(
            label: 'Bajar $label',
            up: false,
            onPressed: index == items.length - 1
                ? null
                : () => _move(items, index, 1),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final state = ref.watch(
      variantActionProvider((widget.productId, VariantAction.order)),
    );
    final error = state.error;

    return CascaModal(
      title: 'Ordenar opciones y valores',
      actions: [
        CascaButton(
          label: 'Cancelar',
          variant: CascaButtonVariant.secondary,
          onPressed: state.isLoading ? null : () => Navigator.of(context).pop(),
        ),
        CascaButton(
          label: 'Guardar orden',
          loading: state.isLoading,
          onPressed: _save,
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (error != null)
            Text(
              apiErrorMessage(error, 'No fue posible guardar el orden.'),
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: colors.danger),
            ),
          for (final (index, group) in _groups.indexed) ...[
            if (index > 0) Divider(color: colors.border),
            _row(_groups, index, group.name, title: true),
            for (final (position, value) in group.values.indexed)
              _row(group.values, position, value),
          ],
        ],
      ),
    );
  }
}

class _MoveButton extends StatelessWidget {
  const _MoveButton({
    required this.label,
    required this.up,
    required this.onPressed,
  });

  final String label;
  final bool up;
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
        radius: _moveSize / 2,
        child: SizedBox.square(
          dimension: _moveSize,
          child: Center(
            child: RotatedBox(
              quarterTurns: up ? 2 : 0,
              child: CascaIcon(
                CascaIcons.chevronDown,
                size: CascaSpacing.space4,
                color: onPressed == null ? colors.border : colors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
