import 'package:casca_app/app/theme/casca_radius.dart';
import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/core/layout/sidebar_controller.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_icon.dart';
import 'package:material_ui/material_ui.dart';

enum CascaModalSize {
  sm(400),
  md(520),
  lg(720);

  const CascaModalSize(this.maxWidth);

  final double maxWidth;
}

const Color _barrierColor = Color(0x520F172A);
const double _closeSize = 44;
const double _sheetMaxHeightFactor = 0.92;

Future<T?> showCascaModal<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  CascaModalSize size = CascaModalSize.md,
  bool dismissible = true,
}) {
  final isMobile = MediaQuery.sizeOf(context).width <= mobileBreakpoint;
  final animation = MediaQuery.disableAnimationsOf(context)
      ? AnimationStyle.noAnimation
      : null;

  if (isMobile) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      isDismissible: dismissible,
      enableDrag: dismissible,
      backgroundColor: context.casca.surface,
      barrierColor: _barrierColor,
      sheetAnimationStyle: animation,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(CascaRadius.xlValue),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (sheetContext) => PopScope(
        canPop: dismissible,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight:
                  MediaQuery.sizeOf(sheetContext).height *
                  _sheetMaxHeightFactor,
            ),
            child: SafeArea(top: false, child: builder(sheetContext)),
          ),
        ),
      ),
    );
  }

  return showDialog<T>(
    context: context,
    barrierDismissible: dismissible,
    barrierColor: _barrierColor,
    animationStyle: animation,
    builder: (dialogContext) => PopScope(
      canPop: dismissible,
      child: Dialog(
        backgroundColor: dialogContext.casca.surface,
        insetPadding: const EdgeInsets.all(CascaSpacing.space6),
        shape: const RoundedRectangleBorder(borderRadius: CascaRadius.lg),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: size.maxWidth),
          child: builder(dialogContext),
        ),
      ),
    ),
  );
}

class CascaModal extends StatelessWidget {
  const CascaModal({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
    this.showCloseButton = true,
  });

  final String title;
  final Widget child;
  final List<Widget> actions;
  final bool showCloseButton;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.only(
              left: CascaSpacing.space5,
              right: CascaSpacing.space2,
              top: CascaSpacing.space2,
              bottom: CascaSpacing.space2,
            ),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: colors.border)),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: _closeSize),
              child: Row(
                children: [
                  Expanded(child: Text(title, style: textTheme.titleMedium)),
                  if (showCloseButton) const _CloseButton(),
                ],
              ),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(CascaSpacing.space5),
              child: child,
            ),
          ),
          if (actions.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(CascaSpacing.space4),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: colors.border)),
              ),
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: CascaSpacing.space3,
                runSpacing: CascaSpacing.space2,
                children: actions,
              ),
            ),
        ],
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Cerrar',
      excludeSemantics: true,
      child: InkResponse(
        onTap: () => Navigator.of(context).pop(),
        radius: _closeSize / 2,
        child: SizedBox(
          width: _closeSize,
          height: _closeSize,
          child: Center(
            child: CascaIcon(
              CascaIcons.xmark,
              size: CascaSpacing.space4,
              color: context.casca.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

Future<bool> showCascaConfirm({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancelar',
  bool danger = false,
}) async {
  final confirmed = await showCascaModal<bool>(
    context: context,
    size: CascaModalSize.sm,
    builder: (modalContext) => CascaModal(
      title: title,
      actions: [
        CascaButton(
          label: cancelLabel,
          variant: CascaButtonVariant.secondary,
          onPressed: () => Navigator.of(modalContext).pop(false),
        ),
        CascaButton(
          label: confirmLabel,
          variant: danger
              ? CascaButtonVariant.danger
              : CascaButtonVariant.primary,
          onPressed: () => Navigator.of(modalContext).pop(true),
        ),
      ],
      child: Text(message, style: Theme.of(modalContext).textTheme.bodyMedium),
    ),
  );
  return confirmed ?? false;
}
