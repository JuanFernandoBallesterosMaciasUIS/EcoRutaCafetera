import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/providers.dart';

const _kCoffeeBgUrl =
    'https://lh3.googleusercontent.com/aida-public/AB6AXuAIA-iIqP6BkHzz5FqBP4MS1RE2K6CkHFWLfA23AyQk8a4LZaRwl6WMhnL9HXLgTlG3OhUWTxIdqQXWpVODXm7Vv35P3nic7t5QXP6eKLIuGwn02QaCTfxL-vLhFLCbWSaPtoMAcApKZEwy92Hmex3Z1SOOafqdjjPQcE7irSK1jRY53c18PDAZqI5Z-qCs0W9LhUu7l5ZRtnTQLe3Vi-nQSyW7e5zdhWzRq6me9QegWH8A6wtURmFybA-sdraKCyAuCZsmH1GLrQg';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() => _isLoading = true);

    final success = await ref.read(authProvider.notifier).login(
          _usernameController.text.trim(),
          _passwordController.text,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      context.go('/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Credenciales invalidas. Intente nuevamente.'),
          backgroundColor: EcoRutaColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showForgotPassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Funcion disponible proximamente'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.network(
            _kCoffeeBgUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: EcoRutaColors.primaryContainer,
            ),
          ),

          // Hero overlay gradient
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
              // App bar
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: EcoRutaColors.onSurfaceVariant,
                  onPressed: () => context.go('/'),
                ),
              ),

              // Form content
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: EcoRutaColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  EcoRutaColors.primary.withValues(alpha: 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Logo circle
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: EcoRutaColors.surfaceContainerLow,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: EcoRutaColors.outlineVariant),
                              ),
                              child: const Icon(
                                Icons.eco_rounded,
                                color: EcoRutaColors.primary,
                                size: 40,
                              ),
                            )
                                .animate()
                                .fadeIn(duration: 400.ms)
                                .scale(begin: const Offset(0.85, 0.85)),

                            const SizedBox(height: 8),

                            // Title
                            Text(
                              'Iniciar Sesion',
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: EcoRutaColors.primary,
                              ),
                            ).animate(delay: 100.ms).fadeIn(),

                            const SizedBox(height: 24),

                            // Form
                            _LoginForm(
                              formKey: _formKey,
                              usernameController: _usernameController,
                              passwordController: _passwordController,
                              obscurePassword: _obscurePassword,
                              isLoading: _isLoading,
                              onTogglePassword: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                              onLogin: _handleLogin,
                              onForgotPassword: _showForgotPassword,
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.05),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Form widget ──────────────────────────────────────────────────────────────

class _LoginForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool isLoading;
  final VoidCallback onTogglePassword;
  final VoidCallback onLogin;
  final VoidCallback onForgotPassword;

  const _LoginForm({
    required this.formKey,
    required this.usernameController,
    required this.passwordController,
    required this.obscurePassword,
    required this.isLoading,
    required this.onTogglePassword,
    required this.onLogin,
    required this.onForgotPassword,
  });

  InputDecoration _fieldDecoration({String? hint, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      suffixIcon: suffix,
      filled: true,
      fillColor: EcoRutaColors.surfaceContainer,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: EcoRutaColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: EcoRutaColors.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: EcoRutaColors.error, width: 2),
      ),
    );
  }

  TextStyle get _labelStyle => GoogleFonts.hankenGrotesk(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: EcoRutaColors.onSurfaceVariant,
      );

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Username
          Text('Usuario o correo', style: _labelStyle),
          const SizedBox(height: 4),
          TextFormField(
            controller: usernameController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: _fieldDecoration(hint: 'ejemplo@correo.com'),
            validator: (v) {
              if ((v ?? '').trim().isEmpty) {
                return 'Ingresa tu usuario o correo';
              }
              return null;
            },
          ).animate().fadeIn(delay: 150.ms),

          const SizedBox(height: 16),

          // Password
          Text('Contrasena', style: _labelStyle),
          const SizedBox(height: 4),
          TextFormField(
            controller: passwordController,
            obscureText: obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => onLogin(),
            decoration: _fieldDecoration(
              hint: '············',
              suffix: IconButton(
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: EcoRutaColors.onSurfaceVariant,
                ),
                onPressed: onTogglePassword,
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) {
                return 'Ingresa tu contrasena';
              }
              if (v.length < 4) {
                return 'Contrasena muy corta';
              }
              return null;
            },
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 24),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: isLoading ? null : onLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: EcoRutaColors.secondary,
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Ingresar',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.14,
                      ),
                    ),
            ),
          ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1),

          const SizedBox(height: 20),

          // Forgot password
          Center(
            child: TextButton(
              onPressed: onForgotPassword,
              child: Text(
                'Olvido la contrasena?',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: EcoRutaColors.primary,
                  letterSpacing: 0.14,
                ),
              ),
            ),
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }
}
