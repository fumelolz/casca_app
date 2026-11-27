import 'dart:typed_data';

class SpoolerPrinter {
  const SpoolerPrinter({
    required this.name,
    required this.port,
    this.offline = false,
  });

  final String name;
  final String port;
  final bool offline;
}

abstract class PrintSpooler {
  List<SpoolerPrinter> printers();

  void printRaw(String printerName, Uint8List data);
}
