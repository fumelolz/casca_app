import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/app/theme/casca_typography.dart';
import 'package:casca_app/core/errors/api_error_message.dart';
import 'package:casca_app/core/routing/app_routes.dart';
import 'package:casca_app/features/auth/presentation/providers/forgot_password_controller.dart';
import 'package:casca_app/features/auth/presentation/widgets/auth_card_layout.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_icon.dart';
import 'package:casca_app/shared/ui/casca_input.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(forgotPasswordControllerProvider.notifier)
        .submit(_emailController.text);
  }

  void _goToCode() {
    context.go(
      AppRoutes.setPasswordFor(
        email: _emailController.text.trim().toLowerCase(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forgotPasswordControllerProvider);
    final sent = state.value ?? false;

    return AuthCardLayout(
      showBackLink: true,
      onBack: () => context.go(AppRoutes.login),
      child: sent
          ? _SentView(onContinue: _goToCode)
          : _RequestView(
              formKey: _formKey,
              controller: _emailController,
              validator: _validateEmail,
              loading: state.isLoading,
              error: state.error,
              onSubmit: _submit,
            ),
    );
  }
}

class _RequestView extends StatelessWidget {
  const _RequestView({
    required this.formKey,
    required this.controller,
    required this.validator,
    required this.loading,
    required this.error,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController controller;
  final FormFieldValidator<String> validator;
  final bool loading;
  final Object? error;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final error = this.error;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Recupera tu contraseña', style: textTheme.headlineMedium),
        const SizedBox(height: CascaSpacing.space1),
        Text(
          'Ingresa tu correo y te enviaremos un código para elegir una '
          'contraseña nueva.',
          style: textTheme.bodyMedium?.copyWith(color: colors.textMuted),
        ),
        const SizedBox(height: CascaSpacing.space4),
        Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Correo electrónico',
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: CascaFontWeight.semibold,
                ),
              ),
              const SizedBox(height: CascaSpacing.space2),
              CascaInput(
                controller: controller,
                hintText: 'ejemplo@correo.com',
                iconStart: CascaIcons.envelope,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                validator: validator,
                showErrorMessage: false,
                onFieldSubmitted: (_) => onSubmit(),
              ),
              if (error != null) ...[
                const SizedBox(height: CascaSpacing.space5),
                Text(
                  apiErrorMessage(
                    error,
                    'No fue posible enviar el código. Inténtalo de nuevo.',
                  ),
                  style: textTheme.bodyMedium?.copyWith(color: colors.danger),
                ),
              ],
              const SizedBox(height: CascaSpacing.space5),
              CascaButton(
                label: 'Enviar código',
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

class _SentView extends StatelessWidget {
  const _SentView({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: AuthStatusBadge(icon: CascaIcons.envelope)),
        const SizedBox(height: CascaSpacing.space4),
        Text(
          'Revisa tu correo',
          textAlign: TextAlign.center,
          style: textTheme.headlineMedium,
        ),
        const SizedBox(height: CascaSpacing.space1),
        Text(
          'Si el correo está registrado, te enviamos un código de 6 dígitos. '
          'Tiene una vigencia de 30 minutos.',
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(color: colors.textMuted),
        ),
        const SizedBox(height: CascaSpacing.space5),
        CascaButton(
          label: 'Ya tengo mi código',
          fullWidth: true,
          onPressed: onContinue,
        ),
      ],
    );
  }
}
