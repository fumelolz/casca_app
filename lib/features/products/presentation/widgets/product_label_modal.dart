import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/core/errors/api_error_message.dart';
import 'package:casca_app/core/printing/device_printer.dart';
import 'package:casca_app/core/printing/label_print_controller.dart';
import 'package:casca_app/core/printing/label_printer_settings.dart';
import 'package:casca_app/core/printing/product_label.dart';
import 'package:casca_app/core/printing/product_label_layout.dart';
import 'package:casca_app/core/routing/app_routes.dart';
import 'package:casca_app/features/products/domain/product_label_rules.dart';
import 'package:casca_app/features/products/presentation/providers/product_form_provider.dart';
import 'package:casca_app/features/products/presentation/widgets/product_label_preview.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_checkbox.dart';
import 'package:casca_app/shared/ui/casca_modal.dart';
import 'package:casca_app/shared/ui/casca_quantity_stepper.dart';
import 'package:casca_app/shared/ui/casca_skeleton.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

Future<void> showProductLabelModal(
  BuildContext context,
  List<String> productIds, {
  VoidCallback? onPrinted,
}) {
  final router = GoRouter.of(context);

  return showCascaModal<void>(
    context: context,
    builder: (_) => ProductLabelModal(
      productIds: productIds,
      onConfigure: () => router.go(AppRoutes.labelPrinters),
      onPrinted: onPrinted,
    ),
  );
}

class ProductLabelModal extends ConsumerStatefulWidget {
  const ProductLabelModal({
    super.key,
    required this.productIds,
    required this.onConfigure,
    this.onPrinted,
  });

  final List<String> productIds;
  final VoidCallback onConfigure;
  final VoidCallback? onPrinted;

  @override
  ConsumerState<ProductLabelModal> createState() => _ProductLabelModalState();
}

class _ProductLabelModalState extends ConsumerState<ProductLabelModal> {
  final Set<LabelField> _fields = {...LabelField.values};
  final Map<int, int> _copies = {};
  bool _matchStock = false;

  int _copiesOf(int index, ProductLabel label) {
    return _copies[index] ?? (_matchStock ? copiesForStock(label.stock) : 1);
  }

  void _setCopies(int index, int copies) {
    setState(() => _copies[index] = copies.clamp(0, maxLabelCopies));
  }

