import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/core/auth/auth_controller.dart';
import 'package:casca_app/core/layout/page_padding.dart';
import 'package:casca_app/features/products/data/models/category_model.dart';
import 'package:casca_app/features/products/presentation/providers/category_list_provider.dart';
import 'package:casca_app/features/products/presentation/widgets/category_delete_modal.dart';
import 'package:casca_app/features/products/presentation/widgets/category_form_modal.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_modal.dart';
import 'package:casca_app/shared/ui/casca_filter_bar.dart';
import 'package:casca_app/shared/ui/casca_icon.dart';
import 'package:casca_app/shared/ui/casca_page_header.dart';
import 'package:casca_app/shared/ui/casca_table.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

const String _emptyValue = '—';

final _columns = <CascaTableColumn<CategoryModel>>[
  CascaTableColumn(
    id: 'name',
    header: 'Nombre',
    flex: 3,
    sortable: true,
    showOnCompact: true,
    cellBuilder: (context, category) => Text(
      category.name,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodyMedium,
    ),
  ),
  CascaTableColumn(
    id: 'description',
    header: 'Descripción',
    flex: 4,
    cellBuilder: (context, category) => Text(
      category.description ?? _emptyValue,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodyMedium,
    ),
  ),
  CascaTableColumn(
    id: 'parent',
    header: 'Categoría padre',
    flex: 2,
    showOnCompact: true,
    cellBuilder: (context, category) => Text(
      category.parentCategoryName ?? _emptyValue,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodyMedium,
    ),
  ),
];

void _openForm(BuildContext context, {CategoryModel? category}) {
  showCascaModal<void>(
    context: context,
    builder: (_) => CategoryFormModal(category: category),
  );
}

Future<void> _confirmDelete(
  BuildContext context,
  WidgetRef ref,
  CategoryModel category,
) async {
  final query = ref.read(categoryListQueryProvider.notifier);
  final currentPage = ref.read(categoryListQueryProvider).page;
  final wasLastOfPage = ref.read(categoryListProvider).value?.items.length == 1;
  final deleted = await showCascaModal<bool>(
    context: context,
    size: CascaModalSize.sm,
    builder: (_) => CategoryDeleteModal(category: category),
  );
  if (!context.mounted) return;
  if (deleted == true && wasLastOfPage && currentPage > 1) {
    query.setPage(currentPage - 1);
  }
}

class CategoryListPage extends ConsumerWidget {
  const CategoryListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(categoryListQueryProvider);
    final categories = ref.watch(categoryListProvider);
    final page = categories.value;
    final failed = categories.hasError && page == null;
    final session = ref.watch(authControllerProvider.select((s) => s.session));
    final canCreate = session?.hasPermission('category.create') ?? false;
    final canUpdate = session?.hasPermission('category.update') ?? false;
    final canDelete = session?.hasPermission('category.delete') ?? false;

    return SingleChildScrollView(
      padding: pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CascaPageHeader(
            title: 'Categorías de productos',
            subtitle: 'Organiza tus productos en categorías.',
            action: canCreate
                ? CascaButton(
                    label: 'Agregar categoría',
                    onPressed: () => _openForm(context),
                  )
                : null,
          ),
          const SizedBox(height: CascaSpacing.space5),
          CascaFilterBar(
            searchHint: 'Buscar categoría...',
            onSearchChanged: ref
                .read(categoryListQueryProvider.notifier)
                .setSearch,
          ),
          const SizedBox(height: CascaSpacing.space4),
          CascaTable<CategoryModel>(
            columns: _columns,
            rowActions: [
              if (canUpdate)
                CascaTableRowAction(
                  label: 'Editar',
                  icon: CascaIcons.pencilSimple,
                  onSelected: (category) =>
                      _openForm(context, category: category),
                ),
              if (canDelete)
                CascaTableRowAction(
                  label: 'Eliminar',
                  icon: CascaIcons.trash,
                  danger: true,
                  onSelected: (category) =>
                      _confirmDelete(context, ref, category),
                ),
            ],
            rows: page?.items ?? const [],
            rowKey: (category) => category.id,
            loading: categories.isLoading,
            errorMessage: failed
                ? 'No fue posible obtener las categorías.'
                : null,
            onRetry: () => ref.invalidate(categoryListProvider),
            emptyTitle: query.search.isEmpty
                ? 'Aún no hay categorías.'
                : 'No se encontraron categorías.',
            emptyMessage: query.search.isEmpty
                ? null
                : 'Prueba con otra búsqueda.',
            sort: CascaTableSort(
              'name',
              query.descending
                  ? CascaSortDirection.desc
                  : CascaSortDirection.asc,
            ),
            onSortChanged: (sort) => ref
                .read(categoryListQueryProvider.notifier)
                .setDescending(sort?.direction == CascaSortDirection.desc),
            page: query.page,
            pageSize: query.pageSize,
            totalItems: page?.totalCount,
            onPageChanged: ref.read(categoryListQueryProvider.notifier).setPage,
          ),
        ],
      ),
    );
  }
}
