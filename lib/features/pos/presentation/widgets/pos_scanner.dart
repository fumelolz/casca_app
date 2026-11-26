import 'dart:async';

import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/features/pos/presentation/providers/pos_cart_provider.dart';
import 'package:casca_app/features/pos/presentation/widgets/pos_add_item.dart';
import 'package:casca_app/shared/formatters/number_formatters.dart';
import 'package:casca_app/shared/ui/casca_barcode_camera.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

typedef BarcodeCameraBuilder = Widget Function(ValueChanged<String> onDetected);

const Duration repeatDelay = Duration(seconds: 2);

final barcodeCameraProvider = Provider<BarcodeCameraBuilder?>(
  (ref) => cascaCameraScanSupported
      ? (onDetected) => CascaBarcodeCamera(onDetected: onDetected)
      : null,
);

class PosScanner extends ConsumerStatefulWidget {
  const PosScanner({super.key});

  @override
  ConsumerState<PosScanner> createState() => _PosScannerState();
}

class _PosScannerState extends ConsumerState<PosScanner> {
  Timer? _repeatTimer;
  String? _lastCode;
  bool _busy = false;
  AddOutcome? _outcome;

  Future<void> _detected(String code) async {
    if (_busy || code == _lastCode) return;
    _busy = true;
    _lastCode = code;
    _repeatTimer?.cancel();

    final outcome = await addCodeToCart(context, ref, code);
    if (!mounted) return;
    _busy = false;
    _repeatTimer = Timer(repeatDelay, () => _lastCode = null);
    if (outcome == null) return;
    if (outcome.added) {
      unawaited(HapticFeedback.mediumImpact());
      unawaited(SystemSound.play(SystemSoundType.click));
    }
    setState(() => _outcome = outcome);
  }

  @override
  void dispose() {
    _repeatTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final camera = ref.watch(barcodeCameraProvider);
    final cart = ref.watch(cartProvider);
    final count = cart.lines.length;
    final total = cart.preview?.finalTotal;
    final outcome = _outcome;

    return Dialog.fullscreen(
      backgroundColor: colors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(CascaSpacing.space4),
              child: Text(
                'Apunta al código de barras',
                textAlign: TextAlign.center,
                style: textTheme.titleMedium,
              ),
            ),
            Expanded(child: camera?.call(_detected) ?? const SizedBox.shrink()),
            Padding(
              padding: const EdgeInsets.all(CascaSpacing.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: CascaSpacing.space3,
                children: [
                  if (outcome != null)
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        outcome.message,
                        textAlign: TextAlign.center,
                        style: textTheme.titleSmall?.copyWith(
                          color: outcome.added ? colors.success : colors.danger,
                        ),
                      ),
                    ),
                  Text(
                    '$count ${count == 1 ? 'producto' : 'productos'}'
                    '${total == null ? '' : ' · ${formatMoney(total)}'}',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium,
                  ),
                  CascaButton(
                    label: 'Listo',
                    size: CascaButtonSize.lg,
                    fullWidth: true,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
