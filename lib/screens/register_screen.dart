import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/providers.dart';
import '../widgets/widgets.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  UserRole _selectedRole = UserRole.tecnicoCampo;
  Municipio? _selectedMunicipio;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Debe aceptar los términos para continuar'),
          backgroundColor: EcoRutaColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1000));

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('¡Cuenta creada exitosamente!'),
          backgroundColor: EcoRutaColors.secondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(connectivityProvider);
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 700;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/'),
        ),
        title: isWide ? null : const Text('Registro'),
        backgroundColor: EcoRutaColors.surface,
        elevation: 0,
      ),
      body: isWide
          ? _buildWideLayout(isOnline)
          : _buildMobileLayout(),
    );
  }

  Widget _buildMobileLayout() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Crear Cuenta',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: EcoRutaColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ).animate().fadeIn(),
            const SizedBox(height: 6),
            Text(
              'Completa los datos para registrarte',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: EcoRutaColors.onSurfaceVariant,
                  ),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 24),
            _buildFormCard(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildWideLayout(bool isOnline) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF00450D), Color(0xFF2E7D32)],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const EcoRutaLogo(size: 80),
                  const SizedBox(height: 32),
                  Text(
                    'Únete a EcoRuta',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Text(
                      'Crea tu cuenta para acceder a la plataforma de censo cafetero.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withOpacity(0.75),
                            height: 1.6,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Container(
            color: EcoRutaColors.background,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Crear Cuenta',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              color: EcoRutaColors.primary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Completa el formulario para registrarte.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: EcoRutaColors.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 32),
                      _buildForm(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: EcoRutaColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: EcoRutaColors.primary.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: _buildForm(),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FormLabel('Nombre completo'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              hintText: 'Ej: Iván Martínez',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
            validator: (v) => (v?.trim().isEmpty ?? true) ? 'Ingresa tu nombre' : null,
          ).animate().fadeIn(delay: 50.ms),

          const SizedBox(height: 16),

          _FormLabel('Correo electrónico'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              hintText: 'ejemplo@correo.com',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Ingresa tu correo';
              if (!v.contains('@')) return 'Correo inválido';
              return null;
            },
          ).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 16),

          _FormLabel('Rol en el sistema'),
          const SizedBox(height: 6),
          DropdownButtonFormField<UserRole>(
            value: _selectedRole,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.badge_outlined),
            ),
            items: UserRole.values.map((role) {
              return DropdownMenuItem(
                value: role,
                child: Text(role.displayName),
              );
            }).toList(),
            onChanged: (v) => setState(() => _selectedRole = v!),
          ).animate().fadeIn(delay: 150.ms),

          const SizedBox(height: 16),

          _FormLabel('Municipio asignado'),
          const SizedBox(height: 6),
          DropdownButtonFormField<Municipio>(
            value: _selectedMunicipio,
            hint: const Text('Selecciona un municipio'),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
            items: Municipio.municipiosPiloto.map((m) {
              return DropdownMenuItem(value: m, child: Text(m.nombre));
            }).toList(),
            onChanged: (v) => setState(() => _selectedMunicipio = v),
            validator: (v) => v == null ? 'Selecciona un municipio' : null,
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 16),

          _FormLabel('Contraseña'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              hintText: 'Mínimo 8 caracteres',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: EcoRutaColors.onSurfaceVariant,
                ),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Ingresa una contraseña';
              if (v.length < 8) return 'Mínimo 8 caracteres';
              return null;
            },
          ).animate().fadeIn(delay: 250.ms),

          const SizedBox(height: 16),

          _FormLabel('Confirmar contraseña'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirm,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleRegister(),
            decoration: InputDecoration(
              hintText: 'Repite tu contraseña',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                icon: Icon(
                  _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: EcoRutaColors.onSurfaceVariant,
                ),
              ),
            ),
            validator: (v) {
              if (v != _passwordController.text) return 'Las contraseñas no coinciden';
              return null;
            },
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 20),

          // Terms checkbox
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: _acceptedTerms,
                onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: EcoRutaColors.onSurfaceVariant,
                            ),
                        children: const [
                          TextSpan(text: 'Acepto el '),
                          TextSpan(
                            text: 'consentimiento informado',
                            style: TextStyle(
                              color: EcoRutaColors.primary,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          TextSpan(text: ' según Ley 1581/2012 (Habeas Data)'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 350.ms),

          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleRegister,
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Text('Crear Cuenta'),
            ),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),

          const SizedBox(height: 16),

          Center(
            child: TextButton(
              onPressed: () => context.go('/login'),
              child: RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium,
                  children: [
                    const TextSpan(
                      text: '¿Ya tienes cuenta? ',
                      style: TextStyle(color: EcoRutaColors.onSurfaceVariant),
                    ),
                    const TextSpan(
                      text: 'Iniciar Sesión',
                      style: TextStyle(
                        color: EcoRutaColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(delay: 450.ms),
        ],
      ),
    );
  }
}

class _FormLabel extends StatelessWidget {
  final String text;
  const _FormLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: EcoRutaColors.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}
