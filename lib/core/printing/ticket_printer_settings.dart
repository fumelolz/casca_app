import 'dart:async';
import 'dart:convert';

import 'package:casca_app/core/printing/device_printer.dart';
import 'package:casca_app/core/storage/preferences_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum TicketPaper {
  mm58(58, 384),
  mm80(80, 576);

  const TicketPaper(this.widthMm, this.dots);

  final int widthMm;
  final int dots;
}

class TicketPrinterSettings {
  const TicketPrinterSettings({
    this.device,
    this.paper = TicketPaper.mm80,
    this.autoPrint = false,
    this.duplicate = false,
  });

  factory TicketPrinterSettings.decode(String? raw) {
    if (raw == null) return const TicketPrinterSettings();
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final id = json['deviceId'] as String?;

      return TicketPrinterSettings(
        device: id == null
            ? null
            : PrinterDevice(id: id, name: json['deviceName'] as String? ?? id),
        paper: TicketPaper.values.firstWhere(
          (paper) => paper.widthMm == json['paperWidthMm'],
          orElse: () => TicketPaper.mm80,
        ),
        autoPrint: json['autoPrint'] == true,
        duplicate: json['duplicate'] == true,
      );
    } catch (_) {
      return const TicketPrinterSettings();
    }
  }

  final PrinterDevice? device;
  final TicketPaper paper;
  final bool autoPrint;
  final bool duplicate;

  TicketPrinterSettings copyWith({
    TicketPaper? paper,
    bool? autoPrint,
    bool? duplicate,
  }) {
    return TicketPrinterSettings(
      device: device,
      paper: paper ?? this.paper,
      autoPrint: autoPrint ?? this.autoPrint,
      duplicate: duplicate ?? this.duplicate,
    );
  }

  TicketPrinterSettings withDevice(PrinterDevice? device) {
    return TicketPrinterSettings(
      device: device,
      paper: paper,
      autoPrint: autoPrint,
      duplicate: duplicate,
    );
  }

  String encode() {
    return jsonEncode({
      'deviceId': device?.id,
      'deviceName': device?.name,
      'paperWidthMm': paper.widthMm,
      'autoPrint': autoPrint,
      'duplicate': duplicate,
    });
  }
}

class TicketPrinterSettingsController extends Notifier<TicketPrinterSettings> {
  bool _changed = false;

  @override
  TicketPrinterSettings build() {
    _restore();
    return const TicketPrinterSettings();
  }

  void selectDevice(PrinterDevice? device) {
    _save(state.withDevice(device));
  }

  void selectPaper(TicketPaper paper) {
    _save(state.copyWith(paper: paper));
  }

  void setAutoPrint(bool autoPrint) {
    _save(state.copyWith(autoPrint: autoPrint));
  }

  void setDuplicate(bool duplicate) {
    _save(state.copyWith(duplicate: duplicate));
  }

  void _save(TicketPrinterSettings settings) {
    _changed = true;
    state = settings;
    unawaited(
      ref
          .read(preferencesStorageProvider)
          .write(PreferencesStorage.ticketPrinterKey, settings.encode()),
    );
  }

  Future<void> _restore() async {
    final stored = await ref
        .read(preferencesStorageProvider)
        .read(PreferencesStorage.ticketPrinterKey);
    if (!ref.mounted || _changed) return;
    state = TicketPrinterSettings.decode(stored);
  }
}

final ticketPrinterSettingsProvider =
    NotifierProvider<TicketPrinterSettingsController, TicketPrinterSettings>(
      TicketPrinterSettingsController.new,
    );
