import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/app/theme/casca_typography.dart';
import 'package:casca_app/core/errors/api_exception.dart';
import 'package:casca_app/core/routing/app_routes.dart';
import 'package:casca_app/core/storage/last_email_storage.dart';
import 'package:casca_app/features/auth/presentation/providers/login_controller.dart';
import 'package:casca_app/features/auth/presentation/widgets/auth_card_layout.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_icon.dart';
import 'package:casca_app/shared/ui/casca_input.dart';
import 'package:casca_app/shared/ui/casca_link.dart';
import 'package:casca_app/shared/ui/casca_overlay_loader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _prefillEmail();
  }

  Future<void> _prefillEmail() async {
    final email = await ref.read(lastEmailStorageProvider).read();
    if (!mounted || email == null || _emailController.text.isNotEmpty) return;
    _emailController.text = email;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Ingresa tu correo';
    final formatoValido = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!formatoValido.hasMatch(email)) return 'Ingresa un correo válido';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Ingresa tu contraseña';
    return null;
  }

  String _errorMessage(Object error) {
    if (error is! ApiException) return 'Ocurrió un error inesperado.';
    if (error.isUnauthorized && error.serverMessage == null) {
      return 'Correo o contraseña incorrectos.';
    }
    return error.message;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    await ref
        .read(loginControllerProvider.notifier)
        .submit(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final loginState = ref.watch(loginControllerProvider);
    final loading = loginState.isLoading;
    final loginError = loginState.error;
    final error = loginError == null ? null : _errorMessage(loginError);
    final labelStyle = textTheme.labelLarge?.copyWith(
      fontWeight: CascaFontWeight.semibold,
    );

    return AuthCardLayout(
      overlay: CascaOverlayLoader(
        visible: loading,
        heading: 'Bienvenido',
        message: 'Preparando todo para ti',
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Bienvenido a Casca',
            textAlign: TextAlign.center,
            style: textTheme.headlineMedium,
          ),
          const SizedBox(height: CascaSpacing.space2),
          Text(
            'Accede a tu espacio de trabajo.',
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(color: colors.textMuted),
          ),
          const SizedBox(height: CascaSpacing.space5),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Correo electrónico', style: labelStyle),
                const SizedBox(height: CascaSpacing.space2),
                CascaInput(
                  controller: _emailController,
                  hintText: 'Ingresa tu correo',
                  iconStart: CascaIcons.envelope,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                  showErrorMessage: false,
                ),
                const SizedBox(height: CascaSpacing.space5),
                Text('Contraseña', style: labelStyle),
                const SizedBox(height: CascaSpacing.space2),
                CascaInput(
                  controller: _passwordController,
                  hintText: 'Ingresa tu contraseña',
                  iconStart: CascaIcons.lock,
                  password: true,
                  showErrorMessage: false,
                  validator: _validatePassword,
                ),
                const SizedBox(height: CascaSpacing.space3),
                Align(
                  alignment: Alignment.centerRight,
                  child: CascaLink(
                    label: '¿Olvidaste tu contraseña?',
                    onTap: () => context.go(AppRoutes.forgotPassword),
                    fontSize: CascaFontSize.sm,
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: CascaSpacing.space5),
                  Text(
                    error,
                    style: textTheme.bodyMedium?.copyWith(color: colors.danger),
                  ),
                ],
                const SizedBox(height: CascaSpacing.space5),
                CascaButton(
                  label: 'Iniciar sesión',
                  loading: loading,
                  fullWidth: true,
                  variant: CascaButtonVariant.primary,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
          const SizedBox(height: CascaSpacing.space6),
          const Divider(),
          const SizedBox(height: CascaSpacing.space4),
          Center(
            child: CascaLink(
              textBefore: '¿Aún no tienes cuenta? ',
              label: 'Regístrate',
              fontSize: CascaFontSize.md,
              onTap: () => context.go(AppRoutes.register),
            ),
          ),
        ],
      ),
    );
  }
}
