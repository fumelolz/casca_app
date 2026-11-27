import 'dart:convert';

import 'package:casca_app/features/pos/data/models/sale_model.dart';
import 'package:casca_app/features/pos/data/pos_repository.dart';
import 'package:casca_app/features/pos/domain/payment_rules.dart';
import 'package:casca_app/features/pos/domain/sale_error_rules.dart';
import 'package:casca_app/features/pos/domain/sale_request.dart';
import 'package:casca_app/features/pos/presentation/providers/pos_cart_provider.dart';
import 'package:casca_app/features/pos/presentation/providers/pos_customer_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CompletedSale {
  const CompletedSale({required this.sale, required this.payment});

  final SaleResultModel sale;
  final Payment payment;
}

class SaleState {
  const SaleState({this.submitting = false, this.failure, this.completed});

  final bool submitting;
  final SaleFailure? failure;
  final CompletedSale? completed;
}

class SaleController extends Notifier<SaleState> {
  String? _attempt;
  String? _attemptKey;

  @override
  SaleState build() => const SaleState();

  void reset() {
    if (!state.submitting) state = const SaleState();
  }

  Future<void> submit(Payment payment) async {
    final cart = ref.read(cartProvider);
    final lines = cart.lines;
    if (state.submitting || lines.isEmpty) return;

    final request = saleRequest(
      lines,
      payment,
      priceListId: cart.priceListId,
      customerId: ref.read(saleCustomerProvider)?.id,
    );
    final attempt = jsonEncode(request);
    if (attempt != _attempt) {
      _attempt = attempt;
      _attemptKey = newIdempotencyKey();
    }

    state = const SaleState(submitting: true);
    try {
      final sale = await ref
          .read(posRepositoryProvider)
          .createSale(request, idempotencyKey: _attemptKey!);
      _attempt = null;
      ref.read(cartProvider.notifier).finishSale();
      ref.read(saleCustomerProvider.notifier).select(null);
      state = SaleState(
        completed: CompletedSale(sale: sale, payment: payment),
      );
    } catch (error) {
      final failure = saleFailure(error, lines);
      if (failure.lineErrors.isNotEmpty) {
        ref.read(cartProvider.notifier).showLineErrors(failure.lineErrors);
      }
      state = SaleState(failure: failure);
    }
  }
}

final saleProvider = NotifierProvider<SaleController, SaleState>(
  SaleController.new,
);
