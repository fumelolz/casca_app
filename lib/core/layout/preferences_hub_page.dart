import 'package:casca_app/app/theme/casca_radius.dart';
import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/app/theme/casca_typography.dart';
import 'package:casca_app/core/layout/navigation_item.dart';
import 'package:casca_app/core/layout/navigation_provider.dart';
import 'package:casca_app/shared/ui/casca_icon.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

const double _contentMaxWidth = 560;
const double _rowMinHeight = 56;
const double _badgeSize = 32;
const String _defaultGroupLabel = 'General';

class PreferencesHubPage extends ConsumerWidget {
  const PreferencesHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final nav = ref.watch(navigationProvider);

    return ListView(
      key: const Key('preferences-hub'),
      padding: const EdgeInsets.all(CascaSpacing.space4),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Preferencias', style: textTheme.headlineMedium),
                for (final group in nav.preferenceGroups) ...[
                  Padding(
                    padding: const EdgeInsets.only(
                      top: CascaSpacing.space5,
                      bottom: CascaSpacing.space2,
                      left: CascaSpacing.space1,
                    ),
                    child: Text(
                      (group.label.isEmpty ? _defaultGroupLabel : group.label)
                          .toUpperCase(),
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.textMuted,
                        fontSize: CascaFontSize.xs,
                        fontWeight: CascaFontWeight.semibold,
                        letterSpacing: 0.72,
                      ),
                    ),
                  ),
                  _GroupCard(items: group.items),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.items});

  final List<NavigationItem> items;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: CascaRadius.md,
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: colors.border),
            _PreferenceRow(item: items[i]),
          ],
        ],
      ),
    );
  }
}

class _PreferenceRow extends StatelessWidget {
  const _PreferenceRow({required this.item});

  final NavigationItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final badge = item.badge;

    return Semantics(
      button: true,
      label: item.label,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go(item.route!),
          hoverColor: colors.surfaceHover,
          child: Container(
            constraints: const BoxConstraints(minHeight: _rowMinHeight),
            padding: const EdgeInsets.symmetric(
              horizontal: CascaSpacing.space4,
              vertical: CascaSpacing.space3,
            ),
            child: Row(
              children: [
                Container(
                  width: _badgeSize,
                  height: _badgeSize,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.infoSoft,
                    borderRadius: CascaRadius.sm,
                  ),
                  child: CascaIcon(
                    item.icon,
                    size: CascaFontSize.md,
                    color: colors.info,
                  ),
                ),
                const SizedBox(width: CascaSpacing.space3),
                Expanded(
                  child: Text(
                    item.label,
                    style: textTheme.bodyLarge?.copyWith(
                      color: colors.text,
                      fontWeight: CascaFontWeight.medium,
                    ),
                  ),
                ),
                if (badge != null && badge > 0) ...[
                  Container(
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: CascaSpacing.space1,
                    ),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.warning,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$badge',
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.onPrimary,
                        fontSize: CascaFontSize.xs,
                        fontWeight: CascaFontWeight.semibold,
                        height: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: CascaSpacing.space2),
                ],
                CascaIcon(
                  CascaIcons.chevronRight,
                  size: 12,
                  color: colors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
