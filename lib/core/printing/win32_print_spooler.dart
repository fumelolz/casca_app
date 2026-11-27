import 'dart:ffi';
import 'dart:typed_data';

import 'package:casca_app/core/printing/print_spooler.dart';
import 'package:ffi/ffi.dart';

const int _localPrinters = 0x2;
const int _infoLevel = 5;
const int _docLevel = 1;
const int _offlineAttribute = 0x400;
const String _documentName = 'Casca';

PrintSpooler createPrintSpooler() => Win32PrintSpooler();

final class _PrinterInfo5 extends Struct {
  external Pointer<Utf16> name;
  external Pointer<Utf16> port;

  @Uint32()
  external int attributes;

  @Uint32()
  external int deviceNotSelectedTimeout;

  @Uint32()
  external int transmissionRetryTimeout;
}

final class _DocInfo1 extends Struct {
  external Pointer<Utf16> documentName;
  external Pointer<Utf16> outputFile;
  external Pointer<Utf16> dataType;
}

typedef _EnumPrintersNative = Int32 Function(
  Uint32,
  Pointer<Utf16>,
  Uint32,
  Pointer<Uint8>,
  Uint32,
  Pointer<Uint32>,
  Pointer<Uint32>,
);
typedef _EnumPrinters = int Function(
  int,
  Pointer<Utf16>,
  int,
  Pointer<Uint8>,
  int,
  Pointer<Uint32>,
  Pointer<Uint32>,
);
typedef _OpenPrinterNative = Int32 Function(
  Pointer<Utf16>,
  Pointer<IntPtr>,
  Pointer<Void>,
);
typedef _OpenPrinter = int Function(
  Pointer<Utf16>,
  Pointer<IntPtr>,
  Pointer<Void>,
);
typedef _StartDocNative = Uint32 Function(IntPtr, Uint32, Pointer<_DocInfo1>);
typedef _StartDoc = int Function(int, int, Pointer<_DocInfo1>);
typedef _WritePrinterNative = Int32 Function(
  IntPtr,
  Pointer<Uint8>,
  Uint32,
  Pointer<Uint32>,
);
typedef _WritePrinter = int Function(int, Pointer<Uint8>, int, Pointer<Uint32>);
typedef _HandleCallNative = Int32 Function(IntPtr);
typedef _HandleCall = int Function(int);

class Win32PrintSpooler implements PrintSpooler {
  late final _library = DynamicLibrary.open('winspool.drv');
  late final _enumPrinters = _library
      .lookupFunction<_EnumPrintersNative, _EnumPrinters>('EnumPrintersW');
  late final _openPrinter = _library
      .lookupFunction<_OpenPrinterNative, _OpenPrinter>('OpenPrinterW');
  late final _startDoc = _library.lookupFunction<_StartDocNative, _StartDoc>(
    'StartDocPrinterW',
  );
  late final _writePrinter = _library
      .lookupFunction<_WritePrinterNative, _WritePrinter>('WritePrinter');
  late final _startPage = _handleCall('StartPagePrinter');
  late final _endPage = _handleCall('EndPagePrinter');
  late final _endDoc = _handleCall('EndDocPrinter');
  late final _closePrinter = _handleCall('ClosePrinter');

  _HandleCall _handleCall(String name) {
    return _library.lookupFunction<_HandleCallNative, _HandleCall>(name);
  }

  @override
  List<SpoolerPrinter> printers() {
    return using((arena) {
      final needed = arena<Uint32>();
      final count = arena<Uint32>();
      int enumerate(Pointer<Uint8> buffer, int size) {
        return _enumPrinters(
          _localPrinters,
          nullptr,
          _infoLevel,
          buffer,
          size,
          needed,
          count,
        );
      }

      final empty = enumerate(nullptr, 0);
      final size = needed.value;
      if (size == 0) {
        _check(empty != 0, 'EnumPrinters');
        return const <SpoolerPrinter>[];
      }
      final buffer = arena<Uint8>(size);
      _check(enumerate(buffer, size) != 0, 'EnumPrinters');
      final infos = buffer.cast<_PrinterInfo5>();

      return [
        for (var index = 0; index < count.value; index++)
          SpoolerPrinter(
            name: infos[index].name.toDartString(),
            port: infos[index].port.toDartString(),
            offline: infos[index].attributes & _offlineAttribute != 0,
          ),
      ];
    });
  }

  @override
  void printRaw(String printerName, Uint8List data) {
    using((arena) {
      final handle = arena<IntPtr>();
      final opened = _openPrinter(
        printerName.toNativeUtf16(allocator: arena),
        handle,
        nullptr,
      );
      _check(opened != 0, 'OpenPrinter');
      try {
        _writeDocument(arena, handle.value, data);
      } finally {
        _closePrinter(handle.value);
      }
    });
  }

  void _writeDocument(Arena arena, int printer, Uint8List data) {
    final info = arena<_DocInfo1>();
    info.ref
      ..documentName = _documentName.toNativeUtf16(allocator: arena)
      ..outputFile = nullptr
      ..dataType = 'RAW'.toNativeUtf16(allocator: arena);
    _check(_startDoc(printer, _docLevel, info) != 0, 'StartDocPrinter');
    try {
      _check(_startPage(printer) != 0, 'StartPagePrinter');
      final bytes = arena<Uint8>(data.length);
      bytes.asTypedList(data.length).setAll(0, data);
      final written = arena<Uint32>();
      final sent = _writePrinter(printer, bytes, data.length, written);
      _check(sent != 0 && written.value == data.length, 'WritePrinter');
      _check(_endPage(printer) != 0, 'EndPagePrinter');
    } finally {
      _endDoc(printer);
    }
  }

  void _check(bool succeeded, String operation) {
    if (!succeeded) throw StateError('Falló $operation');
  }
}
