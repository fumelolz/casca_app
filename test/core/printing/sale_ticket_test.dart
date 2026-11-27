import 'dart:typed_data';

import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/core/auth/auth_repository.dart';
import 'package:casca_app/core/printing/device_printer.dart';
import 'package:casca_app/core/printing/escpos_encoder.dart';
import 'package:casca_app/core/printing/marketing_qr.dart';
import 'package:casca_app/core/printing/sale_ticket.dart';
import 'package:casca_app/core/printing/sale_ticket_layout.dart';
import 'package:casca_app/core/printing/ticket_print_button.dart';
import 'package:casca_app/core/printing/ticket_printer_settings.dart';
import 'package:casca_app/core/printing/ticket_renderer.dart';
import 'package:casca_app/core/storage/preferences_storage.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/fake_auth_repository.dart';

const _json = <String, dynamic>{
  'saleNumber': 'V-15',
  'createdOnUtc': '2026-11-26T18:00:00Z',
  'customerName': null,
  'subtotal': 100,
  'ivaTotal': 16,
  'iepsTotal': 0,
  'totalAmount': 116,
  'roundingAdjustment': 0,
  'payments': [
    {'method': 0, 'amount': 116, 'cashReceived': 200, 'changeGiven': 84},
  ],
  'items': [
    {'displayName': 'Arroz', 'quantity': 2, 'unitPrice': 58, 'total': 116},
  ],
};

class _FakePrinter implements DevicePrinter {
  final sent = <Uint8List>[];

  @override
  bool get supported => true;

  @override
  PrinterTransport get transport => PrinterTransport.usb;

  @override
  Stream<PrinterDevice> scan() => const Stream.empty();

  @override
  Future<void> send(String deviceId, Uint8List data) async => sent.add(data);
}

class _Storage extends PreferencesStorage {
  _Storage([this.preferences = '']);

  final String preferences;

  @override
  Future<String?> read(String key) async {
    return key == PreferencesStorage.ticketPrinterKey
        ? '{"deviceId":"POS-80C","paperWidthMm":58$preferences}'
        : null;
  }
}

void main() {
  test('arma el ticket con productos, totales y cambio', () {
    final blocks = buildSaleTicket(
      const TicketHeader(storeName: 'Centro', cashierName: 'Ana'),
      SaleTicket.tryParse(_json)!,
    );
    final rows = {
      for (final row in blocks.whereType<TicketRow>()) row.label: row.value,
    };
    final texts = blocks.whereType<TicketText>().map((block) => block.text);

    expect(rows['2 x \$58.00'], r'$116.00');
    expect(rows['IVA:'], r'$16.00');
    expect(rows.containsKey('IEPS:'), isFalse);
    expect(rows['Efectivo:'], r'$116.00');
    expect(rows['Cambio:'], r'$84.00');
    expect(texts, containsAll(['Centro', 'Arroz', 'Atendió: Ana']));
    expect(texts, isNot(contains('*** REIMPRESIÓN ***')));
  });

  test('una respuesta sin partidas no genera ticket', () {
    expect(SaleTicket.tryParse({..._json, 'items': const []}), isNull);
    expect(SaleTicket.tryParse(const {'saleNumber': 'V-1'}), isNull);
  });

  test('convierte la imagen a comandos ESC/POS', () {
    final pixels = Uint8List(16 * 2 * 4)..fillRange(0, 16 * 2 * 4, 255);
    pixels.fillRange(0, 3, 0);

    expect(encodeEscPosImage(pixels, width: 16), [
      0x1B,
      0x40,
      0x1D,
      0x76,
      0x30,
      0x00,
      2,
      0,
      2,
      0,
      0x80,
      0,
      0,
      0,
      0x1B,
      0x64,
      0x04,
      0x1D,
      0x56,
      0x42,
      0x03,
    ]);
  });

  testWidgets('dibuja el ticket con el ancho del papel', (tester) async {
    final blocks = buildSaleTicket(
      const TicketHeader(storeName: 'Centro'),
      SaleTicket.tryParse(_json)!,
    );

    final bytes = await tester.runAsync(
      () => encodeTicket(blocks, TicketPaper.mm58),
    );

    expect(bytes!.sublist(0, 8), [0x1B, 0x40, 0x1D, 0x76, 0x30, 0, 48, 0]);
  });

  testWidgets('imprime el QR de la página módulo por módulo', (tester) async {
    const paperBytes = 48;
    const moduleDots = 6;

    final bytes = await tester.runAsync(
      () =>
          encodeTicket(const [TicketQr(marketingQrModules)], TicketPaper.mm58),
    );

    const imageStart = 10;
    final left = (384 - marketingQrModules.length * moduleDots) ~/ 2;
    const top = 24;
    final printed = [
      for (var row = 0; row < marketingQrModules.length; row++)
        [
          for (var column = 0; column < marketingQrModules.length; column++)
            () {
              final x = left + column * moduleDots + moduleDots ~/ 2;
              var y = top + row * moduleDots + moduleDots ~/ 2;
              var offset = imageStart;
              while (y >= 128) {
                offset += 128 * paperBytes + 8;
                y -= 128;
              }
              final byte = bytes![offset + y * paperBytes + (x >> 3)];
              return byte & (0x80 >> (x & 7)) != 0 ? '#' : '.';
            }(),
        ].join(),
    ];

    expect(printed, marketingQrModules);
  });

  testWidgets('al vender imprime solo, con su duplicado marcado', (
    tester,
  ) async {
    final printer = _FakePrinter();
    final printed = <List<TicketBlock>>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          devicePrinterProvider.overrideWithValue(printer),
          preferencesStorageProvider.overrideWithValue(
            _Storage(',"autoPrint":true,"duplicate":true'),
          ),
          ticketEncoderProvider.overrideWithValue((blocks, paper) async {
            printed.add(blocks);
            return Uint8List(1);
          }),
        ],
        child: MaterialApp(
          theme: CascaTheme.light,
          home: Scaffold(
            body: TicketPrintButton(
              sale: SaleTicket.tryParse(_json)!,
              justSold: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    bool isDuplicate(List<TicketBlock> blocks) => blocks
        .whereType<TicketText>()
        .any((block) => block.text == '*** DUPLICADO ***');

    expect(printer.sent, hasLength(2));
    expect(printed.map(isDuplicate), [false, true]);
  });

  testWidgets('el botón reimprime en la impresora guardada', (tester) async {
    final printer = _FakePrinter();
    List<TicketBlock>? printed;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          devicePrinterProvider.overrideWithValue(printer),
          preferencesStorageProvider.overrideWithValue(_Storage()),
          ticketEncoderProvider.overrideWithValue((blocks, paper) async {
            printed = blocks;
            return Uint8List.fromList([paper.widthMm]);
          }),
        ],
        child: MaterialApp(
          theme: CascaTheme.light,
          home: Scaffold(
            body: TicketPrintButton(
              sale: SaleTicket.tryParse(_json)!,
              reprint: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(CascaButton));
    await tester.pumpAndSettle();

    expect(printer.sent.single, [58]);
    expect(
      printed!.whereType<TicketText>().map((block) => block.text),
      contains('*** REIMPRESIÓN ***'),
    );
    expect(find.text('Se envió el ticket a la impresora.'), findsOneWidget);
  });
}
