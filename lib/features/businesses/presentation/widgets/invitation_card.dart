import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/core/auth/business_type_options.dart';
import 'package:casca_app/features/businesses/data/models/invitation_model.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_card.dart';
import 'package:casca_app/shared/ui/casca_status_chip.dart';
import 'package:material_ui/material_ui.dart';

class InvitationCard extends StatelessWidget {
  const InvitationCard({
    super.key,
    required this.invitation,
    required this.accepting,
    required this.onAccept,
    required this.onDecline,
  });

  final InvitationModel invitation;
  final bool accepting;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.copyWith(color: colors.textSecondary);

    return CascaCard(
      padding: const EdgeInsets.all(CascaSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: CascaSpacing.space2,
        children: [
          Wrap(
            spacing: CascaSpacing.space3,
            runSpacing: CascaSpacing.space1,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(invitation.storeName, style: textTheme.titleMedium),
              CascaStatusChip(
                label: invitation.roleName,
                tone: CascaChipTone.info,
              ),
            ],
          ),
          Text(
            '${invitation.tenantName} · '
            '${businessTypeLabel(invitation.businessType)}',
            style: muted,
          ),
          Text(
            'Aceptarla te da acceso a esta sucursal con el rol indicado.',
            style: muted,
          ),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: CascaSpacing.space3,
            runSpacing: CascaSpacing.space2,
            children: [
              CascaButton(
                label: 'Rechazar',
                size: CascaButtonSize.sm,
                variant: CascaButtonVariant.text,
                onPressed: onDecline,
              ),
              CascaButton(
                label: 'Aceptar invitación',
                size: CascaButtonSize.sm,
                loading: accepting,
                onPressed: onAccept,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
