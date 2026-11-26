import 'package:casca_app/app/theme/casca_radius.dart';
import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/app/theme/casca_typography.dart';
import 'package:casca_app/core/auth/session_state.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_icon.dart';
import 'package:casca_app/shared/ui/casca_status_chip.dart';
import 'package:material_ui/material_ui.dart';

const double _iconBoxSize = 40;
const double _borderOpacity = 0.4;
const double _backgroundOpacity = 0.35;

class BusinessStoreTile extends StatelessWidget {
  const BusinessStoreTile({
    super.key,
    required this.store,
    required this.active,
    required this.compact,
    required this.onUse,
  });

  final SessionStore store;
  final bool active;
  final bool compact;
  final VoidCallback? onUse;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final action = active
        ? const _CurrentStoreBadge()
        : CascaButton(
            label: 'Usar esta sucursal',
            size: CascaButtonSize.sm,
            variant: CascaButtonVariant.secondary,
            onPressed: onUse,
          );
    final info = Row(
      spacing: CascaSpacing.space4,
      children: [
        Container(
          width: _iconBoxSize,
          height: _iconBoxSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? colors.success : colors.surfaceHover,
            borderRadius: CascaRadius.md,
          ),
          child: CascaIcon(
            CascaIcons.store,
            size: CascaSpacing.space5,
            color: active ? colors.onSuccess : colors.textSecondary,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: CascaSpacing.space1,
            children: [
              Wrap(
                spacing: CascaSpacing.space2,
                runSpacing: CascaSpacing.space1,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(store.name, style: textTheme.titleSmall),
                  if (active)
                    const CascaStatusChip(
                      label: 'Sucursal activa',
                      tone: CascaChipTone.success,
                    ),
                ],
              ),
              Text(
                active
                    ? 'Estás trabajando en esta sucursal'
                    : 'Cambia a esta sucursal para operar en ella',
                style: textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CascaSpacing.space4,
        vertical: CascaSpacing.space3,
      ),
      decoration: BoxDecoration(
        color: active
            ? Color.alphaBlend(
                colors.successSoft.withValues(alpha: _backgroundOpacity),
                colors.surface,
              )
            : colors.surface,
        borderRadius: CascaRadius.md,
        border: Border.all(
          color: active
              ? colors.success.withValues(alpha: _borderOpacity)
              : colors.border,
        ),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: CascaSpacing.space3,
              children: [
                info,
                Padding(
                  padding: const EdgeInsets.only(
                    left: _iconBoxSize + CascaSpacing.space4,
                  ),
                  child: action,
                ),
              ],
            )
          : Row(
              spacing: CascaSpacing.space4,
              children: [
                Expanded(child: info),
                action,
              ],
            ),
    );
  }
}

class _CurrentStoreBadge extends StatelessWidget {
  const _CurrentStoreBadge();

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CascaSpacing.space3,
        vertical: CascaSpacing.space2,
      ),
      decoration: BoxDecoration(
        borderRadius: CascaRadius.sm,
        border: Border.all(color: colors.success),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: CascaSpacing.space2,
        children: [
          CascaIcon(
            CascaIcons.check,
            size: CascaSpacing.space4,
            color: colors.success,
          ),
          Flexible(
            child: Text(
              'Sucursal en uso',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colors.success,
                fontWeight: CascaFontWeight.semibold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
