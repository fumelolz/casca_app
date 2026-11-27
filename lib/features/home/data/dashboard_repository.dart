import 'package:casca_app/core/network/api_client.dart';
import 'package:casca_app/core/network/network_providers.dart';
import 'package:casca_app/features/home/data/models/dashboard_summary_model.dart';
import 'package:casca_app/features/home/domain/dashboard_rules.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract final class DashboardEndpoints {
  static const String summary = '/api/v1/dashboard/summary';
  static const String layout = '/api/v1/dashboard/layout';
}

class DashboardRepository {
  const DashboardRepository(this._api);

  final ApiClient _api;

  Future<DashboardSummaryModel> getSummary() {
    return _api.get(
      DashboardEndpoints.summary,
      decode: (data) =>
          DashboardSummaryModel.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<List<DashboardWidgetSetting>> getLayout() {
    return _api.get(
      DashboardEndpoints.layout,
      decode: (data) {
        final widgets =
            (data as Map<String, dynamic>)['widgets'] as List<Object?>;

        return [
          for (final widget in widgets.cast<Map<String, dynamic>>())
            (
              key: widget['key'] as String,
              enabled: widget['isEnabled'] as bool,
              order: widget['order'] as int,
            ),
        ];
      },
    );
  }
}

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepository(ref.watch(apiClientProvider)),
);
