import 'package:casca_app/app/theme/casca_radius.dart';
import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/app/theme/casca_typography.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _passwordVisible = false;
  bool _loading = false;
  String? _error;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _passwordVisible = !_passwordVisible;
    });
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

  Future<void> _fakeLogin(String email, String password) async {
    await Future.delayed(const Duration(seconds: 2));
    if (password != '123456') throw Exception('Credenciales inválidas');
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    String? error;
    try {
      await _fakeLogin(_emailController.text.trim(), _passwordController.text);
    } catch (_) {
      error = 'Correo o contraseña incorrectos.';
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final error = _error;
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
                              TextFormField(
                                controller: _emailController,
                                style: textTheme.bodyMedium,
                                keyboardType: TextInputType.emailAddress,
                                validator: _validateEmail,
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                decoration: const InputDecoration(
                                  hintText: 'Ingresa tu correo',
                                  prefixIcon: Icon(
                                    Icons.mail_outline,
                                    size: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(height: CascaSpacing.space5),
                              Text('Contraseña', style: labelStyle),
                              const SizedBox(height: CascaSpacing.space2),
                              TextFormField(
                                controller: _passwordController,
                                style: textTheme.bodyMedium,
                                validator: _validatePassword,
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                obscureText: !_passwordVisible,
                                decoration: InputDecoration(
                                  hintText: 'Ingresa tu contraseña',
                                  prefixIcon: const Icon(
                                    Icons.lock_outline,
                                    size: 16,
                                  ),
                                  suffixIcon: IconButton(
                                    onPressed: _togglePasswordVisibility,
                                    iconSize: 18,
                                    icon: Icon(
                                      _passwordVisible
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: CascaSpacing.space3),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  '¿Olvidaste tu contraseña?',
                                  style: labelStyle?.copyWith(
                                    color: colors.info,
                                  ),
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
                              FilledButton(
                                onPressed: _submit,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_loading) ...[
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: colors.onPrimary,
                                        ),
                                      ),
                                      const SizedBox(
                                        width: CascaSpacing.space2,
                                      ),
                                    ],
                                    const Text('Iniciar sesión'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: CascaSpacing.space6),
                        const Divider(),
                        const SizedBox(height: CascaSpacing.space4),
                        Text.rich(
                          textAlign: TextAlign.center,
                          TextSpan(
                            style: textTheme.bodyLarge?.copyWith(
                              color: colors.textSecondary,
                            ),
                            children: [
                              const TextSpan(text: '¿Aún no tienes cuenta? '),
                              TextSpan(
                                text: 'Regístrate',
                                style: TextStyle(
                                  color: colors.info,
                                  fontWeight: CascaFontWeight.semibold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
              child: SvgPicture.asset(
                'assets/icons/bag-shopping.svg',
                height: 22,
                colorFilter: ColorFilter.mode(colors.onInfo, BlendMode.srcIn),
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
