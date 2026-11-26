import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/app/theme/casca_typography.dart';
import 'package:casca_app/core/errors/api_error_message.dart';
import 'package:casca_app/core/layout/page_padding.dart';
import 'package:casca_app/core/layout/sidebar_controller.dart';
import 'package:casca_app/core/routing/app_routes.dart';
import 'package:casca_app/core/routing/unsaved_changes.dart';
import 'package:casca_app/features/products/data/models/category_model.dart';
import 'package:casca_app/features/products/data/models/product_detail_model.dart';
import 'package:casca_app/features/products/domain/product_form_rules.dart';
import 'package:casca_app/features/products/domain/product_list_rules.dart';
import 'package:casca_app/features/products/domain/product_variant_rules.dart';
import 'package:casca_app/features/products/presentation/providers/product_variants_provider.dart';
import 'package:casca_app/features/products/presentation/widgets/product_variants_manager.dart';
import 'package:casca_app/features/products/presentation/widgets/product_variants_section.dart';
import 'package:casca_app/features/products/presentation/providers/product_form_provider.dart';
import 'package:casca_app/features/products/presentation/providers/product_photos_provider.dart';
import 'package:casca_app/features/products/presentation/widgets/product_form_fields.dart';
import 'package:casca_app/features/products/presentation/widgets/product_form_skeleton.dart';
import 'package:casca_app/features/products/presentation/widgets/product_photos_field.dart';
import 'package:casca_app/shared/formatters/number_formatters.dart';
import 'package:casca_app/shared/ui/casca_barcode_scanner.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_card.dart';
import 'package:casca_app/shared/ui/casca_input.dart';
import 'package:casca_app/shared/ui/casca_segmented_control.dart';
import 'package:casca_app/shared/ui/casca_skeleton.dart';
import 'package:casca_app/shared/ui/casca_select.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

const double _contentMaxWidth = 720;
const int _maxNameLength = 50;
const int _maxDescriptionLength = 150;
const int _maxBarcodeLength = 50;

class ProductFormPage extends ConsumerWidget {
  const ProductFormPage({super.key, this.productId});

