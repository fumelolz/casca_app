import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/app/theme/casca_typography.dart';
import 'package:casca_app/core/auth/register_request.dart';
import 'package:casca_app/core/errors/api_exception.dart';
import 'package:casca_app/core/routing/app_routes.dart';
import 'package:casca_app/features/auth/domain/password_rules.dart';
import 'package:casca_app/core/auth/business_type_options.dart';
import 'package:casca_app/features/auth/presentation/providers/register_controller.dart';
import 'package:casca_app/features/auth/presentation/widgets/auth_card_layout.dart';
import 'package:casca_app/features/auth/presentation/widgets/password_requirements_hint.dart';
import 'package:casca_app/shared/formatters/mask_input_formatter.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_icon.dart';
import 'package:casca_app/shared/ui/casca_input.dart';
import 'package:casca_app/shared/ui/casca_link.dart';
import 'package:casca_app/shared/ui/casca_select.dart';
import 'package:casca_app/shared/ui/casca_step_progress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

class _StepInfo {
  const _StepInfo(this.title, this.description);

  final String title;
  final String description;
}

const _steps = [
  _StepInfo(
    '¡Comencemos con tu negocio!',
    'Cuéntanos sobre tu tienda para configurar tu espacio de trabajo.',
  ),
  _StepInfo('Acceso', 'Correo y contraseña'),
];

