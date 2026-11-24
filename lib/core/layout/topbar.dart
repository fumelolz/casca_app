import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/app/theme/casca_typography.dart';
import 'package:casca_app/core/auth/auth_controller.dart';
import 'package:casca_app/core/layout/brand_lockup.dart';
import 'package:casca_app/core/layout/notification_bell.dart';
import 'package:casca_app/core/layout/sidebar.dart';
import 'package:casca_app/core/layout/sidebar_controller.dart';
import 'package:casca_app/core/layout/topbar_icon_button.dart';
import 'package:casca_app/shared/ui/casca_action_menu.dart';
import 'package:casca_app/shared/ui/casca_icon.dart';
import 'package:casca_app/shared/ui/casca_tooltip.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class Topbar extends ConsumerWidget {
  const Topbar({
    super.key,
    required this.isMobile,
    this.insets = EdgeInsets.zero,
  });

  final bool isMobile;
  final EdgeInsets insets;

  static const double _avatarSize = 34;
  static const double _brandMarkSize = 32;
  static const double _productMinWidth = 360;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.casca;
    final sidebar = ref.watch(sidebarProvider);

    return Container(
      height: topbarHeight + insets.top,
      padding: EdgeInsets.only(
        top: insets.top,
        left: insets.left + CascaSpacing.space2,
        right: insets.right + (isMobile ? CascaSpacing.space3 : 0),
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          _buildMenuButton(ref, sidebar),
          if (isMobile)
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: BrandLockup(
                  markSize: _brandMarkSize,
                  showProduct:
                      MediaQuery.sizeOf(context).width >= _productMinWidth,
                ),
              ),
            )
          else
            const Spacer(),
          const NotificationBell(),
          const SizedBox(width: CascaSpacing.space3),
          Container(
            width: 1,
            height: CascaSpacing.space6,
            color: colors.border,
          ),
          const SizedBox(width: CascaSpacing.space3),
          _buildAccountMenu(context, ref),
        ],
      ),
    );
  }

  Widget _buildMenuButton(WidgetRef ref, SidebarState sidebar) {
    final controller = ref.read(sidebarProvider.notifier);

    if (isMobile) {
      return TopbarIconButton(
        icon: sidebar.mobileOpen ? CascaIcons.xmark : CascaIcons.bars,
        label: 'Alternar menú de navegación',
        borderless: true,
        prominent: true,
        onTap: controller.toggleMobile,
      );
    }

    final message = sidebar.collapsed ? 'Expandir menú' : 'Contraer menú';

    return CascaTooltip(
      message: message,
      position: CascaTooltipPosition.bottom,
      child: TopbarIconButton(
        icon: CascaIcons.bars,
        label: '$message de navegación',
        borderless: true,
        prominent: true,
        onTap: controller.toggle,
      ),
    );
  }

  Widget _buildAccountMenu(BuildContext context, WidgetRef ref) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final session = ref.watch(authControllerProvider.select((s) => s.session));
    final accountName = session?.account.name;
    final storeName = session?.activeStore.name;
    final initial = (accountName != null && accountName.isNotEmpty)
        ? accountName.characters.first.toUpperCase()
        : '?';

    return CascaActionMenu(
      semanticLabel: 'Menú de cuenta',
      sections: [
        CascaActionMenuSection(
          title: 'Mi cuenta',
          items: [
            CascaActionMenuItem(
              id: 'logout',
              label: 'Cerrar sesión',
              icon: CascaIcons.rightFromBracket,
              onSelected: () =>
                  ref.read(authControllerProvider.notifier).signOut(),
            ),
          ],
        ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: _avatarSize,
            height: _avatarSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.primary,
            ),
            child: Text(
              initial,
              style: textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontSize: CascaFontSize.xs,
                fontWeight: CascaFontWeight.medium,
              ),
            ),
          ),
          if (!isMobile) ...[
            const SizedBox(width: CascaSpacing.space2),
            Padding(
              padding: const EdgeInsets.only(right: CascaSpacing.space3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (storeName != null)
                    Text(
                      storeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.text,
                        fontSize: CascaFontSize.sm,
                        fontWeight: CascaFontWeight.semibold,
                        height: 1.3,
                      ),
                    ),
                  if (accountName != null)
                    Text(
                      accountName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.textMuted,
                        fontSize: CascaFontSize.xs,
                        height: 1.3,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
