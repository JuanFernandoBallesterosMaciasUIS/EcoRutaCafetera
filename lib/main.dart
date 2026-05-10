import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'utils/app_router.dart';

void main() {
  runApp(
    // ProviderScope wraps the whole app for Riverpod state management
    const ProviderScope(
      child: EcoRutaCafeteraApp(),
    ),
  );
}

/// EcoRuta Cafetera - Root Application Widget
///
/// Sistema territorial de censo cafetero para el departamento de Santander.
/// Desarrollado para Ingeniería de Software II - UIS.
class EcoRutaCafeteraApp extends ConsumerWidget {
  const EcoRutaCafeteraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'EcoRuta Cafetera',
      debugShowCheckedModeBanner: false,
      theme: EcoRutaTheme.lightTheme,
      routerConfig: router,
      // Accessibility: supports screen reader (TalkBack)
      builder: (context, child) {
        return MediaQuery(
          // Ensure text scale doesn't break UI (WCAG 2.1 AA)
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              MediaQuery.of(context).textScaler.scale(1.0).clamp(0.85, 1.2),
            ),
          ),
          child: child!,
        );
      },
    );
  }
}
