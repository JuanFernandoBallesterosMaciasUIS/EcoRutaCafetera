import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/home_screen.dart';
import '../screens/nueva_finca_screen.dart';
import '../screens/finca_detail_screen.dart';
import '../screens/visita_form_screen.dart';
import '../screens/pendientes_screen.dart';
import '../screens/mapa_fincas_screen.dart';
import '../screens/usuarios_screen.dart';
import '../screens/reportes_screen.dart';
import '../services/providers.dart';

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

      if (!isAuth && !isOnAuthPage) return '/';
      if (isAuth && isOnAuthPage) return '/home';
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
          return FincaDetailScreen(fincaId: id);
        },
      ),
      GoRoute(
        path: '/visita/nueva/:fincaId',
        name: 'nueva-visita',
        builder: (context, state) {
          final fincaId = state.pathParameters['fincaId'] ?? '';
          return VisitaFormScreen(fincaId: fincaId);
        },
      ),
      GoRoute(
        path: '/pendientes',
        name: 'pendientes',
        builder: (_, __) => const PendientesScreen(),
      ),
      GoRoute(
        path: '/mapa-fincas',
        name: 'mapa-fincas',
        builder: (_, __) => const MapaFincasScreen(),
      ),
      GoRoute(
        path: '/usuarios',
        name: 'usuarios',
        builder: (_, __) => const UsuariosScreen(),
      ),
      GoRoute(
        path: '/reportes',
        name: 'reportes',
        builder: (_, __) => const ReportesScreen(),
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
              onPressed: () => context.go('/home'),
              child: const Text('Inicio'),
            ),
          ],
        ),
      ),
    ),
  );
});
