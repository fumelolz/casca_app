import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/shared/ui/casca_barcode_camera.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_icon.dart';
import 'package:casca_app/shared/ui/casca_input.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

typedef BarcodeCameraBuilder = Widget Function(ValueChanged<String> onDetected);

final barcodeCameraProvider = Provider<BarcodeCameraBuilder?>(
  (ref) => cascaCameraScanSupported
      ? (onDetected) => CascaBarcodeCamera(onDetected: onDetected)
      : null,
);

CascaInputButton? cascaScanButton(
  BuildContext context,
  WidgetRef ref, {
  required TextEditingController controller,
  required int maxLength,
}) {
  if (ref.watch(barcodeCameraProvider) == null) return null;

  return CascaInputButton(
    label: 'Escanear código de barras',
    icon: CascaIcons.barcode,
    onPressed: () async {
      FocusManager.instance.primaryFocus?.unfocus();
      final code = await showDialog<String>(
        context: context,
        builder: (_) => _BarcodeScanner(maxLength: maxLength),
      );
      if (code != null && context.mounted) controller.text = code;
    },
  );
}

class _BarcodeScanner extends ConsumerStatefulWidget {
  const _BarcodeScanner({required this.maxLength});

  final int maxLength;

  @override
  ConsumerState<_BarcodeScanner> createState() => _BarcodeScannerState();
}

class _BarcodeScannerState extends ConsumerState<_BarcodeScanner> {
  bool _read = false;

  void _detected(String value) {
    final code = value.trim();
    if (_read || code.isEmpty || code.length > widget.maxLength) return;
    _read = true;
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);
    Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) {
    final camera = ref.watch(barcodeCameraProvider);

    return Dialog.fullscreen(
      backgroundColor: context.casca.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(CascaSpacing.space4),
              child: Text(
                'Apunta al código de barras',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Expanded(child: camera?.call(_detected) ?? const SizedBox.shrink()),
            Padding(
              padding: const EdgeInsets.all(CascaSpacing.space4),
              child: CascaButton(
                label: 'Cancelar',
                variant: CascaButtonVariant.secondary,
                size: CascaButtonSize.lg,
                fullWidth: true,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
