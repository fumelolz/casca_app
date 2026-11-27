const List<String> _preferredCharacteristics = [
  '49535343-8841-43f4-a8d4-ecbe34729bb3',
  '00002af1-0000-1000-8000-00805f9b34fb',
  'bef8d6c9-9c21-4c9e-b632-bd58c1009f9f',
  '6e400002-b5a3-f393-e0a9-e50e24dcca9e',
  '0000ff02-0000-1000-8000-00805f9b34fb',
  '0000fff2-0000-1000-8000-00805f9b34fb',
  '0000ffe1-0000-1000-8000-00805f9b34fb',
  '0000ae01-0000-1000-8000-00805f9b34fb',
];

class PrinterChannel {
  const PrinterChannel({
    required this.serviceId,
    required this.characteristicId,
    required this.withResponse,
    required this.withoutResponse,
  });

  final String serviceId;
  final String characteristicId;
  final bool withResponse;
  final bool withoutResponse;

  bool get writable => withResponse || withoutResponse;
}

PrinterChannel? pickPrinterChannel(Iterable<PrinterChannel> channels) {
  final writable = channels.where((channel) => channel.writable).toList();
  for (final id in _preferredCharacteristics) {
    for (final channel in writable) {
      if (channel.characteristicId.toLowerCase() == id) return channel;
    }
  }
  return null;
}
