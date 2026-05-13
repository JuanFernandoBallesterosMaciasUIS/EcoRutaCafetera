import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/providers.dart';
import '../widgets/widgets.dart';

const _kCoffeeBgUrl =
    'https://lh3.googleusercontent.com/aida-public/AB6AXuAIA-iIqP6BkHzz5FqBP4MS1RE2K6CkHFWLfA23AyQk8a4LZaRwl6WMhnL9HXLgTlG3OhUWTxIdqQXWpVODXm7Vv35P3nic7t5QXP6eKLIuGwn02QaCTfxL-vLhFLCbWSaPtoMAcApKZEwy92Hmex3Z1SOOafqdjjPQcE7irSK1jRY53c18PDAZqI5Z-qCs0W9LhUu7l5ZRtnTQLe3Vi-nQSyW7e5zdhWzRq6me9QegWH8A6wtURmFybA-sdraKCyAuCZsmH1GLrQg';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(connectivityProvider);
    return Scaffold(
      body: _SplashBody(isOnline: isOnline),
    );
  }
}

// ─── Splash Body ────────────────────────────────────────────────────────────

class _SplashBody extends StatelessWidget {
  final bool isOnline;
  const _SplashBody({required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return Stack(
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

        // Hero overlay: rgba(0,69,13,0.2) → white95% → #f9f9f9
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
        SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 448),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 32),

                          // Logo pill card
                          _LogoCard()
                              .animate()
                              .fadeIn(duration: 600.ms)
                              .scale(begin: const Offset(0.9, 0.9)),

                          const SizedBox(height: 32),

                          // Brand message
                          _BrandMessage()
                              .animate(delay: 200.ms)
                              .fadeIn(duration: 500.ms),

                          const SizedBox(height: 24),

                          // Connectivity badge
                          ConnectivityBadge(isOnline: isOnline)
                              .animate(delay: 400.ms)
                              .fadeIn(duration: 400.ms),

                          const SizedBox(height: 32),

                          // Action buttons
                          _ActionButtons()
                              .animate(delay: 500.ms)
                              .fadeIn(duration: 400.ms)
                              .slideY(begin: 0.15),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Footer
              _SplashFooter().animate(delay: 700.ms).fadeIn(),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Logo Card ──────────────────────────────────────────────────────────────

class _LogoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(9999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: EcoRutaColors.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Green circle with eco icon
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              color: EcoRutaColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x4000450D),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.eco_rounded, color: Colors.white, size: 48),
          ),

          const SizedBox(height: 12),

          // EcoRuta title
          Text(
            'EcoRuta',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: EcoRutaColors.primary,
              letterSpacing: -0.6,
            ),
          ),

          // Cafetera subtitle
          Text(
            'Cafetera',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: EcoRutaColors.primary,
              height: 1.1,
            ).copyWith(
              color: EcoRutaColors.primary.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Brand Message ──────────────────────────────────────────────────────────

class _BrandMessage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'SISTEMA TERRITORIAL',
          textAlign: TextAlign.center,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 4,
            color: EcoRutaColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Potenciando la eficiencia en la cosecha y la gestión de fincas cafeteras.',
          textAlign: TextAlign.center,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 1.5,
            color: EcoRutaColors.onSurface,
          ),
        ),
      ],
    );
  }
}

// ─── Action Buttons ─────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => context.go('/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: EcoRutaColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 8,
              shadowColor: EcoRutaColors.primary.withOpacity(0.4),
            ),
            child: Text(
              'Iniciar Sesión',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: () => context.go('/register'),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: EcoRutaColors.primary,
              side: const BorderSide(color: EcoRutaColors.primary, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Registrarse',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Footer ─────────────────────────────────────────────────────────────────

class _SplashFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.verified_rounded,
                size: 16,
                color: EcoRutaColors.onSurfaceVariant.withOpacity(0.6),
              ),
              const SizedBox(width: 4),
              Text(
                'Versión 1.0.0 • 2026',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 12,
                  letterSpacing: 0.04 * 12,
                  fontWeight: FontWeight.w500,
                  color: EcoRutaColors.onSurfaceVariant.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 4,
            width: 128,
            decoration: BoxDecoration(
              color: EcoRutaColors.outlineVariant,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}
