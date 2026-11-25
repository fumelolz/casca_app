import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/app/theme/casca_typography.dart';
import 'package:casca_app/core/errors/api_error_message.dart';
import 'package:casca_app/features/products/data/models/category_model.dart';
import 'package:casca_app/features/products/data/models/category_request.dart';
import 'package:casca_app/features/products/presentation/providers/category_form_provider.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_input.dart';
import 'package:casca_app/shared/ui/casca_modal.dart';
import 'package:casca_app/shared/ui/casca_select.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

const int _maxTextLength = 50;
const String _noParent = '';

class CategoryFormModal extends ConsumerStatefulWidget {
  const CategoryFormModal({super.key, this.category});

  final CategoryModel? category;

  @override
  ConsumerState<CategoryFormModal> createState() => _CategoryFormModalState();
}

class _CategoryFormModalState extends ConsumerState<CategoryFormModal> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(
    text: widget.category?.name,
  );
  late final _descriptionController = TextEditingController(
    text: widget.category?.description,
  );
  late String _parentId = widget.category?.parentCategoryId ?? _noParent;

  bool get _isEdit => widget.category != null;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    return (value?.trim() ?? '').isEmpty ? 'Ingresa el nombre' : null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final description = _descriptionController.text.trim();
    final saved = await ref
        .read(categoryFormControllerProvider.notifier)
        .save(
          CategoryRequest(
            name: _nameController.text.trim(),
            description: description.isEmpty ? null : description,
            parentCategoryId: _parentId == _noParent ? null : _parentId,
          ),
          categoryId: widget.category?.id,
        );
    if (saved && mounted) Navigator.of(context).pop();
  }

  List<CascaSelectOption<String>> _parentOptions(
    List<CategoryModel> categories,
  ) {
    final category = widget.category;
    final currentId = category?.parentCategoryId;
    final currentListed = categories.any((item) => item.id == currentId);

    return [
      const CascaSelectOption(value: _noParent, label: 'Sin categoría padre'),
      if (currentId != null && !currentListed)
        CascaSelectOption(
          value: currentId,
          label: category?.parentCategoryName ?? 'Categoría actual',
        ),
      for (final item in categories)
        if (item.id != category?.id)
          CascaSelectOption(value: item.id, label: item.name),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final saveState = ref.watch(categoryFormControllerProvider);
    final parents = ref.watch(categoryParentOptionsProvider);
    final saving = saveState.isLoading;
    final error = saveState.error;
    final labelStyle = textTheme.labelLarge?.copyWith(
      fontWeight: CascaFontWeight.semibold,
    );
    final errorStyle = textTheme.bodyMedium?.copyWith(color: colors.danger);

    return CascaModal(
      title: _isEdit ? 'Editar categoría' : 'Agregar categoría',
      actions: [
        CascaButton(
          label: 'Cancelar',
          variant: CascaButtonVariant.secondary,
          onPressed: saving ? null : () => Navigator.of(context).pop(),
        ),
        CascaButton(label: 'Guardar', loading: saving, onPressed: _save),
      ],
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Nombre', style: labelStyle),
            const SizedBox(height: CascaSpacing.space2),
            CascaInput(
              controller: _nameController,
              hintText: 'Nombre de la categoría',
              maxLength: _maxTextLength,
              textInputAction: TextInputAction.next,
              validator: _validateName,
            ),
            const SizedBox(height: CascaSpacing.space4),
            Text('Descripción', style: labelStyle),
            const SizedBox(height: CascaSpacing.space2),
            CascaInput(
              controller: _descriptionController,
              hintText: 'Descripción de la categoría',
              lines: 3,
              maxLength: _maxTextLength,
            ),
            const SizedBox(height: CascaSpacing.space4),
            Text('Categoría padre', style: labelStyle),
            const SizedBox(height: CascaSpacing.space2),
            CascaSelect<String>(
              options: _parentOptions(parents.value ?? const []),
              value: _parentId,
              hintText: 'Selecciona una categoría padre',
              enabled: !parents.isLoading,
              onChanged: (value) => setState(() => _parentId = value),
            ),
            if (parents.hasError) ...[
              const SizedBox(height: CascaSpacing.space2),
              Text(
                'No fue posible cargar las categorías padre.',
                style: errorStyle,
              ),
            ],
            if (error != null) ...[
              const SizedBox(height: CascaSpacing.space4),
              Text(
                apiErrorMessage(
                  error,
                  _isEdit
                      ? 'No fue posible actualizar la categoría.'
                      : 'No fue posible crear la categoría.',
                  forbidden: 'No tienes permiso para esta acción.',
                ),
                style: errorStyle,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
