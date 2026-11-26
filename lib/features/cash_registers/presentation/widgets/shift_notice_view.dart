import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/core/layout/page_padding.dart';
import 'package:casca_app/shared/ui/casca_icon.dart';
import 'package:material_ui/material_ui.dart';

const double _iconSize = 48;

class ShiftNoticeView extends StatelessWidget {
  const ShiftNoticeView({
    super.key,
    required this.title,
    this.message,
    this.actions = const [],
  });

  final String title;
  final String? message;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final message = this.message;

    return Center(
      child: SingleChildScrollView(
        padding: pagePadding(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: CascaSpacing.space3,
          children: [
            CascaIcon(
              CascaIcons.cashRegister,
              size: _iconSize,
              color: colors.textMuted,
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: textTheme.titleLarge,
            ),
            if (message != null)
              Text(
                message,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ...actions,
          ],
        ),
      ),
    );
  }
}
