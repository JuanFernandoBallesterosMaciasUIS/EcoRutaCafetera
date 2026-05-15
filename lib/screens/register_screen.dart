import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/providers.dart';

const _kCoffeeBgUrl =
    'https://lh3.googleusercontent.com/aida-public/AB6AXuAIA-iIqP6BkHzz5FqBP4MS1RE2K6CkHFWLfA23AyQk8a4LZaRwl6WMhnL9HXLgTlG3OhUWTxIdqQXWpVODXm7Vv35P3nic7t5QXP6eKLIuGwn02QaCTfxL-vLhFLCbWSaPtoMAcApKZEwy92Hmex3Z1SOOafqdjjPQcE7irSK1jRY53c18PDAZqI5Z-qCs0W9LhUu7l5ZRtnTQLe3Vi-nQSyW7e5zdhWzRq6me9QegWH8A6wtURmFybA-sdraKCyAuCZsmH1GLrQg';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
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
    _usernameController.dispose();
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

    final success = await ref.read(authProvider.notifier).register(
          username: _usernameController.text.trim(),
          password: _passwordController.text,
          nombre: _nameController.text.trim(),
          rol: _selectedRole,
          municipioAsignado: _selectedMunicipio?.id,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('¡Cuenta creada exitosamente!'),
          backgroundColor: EcoRutaColors.secondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      context.go('/login');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('El nombre de usuario ya está en uso'),
          backgroundColor: EcoRutaColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image — same as login/splash
          Image.network(
            _kCoffeeBgUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: EcoRutaColors.primaryContainer,
            ),
          ),

          // Gradient overlay
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x3300450D),
                  Color(0xF2FFFFFF),
                  Color(0xFFF9F9F9),
                ],
                stops: [0.0, 0.70, 1.0],
              ),
            ),
          ),

          // Content
          Column(
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: EcoRutaColors.onSurfaceVariant,
                  onPressed: () => context.go('/'),
                ),
                title: const Text(
                  'Registro',
                  style: TextStyle(color: EcoRutaColors.onSurface),
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: EcoRutaColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.10),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: _buildForm(),
                      ),
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Crear Cuenta',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: EcoRutaColors.primary,
                  fontWeight: FontWeight.w700,
                ),
          ).animate().fadeIn(),
          const SizedBox(height: 4),
          Text(
            'Completa los datos para registrarte',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: EcoRutaColors.onSurfaceVariant,
                ),
          ).animate().fadeIn(delay: 60.ms),

          const SizedBox(height: 20),

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

          const SizedBox(height: 14),

          _FormLabel('Nombre de usuario'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _usernameController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              hintText: 'Ej: ivan.martinez',
              prefixIcon: Icon(Icons.account_circle_outlined),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Ingresa un nombre de usuario';
              if (v.trim().length < 3) return 'Mínimo 3 caracteres';
              return null;
            },
          ).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 14),

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

          const SizedBox(height: 14),

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

          const SizedBox(height: 14),

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

          const SizedBox(height: 14),

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

          const SizedBox(height: 18),

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

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 52,
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

          const SizedBox(height: 14),

          Center(
            child: TextButton(
              onPressed: () => context.go('/login'),
              child: RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium,
                  children: const [
                    TextSpan(
                      text: '¿Ya tienes cuenta? ',
                      style: TextStyle(color: EcoRutaColors.onSurfaceVariant),
                    ),
                    TextSpan(
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
