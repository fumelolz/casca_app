import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/app/theme/casca_typography.dart';
import 'package:casca_app/features/auth/domain/password_rules.dart';
import 'package:casca_app/shared/ui/casca_icon.dart';
import 'package:material_ui/material_ui.dart';

class PasswordRequirementsHint extends StatelessWidget {
  const PasswordRequirementsHint({
    super.key,
    required this.password,
    this.showMissingAsError = false,
  });

  final String password;
  final bool showMissingAsError;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final missing = [
      for (final check in checkPassword(password))
        if (!check.met) check.shortLabel,
    ];

    if (missing.isEmpty) {
      return Row(
        children: [
          CascaIcon(
            CascaIcons.circleCheck,
            size: CascaFontSize.sm,
            color: colors.success,
          ),
          const SizedBox(width: CascaSpacing.space2),
          Text(
            'Contraseña segura',
            style: textTheme.bodySmall?.copyWith(color: colors.success),
          ),
        ],
      );
    }

    final text = password.isEmpty
        ? 'Debe tener 8 caracteres, mayúscula, minúscula, número y carácter '
              'especial.'
        : 'Falta: ${missing.join(', ')}.';

    return Text(
      text,
      style: textTheme.bodySmall?.copyWith(
        color: showMissingAsError ? colors.danger : colors.textMuted,
      ),
    );
  }
}
