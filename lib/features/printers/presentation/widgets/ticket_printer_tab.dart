import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/core/printing/ticket_print_controller.dart';
import 'package:casca_app/core/printing/ticket_printer_settings.dart';
import 'package:casca_app/features/printers/presentation/widgets/printer_card.dart';
import 'package:casca_app/shared/ui/casca_card.dart';
import 'package:casca_app/shared/ui/casca_checkbox.dart';
import 'package:casca_app/shared/ui/casca_segmented_control.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

const String _testTicketId = 'prueba';
const double _preferenceHeight = 28;

class TicketPrinterTab extends ConsumerWidget {
  const TicketPrinterTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(ticketPrinterSettingsProvider);
    final controller = ref.read(ticketPrinterSettingsProvider.notifier);
    final test = ticketPrintControllerProvider(_testTicketId);
    final printing = ref.watch(test);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: CascaSpacing.space4,
      children: [
        PrinterCard(
          title: 'Impresora de tickets (ESC/POS)',
          device: settings.device,
          printing: printing.isLoading,
          error: printing.error,
          successMessage: !printing.isLoading && printing.value == true
              ? 'Se envió el ticket a la impresora.'
              : null,
          onSelect: controller.selectDevice,
          onTest: () => ref.read(test.notifier).printTest(),
        ),
        CascaCard(
          title: 'Ancho del papel',
          child: CascaSegmentedControl<TicketPaper>(
            segments: [
              for (final paper in TicketPaper.values)
                CascaSegment(value: paper, label: '${paper.widthMm} mm'),
            ],
            value: settings.paper,
            onChanged: controller.selectPaper,
          ),
        ),
        CascaCard(
          title: 'Preferencias de impresión',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Preference(
                label: 'Imprimir el ticket al finalizar cada venta',
                value: settings.autoPrint,
                onChanged: controller.setAutoPrint,
              ),
              _Preference(
                label: 'Imprimir un duplicado de cada ticket de venta',
                value: settings.duplicate,
                onChanged: controller.setDuplicate,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Preference extends StatelessWidget {
  const _Preference({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _preferenceHeight),
      child: Row(
        children: [
          SizedBox(
            height: _preferenceHeight,
            child: CascaCheckbox(
              value: value,
              semanticLabel: label,
              onChanged: onChanged,
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(!value),
              child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ),
          ),
        ],
      ),
    );
  }
}
