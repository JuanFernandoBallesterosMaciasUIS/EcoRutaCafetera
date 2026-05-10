import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/home_screen.dart';
import '../screens/nueva_finca_screen.dart';
import '../services/providers.dart';
import '../models/models.dart';

/// App router configuration using go_router with role-based guards
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final user = ref.read(authProvider);
      final isAuth = user != null;
      final isOnAuthPage = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/';

      // If not authenticated and trying to access protected routes
      if (!isAuth && !isOnAuthPage) {
        return '/';
      }

      // If authenticated and on splash/auth pages, go to home
      if (isAuth && isOnAuthPage) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (_, __) => const HomeScreen(),
      ),
      GoRoute(
        path: '/finca/nueva',
        name: 'nueva-finca',
        builder: (_, __) => const NuevaFincaScreen(),
      ),
      GoRoute(
        path: '/finca/:id',
        name: 'detalle-finca',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return _FincaDetailPlaceholder(id: id);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Página no encontrada: ${state.uri}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Inicio'),
            ),
          ],
        ),
      ),
    ),
  );
});

/// Placeholder for finca detail screen
class _FincaDetailPlaceholder extends ConsumerWidget {
  final String id;
  const _FincaDetailPlaceholder({required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fincas = ref.read(fincasProvider);
    final finca = fincas.firstWhere(
      (f) => f.id.toString() == id,
      orElse: () => const Finca(
        nombre: 'No encontrada',
        propietario: '',
        vereda: '',
        hectareas: 0,
        variedadCafe: '',
        municipioId: 1,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/home'),
        ),
        title: Text(finca.nombre),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DetailRow('Propietario', finca.propietario),
                    _DetailRow('Vereda', finca.vereda),
                    _DetailRow('Municipio', finca.municipioNombre),
                    _DetailRow('Hectáreas', '${finca.hectareas} ha'),
                    _DetailRow('Variedad', finca.variedadCafe),
                    _DetailRow(
                      'Coordenadas',
                      finca.latitud != null
                          ? '${finca.latitud!.toStringAsFixed(4)}°N, ${finca.longitud!.toStringAsFixed(4)}°O'
                          : 'Sin capturar',
                    ),
                    _DetailRow('Estado sync', finca.syncStatus.displayName),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Historial de visitas',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: const Color(0xFF00450D),
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'Sin visitas registradas',
                    style: TextStyle(color: Color(0xFF41493E)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: const Color(0xFF006E1C),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_chart_rounded),
        label: const Text('Capturar indicadores'),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: const Color(0xFF41493E),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
