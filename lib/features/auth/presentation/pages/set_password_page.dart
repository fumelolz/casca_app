import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/app/theme/casca_typography.dart';
import 'package:casca_app/core/errors/api_error_message.dart';
import 'package:casca_app/core/routing/app_routes.dart';
import 'package:casca_app/features/auth/domain/password_rules.dart';
import 'package:casca_app/features/auth/presentation/providers/set_password_controller.dart';
import 'package:casca_app/features/auth/presentation/widgets/auth_card_layout.dart';
import 'package:casca_app/features/auth/presentation/widgets/password_requirements_hint.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_icon.dart';
import 'package:casca_app/shared/ui/casca_input.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

class SetPasswordPage extends ConsumerStatefulWidget {
  const SetPasswordPage({super.key, this.email = '', this.recovery = false});

  final String email;
  final bool recovery;

  @override
  ConsumerState<SetPasswordPage> createState() => _SetPasswordPageState();
}

class _SetPasswordPageState extends ConsumerState<SetPasswordPage> {
  late final _emailController = TextEditingController(text: widget.email);
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _submitAttempted = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Ingresa tu correo';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Ingresa un correo válido';
    }
    return null;
  }

  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) return 'Campo obligatorio';
    return null;
  }

  Future<void> _submit() async {
    setState(() => _submitAttempted = true);

    final formValid = _formKey.currentState!.validate();
    final password = _passwordController.text;
    if (!formValid || !isPasswordValid(password)) return;

    await ref
        .read(setPasswordControllerProvider.notifier)
        .submit(
          email: _emailController.text,
          code: _codeController.text,
          newPassword: password,
          confirmPassword: password,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(setPasswordControllerProvider);
    final completed = state.value ?? false;

    return AuthCardLayout(
      showBackLink: !completed,
      onBack: () =>
          context.go(completed ? AppRoutes.login : AppRoutes.forgotPassword),
      child: completed
          ? const _DoneView()
          : _FormView(
              recovery: widget.recovery,
              emailLocked: widget.email.isNotEmpty,
              formKey: _formKey,
              emailController: _emailController,
              codeController: _codeController,
              passwordController: _passwordController,
              validateEmail: _validateEmail,
              validateRequired: _validateRequired,
              showMissingAsError: _submitAttempted,
              loading: state.isLoading,
              error: state.error,
              onSubmit: _submit,
            ),
    );
  }
}

class _FormView extends StatelessWidget {
  const _FormView({
    required this.recovery,
    required this.emailLocked,
    required this.formKey,
    required this.emailController,
    required this.codeController,
    required this.passwordController,
    required this.validateEmail,
    required this.validateRequired,
    required this.showMissingAsError,
    required this.loading,
    required this.error,
    required this.onSubmit,
  });

  static const int _codeLength = 6;

  final bool recovery;
  final bool emailLocked;
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController codeController;
  final TextEditingController passwordController;
  final FormFieldValidator<String> validateEmail;
  final FormFieldValidator<String> validateRequired;
  final bool showMissingAsError;
  final bool loading;
  final Object? error;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final labelStyle = textTheme.labelLarge?.copyWith(
      fontWeight: CascaFontWeight.semibold,
    );
    final error = this.error;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          recovery ? 'Elige tu contraseña nueva' : 'Crea tu contraseña',
          style: textTheme.headlineMedium,
        ),
        const SizedBox(height: CascaSpacing.space1),
        if (emailLocked)
          Text.rich(
            TextSpan(
              text: 'Enviamos el código a ',
              children: [
                TextSpan(
                  text: emailController.text,
                  style: TextStyle(
                    color: colors.text,
                    fontWeight: CascaFontWeight.semibold,
                  ),
                ),
              ],
            ),
            style: textTheme.bodyMedium?.copyWith(color: colors.textMuted),
          )
        else
          Text(
            recovery
                ? 'Ingresa el código de 6 dígitos que te enviamos por correo y '
                      'tu contraseña nueva.'
                : 'Establece tu clave de acceso para comenzar a usar Casca '
                      'con tu cuenta asignada.',
            style: textTheme.bodyMedium?.copyWith(color: colors.textMuted),
          ),
        const SizedBox(height: CascaSpacing.space4),
        Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!emailLocked) ...[
                Text('Correo electrónico', style: labelStyle),
                const SizedBox(height: CascaSpacing.space2),
                CascaInput(
                  controller: emailController,
                  iconStart: CascaIcons.envelope,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: validateEmail,
                  showErrorMessage: false,
                ),
                const SizedBox(height: CascaSpacing.space5),
              ],
              Text(
                recovery ? 'Código de recuperación' : 'Código de la invitación',
                style: labelStyle,
              ),
              const SizedBox(height: CascaSpacing.space2),
              CascaInput(
                controller: codeController,
                hintText: '000000',
                iconStart: CascaIcons.key,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.oneTimeCode],
                autofocus: emailLocked,
                maxLength: recovery ? _codeLength : null,
                validator: validateRequired,
                showErrorMessage: false,
              ),
              const SizedBox(height: CascaSpacing.space5),
              Text('Contraseña nueva', style: labelStyle),
              const SizedBox(height: CascaSpacing.space2),
              CascaInput(
                controller: passwordController,
                hintText: 'Ingresa al menos 8 caracteres',
                iconStart: CascaIcons.lock,
                password: true,
                textInputAction: TextInputAction.done,
                validator: validateRequired,
                showErrorMessage: false,
                onFieldSubmitted: (_) => onSubmit(),
              ),
              const SizedBox(height: CascaSpacing.space2),
              PasswordRequirementsHint(
                password: passwordController.text,
                showMissingAsError: showMissingAsError,
              ),
              if (error != null) ...[
                const SizedBox(height: CascaSpacing.space4),
                Text(
                  apiErrorMessage(
                    error,
                    'No fue posible establecer la contraseña. Revisa el '
                    'correo y el código.',
                  ),
                  style: textTheme.bodyMedium?.copyWith(color: colors.danger),
                ),
              ],
              const SizedBox(height: CascaSpacing.space5),
              CascaButton(
                label: recovery ? 'Restablecer contraseña' : 'Crear contraseña',
                loading: loading,
                fullWidth: true,
                onPressed: onSubmit,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DoneView extends StatelessWidget {
  const _DoneView();

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: AuthStatusBadge(icon: CascaIcons.check)),
        const SizedBox(height: CascaSpacing.space4),
        Text(
          'Contraseña lista',
          textAlign: TextAlign.center,
          style: textTheme.headlineMedium,
        ),
        const SizedBox(height: CascaSpacing.space1),
        Text(
          'Tu contraseña quedó lista. Ya puedes iniciar sesión con tus nuevas '
          'credenciales.',
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(color: colors.textMuted),
        ),
        const SizedBox(height: CascaSpacing.space5),
        CascaButton(
          label: 'Ir a iniciar sesión',
          fullWidth: true,
          onPressed: () => context.go(AppRoutes.login),
        ),
      ],
    );
  }
}
