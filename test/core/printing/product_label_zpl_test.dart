import 'package:casca_app/core/printing/label_printer_settings.dart';
import 'package:casca_app/core/printing/printer_channel_rules.dart';
import 'package:casca_app/core/printing/product_label.dart';
import 'package:casca_app/core/printing/product_label_zpl.dart';
import 'package:flutter_test/flutter_test.dart';

const _label = ProductLabel(
  name: 'Arroz',
  sku: 'ARR-1',
  barcode: '750999',
  price: 1234.5,
);

PrinterChannel _channel(String id, {bool writable = true}) {
  return PrinterChannel(
    serviceId: 's',
    characteristicId: id,
    withResponse: writable,
    withoutResponse: false,
  );
}

void main() {
  test('arma la etiqueta igual que el agente de impresión', () {
    expect(
      buildProductLabelZpl(_label, copies: 3),
      '^XA^CI28^MNY^MTD^PW408^LL200^LH0,0'
      '^FO16,10^A0N,30,30^FB376,1,0,C^FDArroz^FS'
      '^FO16,44^A0N,24,24^FB376,1,0,C^FDARR-1^FS'
      '^FO16,72^A0N,34,34^FB376,1,0,C^FD\$1,234.50^FS'
      '^FO136,110^BY2^BCN,54,N,N,N,N^FD>;750999^FS'
      '^FO16,168^A0N,22,22^FB376,1,0,C^FD750999^FS'
      '^PQ3^XZ',
    );
  });

  test('sin código de barras usa el SKU y no lo repite', () {
    final zpl = buildProductLabelZpl(
      const ProductLabel(name: 'Arroz', sku: 'ARR-1', price: 10),
    );

    expect(zpl, contains('^FD>:ARR-1^FS'));
    expect('^FDARR-1^FS'.allMatches(zpl), hasLength(1));
  });

  test('solo imprime los datos elegidos', () {
    final zpl = buildProductLabelZpl(_label, fields: {LabelField.price});

    expect(zpl, isNot(contains('Arroz')));
    expect(zpl, isNot(contains('^BC')));
    expect(zpl, contains(r'^FO16,83^A0N,34,34^FB376,1,0,C^FD$1,234.50^FS'));
  });

  test('centra verticalmente lo que queda al quitar datos', () {
    final zpl = buildProductLabelZpl(
      _label,
      fields: {LabelField.name, LabelField.price},
    );

    expect(zpl, contains('^FO16,66^A0N,30,30'));
    expect(zpl, contains('^FO16,100^A0N,34,34'));
  });

  test('limpia los comandos escritos en el nombre y limita las copias', () {
    final zpl = buildProductLabelZpl(
      const ProductLabel(name: 'A^XZ~B', sku: 'S', price: 1),
      copies: 500,
      size: const LabelSize(widthMm: 40, heightMm: 30),
    );

    expect(zpl, contains('^FDA XZ B^FS'));
    expect(zpl, contains('^PW320^LL240'));
    expect(zpl, endsWith('^PQ100^XZ'));
  });

  test('codifica los números impares con cambio de subconjunto', () {
    final zpl = buildProductLabelZpl(
      const ProductLabel(name: 'A', sku: 'S', barcode: '12345', price: 1),
    );

    expect(zpl, contains('^FD>;1234>65^FS'));
  });

  test('elige el canal de impresión conocido e ignora los demás', () {
    final preferred = _channel('49535343-8841-43F4-A8D4-ECBE34729BB3');

    expect(
      pickPrinterChannel([
        _channel('0000ffe1-0000-1000-8000-00805f9b34fb'),
        preferred,
      ]),
      preferred,
    );
    expect(
      pickPrinterChannel([
        _channel('00002a00-0000-1000-8000-00805f9b34fb'),
        _channel(preferred.characteristicId, writable: false),
      ]),
      isNull,
    );
  });

  test('la configuración se guarda y descarta valores inválidos', () {
    final restored = LabelPrinterSettings.decode(
      '{"deviceId":"a1","deviceName":"RP425","widthMm":60,"heightMm":9000}',
    );

    expect(restored.device?.name, 'RP425');
    expect(restored.size.widthMm, 60);
    expect(restored.size.heightMm, 25);
    expect(LabelPrinterSettings.decode(restored.encode()).device?.id, 'a1');
    expect(LabelPrinterSettings.decode('roto').device, isNull);
  });
}
