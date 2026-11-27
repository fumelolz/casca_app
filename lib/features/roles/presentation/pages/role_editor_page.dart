import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/core/auth/auth_controller.dart';
import 'package:casca_app/core/errors/api_error_message.dart';
import 'package:casca_app/core/layout/page_padding.dart';
import 'package:casca_app/core/routing/app_routes.dart';
import 'package:casca_app/core/routing/unsaved_changes.dart';
import 'package:casca_app/features/roles/domain/permission_rules.dart';
import 'package:casca_app/features/roles/presentation/providers/role_providers.dart';
import 'package:casca_app/features/roles/presentation/widgets/permission_matrix.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_card.dart';
import 'package:casca_app/shared/ui/casca_delete_modal.dart';
import 'package:casca_app/shared/ui/casca_input.dart';
import 'package:casca_app/shared/ui/casca_modal.dart';
import 'package:casca_app/shared/ui/casca_page_header.dart';
import 'package:casca_app/shared/ui/casca_skeleton.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

const int _descriptionLines = 2;
const double _skeletonHeight = 120;

class RoleEditorPage extends ConsumerStatefulWidget {
  const RoleEditorPage({super.key, this.roleId, this.copyFrom});

  final String? roleId;
  final String? copyFrom;

  @override
  ConsumerState<RoleEditorPage> createState() => _RoleEditorPageState();
}

class _RoleEditorPageState extends ConsumerState<RoleEditorPage> {
  late final UnsavedChanges _unsavedChanges;
  final _name = TextEditingController();
  final _description = TextEditingController();
  Set<String> _selected = {};
  ({String name, String description, Set<String> keys}) _saved = (
    name: '',
    description: '',
    keys: {},
  );
  RoleEditorData? _loaded;

  RoleEditorKey get _key => (roleId: widget.roleId, copyFrom: widget.copyFrom);

  bool _isDirty() {
    return _loaded != null &&
        (_name.text != _saved.name ||
            _description.text != _saved.description ||
            !sameSelection(_selected, _saved.keys));
  }

  @override
  void initState() {
    super.initState();
    _unsavedChanges = ref.read(unsavedChangesProvider)..watch(_isDirty);
  }

