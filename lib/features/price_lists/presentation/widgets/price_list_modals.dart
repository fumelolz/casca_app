import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/core/errors/api_error_message.dart';
import 'package:casca_app/features/price_lists/data/models/price_list_model.dart';
import 'package:casca_app/features/price_lists/domain/price_list_rules.dart';
import 'package:casca_app/features/price_lists/presentation/providers/price_list_providers.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_delete_modal.dart';
import 'package:casca_app/shared/ui/casca_input.dart';
import 'package:casca_app/shared/ui/casca_modal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class PriceListNameModal extends ConsumerStatefulWidget {
  const PriceListNameModal({super.key, this.priceList});

  final PriceListModel? priceList;

  @override
  ConsumerState<PriceListNameModal> createState() => _PriceListNameModalState();
}

class _PriceListNameModalState extends ConsumerState<PriceListNameModal> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.priceList?.name);

  bool get _isEdit => widget.priceList != null;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final saved = await ref
        .read(priceListActionProvider.notifier)
        .save(_name.text.trim(), priceListId: widget.priceList?.id);
    if (saved != null && mounted) Navigator.of(context).pop(saved);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final state = ref.watch(priceListActionProvider);
    final error = state.error;

    return CascaModal(
      title: _isEdit ? 'Renombrar lista de precios' : 'Nueva lista de precios',
      actions: [
        CascaButton(
          label: 'Cancelar',
          variant: CascaButtonVariant.secondary,
          onPressed: state.isLoading ? null : () => Navigator.of(context).pop(),
        ),
        CascaButton(
          label: _isEdit ? 'Guardar cambios' : 'Crear lista',
          loading: state.isLoading,
          onPressed: _save,
        ),
      ],
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: CascaSpacing.space2,
          children: [
            Text('Nombre', style: textTheme.labelLarge),
            CascaInput(
              controller: _name,
              autofocus: true,
              hintText: 'Por ejemplo: Mayorista',
              maxLength: maxPriceListNameLength,
              validator: (value) =>
                  (value?.trim() ?? '').isEmpty ? 'Ingresa el nombre' : null,
              onFieldSubmitted: (_) => _save(),
            ),
            if (error != null)
              Text(
                apiErrorMessage(
                  error,
                  'No fue posible guardar la lista de precios.',
                  forbidden:
                      'No tienes permiso para modificar listas de precios.',
                ),
                style: textTheme.bodyMedium?.copyWith(color: colors.danger),
              ),
          ],
        ),
      ),
    );
  }
}

class PriceListDeleteModal extends ConsumerWidget {
  const PriceListDeleteModal({super.key, required this.priceList});

  final PriceListModel priceList;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(priceListActionProvider);
    final error = state.error;

    return CascaDeleteModal(
      title: '¿Eliminar ${priceList.name}?',
      message: 'Se eliminarán todos los precios de esta lista. Las ventas ya registradas conservan el precio con el que se cobraron.',
      deleting: state.isLoading,
      errorMessage: error == null
          ? null
          : apiErrorMessage(
              error,
              'No fue posible eliminar la lista de precios.',
              forbidden: 'No tienes permiso para eliminar listas de precios.',
            ),
      onConfirm: () async {
        final deleted = await ref
            .read(priceListActionProvider.notifier)
            .delete(priceList.id);
        if (deleted && context.mounted) Navigator.of(context).pop(true);
      },
    );
  }
}
