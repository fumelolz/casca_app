import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/core/printing/label_print_controller.dart';
import 'package:casca_app/core/printing/label_printer_settings.dart';
import 'package:casca_app/core/printing/product_label.dart';
import 'package:casca_app/features/printers/presentation/widgets/label_size_card.dart';
import 'package:casca_app/features/printers/presentation/widgets/printer_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

const ProductLabel _testLabel = ProductLabel(
  name: 'Etiqueta de prueba',
  sku: 'CASCA-001',
  barcode: '750000000001',
  price: 12.5,
);

class LabelPrinterTab extends ConsumerWidget {
  const LabelPrinterTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final device = ref.watch(
      labelPrinterSettingsProvider.select((s) => s.device),
    );
    final printing = ref.watch(labelPrintControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: CascaSpacing.space4,
      children: [
        PrinterCard(
          title: 'Impresora de etiquetas (ZPL)',
          device: device,
          printing: printing.isLoading,
          error: printing.error,
          successMessage: !printing.isLoading && (printing.value ?? 0) > 0
              ? 'Se envió la etiqueta a la impresora.'
              : null,
          onSelect: ref
              .read(labelPrinterSettingsProvider.notifier)
              .selectDevice,
          onTest: () => ref
              .read(labelPrintControllerProvider.notifier)
              .printLabels([(label: _testLabel, copies: 1)]),
        ),
        const LabelSizeCard(),
      ],
    );
  }
}