  @override
  void dispose() {
    _unsavedChanges.release(_isDirty);
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  void _fill(RoleEditorData data) {
    _loaded = data;
    final role = data.role;
    if (role == null) return;

    final copying = widget.roleId == null;
    _name.text = copying ? copyName(role.name) : role.name;
    _description.text = role.description ?? '';
    _selected = copying
        ? copyablePermissions(data.groups, role.permissionKeys)
        : role.permissionKeys.intersection(knownKeys(data.groups));
    if (!copying) {
      _saved = (
        name: _name.text,
        description: _description.text,
        keys: _selected,
      );
    }
  }

  void _back() => context.go(AppRoutes.roles);

  Future<void> _save() async {
    final saved = await ref
        .read(roleActionProvider.notifier)
        .save(
          saveRoleRequest(
            name: _name.text,
            description: _description.text,
            permissionKeys: _selected,
          ),
          roleId: widget.roleId,
        );
    if (!saved || !mounted) return;
    _saved = (
      name: _name.text,
      description: _description.text,
      keys: _selected,
    );
    ref.invalidate(roleEditorProvider(_key));
    _back();
  }

  Future<void> _delete(String name) async {
    final deleted = await showCascaModal<bool>(
      context: context,
      size: CascaModalSize.sm,
      builder: (_) => _DeleteRoleModal(roleId: widget.roleId!, name: name),
    );
    if ((deleted ?? false) && mounted) {
      _loaded = null;
      _back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: _content(context),
    );
  }

  Widget _content(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final state = ref.watch(roleEditorProvider(_key));
    final action = ref.watch(roleActionProvider);
    final session = ref.watch(authControllerProvider.select((s) => s.session));
    final data = state.value;
    if (data != null && _loaded == null) _fill(data);
    final loaded = _loaded;

    if (loaded == null) {
      final error = state.error;
      return SingleChildScrollView(
        padding: pagePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: CascaSpacing.space4,
          children: error == null
              ? const [
                  CascaSkeleton(height: _skeletonHeight),
                  CascaSkeleton(height: _skeletonHeight),
                ]
              : [
                  Text(
                    apiErrorMessage(
                      error,
                      'No fue posible cargar el rol.',
                      forbidden: 'No tienes permiso para ver los roles.',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  CascaButton(
                    label: 'Reintentar',
                    variant: CascaButtonVariant.secondary,
                    onPressed: () => ref.invalidate(roleEditorProvider(_key)),
                  ),
                  CascaButton(
                    label: 'Volver a roles',
                    variant: CascaButtonVariant.text,
                    onPressed: _back,
                  ),
                ],
        ),
      );
    }

    bool can(String permission) => session?.hasPermission(permission) ?? false;
    final creating = widget.roleId == null;
    final role = creating ? null : loaded.role;
    final system = role?.isSystem ?? false;
    final readOnly = system || !can(creating ? 'role.create' : 'role.update');
    final canSave = !readOnly && _name.text.trim().isNotEmpty && _isDirty();
    Widget labeled(String label, Widget input) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: CascaSpacing.space2,
      children: [
        Text(label, style: textTheme.bodyMedium),
        input,
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: pagePadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: CascaSpacing.space4,
              children: [
                CascaPageHeader(
                  title: creating ? 'Nuevo rol' : role!.name,
                  subtitle: role == null
                      ? 'Elige qué puede hacer quien tenga este rol.'
                      : '${role.employeeCount} '
                            '${role.employeeCount == 1 ? 'empleado' : 'empleados'} '
                            'con este rol',
                ),
                if (system)
                  Text(
                    'Rol del sistema: tiene todos los permisos y no se puede '
                    'modificar. Duplícalo para crear uno propio.',
                    style: textTheme.bodyMedium?.copyWith(color: colors.info),
                  ),
                if (role != null && (can('role.create') || can('role.delete')))
                  Wrap(
                    spacing: CascaSpacing.space3,
                    runSpacing: CascaSpacing.space2,
                    children: [
                      if (can('role.create'))
                        CascaButton(
                          label: 'Duplicar',
                          variant: CascaButtonVariant.secondary,
                          onPressed: () =>
                              context.go(AppRoutes.roleCopyOf(role.id)),
                        ),
                      if (can('role.delete') && !system)
                        CascaButton(
                          label: 'Eliminar',
                          variant: CascaButtonVariant.danger,
                          onPressed: () => _delete(role.name),
                        ),
                    ],
                  ),
                CascaCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: CascaSpacing.space3,
                    children: [
                      labeled(
                        'Nombre',
                        CascaInput(
                          controller: _name,
                          enabled: !readOnly,
                          hintText: 'Por ejemplo: Supervisor de turno',
                          maxLength: maxRoleName,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      labeled(
                        'Descripción',
                        CascaInput(
                          controller: _description,
                          enabled: !readOnly,
                          hintText: 'Para qué sirve este rol',
                          maxLength: maxRoleDescription,
                          lines: _descriptionLines,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                ),
                PermissionMatrix(
                  groups: loaded.groups,
                  selected: _selected,
                  readOnly: readOnly,
                  onChanged: (selected) => setState(() => _selected = selected),
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(
            CascaSpacing.space4,
            CascaSpacing.space3,
            CascaSpacing.space4,
            CascaSpacing.space3 + MediaQuery.paddingOf(context).bottom,
          ),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(top: BorderSide(color: colors.border)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: CascaSpacing.space2,
            children: [
              if (action.error case final error?)
                Text(
                  apiErrorMessage(
                    error,
                    'No fue posible guardar el rol.',
                    forbidden: 'No tienes permiso para esta acción.',
                  ),
                  textAlign: TextAlign.end,
                  style: textTheme.bodyMedium?.copyWith(color: colors.danger),
                ),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: CascaSpacing.space3,
                runSpacing: CascaSpacing.space2,
                children: [
                  CascaButton(
                    label: 'Volver',
                    variant: CascaButtonVariant.secondary,
                    onPressed: action.isLoading ? null : _back,
                  ),
                  if (!readOnly)
                    CascaButton(
                      label: creating ? 'Crear rol' : 'Guardar cambios',
                      loading: action.isLoading,
                      onPressed: canSave ? _save : null,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DeleteRoleModal extends ConsumerWidget {
  const _DeleteRoleModal({required this.roleId, required this.name});

  final String roleId;
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final action = ref.watch(roleActionProvider);
    final error = action.error;

    return CascaDeleteModal(
      title: '¿Eliminar $name?',
      message:
          'Esta acción no se puede deshacer. Solo se eliminan roles que '
          'ningún empleado tenga asignado.',
      deleting: action.isLoading,
      errorMessage: error == null
          ? null
          : apiErrorMessage(
              error,
              'No fue posible eliminar el rol.',
              forbidden: 'No tienes permiso para eliminar roles.',
            ),
      onConfirm: () async {
        final navigator = Navigator.of(context);
        final deleted = await ref
            .read(roleActionProvider.notifier)
            .delete(roleId);
        if (deleted) navigator.pop(true);
      },
    );
  }
}
