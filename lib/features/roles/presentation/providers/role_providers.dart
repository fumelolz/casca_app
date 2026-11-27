import 'package:casca_app/core/auth/auth_controller.dart';
import 'package:casca_app/features/roles/data/models/role_models.dart';
import 'package:casca_app/features/roles/data/role_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef RoleEditorKey = ({String? roleId, String? copyFrom});

class RoleEditorData {
  const RoleEditorData({required this.groups, this.role});

  final List<PermissionGroupModel> groups;
  final RoleDetailModel? role;
}

final roleListProvider = FutureProvider.autoDispose<List<RoleListItemModel>>(
  retry: (_, _) => null,
  (ref) {
    ref.watch(authControllerProvider.select((s) => s.session?.activeStore.id));
    return ref.watch(roleRepositoryProvider).getRoles();
  },
);

final roleEditorProvider = FutureProvider.autoDispose
    .family<RoleEditorData, RoleEditorKey>(retry: (_, _) => null, (
      ref,
      key,
    ) async {
      ref.watch(
        authControllerProvider.select((s) => s.session?.activeStore.id),
      );
      final repository = ref.watch(roleRepositoryProvider);
      final source = key.roleId ?? key.copyFrom;
      final role = source == null ? null : repository.getRole(source);
      final (groups, detail) = await (
        repository.getPermissions(),
        role ?? Future<RoleDetailModel?>.value(),
      ).wait;

      return RoleEditorData(groups: groups, role: detail);
    });

class RoleActionController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> save(Map<String, dynamic> request, {String? roleId}) {
    final repository = ref.read(roleRepositoryProvider);
    return _run(
      () => roleId == null
          ? repository.createRole(request)
          : repository.updateRole(roleId, request),
    );
  }

  Future<bool> delete(String roleId) {
    final repository = ref.read(roleRepositoryProvider);
    return _run(() => repository.deleteRole(roleId));
  }

  Future<bool> _run(Future<void> Function() action) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    final link = ref.keepAlive();
    final result = await AsyncValue.guard(action);
    if (ref.mounted) {
      if (!result.hasError) ref.invalidate(roleListProvider);
      state = result;
    }
    link.close();
    return !result.hasError;
  }
}

final roleActionProvider =
    NotifierProvider.autoDispose<RoleActionController, AsyncValue<void>>(
      RoleActionController.new,
    );
