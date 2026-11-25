import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_modal.dart';
import 'package:material_ui/material_ui.dart';

class CascaDeleteModal extends StatelessWidget {
  const CascaDeleteModal({
    super.key,
    required this.title,
    required this.message,
    required this.onConfirm,
    this.deleting = false,
    this.errorMessage,
  });

  final String title;
  final String message;
  final VoidCallback onConfirm;
  final bool deleting;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;

    return CascaModal(
      title: title,
      actions: [
        CascaButton(
          label: 'Cancelar',
          variant: CascaButtonVariant.secondary,
          onPressed: deleting ? null : () => Navigator.of(context).pop(false),
        ),
        CascaButton(
          label: 'Eliminar',
          variant: CascaButtonVariant.danger,
          loading: deleting,
          onPressed: onConfirm,
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(message, style: textTheme.bodyMedium),
          if (errorMessage != null) ...[
            const SizedBox(height: CascaSpacing.space4),
            Text(
              errorMessage!,
              style: textTheme.bodyMedium?.copyWith(color: colors.danger),
            ),
          ],
        ],
      ),
    );
  }
}
