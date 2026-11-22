import 'package:casca_app/app/theme/casca_radius.dart';
import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/app/theme/casca_typography.dart';
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

    debugPrint(
      'ancho: ${MediaQuery.sizeOf(context).width}, '
      'densidad: ${MediaQuery.devicePixelRatioOf(context)}, '
      'texto: ${MediaQuery.textScalerOf(context)}',
    );

    return Scaffold(
      body: Center(
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
                  border: Border.all(color: colors.border),
                ),
                child: Form(
                  key: _formKey,
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
                        style: textTheme.bodyLarge,
                      ),
                      const SizedBox(height: CascaSpacing.space5),
                      Text('Correo electrónico', style: labelStyle),
                      const SizedBox(height: CascaSpacing.space2),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: const InputDecoration(
                          hintText: 'Ingresa tu correo',
                          prefixIcon: Icon(Icons.mail_outline),
                        ),
                      ),
                      const SizedBox(height: CascaSpacing.space5),
                      Text('Contraseña', style: labelStyle),
                      const SizedBox(height: CascaSpacing.space2),
                      TextFormField(
                        controller: _passwordController,
                        validator: _validatePassword,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        obscureText: !_passwordVisible,
                        decoration: InputDecoration(
                          hintText: 'Ingresa tu contraseña',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: _togglePasswordVisibility,
                            icon: Icon(
                              _passwordVisible
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                        ),
                      ),
                      if (error != null) ...[
                        const SizedBox(height: CascaSpacing.space3),
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
                              const SizedBox(width: CascaSpacing.space2),
                            ],
                            const Text('Iniciar sesión'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
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
              ),
            ],
          ),
        ),
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
              child: Icon(Icons.shopping_bag, color: colors.onInfo, size: 22),
            ),
            const SizedBox(width: CascaSpacing.space3),
            Text(
              'Casca tiendas',
              style: textTheme.displaySmall?.copyWith(letterSpacing: -0.64),
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
