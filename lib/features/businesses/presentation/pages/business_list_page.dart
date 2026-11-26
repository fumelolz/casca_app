import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/core/auth/auth_controller.dart';
import 'package:casca_app/core/errors/api_error_message.dart';
import 'package:casca_app/core/layout/page_padding.dart';
import 'package:casca_app/core/routing/app_routes.dart';
import 'package:casca_app/features/businesses/domain/business_rules.dart';
import 'package:casca_app/features/businesses/presentation/providers/business_providers.dart';
import 'package:casca_app/features/businesses/presentation/widgets/business_card.dart';
import 'package:casca_app/features/businesses/presentation/widgets/business_form_modal.dart';
import 'package:casca_app/features/businesses/presentation/widgets/business_section_title.dart';
import 'package:casca_app/features/businesses/presentation/widgets/invitation_card.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_modal.dart';
import 'package:casca_app/shared/ui/casca_overlay_loader.dart';
import 'package:casca_app/shared/ui/casca_page_header.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

class BusinessListPage extends ConsumerWidget {
  const BusinessListPage({super.key});

  Future<void> _create(BuildContext context) async {
    final created = await showCascaModal<bool>(
      context: context,
      size: CascaModalSize.sm,
      builder: (_) => const BusinessFormModal(),
    );
    if ((created ?? false) && context.mounted) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider.select((s) => s.session));
    if (session == null) return const SizedBox.shrink();

    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final invitations = ref.watch(invitationsProvider);
    final action = ref.watch(businessActionProvider);
    final controller = ref.read(businessActionProvider.notifier);
    final businesses = groupBusinesses(session);
    final pending = invitations.value ?? const [];
    final target = action.switchingTo;
    final error = action.error;
    final failure = action.failure;

    Widget card(BusinessGroup business) => BusinessCard(
      key: ValueKey(business.tenantId),
      business: business,
      activeStoreId: session.activeStore.id,
      onUseStore: action.busy
          ? null
          : (store) async {
              final switched = await controller.switchStore(store);
              if (switched && context.mounted) context.go(AppRoutes.home);
            },
    );

    return Stack(
      children: [
        SingleChildScrollView(
          padding: pagePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: CascaSpacing.space4,
            children: [
              CascaPageHeader(
                title: 'Negocios',
                subtitle: 'Cambia de sucursal o agrega otro negocio.',
                action: canCreateBusiness(session)
                    ? CascaButton(
                        label: 'Agregar negocio',
                        onPressed: action.busy ? null : () => _create(context),
                      )
                    : null,
              ),
              if (error != null && failure != null)
                Text(
                  apiErrorMessage(
                    error,
                    failure,
                    forbidden: 'No tienes permiso para esta acción.',
                  ),
                  style: textTheme.bodyMedium?.copyWith(color: colors.danger),
                ),
              if (invitations.hasError && !invitations.isLoading)
                Wrap(
                  spacing: CascaSpacing.space3,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'No fue posible consultar tus invitaciones.',
                      style: textTheme.bodyMedium,
                    ),
                    CascaButton(
                      label: 'Reintentar',
                      size: CascaButtonSize.sm,
                      variant: CascaButtonVariant.text,
                      onPressed: () => ref.invalidate(invitationsProvider),
                    ),
                  ],
                ),
              if (pending.isNotEmpty) ...[
                Text('Invitaciones pendientes', style: textTheme.titleMedium),
                for (final invitation in pending)
                  InvitationCard(
                    key: ValueKey(invitation.id),
                    invitation: invitation,
                    accepting: action.respondingTo == invitation.id,
                    onAccept: action.busy
                        ? null
                        : () => controller.respond(invitation.id, accept: true),
                    onDecline: action.busy
                        ? null
                        : () =>
                              controller.respond(invitation.id, accept: false),
                  ),
              ],
              const BusinessSectionTitle('Negocio en uso'),
              for (final business in businesses)
                if (business.isActive) card(business),
              if (businesses.any((business) => !business.isActive)) ...[
                const BusinessSectionTitle('Otros negocios'),
                for (final business in businesses)
                  if (!business.isActive) card(business),
              ],
            ],
          ),
        ),
        CascaOverlayLoader(
          visible: target != null,
          heading: 'Cambiando de sucursal',
          message: target == null
              ? null
              : '${target.tenantName} · ${target.name}',
        ),
      ],
    );
  }
}
