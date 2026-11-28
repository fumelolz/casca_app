import 'package:casca_app/app/theme/casca_radius.dart';
import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/core/auth/auth_controller.dart';
import 'package:casca_app/core/errors/api_error_message.dart';
import 'package:casca_app/core/layout/page_padding.dart';
import 'package:casca_app/core/routing/app_routes.dart';
import 'package:casca_app/features/products/data/models/product_detail_model.dart';
import 'package:casca_app/features/products/data/models/product_variant_model.dart';
import 'package:casca_app/features/products/domain/product_variant_view_rules.dart';
import 'package:casca_app/features/products/presentation/providers/product_detail_providers.dart';
import 'package:casca_app/features/products/presentation/providers/product_form_provider.dart';
import 'package:casca_app/features/products/presentation/widgets/inventory_movement_modal.dart';
import 'package:casca_app/features/products/presentation/widgets/product_delete_modal.dart';
import 'package:casca_app/features/products/presentation/widgets/product_detail_cards.dart';
import 'package:casca_app/features/products/presentation/widgets/product_label_modal.dart';
import 'package:casca_app/shared/ui/casca_action_menu.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_card.dart';
import 'package:casca_app/shared/ui/casca_icon.dart';
import 'package:casca_app/shared/ui/casca_modal.dart';
import 'package:casca_app/shared/ui/casca_skeleton.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

const double _contentMaxWidth = 1200;
const double _skeletonImageHeight = 220;
const double _menuSize = CascaSpacing.space8;
const double _hoverMix = 0.18;

class ProductDetailPage extends ConsumerWidget {
  const ProductDetailPage({super.key, required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(AppRoutes.products);
      },
      child: _content(context, ref),
    );
  }

  Widget _content(BuildContext context, WidgetRef ref) {
    final state = ref.watch(productDetailProvider(productId));
    final product = state.value;
    final error = state.error;

    if (product == null && error == null) return const _DetailSkeleton();

    if (product == null) {
      return Center(
        child: SingleChildScrollView(
          padding: pagePadding(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: CascaSpacing.space3,
            children: [
              Text(
                apiErrorMessage(
                  error ?? Object(),
                  'No fue posible obtener el producto.',
                  forbidden: 'No tienes permiso para ver los productos.',
                ),
                textAlign: TextAlign.center,
              ),
              CascaButton(
                label: 'Reintentar',
                variant: CascaButtonVariant.secondary,
                onPressed: () =>
                    ref.invalidate(productDetailProvider(productId)),
              ),
              CascaButton(
                label: 'Volver a productos',
                variant: CascaButtonVariant.text,
                onPressed: () => context.go(AppRoutes.products),
              ),
            ],
          ),
        ),
      );
    }

    return _ProductDetail(product: product);
  }
}

class _ProductDetail extends ConsumerWidget {
  const _ProductDetail({required this.product});

  final ProductDetailModel product;

  Future<void> _adjust(
    BuildContext context, {
    required String name,
    required double stock,
    required bool allowsDecimals,
    String? variantId,
  }) {
    return showCascaModal<bool>(
      context: context,
      builder: (_) => InventoryMovementModal(
        productId: product.id,
        variantId: variantId,
        name: name,
        currentStock: stock,
        allowsDecimals: allowsDecimals,
      ),
    );
  }

  void _adjustVariant(BuildContext context, ProductVariantModel variant) {
    _adjust(
      context,
      variantId: variant.id,
      name: '${product.name} · ${variantName(variant)}',
      stock: variant.stock,
      allowsDecimals: variant.saleUnit?.allowsDecimalQuantity ?? false,
    );
  }

  Future<void> _delete(BuildContext context) async {
    final router = GoRouter.of(context);
    final deleted = await showCascaModal<bool>(
      context: context,
      builder: (_) => ProductDeleteModal(product: product),
    );
    if (deleted ?? false) router.go(AppRoutes.products);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider.select((s) => s.session));
    bool can(String permission) => session?.hasPermission(permission) ?? false;
    final canAdjust = can('inventory.update');
    final tracksInventory = !product.isService;
    final gallery = ref.watch(productGalleryProvider(product.id)).value;
    final images = [?product.image, ...?gallery];

