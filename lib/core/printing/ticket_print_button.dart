import 'dart:async';

import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/core/printing/device_printer.dart';
import 'package:casca_app/core/printing/sale_ticket.dart';
import 'package:casca_app/core/printing/ticket_print_controller.dart';
import 'package:casca_app/core/printing/ticket_printer_settings.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class TicketPrintButton extends ConsumerStatefulWidget {
  const TicketPrintButton({
    super.key,
    required this.sale,
    this.reprint = false,
    this.justSold = false,
  });

  final SaleTicket sale;
  final bool reprint;
  final bool justSold;

  @override
  ConsumerState<TicketPrintButton> createState() => _TicketPrintButtonState();
}

class _TicketPrintButtonState extends ConsumerState<TicketPrintButton> {
  bool _autoPrinted = false;

  void _print() {
    unawaited(
      ref
          .read(ticketPrintControllerProvider(widget.sale.saleNumber).notifier)
          .printSale(widget.sale, reprint: widget.reprint),
    );
  }

  void _printAutomatically() {
    _autoPrinted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _print();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final settings = ref.watch(ticketPrinterSettingsProvider);
    final configured = settings.device != null;
    final printing = ref.watch(
      ticketPrintControllerProvider(widget.sale.saleNumber),
    );
    if (widget.justSold && configured && settings.autoPrint && !_autoPrinted) {
      _printAutomatically();
    }
    Text message(String text, Color color) => Text(
      text,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: CascaSpacing.space2,
      children: [
        CascaButton(
          label: widget.reprint ? 'Reimprimir ticket' : 'Imprimir ticket',
          variant: CascaButtonVariant.secondary,
          fullWidth: true,
          loading: printing.isLoading,
          onPressed: configured ? _print : null,
        ),
        if (!configured)
          message(
            'Configura la impresora de tickets en Impresoras.',
            colors.textSecondary,
          ),
        if (printing.error case final error?)
          message(printerErrorMessage(error), colors.danger),
        if (!printing.isLoading && printing.value == true)
          message('Se envió el ticket a la impresora.', colors.success),
      ],
    );
  }
}
