import 'package:casca_app/core/auth/auth_controller.dart';
import 'package:casca_app/core/auth/register_request.dart';
import 'package:casca_app/core/auth/session_state.dart';
import 'package:casca_app/features/businesses/data/business_repository.dart';
import 'package:casca_app/features/businesses/data/models/invitation_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final invitationsProvider = FutureProvider.autoDispose<List<InvitationModel>>(
  retry: (_, _) => null,
  (ref) {
    ref.watch(authControllerProvider.select((s) => s.session?.account.id));
    return ref.watch(businessRepositoryProvider).getInvitations();
  },
);

class BusinessActionState {
  const BusinessActionState({
    this.switchingTo,
    this.respondingTo,
    this.error,
    this.failure,
  });

  final SessionStore? switchingTo;
  final String? respondingTo;
  final Object? error;
  final String? failure;

  bool get busy => switchingTo != null || respondingTo != null;
}

class BusinessActionController extends Notifier<BusinessActionState> {
  @override
  BusinessActionState build() => const BusinessActionState();

  Future<bool> switchStore(SessionStore store) async {
    if (state.busy) return false;
    state = BusinessActionState(switchingTo: store);
    final keepAlive = ref.keepAlive();
    final auth = ref.read(authControllerProvider.notifier);
    try {
      final session = await ref
          .read(businessRepositoryProvider)
          .switchStore(store.id);
      auth.applySession(session);
      if (ref.mounted) state = const BusinessActionState();
      return true;
    } catch (error) {
      if (ref.mounted) {
        state = BusinessActionState(
          error: error,
          failure: 'No fue posible cambiar de sucursal.',
        );
      }
      return false;
    } finally {
      keepAlive.close();
    }
  }

  Future<void> respond(String invitationId, {required bool accept}) async {
    if (state.busy) return;
    state = BusinessActionState(respondingTo: invitationId);
    final keepAlive = ref.keepAlive();
    final repository = ref.read(businessRepositoryProvider);
    final auth = ref.read(authControllerProvider.notifier);
    try {
      if (accept) {
        await repository.acceptInvitation(invitationId);
        await auth.refreshSession();
      } else {
        await repository.declineInvitation(invitationId);
      }
      if (ref.mounted) {
        ref.invalidate(invitationsProvider);
        state = const BusinessActionState();
      }
    } catch (error) {
      if (ref.mounted) {
        state = BusinessActionState(
          error: error,
          failure: 'No fue posible responder la invitación.',
        );
      }
    } finally {
      keepAlive.close();
    }
  }
}

final businessActionProvider =
    NotifierProvider.autoDispose<BusinessActionController, BusinessActionState>(
      BusinessActionController.new,
    );

class CreateBusinessController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> create({
    required String name,
    required BusinessType businessType,
  }) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    final keepAlive = ref.keepAlive();
    final repository = ref.read(businessRepositoryProvider);
    final auth = ref.read(authControllerProvider.notifier);
    final result = await AsyncValue.guard(() async {
      auth.applySession(
        await repository.createBusiness(name: name, businessType: businessType),
      );
    });
    if (ref.mounted) state = result;
    keepAlive.close();
    return !result.hasError;
  }
}

final createBusinessProvider =
    NotifierProvider.autoDispose<CreateBusinessController, AsyncValue<void>>(
      CreateBusinessController.new,
    );
