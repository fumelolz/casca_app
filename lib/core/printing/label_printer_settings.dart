import 'dart:async';
import 'dart:convert';

import 'package:casca_app/core/printing/device_printer.dart';
import 'package:casca_app/core/printing/product_label.dart';
import 'package:casca_app/core/storage/preferences_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LabelPrinterSettings {
  const LabelPrinterSettings({this.device, this.size = const LabelSize()});

  factory LabelPrinterSettings.decode(String? raw) {
    if (raw == null) return const LabelPrinterSettings();
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final id = json['deviceId'] as String?;
      final width = json['widthMm'] as int?;
      final height = json['heightMm'] as int?;
      const fallback = LabelSize();

      return LabelPrinterSettings(
        device: id == null
            ? null
            : PrinterDevice(id: id, name: json['deviceName'] as String? ?? id),
        size: LabelSize(
          widthMm: LabelSize.isValidWidth(width) ? width! : fallback.widthMm,
          heightMm: LabelSize.isValidHeight(height)
              ? height!
              : fallback.heightMm,
        ),
      );
    } catch (_) {
      return const LabelPrinterSettings();
    }
  }

  final PrinterDevice? device;
  final LabelSize size;

  String encode() {
    return jsonEncode({
      'deviceId': device?.id,
      'deviceName': device?.name,
      'widthMm': size.widthMm,
      'heightMm': size.heightMm,
    });
  }
}

class LabelPrinterSettingsController extends Notifier<LabelPrinterSettings> {
  bool _changed = false;

  @override
  LabelPrinterSettings build() {
    _restore();
    return const LabelPrinterSettings();
  }

  void selectDevice(PrinterDevice? device) {
    _save(LabelPrinterSettings(device: device, size: state.size));
  }

  void resize(LabelSize size) {
    _save(LabelPrinterSettings(device: state.device, size: size));
  }

  void _save(LabelPrinterSettings settings) {
    _changed = true;
    state = settings;
    unawaited(
      ref
          .read(preferencesStorageProvider)
          .write(PreferencesStorage.labelPrinterKey, settings.encode()),
    );
  }

  Future<void> _restore() async {
    final stored = await ref
        .read(preferencesStorageProvider)
        .read(PreferencesStorage.labelPrinterKey);
    if (!ref.mounted || _changed) return;
    state = LabelPrinterSettings.decode(stored);
  }
}

final labelPrinterSettingsProvider =
    NotifierProvider<LabelPrinterSettingsController, LabelPrinterSettings>(
      LabelPrinterSettingsController.new,
    );
