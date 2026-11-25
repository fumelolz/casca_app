import 'package:casca_app/core/auth/auth_controller.dart';
import 'package:casca_app/core/routing/unsaved_changes.dart';
import 'package:casca_app/shared/ui/casca_modal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

ExitCallback confirmDiscard(Ref ref) {
  return (BuildContext context, GoRouterState state) async {
    final signedIn =
        ref.read(authControllerProvider).status == AuthStatus.authenticated;
    if (!signedIn || !ref.read(unsavedChangesProvider).pending) return true;

    return showCascaConfirm(
      context: context,
      title: '¿Descartar cambios?',
      message: 'Si sales ahora se perderá lo que capturaste.',
      confirmLabel: 'Descartar',
      cancelLabel: 'Seguir editando',
      danger: true,
    );
  };
}
