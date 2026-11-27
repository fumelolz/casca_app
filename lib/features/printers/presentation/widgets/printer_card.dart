import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/core/printing/device_printer.dart';
import 'package:casca_app/features/printers/presentation/providers/printer_scan_provider.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class PrinterCard extends ConsumerWidget {
  const PrinterCard({
    super.key,
    required this.title,
    required this.device,
    required this.printing,
    required this.error,
    required this.successMessage,
    required this.onSelect,
    required this.onTest,
  });

  final String title;
  final PrinterDevice? device;
  final bool printing;
  final Object? error;
  final String? successMessage;
  final ValueChanged<PrinterDevice?> onSelect;
  final VoidCallback onTest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final scan = ref.watch(printerScanProvider);
    final usb =
        ref.watch(devicePrinterProvider).transport == PrinterTransport.usb;
    final scanner = ref.read(printerScanProvider.notifier);
    Text message(String text, [Color? color]) => Text(
      text,
      style: textTheme.bodySmall?.copyWith(
        color: color ?? colors.textSecondary,
      ),
    );

    return CascaCard(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: CascaSpacing.space3,
        children: [
          Text(
            device?.name ?? 'No hay una impresora seleccionada.',
            style: textTheme.bodyMedium,
          ),
          if (device != null)
            Wrap(
              spacing: CascaSpacing.space3,
              runSpacing: CascaSpacing.space2,
              children: [
                CascaButton(
                  label: 'Imprimir prueba',
                  loading: printing,
                  onPressed: () {
                    scanner.stop();
                    onTest();
                  },
                ),
                CascaButton(
                  label: 'Quitar',
                  variant: CascaButtonVariant.secondary,
                  onPressed: printing ? null : () => onSelect(null),
                ),
              ],
            ),
          if (error case final error?)
            message(printerErrorMessage(error), colors.danger),
          if (successMessage case final success?)
            message(success, colors.success),
          CascaButton(
            label: 'Buscar impresoras',
            variant: CascaButtonVariant.secondary,
            loading: scan.scanning,
            onPressed: printing ? null : scanner.start,
          ),
          if (scan.error case final error?)
            message(printerErrorMessage(error), colors.danger),
          for (final found in scan.devices)
            Row(
              spacing: CascaSpacing.space3,
              children: [
                Expanded(child: Text(found.name, style: textTheme.bodyMedium)),
                CascaButton(
                  label: found.id == device?.id ? 'Seleccionada' : 'Usar',
                  variant: CascaButtonVariant.secondary,
                  size: CascaButtonSize.sm,
                  onPressed: found.id == device?.id || printing
                      ? null
                      : () {
                          scanner.stop();
                          onSelect(found);
                        },
                ),
              ],
            ),
          if (scan.foundNothing) message('No se encontraron impresoras.'),
          message(
            usb
                ? 'Aparecen las impresoras USB instaladas en Windows.'
                : 'Cierra otras apps conectadas a la impresora; solo atiende '
                      'una a la vez.',
          ),
        ],
      ),
    );
  }
}
