import 'package:casca_app/core/auth/auth_controller.dart';
import 'package:casca_app/features/home/data/dashboard_repository.dart';
import 'package:casca_app/features/home/data/models/dashboard_summary_model.dart';
import 'package:casca_app/features/home/domain/dashboard_rules.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Dashboard {
  const Dashboard({required this.summary, required this.blocks});

  final DashboardSummaryModel summary;
  final List<DashboardBlock> blocks;
}

final dashboardProvider = FutureProvider.autoDispose<Dashboard>(
  retry: (_, _) => null,
  (ref) async {
    ref.watch(authControllerProvider.select((s) => s.session?.activeStore.id));
    final repository = ref.watch(dashboardRepositoryProvider);
    final layout = repository.getLayout().catchError(
      (Object _) => <DashboardWidgetSetting>[],
    );
    final summary = await repository.getSummary();

    return Dashboard(summary: summary, blocks: visibleBlocks(await layout));
  },
);
