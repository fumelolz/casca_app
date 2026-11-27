import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/core/storage/preferences_storage.dart';
import 'package:casca_app/features/products/data/models/product_detail_model.dart';
import 'package:casca_app/features/products/presentation/providers/product_form_provider.dart';
import 'package:casca_app/features/products/presentation/widgets/product_label_modal.dart';
import 'package:casca_app/features/products/presentation/widgets/product_label_preview.dart';
import 'package:casca_app/shared/ui/casca_checkbox.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _EmptyStorage extends PreferencesStorage {
  @override
  Future<String?> read(String key) async => null;
}

const _product = ProductDetailModel(
  id: 'p1',
  name: 'Arroz',
  sku: 'ARR-1',
  productType: 1,
  version: 1,
  ivaRate: 0,
  iepsRate: 0,
  satUnitCode: 1,
  baseUnit: ProductSaleUnitModel(
    unitOfMeasure: 1,
    price: 25,
    cost: 10,
    barcode: '750999',
  ),
);

const _other = ProductDetailModel(
  id: 'p2',
  name: 'Frijol',
  sku: 'FRI-1',
  productType: 1,
  version: 1,
  ivaRate: 0,
  iepsRate: 0,
  satUnitCode: 1,
  baseUnit: ProductSaleUnitModel(unitOfMeasure: 1, price: 30, cost: 12),
);

void main() {
  testWidgets('la vista previa muestra solo los datos elegidos', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesStorageProvider.overrideWithValue(_EmptyStorage()),
          productDetailProvider('p1').overrideWith((ref) => _product),
          productDetailProvider('p2').overrideWith((ref) => _other),
        ],
        child: MaterialApp(
          theme: CascaTheme.light,
          home: Scaffold(
            body: ProductLabelModal(
              productIds: const ['p1', 'p2'],
              onConfigure: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    Finder inPreview(String text) => find.descendant(
      of: find.byType(ProductLabelPreview),
      matching: find.text(text),
    );

    expect(find.text('Frijol'), findsOneWidget);
    expect(inPreview('Arroz'), findsOneWidget);
    expect(inPreview(r'$25.00'), findsOneWidget);
    expect(inPreview('750999'), findsOneWidget);

    await tester.tap(
      find.byWidgetPredicate(
        (widget) => widget is CascaCheckbox && widget.semanticLabel == 'Nombre',
      ),
    );
    await tester.pumpAndSettle();

    expect(inPreview('Arroz'), findsNothing);
    expect(inPreview(r'$25.00'), findsOneWidget);
  });
}