const _phoneDigits = 10;
const _maxNameLength = 100;

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _tenantController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  int _step = 0;
  BusinessType? _businessType;
  bool _submitAttempted = false;

  bool get _isLastStep => _step == _steps.length - 1;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tenantController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) return 'Campo obligatorio';
    return null;
  }

  String? _validatePhone(String? value) {
    final digits = MaskInputFormatter.digitsOnly(value ?? '');
    return digits.length == _phoneDigits ? null : 'Ingresa 10 dígitos';
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Ingresa un correo válido';
    }
    return null;
  }

  String? _validateBusinessType(BusinessType? value) {
    return value == null ? 'Selecciona el tipo de negocio' : null;
  }

  String _errorMessage(Object error) {
    if (error is ApiException && error.statusCode == 409) {
      return 'Ya existe una cuenta con ese correo electrónico.';
    }
    return 'No fue posible crear la cuenta. Revisa los datos e inténtalo de '
        'nuevo.';
  }

  void _back() => setState(() => _step = _step - 1);

  void _systemBack() {
    if (ref.read(registerControllerProvider).isLoading) return;
    if (_step > 0) return _back();
    context.go(AppRoutes.login);
  }

  Future<void> _next() async {
    if (_isLastStep) setState(() => _submitAttempted = true);

    final valid = _formKey.currentState!.validate();
    if (!valid) return;

    if (!_isLastStep) {
      setState(() => _step = _step + 1);
      return;
    }

    if (!isPasswordValid(_passwordController.text)) return;

    await ref
        .read(registerControllerProvider.notifier)
        .submit(
          RegisterRequest(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            phone: MaskInputFormatter.digitsOnly(_phoneController.text),
            tenantName: _tenantController.text.trim(),
            businessType: _businessType!,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final state = ref.watch(registerControllerProvider);
    final error = _isLastStep ? state.error : null;
    final info = _steps[_step];

    return AuthCardLayout(
      onBack: _systemBack,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CascaStepProgress(currentStep: _step, totalSteps: _steps.length),
          const SizedBox(height: CascaSpacing.space5),
          Text(info.title, style: textTheme.headlineMedium),
          const SizedBox(height: CascaSpacing.space1),
          Text(
            info.description,
            style: textTheme.bodyMedium?.copyWith(color: colors.textMuted),
          ),
          const SizedBox(height: CascaSpacing.space4),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_step == 0) _businessStep(context),
                if (_step == 1) _accessStep(context),
                if (error != null) ...[
                  const SizedBox(height: CascaSpacing.space4),
                  Text(
                    _errorMessage(error),
                    style: textTheme.bodyMedium?.copyWith(color: colors.danger),
                  ),
                ],
                const SizedBox(height: CascaSpacing.space5),
                Row(
                  children: [
                    if (_step > 0) ...[
                      CascaButton(
                        label: 'Atrás',
                        variant: CascaButtonVariant.secondary,
                        onPressed: state.isLoading ? null : _back,
                      ),
                      const SizedBox(width: CascaSpacing.space3),
                    ],
                    Expanded(
                      child: CascaButton(
                        label: _isLastStep ? 'Crear cuenta' : 'Continuar',
                        loading: state.isLoading,
                        fullWidth: true,
                        onPressed: _next,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: CascaSpacing.space6),
          const Divider(),
          const SizedBox(height: CascaSpacing.space4),
          Center(
            child: CascaLink(
              textBefore: '¿Ya tienes cuenta? ',
              label: 'Inicia sesión',
              fontSize: CascaFontSize.md,
              onTap: () => context.go(AppRoutes.login),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(BuildContext context, String text) {
    final style = Theme.of(context).textTheme.labelLarge
        ?.copyWith(fontWeight: CascaFontWeight.semibold);
    return Padding(
      padding: const EdgeInsets.only(bottom: CascaSpacing.space2),
      child: Text(text, style: style),
    );
  }

  Widget _businessStep(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      key: const ValueKey('business-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _label(context, 'Nombre del negocio'),
        CascaInput(
          controller: _tenantController,
          hintText: 'Ej. Joyería El Sol',
          iconStart: CascaIcons.store,
          maxLength: _maxNameLength,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.organizationName],
          validator: _validateRequired,
          showErrorMessage: false,
        ),
        const SizedBox(height: CascaSpacing.space5),
        _label(context, 'Tipo de negocio'),
        CascaSelect<BusinessType>(
          options: businessTypeOptions,
          value: _businessType,
          hintText: 'Selecciona el tipo de negocio',
          validator: _validateBusinessType,
          showErrorMessage: false,
          onChanged: (value) => setState(() => _businessType = value),
        ),
        const SizedBox(height: CascaSpacing.space6),
        Text('Tus datos de contacto', style: textTheme.titleLarge),
        const SizedBox(height: CascaSpacing.space1),
        Text(
          '¿Quién administrará este negocio?',
          style: textTheme.bodyMedium?.copyWith(color: colors.textMuted),
        ),
        const SizedBox(height: CascaSpacing.space4),
        _label(context, 'Nombre completo'),
        CascaInput(
          controller: _nameController,
          hintText: 'Ej. María López',
          maxLength: _maxNameLength,
          keyboardType: TextInputType.name,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.name],
          validator: _validateRequired,
          showErrorMessage: false,
        ),
        const SizedBox(height: CascaSpacing.space5),
        _label(context, 'Teléfono'),
        CascaInput(
          controller: _phoneController,
          hintText: '10 dígitos',
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.telephoneNumberNational],
          inputFormatters: const [MaskInputFormatter.phone],
          validator: _validatePhone,
          showErrorMessage: false,
          onFieldSubmitted: (_) => _next(),
        ),
      ],
    );
  }

  Widget _accessStep(BuildContext context) {
    return Column(
      key: const ValueKey('access-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _label(context, 'Correo electrónico'),
        CascaInput(
          controller: _emailController,
          hintText: 'ejemplo@correo.com',
          iconStart: CascaIcons.envelope,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          validator: _validateEmail,
          showErrorMessage: false,
        ),
        const SizedBox(height: CascaSpacing.space5),
        _label(context, 'Contraseña'),
        CascaInput(
          controller: _passwordController,
          hintText: 'Ingresa al menos 8 caracteres',
          iconStart: CascaIcons.lock,
          password: true,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.newPassword],
          validator: _validateRequired,
          showErrorMessage: false,
          onFieldSubmitted: (_) => _next(),
        ),
        const SizedBox(height: CascaSpacing.space2),
        PasswordRequirementsHint(
          password: _passwordController.text,
          showMissingAsError: _submitAttempted,
        ),
      ],
    );
  }
}
