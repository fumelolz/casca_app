import 'dart:async';

import 'package:casca_app/core/auth/auth_controller.dart';
import 'package:casca_app/features/pos/data/models/pos_catalog_model.dart';
import 'package:casca_app/features/pos/data/models/sale_model.dart';
import 'package:casca_app/features/pos/data/pos_repository.dart';
import 'package:casca_app/features/pos/domain/cart_rules.dart';
import 'package:casca_app/features/pos/domain/sale_request.dart';
import 'package:casca_app/shared/formatters/number_formatters.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CartState {
  const CartState({
    this.lines = const [],
    this.preview,
    this.calculating = false,
    this.previewError,
    this.notice,
    this.lineErrors = const {},
  });

  final List<CartLine> lines;
  final SalePreviewModel? preview;
  final bool calculating;
  final Object? previewError;
  final String? notice;
  final Map<String, String> lineErrors;

  double? get payableTotal {
    final total = preview?.finalTotal;
    final ready = lines.isNotEmpty && !calculating && previewError == null;
    return ready && total != null && total > 0 ? total : null;
  }

  double quantityOf(PosCatalogItemModel item) {
    return lines
        .where((line) => line.item.id == item.id)
        .fold(0, (sum, line) => sum + line.quantity);
  }

  SalePreviewLineModel? previewFor(CartLine line) {
    for (final item in preview?.items ?? const <SalePreviewLineModel>[]) {
      final key = cartKey(
        item.productId,
        item.productVariantId,
        item.sellableItemId,
        item.type,
      );
      if (key == line.key) return item;
    }
    return null;
  }
}

class CartController extends Notifier<CartState> {
  static const Duration previewDelay = Duration(milliseconds: 250);

  Timer? _previewTimer;
  int _request = 0;
  bool _taxesEnabled = false;

  @override
  CartState build() {
    final owner = ref.watch(
      authControllerProvider.select((s) {
        final session = s.session;
        if (session == null) return null;
        return (
          session.account.id,
          session.activeStore.id,
          session.activeStore.taxesEnabled,
        );
      }),
    );
    _taxesEnabled = owner?.$3 ?? false;
    _request++;
    ref.onDispose(() => _previewTimer?.cancel());
    return const CartState();
  }

  void add(PosCatalogItemModel item, [double quantity = 1]) {
    if (!isAvailable(item) || !isValidQuantity(item, quantity)) return;

    final added = CartLine(item: item, quantity: quantity);
    final index = state.lines.indexWhere((line) => line.key == added.key);
    final current = index == -1 ? 0.0 : state.lines[index].quantity;
    _put(added.withQuantity(roundQuantity(current + quantity)), index);
  }

  void setQuantity(CartLine line, double quantity) {
    if (quantity == 0) return remove(line);
    if (!isValidQuantity(line.item, quantity)) return;
    final index = state.lines.indexWhere((other) => other.key == line.key);
    if (index != -1) _put(line.withQuantity(quantity), index);
  }

  void increase(CartLine line) => setQuantity(line, line.quantity + 1);

  void decrease(CartLine line) {
    if (line.quantity <= 1) return remove(line);
    setQuantity(line, roundQuantity(line.quantity - 1));
  }

  bool canIncrease(CartLine line) {
    return line.quantity < maxQuantity(state.lines, line.item, line.key);
  }

  void remove(CartLine line) {
    _setLines([
      for (final other in state.lines)
        if (other.key != line.key) other,
    ]);
  }

  void clear() => _setLines(const []);

  void retryPreview() => _setLines(state.lines);

  void showLineErrors(Map<String, String> errors) {
    state = CartState(
      lines: state.lines,
      preview: state.preview,
      calculating: state.calculating,
      previewError: state.previewError,
      lineErrors: errors,
    );
  }

  void _put(CartLine line, int index) {
    final max = maxQuantity(state.lines, line.item, line.key);
    final limited = line.quantity > max;
    final notice = limited
        ? 'Solo hay ${formatQuantity(max)} disponible(s) de ${line.item.displayName}.'
        : null;
    final allowed = limited ? line.withQuantity(max) : line;
    final unchanged =
        index != -1 && state.lines[index].quantity == allowed.quantity;

    if (allowed.quantity <= 0 || unchanged) {
      state = CartState(
        lines: state.lines,
        preview: state.preview,
        calculating: state.calculating,
        previewError: state.previewError,
        lineErrors: state.lineErrors,
        notice: notice,
      );
      return;
    }

    final lines = [...state.lines];
    index == -1 ? lines.add(allowed) : lines[index] = allowed;
    _setLines(lines, notice: notice);
  }

  void _setLines(List<CartLine> lines, {String? notice}) {
    _previewTimer?.cancel();
    final request = ++_request;

    if (lines.isEmpty) {
      state = CartState(notice: notice);
      return;
    }
    if (!_taxesEnabled) {
      state = CartState(
        lines: lines,
        preview: untaxedPreview(lines),
        notice: notice,
      );
      return;
    }

    state = CartState(lines: lines, calculating: true, notice: notice);
    _previewTimer = Timer(previewDelay, () => _calculate(lines, request));
  }

  Future<void> _calculate(List<CartLine> lines, int request) async {
    try {
      final preview = await ref
          .read(posRepositoryProvider)
          .preview(previewRequest(lines));
      if (!ref.mounted || request != _request) return;
      state = CartState(lines: lines, preview: preview, notice: state.notice);
    } catch (error) {
      if (!ref.mounted || request != _request) return;
      state = CartState(
        lines: lines,
        previewError: error,
        notice: state.notice,
      );
    }
  }
}

final cartProvider = NotifierProvider<CartController, CartState>(
  CartController.new,
);
