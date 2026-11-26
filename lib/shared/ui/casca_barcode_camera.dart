import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

bool get cascaCameraScanSupported {
  return !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
}

class CascaBarcodeCamera extends StatelessWidget {
  const CascaBarcodeCamera({super.key, required this.onDetected});

  final ValueChanged<String> onDetected;

  @override
  Widget build(BuildContext context) {
    return MobileScanner(
      onDetect: (capture) {
        final value = capture.barcodes.firstOrNull?.rawValue;
        if (value != null && value.isNotEmpty) onDetected(value);
      },
      errorBuilder: (context, error) => ColoredBox(
        color: context.casca.surface,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(CascaSpacing.space6),
            child: Text(
              error.errorCode == MobileScannerErrorCode.permissionDenied
                  ? 'Permite el acceso a la cámara en los ajustes del teléfono.'
                  : 'No fue posible abrir la cámara.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      ),
    );
  }
}
