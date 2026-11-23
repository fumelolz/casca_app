import 'package:casca_app/app/theme/casca_radius.dart';
import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/app/theme/casca_typography.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_icon.dart';
import 'package:casca_app/shared/ui/casca_input.dart';
import 'package:casca_app/shared/ui/casca_link.dart';
import 'package:casca_app/shared/ui/casca_overlay_loader.dart';
import 'package:casca_app/core/errors/api_exception.dart';
import 'package:casca_app/features/auth/presentation/providers/login_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _GlowPainter(colors.infoSoft)),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: CascaSpacing.space4,
                vertical: CascaSpacing.space6,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _Brand(),
                  const SizedBox(height: CascaSpacing.space6),
                  Container(
                    width: 450,
                    padding: const EdgeInsets.all(36),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: CascaRadius.sm,
                      border: Border.all(
                        color: colors.border.withValues(alpha: 0.6),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1F0F172A),
                          blurRadius: 50,
                          spreadRadius: -12,
                          offset: Offset(0, 20),
                        ),
                      ],
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
                          style: textTheme.bodyLarge?.copyWith(
                            color: colors.textMuted,
                          ),
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
                                  onTap: () {},
                                  fontSize: CascaFontSize.sm,
                                ),
                              ),
                              if (error != null) ...[
                                const SizedBox(height: CascaSpacing.space5),
                                Text(
                                  error,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colors.danger,
                                  ),
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
                            onTap: () {},
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          CascaOverlayLoader(
            visible: loading,
            heading: 'Bienvenido',
            message: 'Preparando todo para ti',
          ),
        ],
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colors.info,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: CascaIcon(
                CascaIcons.bagShopping,
                size: 22,
                color: colors.onInfo,
              ),
            ),
            const SizedBox(width: CascaSpacing.space3),
            Flexible(
              child: Text(
                'Casca tiendas',
                style: textTheme.displaySmall?.copyWith(letterSpacing: -0.64),
              ),
            ),
          ],
        ),
        const SizedBox(height: CascaSpacing.space3),
        Text(
          'Punto de venta y gestión de tiendas',
          style: textTheme.bodySmall?.copyWith(letterSpacing: 0.24),
        ),
      ],
    );
  }
}

class _GlowPainter extends CustomPainter {
  const _GlowPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    _paintGlow(
      canvas,
      size,
      center: Offset(size.width / 2, -size.height * 0.1),
      radiusX: 960,
      radiusY: 480,
    );
    _paintGlow(
      canvas,
      size,
      center: Offset(size.width, size.height),
      radiusX: 480,
      radiusY: 320,
    );
  }

  void _paintGlow(
    Canvas canvas,
    Size size, {
    required Offset center,
    required double radiusX,
    required double radiusY,
  }) {
    final scaleY = radiusY / radiusX;
    final shader = RadialGradient(
      colors: [color, color.withValues(alpha: 0)],
      stops: const [0, 0.7],
    ).createShader(Rect.fromCircle(center: Offset.zero, radius: radiusX));

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(1, scaleY);
    canvas.drawRect(
      Rect.fromLTRB(
        -center.dx,
        -center.dy / scaleY,
        size.width - center.dx,
        (size.height - center.dy) / scaleY,
      ),
      Paint()..shader = shader,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GlowPainter oldDelegate) => oldDelegate.color != color;
}
