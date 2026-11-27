import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/core/layout/page_padding.dart';
import 'package:casca_app/core/printing/device_printer.dart';
import 'package:casca_app/features/printers/presentation/providers/printer_scan_provider.dart';
import 'package:casca_app/features/printers/presentation/widgets/label_printer_tab.dart';
import 'package:casca_app/features/printers/presentation/widgets/ticket_printer_tab.dart';
import 'package:casca_app/shared/ui/casca_page_header.dart';
import 'package:casca_app/shared/ui/casca_segmented_control.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

const double _contentMaxWidth = 640;

class PrinterSettingsPage extends ConsumerStatefulWidget {
  const PrinterSettingsPage({super.key, this.initialTab = PrinterTab.tickets});

  final PrinterTab initialTab;

  @override
  ConsumerState<PrinterSettingsPage> createState() =>
      _PrinterSettingsPageState();
}

class _PrinterSettingsPageState extends ConsumerState<PrinterSettingsPage> {
  late PrinterTab _tab = widget.initialTab;

  void _selectTab(PrinterTab tab) {
    ref.invalidate(printerScanProvider);
    setState(() => _tab = tab);
  }

  @override
  Widget build(BuildContext context) {
    final printer = ref.watch(devicePrinterProvider);
    final transport = printer.transport == PrinterTransport.usb
        ? 'USB'
        : 'Bluetooth';

    return SingleChildScrollView(
      padding: pagePadding(context),
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: CascaSpacing.space4,
            children: [
              CascaPageHeader(
                title: 'Impresoras',
                subtitle: 'Imprime tickets y etiquetas por $transport.',
              ),
              if (printer.supported) ...[
                CascaSegmentedControl<PrinterTab>(
                  segments: const [
                    CascaSegment(value: PrinterTab.tickets, label: 'Tickets'),
                    CascaSegment(value: PrinterTab.labels, label: 'Etiquetas'),
                  ],
                  value: _tab,
                  onChanged: _selectTab,
                ),
                switch (_tab) {
                  PrinterTab.tickets => const TicketPrinterTab(),
                  PrinterTab.labels => const LabelPrinterTab(),
                },
              ] else
                Text(PrinterFailure.unsupported.message),
            ],
          ),
        ),
      ),
    );
  }
}
