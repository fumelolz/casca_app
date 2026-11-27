import 'dart:convert';

import 'package:casca_app/core/printing/device_printer.dart';
import 'package:casca_app/core/printing/label_printer_settings.dart';
import 'package:casca_app/core/printing/product_label.dart';
import 'package:casca_app/core/printing/product_label_zpl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef LabelJob = ({ProductLabel label, int copies});

class LabelPrintController extends Notifier<AsyncValue<int>> {
  @override
  AsyncValue<int> build() => const AsyncData(0);

  Future<void> printLabels(
    List<LabelJob> jobs, {
    Set<LabelField> fields = const {...LabelField.values},
  }) async {
    final settings = ref.read(labelPrinterSettingsProvider);
    final device = settings.device;
    final pending = jobs.where((job) => job.copies > 0).toList();
    if (state.isLoading || device == null || pending.isEmpty) return;

    final zpl = pending
        .map(
          (job) => buildProductLabelZpl(
            job.label,
            fields: fields,
            size: settings.size,
            copies: job.copies,
          ),
        )
        .join();
    final printer = ref.read(devicePrinterProvider);
    final link = ref.keepAlive();
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      await printer.send(device.id, utf8.encode(zpl));
      return pending.fold(0, (total, job) => total + job.copies);
    });
    if (ref.mounted) state = result;
    link.close();
  }
}

final labelPrintControllerProvider =
    NotifierProvider.autoDispose<LabelPrintController, AsyncValue<int>>(
      LabelPrintController.new,
    );
