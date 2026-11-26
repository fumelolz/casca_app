import 'package:casca_app/app/theme/casca_radius.dart';
import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/app/theme/casca_typography.dart';
import 'package:casca_app/core/auth/business_type_options.dart';
import 'package:casca_app/core/auth/session_state.dart';
import 'package:casca_app/features/businesses/domain/business_rules.dart';
import 'package:casca_app/features/businesses/presentation/widgets/business_section_title.dart';
import 'package:casca_app/features/businesses/presentation/widgets/business_store_tile.dart';
import 'package:casca_app/shared/ui/casca_card.dart';
import 'package:casca_app/shared/ui/casca_icon.dart';
import 'package:casca_app/shared/ui/casca_status_chip.dart';
import 'package:material_ui/material_ui.dart';

const double _compactBreakpoint = 520;
const double _avatarSize = 48;
const double _activeBorderWidth = 2;
const double _borderOpacity = 0.4;
const Duration _expandDuration = Duration(milliseconds: 200);

class BusinessCard extends StatefulWidget {
  const BusinessCard({
    super.key,
    required this.business,
    required this.activeStoreId,
    required this.onUseStore,
  });

  final BusinessGroup business;
  final String activeStoreId;
  final ValueChanged<SessionStore>? onUseStore;

  @override
  State<BusinessCard> createState() => _BusinessCardState();
}

class _BusinessCardState extends State<BusinessCard> {
  late bool _expanded = widget.business.isActive;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final business = widget.business;
    final onUseStore = widget.onUseStore;

    final card = CascaCard(
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < _compactBreakpoint;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                button: true,
                expanded: _expanded,
                child: InkWell(
                  borderRadius: CascaRadius.lg,
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Padding(
                    padding: EdgeInsets.all(
                      compact ? CascaSpacing.space4 : CascaSpacing.space5,
                    ),
                    child: _Header(
                      business: business,
                      expanded: _expanded,
                      compact: compact,
                    ),
                  ),
                ),
              ),
              if (_expanded) ...[
                Divider(
                  height: 1,
                  color: business.isActive
                      ? colors.success.withValues(alpha: _borderOpacity)
                      : colors.border,
                ),
                Padding(
                  padding: const EdgeInsets.all(CascaSpacing.space4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: CascaSpacing.space3,
                    children: [
                      Row(
                        spacing: CascaSpacing.space3,
                        children: [
                          const Expanded(
                            child: BusinessSectionTitle(
                              'Sucursales disponibles',
                            ),
                          ),
                          Text(
                            '${business.stores.length} '
                            '${business.stores.length == 1 ? 'registrada' : 'registradas'}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colors.textMuted),
                          ),
                        ],
                      ),
                      for (final store in business.stores)
                        BusinessStoreTile(
                          store: store,
                          active: store.id == widget.activeStoreId,
                          compact: compact,
                          onUse: onUseStore == null
                              ? null
                              : () => onUseStore(store),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );

    if (!business.isActive) return card;
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: CascaRadius.lg,
        border: Border.all(color: colors.success, width: _activeBorderWidth),
      ),
      child: card,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.business,
    required this.expanded,
    required this.compact,
  });

  final BusinessGroup business;
  final bool expanded;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.copyWith(color: colors.textSecondary);
    final active = business.isActive;
    const available = CascaStatusChip(label: 'Disponible');

    return Row(
      spacing: CascaSpacing.space4,
      children: [
        Container(
          width: _avatarSize,
          height: _avatarSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? colors.successSoft : colors.surfaceHover,
            borderRadius: CascaRadius.md,
            border: Border.all(
              color: active
                  ? colors.success.withValues(alpha: _borderOpacity)
                  : colors.border,
            ),
          ),
          child: Text(
            businessInitials(business.tenantName),
            style: textTheme.titleSmall?.copyWith(
              color: active ? colors.success : colors.text,
              fontWeight: CascaFontWeight.semibold,
            ),
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
                  Text(business.tenantName, style: textTheme.titleMedium),
                  if (active)
                    const CascaStatusChip(
                      label: 'Negocio activo',
                      tone: CascaChipTone.success,
                    ),
                  if (!active && compact) available,
                ],
              ),
              Wrap(
                spacing: CascaSpacing.space2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(businessTypeLabel(business.businessType), style: muted),
                  Text('•', style: muted),
                  Text(linkedStoresLabel(business.stores.length), style: muted),
                ],
              ),
            ],
          ),
        ),
        if (!active && !compact) available,
        AnimatedRotation(
          turns: expanded ? 0.5 : 0,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : _expandDuration,
          child: CascaIcon(
            CascaIcons.chevronDown,
            size: CascaSpacing.space4,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
}
