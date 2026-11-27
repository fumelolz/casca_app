import 'dart:async';
import 'dart:math';

import 'package:casca_app/core/printing/device_printer.dart';
import 'package:casca_app/core/printing/printer_channel_rules.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_ble/universal_ble.dart';

const Duration _connectTimeout = Duration(seconds: 15);
const int _connectAttempts = 4;
const Duration _retryPause = Duration(milliseconds: 700);
const Duration _powerTimeout = Duration(seconds: 3);
const Duration _chunkPause = Duration(milliseconds: 20);
const Duration _flushPause = Duration(milliseconds: 500);
const int _requestedMtu = 185;
const int _attHeaderBytes = 3;
const int _minChunkBytes = 20;
const int _maxChunkBytes = 180;

class BlePrinter implements DevicePrinter {
  @override
  bool get supported {
    return !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
  }

  @override
  PrinterTransport get transport => PrinterTransport.bluetooth;

  @override
  Stream<PrinterDevice> scan() {
    late final StreamController<PrinterDevice> controller;
    StreamSubscription<BleDevice>? results;

    Future<void> start() async {
      try {
        await _ensureReady();
        if (controller.isClosed) return;
        results = UniversalBle.scanStream.listen((device) {
          final name = device.name ?? '';
          if (name.isEmpty || controller.isClosed) return;
          controller.add(PrinterDevice(id: device.deviceId, name: name));
        });
        await UniversalBle.startScan();
      } on PrinterException catch (error) {
        if (!controller.isClosed) controller.addError(error);
      } catch (_) {
        if (!controller.isClosed) {
          controller.addError(
            const PrinterException(PrinterFailure.bluetoothOff),
          );
        }
      }
    }

    Future<void> stop() async {
      await results?.cancel();
      try {
        await UniversalBle.stopScan();
      } catch (_) {
        return;
      }
    }

    controller = StreamController<PrinterDevice>(
      onListen: start,
      onCancel: stop,
    );
    return controller.stream;
  }

  @override
  Future<void> send(String deviceId, Uint8List data) async {
    await _ensureReady();
    try {
      await _connect(deviceId);
      final services = await UniversalBle.discoverServices(deviceId);
      final channel = pickPrinterChannel([
        for (final service in services)
          for (final characteristic in service.characteristics)
            PrinterChannel(
              serviceId: service.uuid,
              characteristicId: characteristic.uuid,
              withResponse: characteristic.properties.contains(
                CharacteristicProperty.write,
              ),
              withoutResponse: characteristic.properties.contains(
                CharacteristicProperty.writeWithoutResponse,
              ),
            ),
      ]);
      if (channel == null) {
        throw const PrinterException(PrinterFailure.notPrinter);
      }

      await _write(deviceId, channel, data, await _chunkSize(deviceId));
      await Future<void>.delayed(_flushPause);
    } on PrinterException {
      rethrow;
    } catch (_) {
      throw const PrinterException(PrinterFailure.connection);
    } finally {
      await _disconnect(deviceId);
    }
  }

  Future<void> _ensureReady() async {
    if (!supported) {
      throw const PrinterException(PrinterFailure.unsupported);
    }
    try {
      await UniversalBle.requestPermissions();
    } catch (_) {
      throw const PrinterException(PrinterFailure.permission);
    }

    var state = await UniversalBle.getBluetoothAvailabilityState();
    if (state == AvailabilityState.unknown ||
        state == AvailabilityState.resetting) {
      state = await UniversalBle.availabilityStream
          .firstWhere((next) => next == AvailabilityState.poweredOn)
          .timeout(_powerTimeout, onTimeout: () => state);
    }
    switch (state) {
      case AvailabilityState.poweredOn:
        return;
      case AvailabilityState.unauthorized:
        throw const PrinterException(PrinterFailure.permission);
      case AvailabilityState.unsupported:
        throw const PrinterException(PrinterFailure.unsupported);
      default:
        throw const PrinterException(PrinterFailure.bluetoothOff);
    }
  }

  Future<void> _connect(String deviceId) async {
    for (var attempt = 1; ; attempt++) {
      try {
        return await UniversalBle.connect(deviceId, timeout: _connectTimeout);
      } on TimeoutException {
        rethrow;
      } catch (error) {
        debugPrint('Intento $attempt de conexión con la impresora: $error');
        if (attempt == _connectAttempts) rethrow;
        await _disconnect(deviceId);
        await Future<void>.delayed(_retryPause * attempt);
      }
    }
  }

  Future<int> _chunkSize(String deviceId) async {
    try {
      final mtu = await UniversalBle.requestMtu(deviceId, _requestedMtu);
      return (mtu - _attHeaderBytes).clamp(_minChunkBytes, _maxChunkBytes);
    } catch (_) {
      return _minChunkBytes;
    }
  }

  Future<void> _write(
    String deviceId,
    PrinterChannel channel,
    Uint8List data,
    int chunkSize,
  ) async {
    for (var start = 0; start < data.length; start += chunkSize) {
      await UniversalBle.write(
        deviceId,
        channel.serviceId,
        channel.characteristicId,
        data.sublist(start, min(start + chunkSize, data.length)),
        withoutResponse: !channel.withResponse,
      );
      await Future<void>.delayed(_chunkPause);
    }
  }

  Future<void> _disconnect(String deviceId) async {
    try {
      await UniversalBle.disconnect(deviceId);
    } catch (_) {
      return;
    }
  }
}
