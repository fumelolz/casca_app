import 'package:casca_app/core/auth/auth_controller.dart';
import 'package:casca_app/core/printing/device_printer.dart';
import 'package:casca_app/core/printing/print_queue.dart';
import 'package:casca_app/core/printing/sale_ticket.dart';
import 'package:casca_app/core/printing/sale_ticket_layout.dart';
import 'package:casca_app/core/printing/ticket_printer_settings.dart';
import 'package:casca_app/core/printing/ticket_renderer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TicketPrintController extends Notifier<AsyncValue<bool>> {
  TicketPrintController(this.ticketId);

  final String ticketId;

  @override
  AsyncValue<bool> build() => const AsyncData(false);

  Future<void> printSale(SaleTicket sale, {bool reprint = false}) {
    final session = ref.read(authControllerProvider).session;
    final header = TicketHeader(
      storeName: session?.activeStore.name ?? '',
      tenantName: session?.tenantName ?? session?.activeStore.tenantName,
      cashierName: reprint ? null : session?.account.name,
    );
    final reprintedAt = reprint ? DateTime.now() : null;
    final withDuplicate =
        !reprint && ref.read(ticketPrinterSettingsProvider).duplicate;

    return _print([
      buildSaleTicket(header, sale, reprintedAt: reprintedAt),
      if (withDuplicate) buildSaleTicket(header, sale, duplicate: true),
    ]);
  }

  Future<void> printTest() {
    return _print([
      buildSaleTicket(
        const TicketHeader(storeName: 'Ticket de prueba'),
        SaleTicket(
          saleNumber: 'PRUEBA',
          createdAt: DateTime.now(),
          items: const [
            TicketItem(
              name: 'Producto de ejemplo',
              quantity: 2,
              unitPrice: 12.5,
              total: 25,
            ),
          ],
          payments: const [
            TicketPayment(
              method: 0,
              amount: 25,
              cashReceived: 50,
              changeGiven: 25,
            ),
          ],
          subtotal: 25,
          total: 25,
        ),
      ),
    ]);
  }

  Future<void> _print(List<List<TicketBlock>> tickets) async {
    final settings = ref.read(ticketPrinterSettingsProvider);
    final device = settings.device;
    if (state.isLoading || device == null) return;

    final printer = ref.read(devicePrinterProvider);
    final encode = ref.read(ticketEncoderProvider);
    final queue = ref.read(printQueueProvider);
    final link = ref.keepAlive();
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      await queue.add(() async {
        for (final blocks in tickets) {
          await printer.send(device.id, await encode(blocks, settings.paper));
        }
      });
      return true;
    });
    if (ref.mounted) state = result;
    link.close();
  }
}

final ticketPrintControllerProvider = NotifierProvider.autoDispose
    .family<TicketPrintController, AsyncValue<bool>, String>(
      TicketPrintController.new,
    );
