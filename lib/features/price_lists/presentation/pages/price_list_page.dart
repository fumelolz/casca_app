import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/core/auth/auth_controller.dart';
import 'package:casca_app/core/errors/api_error_message.dart';
import 'package:casca_app/core/layout/page_padding.dart';
import 'package:casca_app/core/routing/app_routes.dart';
import 'package:casca_app/features/price_lists/data/models/price_list_model.dart';
import 'package:casca_app/features/price_lists/presentation/providers/price_list_providers.dart';
import 'package:casca_app/features/price_lists/presentation/widgets/price_list_modals.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_modal.dart';
import 'package:casca_app/shared/ui/casca_page_header.dart';
import 'package:casca_app/shared/ui/casca_table.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

const PriceListModel _publicList = PriceListModel(
  id: '',
  name: 'Público (Por defecto)',
  priceCount: 0,
);

final _columns = <CascaTableColumn<PriceListModel>>[
  CascaTableColumn(
    id: 'name',
    header: 'Nombre',
    flex: 3,
    showOnCompact: true,
    cellBuilder: (context, list) => Text(
      list.name,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodyMedium,
    ),
  ),
  CascaTableColumn(
    id: 'prices',
    header: 'Precios',
    flex: 2,
    showOnCompact: true,
    cellBuilder: (context, list) => Text(
      list.id.isEmpty
          ? 'Precio de cada producto'
          : '${list.priceCount} ${list.priceCount == 1 ? 'precio' : 'precios'}',
      style: Theme.of(context).textTheme.bodySmall
          ?.copyWith(color: context.casca.textSecondary),
    ),
  ),
];

class PriceListPage extends ConsumerWidget {
  const PriceListPage({super.key});

  Future<void> _create(BuildContext context) async {
    final created = await showCascaModal<PriceListModel>(
      context: context,
      size: CascaModalSize.sm,
      builder: (_) => const PriceListNameModal(),
    );
    if (created != null && context.mounted) {
      context.go(AppRoutes.priceListFor(created.id));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lists = ref.watch(priceListsProvider);
    final value = lists.value;
    final error = lists.error;
    final session = ref.watch(authControllerProvider.select((s) => s.session));
    final canCreate = session?.hasPermission('pricelist.create') ?? false;

    return SingleChildScrollView(
      padding: pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CascaPageHeader(
            title: 'Listas de precios',
            subtitle: 'Configura los precios que ofreces a tus clientes.',
            action: canCreate
                ? CascaButton(
                    label: 'Agregar lista',
                    onPressed: () => _create(context),
                  )
                : null,
          ),
          const SizedBox(height: CascaSpacing.space5),
          CascaTable<PriceListModel>(
            columns: _columns,
            rows: value == null ? const [] : [_publicList, ...value],
            rowKey: (list) => list.id,
            loading: lists.isLoading,
            errorMessage: error == null || value != null
                ? null
                : apiErrorMessage(
                    error,
                    'No fue posible obtener las listas de precios.',
                    forbidden:
                        'No tienes permiso para ver las listas de precios.',
                  ),
            onRetry: () => ref.invalidate(priceListsProvider),
            onRowTap: (list) {
              if (list.id.isNotEmpty) {
                context.go(AppRoutes.priceListFor(list.id));
              }
            },
          ),
        ],
      ),
    );
  }
}
