import 'dart:async';

import 'package:casca_app/core/printing/device_printer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const Duration printerScanDuration = Duration(seconds: 12);

enum PrinterTab { tickets, labels }

class PrinterScanState {
  const PrinterScanState({
    this.scanning = false,
    this.searched = false,
    this.devices = const [],
    this.error,
  });

  final bool scanning;
  final bool searched;
  final List<PrinterDevice> devices;
  final Object? error;

  bool get foundNothing {
    return searched && !scanning && devices.isEmpty && error == null;
  }
}

class PrinterScanController extends Notifier<PrinterScanState> {
  StreamSubscription<PrinterDevice>? _subscription;
  Timer? _timer;

  @override
  PrinterScanState build() {
    ref.onDispose(_release);
    return const PrinterScanState();
  }

  void start() {
    _release();
    state = const PrinterScanState(scanning: true, searched: true);
    _timer = Timer(printerScanDuration, stop);
    _subscription = ref
        .read(devicePrinterProvider)
        .scan()
        .listen(_add, onDone: stop, onError: _fail);
  }

  void stop() {
    _release();
    state = PrinterScanState(
      searched: state.searched,
      devices: state.devices,
      error: state.error,
    );
  }

  void _fail(Object error) {
    _release();
    state = PrinterScanState(
      searched: true,
      devices: state.devices,
      error: error,
    );
  }

  void _add(PrinterDevice device) {
    if (state.devices.any((known) => known.id == device.id)) return;
    state = PrinterScanState(
      scanning: true,
      searched: true,
      devices: [...state.devices, device],
    );
  }

  void _release() {
    _timer?.cancel();
    _timer = null;
    unawaited(_subscription?.cancel());
    _subscription = null;
  }
}

final printerScanProvider =
    NotifierProvider.autoDispose<PrinterScanController, PrinterScanState>(
      PrinterScanController.new,
    );
