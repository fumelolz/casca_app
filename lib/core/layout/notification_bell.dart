import 'dart:math' as math;

import 'package:casca_app/app/theme/casca_radius.dart';
import 'package:casca_app/app/theme/casca_shadows.dart';
import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/app/theme/casca_typography.dart';
import 'package:casca_app/core/layout/topbar_icon_button.dart';
import 'package:casca_app/core/routing/app_routes.dart';
import 'package:casca_app/shared/ui/casca_icon.dart';
import 'package:casca_app/shared/ui/casca_link.dart';
import 'package:casca_app/shared/ui/casca_popover.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

const double _panelWidth = 384;
const double _viewportMargin = CascaSpacing.space2;

class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    return CascaPopover(
      targetAnchor: Alignment.bottomRight,
      followerAnchor: Alignment.topRight,
      triggerBuilder: (context, handle) => TopbarIconButton(
        icon: CascaIcons.bell,
        label: 'Notificaciones',
        active: handle.isOpen,
        borderless: true,
        prominent: true,
        onTap: handle.toggle,
      ),
      panelBuilder: (context, close) => _Panel(
        onSeeBusinesses: () {
          close();
          context.go(AppRoutes.businesses);
        },
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.onSeeBusinesses});

  final VoidCallback onSeeBusinesses;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final width = math.min(
      _panelWidth,
      MediaQuery.sizeOf(context).width - _viewportMargin * 2,
    );

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: CascaRadius.lg,
        border: Border.all(color: colors.border),
        boxShadow: CascaShadows.lg,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: CascaSpacing.space4,
              vertical: CascaSpacing.space3,
            ),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: colors.border)),
            ),
            child: Text(
              'Notificaciones',
              style: textTheme.bodyLarge?.copyWith(
                color: colors.text,
                fontSize: CascaFontSize.md,
                fontWeight: CascaFontWeight.semibold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: CascaSpacing.space4,
              vertical: CascaSpacing.space6,
            ),
            child: Column(
              children: [
                CascaIcon(
                  CascaIcons.bellSlash,
                  size: CascaFontSize.xl,
                  color: colors.textMuted,
                ),
                const SizedBox(height: CascaSpacing.space2),
                Text(
                  'No tienes notificaciones.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.textMuted,
                    fontSize: CascaFontSize.sm,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: CascaSpacing.space4,
              vertical: CascaSpacing.space3,
            ),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: colors.border)),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: CascaLink(
                label: 'Ver mis negocios',
                onTap: onSeeBusinesses,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
