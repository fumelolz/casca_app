import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/core/auth/auth_controller.dart';
import 'package:casca_app/core/errors/api_error_message.dart';
import 'package:casca_app/core/layout/page_padding.dart';
import 'package:casca_app/features/home/domain/dashboard_rules.dart';
import 'package:casca_app/features/home/presentation/providers/dashboard_provider.dart';
import 'package:casca_app/features/home/presentation/widgets/low_stock_panel.dart';
import 'package:casca_app/features/home/presentation/widgets/metric_grid.dart';
import 'package:casca_app/features/home/presentation/widgets/payment_methods_panel.dart';
import 'package:casca_app/features/home/presentation/widgets/sales_hero_card.dart';
import 'package:casca_app/features/home/presentation/widgets/top_products_panel.dart';
import 'package:casca_app/shared/formatters/date_formatters.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_page_header.dart';
import 'package:casca_app/shared/ui/casca_skeleton.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

const double _contentMaxWidth = 1100;
const double _twoColumnBreakpoint = 720;
const double _sideBySideBreakpoint = 440;
const double _heroSkeletonHeight = 180;
const double _panelSkeletonHeight = 120;

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider.select((s) => s.session));
    final canView = session?.hasPermission('dashboard.view') ?? false;
    final name = firstName(session?.account.name ?? '');

    return SingleChildScrollView(
      key: const Key('home-page'),
      padding: pagePadding(context),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: CascaSpacing.space4,
            children: [
              CascaPageHeader(
                title: name.isEmpty ? 'Hola' : 'Hola, $name',
                subtitle:
                    '${session?.activeStore.name ?? ''} · '
                    '${longDate(DateTime.now())}',
                action: canView
                    ? CascaButton(
                        label: 'Actualizar',
                        variant: CascaButtonVariant.secondary,
                        size: CascaButtonSize.sm,
                        onPressed: () => ref.invalidate(dashboardProvider),
                      )
                    : null,
              ),
              if (canView)
                const _DashboardContent()
              else
                Text(
                  'Usa el menú para empezar a trabajar.',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: context.casca.textMuted),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardContent extends ConsumerWidget {
  const _DashboardContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardProvider);
    final dashboard = state.value;

    if (state.isLoading && (dashboard == null || state.isReloading)) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: CascaSpacing.space4,
        children: [
          CascaSkeleton(height: _heroSkeletonHeight),
          CascaSkeleton(height: _panelSkeletonHeight),
          CascaSkeleton(height: _panelSkeletonHeight),
        ],
      );
    }

    if (dashboard == null || state.hasError) {
      return Column(
        spacing: CascaSpacing.space3,
        children: [
          Text(
            apiErrorMessage(
              state.error ?? Object(),
              'No fue posible cargar el resumen del día.',
            ),
            textAlign: TextAlign.center,
          ),
          CascaButton(
            label: 'Reintentar',
            variant: CascaButtonVariant.secondary,
            onPressed: () => ref.invalidate(dashboardProvider),
          ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) =>
          _blocks(context, dashboard, constraints.maxWidth),
    );
  }

  Widget _blocks(BuildContext context, Dashboard dashboard, double width) {
    final summary = dashboard.summary;
    final generatedAt = summary.generatedAt;
    final twoColumns = width >= _twoColumnBreakpoint;
    final panelWidth = twoColumns ? (width - CascaSpacing.space4) / 2 : width;

    Widget panel(DashboardBlock block) {
      return switch (block) {
        DashboardBlock.salesToday => SalesHeroCard(summary: summary),
        DashboardBlock.paymentMethods => PaymentMethodsPanel(
          payments: summary.payments,
          sideBySide: panelWidth >= _sideBySideBreakpoint,
        ),
        DashboardBlock.topProducts => TopProductsPanel(
          products: summary.topProducts,
        ),
        DashboardBlock.lowStock => LowStockPanel(products: summary.lowStock),
        DashboardBlock.ordersToday ||
        DashboardBlock.averageTicket ||
        DashboardBlock.profitToday => MetricGrid(
          blocks: [block],
          summary: summary,
        ),
      };
    }

    final rows = twoColumns
        ? columnRows(dashboard.blocks)
        : [
            for (final block in dashboard.blocks) [block],
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: CascaSpacing.space4,
      children: [
        for (final group in mergeMetrics(rows))
          if (group.first.metric)
            MetricGrid(blocks: group, summary: summary)
          else if (group.length == 1)
            panel(group.single)
          else
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: CascaSpacing.space4,
                children: [
                  for (final block in group) Expanded(child: panel(block)),
                ],
              ),
            ),
        if (generatedAt != null)
          Text(
            'Actualizado: ${formatDateTime(generatedAt)}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }
}