  final String? productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(AppRoutes.products);
      },
      child: _content(context, ref),
    );
  }

  Widget _content(BuildContext context, WidgetRef ref) {
    final id = productId;
    if (id == null) return const _ProductForm();

    final detail = ref.watch(productDetailProvider(id));
    final product = detail.value;
    if (product != null) {
      return _ProductForm(key: ValueKey(product.id), current: product);
    }

    final error = detail.error;
    if (error == null) {
      return const ProductFormSkeleton();
    }

    return Center(
      child: Padding(
        padding: pagePadding(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              apiErrorMessage(error, 'No fue posible obtener el producto.'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: CascaSpacing.space4),
            CascaButton(
              label: 'Reintentar',
              variant: CascaButtonVariant.secondary,
              onPressed: () => ref.invalidate(productDetailProvider(id)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductForm extends ConsumerStatefulWidget {
  const _ProductForm({super.key, this.current});

  final ProductDetailModel? current;

  @override
  ConsumerState<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends ConsumerState<_ProductForm> {
  final _formKey = GlobalKey<FormState>();

  ProductDetailModel? get _current => widget.current;
  bool get _isEdit => _current != null;

  late ProductKind _kind = ProductKind.values.firstWhere(
    (kind) => kind.code == _current?.productType,
    orElse: () => ProductKind.product,
  );
  late ProductUnit _unit = ProductUnit.values.firstWhere(
    (unit) => unit.code == _current?.baseUnit?.unitOfMeasure,
    orElse: () => ProductUnit.piece,
  );
  late String? _categoryId = _current?.categoryId;
  bool _categoryMissing = false;
  String? _createdId;

  late final _name = TextEditingController(text: _current?.name);
  late final _description = TextEditingController(text: _current?.description);
  late final _barcode = TextEditingController(
    text: _current?.baseUnit?.barcode,
  );
  late final _price = _amount(_current?.baseUnit?.price);
  late final _cost = _amount(
    _current?.productType == ProductKind.service.code
        ? _current?.baseUnit?.cost
        : _current?.averageCost,
  );
  late final _initialStock = _amount(_current?.stock);
  late final _minimumStock = _amount(_current?.minimumStock);
  late final _maximumStock = _amount(_current?.maximumStock);

  bool get _isService => _kind == ProductKind.service;
  bool get _hasVariants => _current?.hasVariants ?? false;

  static TextEditingController _amount(double? value) {
    return TextEditingController(
      text: value == null ? '' : formatQuantity(value).replaceAll(',', ''),
    );
  }

  late final UnsavedChanges _unsavedChanges;
  late final List<Object?> _initialValues;
  bool _saved = false;
  String? _variantError;

  List<ProductVariantDraft> _variantsToCreate() {
    if (_isEdit || _isService) return const [];
    return ref.read(productVariantsProvider).variants;
  }

  String? _checkVariants() {
    if (_isEdit || _isService) return null;
    final state = ref.read(productVariantsProvider);
    if (state.isEditing) return 'Termina de editar la opción de variantes.';
    return missingVariantCostMessage(state.variants);
  }

  @override
  void initState() {
    super.initState();
    _initialValues = _currentValues();
    _unsavedChanges = ref.read(unsavedChangesProvider)
      ..watch(_hasUnsavedChanges);
  }

  List<Object?> _currentValues() {
    return [
      _kind,
      _unit,
      _categoryId,
      for (final controller in [
        _name,
        _description,
        _barcode,
        _price,
        _cost,
        _initialStock,
        _minimumStock,
        _maximumStock,
      ])
        controller.text,
    ];
  }

  bool _hasUnsavedChanges() {
    if (_saved || _createdId != null) return false;
    if (!listEquals(_initialValues, _currentValues())) return true;
    if (_isEdit) return false;
    return ref.read(productPhotosProvider(null)).main != null ||
        ref.read(productVariantsProvider).hasChanges;
  }

  @override
  void dispose() {
    _unsavedChanges.release(_hasUnsavedChanges);
    for (final controller in [
      _name,
      _description,
      _barcode,
      _price,
      _cost,
      _initialStock,
      _minimumStock,
      _maximumStock,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final createdId = _createdId;
    if (createdId != null) return _uploadPhotos(createdId);

    final categoryId = _categoryId;
    final variantError = _checkVariants();
    setState(() {
      _categoryMissing = categoryId == null;
      _variantError = variantError;
    });
    final valid = _formKey.currentState!.validate();
    if (!valid || categoryId == null || variantError != null) return;

    final current = _current;
    final values = ProductFormValues(
      kind: _kind,
      name: _name.text,
      categoryId: categoryId,
      description: _description.text,
      unit: _unit,
      barcode: _barcode.text,
      price: parseAmount(_price.text) ?? 0,
      iva: IvaRate.values.firstWhere(
        (rate) => rate.code == current?.ivaRate,
        orElse: () => IvaRate.rate16,
      ),
      ieps: IepsRate.values.firstWhere(
        (rate) => rate.code == current?.iepsRate,
        orElse: () => IepsRate.none,
      ),
      iepsQuantity: current?.iepsQuantityFactor,
      cost: parseAmount(_cost.text) ?? 0,
      initialStock: parseAmount(_initialStock.text) ?? 0,
      minimumStock: parseAmount(_minimumStock.text) ?? 0,
      maximumStock: parseAmount(_maximumStock.text),
      variants: _variantsToCreate(),
    );
    final savedId = await ref
        .read(productFormControllerProvider.notifier)
        .save(
          current == null
              ? toCreateProductRequest(values)
              : toUpdateProductRequest(values, current),
          productId: current?.id,
        );
    if (savedId == null || !mounted) return;
    if (current != null) {
      _saved = true;
      return context.go(AppRoutes.products);
    }

    setState(() => _createdId = savedId);
    await _uploadPhotos(savedId);
  }

  Future<void> _uploadPhotos(String productId) async {
    final uploaded = await ref
        .read(productPhotosProvider(null).notifier)
        .uploadPending(productId);
    if (uploaded && mounted) context.go(AppRoutes.products);
  }

  Widget _informationCard(AsyncValue<List<CategoryModel>> options) {
    final categories = options.value ?? const <CategoryModel>[];
    final loading = options.isLoading && !options.hasValue;
    final loadFailed = options.hasError;
    final colors = context.casca;
    final errorStyle = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: colors.danger);
    final current = _current;
    final currentListed = categories.any(
      (category) => category.id == current?.categoryId,
    );

    return CascaCard(
      child: _FieldColumn([
        ProductPhotosField(productId: current?.id),
        ProductField(
          label: 'Nombre',
          child: CascaInput(
            controller: _name,
            hintText: 'Nombre del producto',
            maxLength: _maxNameLength,
            textInputAction: TextInputAction.next,
            validator: validateProductName,
          ),
        ),
        ProductField(
          label: 'Tipo',
          child: CascaSegmentedControl<ProductKind>(
            segments: [
              for (final kind in ProductKind.values)
                CascaSegment(value: kind, label: kind.label),
            ],
            value: _kind,
            enabled: !_isEdit,
            onChanged: (kind) => setState(() => _kind = kind),
          ),
        ),
        ProductField(
          label: 'Categoría',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (loading)
                const CascaSkeleton(height: CascaSpacing.space8)
              else
                CascaSelect<String>(
                  options: [
                    if (current?.categoryId != null && !currentListed)
                      CascaSelectOption(
                        value: current!.categoryId!,
                        label: current.categoryName ?? 'Categoría actual',
                      ),
                    for (final category in categories)
                      CascaSelectOption(
                        value: category.id,
                        label: category.parentCategoryName == null
                            ? category.name
                            : '${category.parentCategoryName} › ${category.name}',
                      ),
                  ],
                  value: _categoryId,
                  hintText: 'Selecciona una categoría',
                  onChanged: (id) => setState(() {
                    _categoryId = id;
                    _categoryMissing = false;
                  }),
                ),
              if (_categoryMissing)
                Text('Selecciona una categoría', style: errorStyle),
              if (loadFailed)
                Text(
                  'No fue posible cargar las categorías.',
                  style: errorStyle,
                ),
            ],
          ),
        ),
        ProductField(
          label: 'Descripción',
          child: CascaInput(
            controller: _description,
            hintText: 'Descripción del producto',
            maxLength: _maxDescriptionLength,
            lines: 3,
          ),
        ),
      ]),
    );
  }

  Widget _priceCard() {
    final textTheme = Theme.of(context).textTheme;
    return CascaCard(
      title: 'Precio',
      child: _FieldColumn([
        ProductFieldRow(
          children: [
            ProductField(
              label: 'Venta',
              child: ProductAmountInput(
                controller: _price,
                hintText: '0.00',
                money: true,
                enabled: !_isEdit,
                validator: _isEdit ? null : validatePrice,
              ),
            ),
            ProductField(
              label: _isEdit && !_isService ? 'Costo promedio' : 'Costo',
              child: ProductAmountInput(
                controller: _cost,
                hintText: '0.00',
                money: true,
                enabled: !_isEdit,
                validator: _isEdit
                    ? null
                    : (value) => _isService
                          ? validateOptionalAmount(value)
                          : validateCost(
                              value,
                              initialStock:
                                  parseAmount(_initialStock.text) ?? 0,
                            ),
              ),
            ),
            _ProfitField(price: _price, cost: _cost, isService: _isService),
          ],
        ),
        if (!_isService)
          ProductFieldRow(
            children: [
              ProductField(
                label: 'Unidad de medida',
                child: CascaSelect<ProductUnit>(
                  options: [
                    for (final unit in ProductUnit.values)
                      CascaSelectOption(value: unit, label: unit.label),
                  ],
                  value: _unit,
                  enabled: !_isEdit,
                  onChanged: (unit) => setState(() => _unit = unit),
                ),
              ),
              ProductField(
                label: 'Código de barras',
                child: CascaInput(
                  controller: _barcode,
                  hintText: 'Opcional',
                  enabled: !_isEdit,
                  maxLength: _maxBarcodeLength,
                  action: cascaScanButton(
                    context,
                    ref,
                    controller: _barcode,
                    maxLength: _maxBarcodeLength,
                  ),
                ),
              ),
            ],
          ),
        if (_isEdit)
          Text(
            'El precio, el costo, la unidad y el código todavía no se pueden cambiar aquí.',
            style: textTheme.bodySmall,
          ),
      ]),
    );
  }

  Widget _inventoryCard() {
    return CascaCard(
      title: 'Inventario',
      child: ProductFieldRow(
        children: [
          ProductField(
            label: _isEdit ? 'Existencias' : 'Stock inicial',
            child: ProductAmountInput(
              controller: _initialStock,
              hintText: '0',
              unit: _unit.symbol,
              enabled: !_isEdit,
              validator: validateOptionalAmount,
            ),
          ),
          ProductField(
            label: 'Stock mínimo',
            child: ProductAmountInput(
              controller: _minimumStock,
              hintText: '0',
              unit: _unit.symbol,
              validator: validateOptionalAmount,
            ),
          ),
          ProductField(
            label: 'Stock máximo',
            child: ProductAmountInput(
              controller: _maximumStock,
              hintText: 'Opcional',
              unit: _unit.symbol,
              validator: (value) => validateMaximumStock(
                value,
                minimumStock: parseAmount(_minimumStock.text) ?? 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final categories = ref.watch(productCategoryOptionsProvider);
    final saveState = ref.watch(productFormControllerProvider);
    final uploading = ref.watch(
      productPhotosProvider(_current?.id).select((state) => state.busy),
    );
    final saving = saveState.isLoading || (!_isEdit && uploading);
    final error = saveState.error;
    final photosPending = _createdId != null && !saving;
    final showVariants = !_isEdit && !_isService;
    var usesVariants = false;
    if (!_isEdit) {
      final hasDraftVariants = ref.watch(
        productVariantsProvider.select((state) => state.variants.isNotEmpty),
      );
      usesVariants = showVariants && hasDraftVariants;
      ref.listen(productVariantsProvider, (_, _) {
        if (_variantError != null) setState(() => _variantError = null);
      });
    }
    final showInventory = !_isService && !_hasVariants && !usesVariants;

    final information = _informationCard(categories);
    final price = usesVariants || _hasVariants ? null : _priceCard();
    final managedId = _isService ? null : _current?.id;
    final inventory = showInventory ? _inventoryCard() : null;

    final messages = [
      ?_variantError,
      if (photosPending)
        'El producto se guardó, pero algunas fotos no se subieron.',
      if (error != null)
        apiErrorMessage(
          error,
          _isEdit
              ? 'No fue posible actualizar el producto.'
              : 'No fue posible crear el producto.',
          forbidden: 'No tienes permiso para esta acción.',
        ),
    ];

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: pagePadding(context),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _isEdit ? 'Editar producto' : 'Nuevo producto',
                        style: textTheme.headlineMedium?.copyWith(
                          fontWeight: CascaFontWeight.semibold,
                        ),
                      ),
                      const SizedBox(height: CascaSpacing.space5),
                      _CardColumn([
                        information,
                        ?price,
                        ?inventory,
                        if (showVariants) const ProductVariantsSection(),
                        if (managedId != null)
                          ProductVariantsManager(productId: managedId),
                      ]),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        _ActionsFooter(
          messages: messages,
          cancelLabel: _createdId == null ? 'Cancelar' : 'Ir a la lista',
          saveLabel: _createdId == null ? 'Guardar' : 'Reintentar fotos',
          saving: saving,
          onCancel: () => context.go(AppRoutes.products),
          onSave: _save,
        ),
      ],
    );
  }
}

class _ActionsFooter extends StatelessWidget {
  const _ActionsFooter({
    required this.messages,
    required this.cancelLabel,
    required this.saveLabel,
    required this.saving,
    required this.onCancel,
    required this.onSave,
  });

  final List<String> messages;
  final String cancelLabel;
  final String saveLabel;
  final bool saving;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final stacked = MediaQuery.sizeOf(context).width <= mobileBreakpoint;
    final cancel = CascaButton(
      label: cancelLabel,
      variant: CascaButtonVariant.secondary,
      fullWidth: stacked,
      onPressed: saving ? null : onCancel,
    );
    final save = CascaButton(
      label: saveLabel,
      loading: saving,
      fullWidth: stacked,
      onPressed: onSave,
    );

    final horizontal = stacked ? CascaSpacing.space4 : CascaSpacing.space7;

    return Container(
      key: const Key('product-form-footer'),
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        horizontal,
        CascaSpacing.space3,
        horizontal,
        CascaSpacing.space3 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final message in messages)
                Padding(
                  padding: const EdgeInsets.only(bottom: CascaSpacing.space2),
                  child: Text(
                    message,
                    textAlign: TextAlign.end,
                    style: textTheme.bodyMedium?.copyWith(color: colors.danger),
                  ),
                ),
              if (stacked) ...[
                save,
                const SizedBox(height: CascaSpacing.space2),
                cancel,
              ] else
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    cancel,
                    const SizedBox(width: CascaSpacing.space3),
                    save,
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfitField extends StatelessWidget {
  const _ProfitField({
    required this.price,
    required this.cost,
    required this.isService,
  });

  final TextEditingController price;
  final TextEditingController cost;
  final bool isService;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;

    return ProductField(
      label: 'Ganancia',
      child: ListenableBuilder(
        listenable: Listenable.merge([price, cost]),
        builder: (context, _) {
          final sale = parseAmount(price.text);
          final margin = sale == null
              ? null
              : profitMargin(
                  sale,
                  parseAmount(cost.text) ?? 0,
                  allowZeroCost: isService,
                );
          final percentage = margin?.percentage;
          final text = margin == null
              ? '—'
              : '${formatMoney(margin.amount)}${percentage == null ? '' : ' ($percentage%)'}';

          return SizedBox(
            height: CascaSpacing.space8,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                text,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: switch (margin?.tone) {
                    ProfitTone.positive => colors.success,
                    ProfitTone.negative => colors.danger,
                    _ => colors.textSecondary,
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FieldColumn extends StatelessWidget {
  const _FieldColumn(this.children);

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, child) in children.indexed) ...[
          if (index > 0) const SizedBox(height: CascaSpacing.space4),
          child,
        ],
      ],
    );
  }
}

class _CardColumn extends StatelessWidget {
  const _CardColumn(this.cards);

  final List<Widget> cards;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, card) in cards.indexed) ...[
          if (index > 0) const SizedBox(height: CascaSpacing.space4),
          card,
        ],
      ],
    );
  }
}