  void _configure() {
    Navigator.of(context).pop();
    widget.onConfigure();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final settings = ref.watch(labelPrinterSettingsProvider);
    final device = settings.device;
    final details = [
      for (final id in widget.productIds) ref.watch(productDetailProvider(id)),
    ];
    final printing = ref.watch(labelPrintControllerProvider);
    ref.listen(labelPrintControllerProvider, (previous, next) {
      if (!next.isLoading && !next.hasError && (next.value ?? 0) > 0) {
        widget.onPrinted?.call();
      }
    });
    final products = [for (final detail in details) ?detail.value];
    final loaded = products.length == details.length;
    final loadError = details
        .where((detail) => detail.value == null)
        .map((detail) => detail.error)
        .nonNulls
        .firstOrNull;
    final labelsByProduct = loaded
        ? products.map(productLabels).toList()
        : const <List<ProductLabel>>[];
    final labels = labelsByProduct.expand((own) => own).toList();
    final withoutLabels = labelsByProduct.where((own) => own.isEmpty).length;
    final jobs = [
      for (final (index, label) in labels.indexed)
        (label: label, copies: _copiesOf(index, label)),
    ];
    final total = jobs.fold(0, (sum, job) => sum + job.copies);
    final canPrint = total > 0 && _fields.isNotEmpty;
    final previewed =
        jobs.where((job) => job.copies > 0).firstOrNull ?? jobs.firstOrNull;
    Text message(String text, [Color? color]) => Text(
      text,
      style: textTheme.bodySmall?.copyWith(
        color: color ?? colors.textSecondary,
      ),
    );

    return CascaModal(
      title: 'Imprimir etiquetas',
      actions: [
        if (device == null)
          CascaButton(label: 'Configurar impresora', onPressed: _configure)
        else
          CascaButton(
            label: total == 1
                ? 'Imprimir 1 etiqueta'
                : 'Imprimir $total etiquetas',
            loading: printing.isLoading,
            onPressed: canPrint
                ? () => ref
                      .read(labelPrintControllerProvider.notifier)
                      .printLabels(jobs, fields: {..._fields})
                : null,
          ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: CascaSpacing.space3,
        children: [
          message(
            device == null
                ? 'Elige una impresora de etiquetas para poder imprimir.'
                : 'Impresora: ${device.name}',
          ),
          Text('Datos a mostrar', style: textTheme.titleSmall),
          Wrap(
            spacing: CascaSpacing.space4,
            children: [
              for (final field in LabelField.values)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CascaCheckbox(
                      value: _fields.contains(field),
                      semanticLabel: field.label,
                      onChanged: (checked) => setState(
                        () => checked
                            ? _fields.add(field)
                            : _fields.remove(field),
                      ),
                    ),
                    Text(field.label, style: textTheme.bodyMedium),
                  ],
                ),
            ],
          ),
          if (previewed != null) ...[
            Text('Vista previa', style: textTheme.titleSmall),
            ProductLabelPreview(
              layout: layoutProductLabel(
                previewed.label,
                fields: _fields,
                size: settings.size,
              ),
            ),
            message(
              'Etiqueta de ${settings.size.widthMm} x '
              '${settings.size.heightMm} mm. La letra y las barras impresas '
              'pueden variar un poco.',
            ),
          ],
          Text('Copias', style: textTheme.titleSmall),
          if (!loaded && loadError == null)
            const CascaSkeleton(height: CascaSpacing.space8),
          if (loadError != null) ...[
            message(
              apiErrorMessage(
                loadError,
                'No fue posible obtener los productos.',
              ),
              colors.danger,
            ),
            CascaButton(
              label: 'Reintentar',
              variant: CascaButtonVariant.secondary,
              onPressed: () {
                for (final (index, detail) in details.indexed) {
                  if (detail.hasError) {
                    ref.invalidate(
                      productDetailProvider(widget.productIds[index]),
                    );
                  }
                }
              },
            ),
          ],
          if (withoutLabels > 0)
            message(
              widget.productIds.length == 1
                  ? 'Este producto no tiene precios activos para imprimir.'
                  : 'Productos sin precios activos para imprimir: '
                        '$withoutLabels.',
            ),
          for (final (index, job) in jobs.indexed)
            Row(
              spacing: CascaSpacing.space3,
              children: [
                Expanded(
                  child: Text(job.label.name, style: textTheme.bodyMedium),
                ),
                CascaQuantityStepper(
                  value: job.copies.toDouble(),
                  subject: job.label.name,
                  onChanged: (typed) {
                    _setCopies(index, typed.floor());
                    return typed.clamp(0, maxLabelCopies).toDouble();
                  },
                  onDecrease: () => _setCopies(index, job.copies - 1),
                  onIncrease: job.copies < maxLabelCopies
                      ? () => _setCopies(index, job.copies + 1)
                      : null,
                ),
              ],
            ),
          if (labels.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: CascaButton(
                label: _matchStock
                    ? 'Una etiqueta por producto'
                    : 'Igualar al stock',
                variant: CascaButtonVariant.secondary,
                size: CascaButtonSize.sm,
                onPressed: () => setState(() {
                  _matchStock = !_matchStock;
                  _copies.clear();
                }),
              ),
            ),
          if (printing.error case final error?)
            message(printerErrorMessage(error), colors.danger),
          if (!printing.isLoading && (printing.value ?? 0) > 0)
            message(
              'Etiquetas enviadas a la impresora: ${printing.value}.',
              colors.success,
            ),
        ],
      ),
    );
  }
}