    final menu = [
      CascaActionMenuSection(
        items: [
          if (can('product.update'))
            CascaActionMenuItem(
              id: 'edit',
              label: 'Editar',
              icon: CascaIcons.pencilSimple,
              onSelected: () =>
                  context.go(AppRoutes.productEditFor(product.id)),
            ),
          if (tracksInventory)
            CascaActionMenuItem(
              id: 'labels',
              label: 'Imprimir etiquetas',
              icon: CascaIcons.print,
              onSelected: () => showProductLabelModal(context, [product.id]),
            ),
        ],
      ),
      if (can('product.delete'))
        CascaActionMenuSection(
          items: [
            CascaActionMenuItem(
              id: 'delete',
              label: 'Eliminar',
              icon: CascaIcons.trash,
              danger: true,
              onSelected: () => _delete(context),
            ),
          ],
        ),
    ].where((section) => section.items.isNotEmpty).toList();

    final actions = [
      if (tracksInventory && !product.hasVariants && canAdjust)
        CascaButton(
          label: 'Ajustar existencias',
          onPressed: () => _adjust(
            context,
            name: product.name,
            stock: product.stock ?? 0,
            allowsDecimals: product.baseUnit?.allowsDecimalQuantity ?? false,
          ),
        ),
      if (menu.isNotEmpty)
        CascaActionMenu(
          semanticLabel: 'Más acciones del producto',
          sections: menu,
          child: const _MoreButton(),
        ),
    ];

    final sections = [
      if (product.hasVariants)
        ProductVariantsCard(
          product: product,
          onAdjust: tracksInventory && canAdjust
              ? (variant) => _adjustVariant(context, variant)
              : null,
        )
      else if (product.saleUnits.length > 1)
        ProductPricesCard(product: product),
    ];
    final movements = tracksInventory && can('inventory.view')
        ? ProductMovementsCard(product: product)
        : null;

    return SingleChildScrollView(
      padding: pagePadding(context),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: CascaSpacing.space4,
            children: [
              _TopBar(actions: actions),
              ProductHero(
                product: product,
                images: images,
                showTaxes: session?.activeStore.taxesEnabled ?? false,
              ),
              ...sections,
              ?movements,
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.actions});

  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;

    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Semantics(
              button: true,
              label: 'Volver a productos',
              excludeSemantics: true,
              child: InkWell(
                onTap: () => context.go(AppRoutes.products),
                borderRadius: CascaRadius.sm,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: CascaSpacing.space2,
                    vertical: CascaSpacing.space3,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: CascaSpacing.space2,
                    children: [
                      CascaIcon(
                        CascaIcons.arrowLeft,
                        size: CascaSpacing.space4,
                        color: colors.textSecondary,
                      ),
                      Flexible(
                        child: Text(
                          'Productos',
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: colors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: CascaSpacing.space2,
          children: actions,
        ),
      ],
    );
  }
}

class _MoreButton extends StatefulWidget {
  const _MoreButton();

  @override
  State<_MoreButton> createState() => _MoreButtonState();
}

class _MoreButtonState extends State<_MoreButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        width: _menuSize,
        height: _menuSize,
        decoration: BoxDecoration(
          color: _hovered
              ? Color.lerp(colors.surfaceHover, colors.border, _hoverMix)
              : colors.surfaceHover,
          borderRadius: CascaRadius.sm,
          border: Border.all(color: colors.border),
        ),
        child: Center(
          child: CascaIcon(
            CascaIcons.dotsThreeVertical,
            size: CascaSpacing.space5,
            color: colors.text,
          ),
        ),
      ),
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: pagePadding(context),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: CascaSpacing.space4,
            children: [
              CascaCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: CascaSpacing.space4,
                  children: [
                    CascaSkeleton(height: _skeletonImageHeight),
                    CascaSkeleton(),
                    CascaSkeleton(),
                  ],
                ),
              ),
              CascaCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: CascaSpacing.space4,
                  children: [CascaSkeleton(), CascaSkeleton(), CascaSkeleton()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
