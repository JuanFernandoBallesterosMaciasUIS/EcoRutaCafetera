import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/providers.dart';
import '../widgets/widgets.dart';

class PendientesScreen extends ConsumerStatefulWidget {
  const PendientesScreen({super.key});

  @override
  ConsumerState<PendientesScreen> createState() => _PendientesScreenState();
}

class _PendientesScreenState extends ConsumerState<PendientesScreen> {
  bool _isSyncing = false;

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(connectivityProvider);
    final fincas = ref.watch(fincasProvider);
    final visitas = ref.watch(visitasProvider);

    final fincasPendientes =
        fincas.where((f) => f.syncStatus == SyncStatus.pendiente).toList();
    final fincasError =
        fincas.where((f) => f.syncStatus == SyncStatus.error).toList();
    final visitasPendientes =
        visitas.where((v) => v.syncStatus == SyncStatus.pendiente).toList();

    final totalPendiente =
        fincasPendientes.length + fincasError.length + visitasPendientes.length;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Cola de sincronización'),
        actions: [
          if (!isOnline)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: () =>
                    ref.read(connectivityProvider.notifier).setOnline(true),
                icon: const Icon(Icons.wifi_rounded, size: 18),
                label: const Text('Activar conexión'),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Status banner
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            color: isOnline
                ? EcoRutaColors.secondaryContainer.withOpacity(0.4)
                : EcoRutaColors.errorContainer.withOpacity(0.5),
            child: Row(
              children: [
                Icon(
                  isOnline ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                  color: isOnline
                      ? EcoRutaColors.secondary
                      : EcoRutaColors.onErrorContainer,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  isOnline
                      ? 'Conectado — listo para sincronizar'
                      : 'Sin conexión — sincronización en espera',
                  style: TextStyle(
                    color: isOnline
                        ? EcoRutaColors.onSecondaryContainer
                        : EcoRutaColors.onErrorContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Stats row
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _StatBubble(
                    count: fincasPendientes.length,
                    label: 'Fincas\npendientes',
                    color: EcoRutaColors.tertiary,
                    icon: Icons.agriculture_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatBubble(
                    count: fincasError.length,
                    label: 'Con\nerror',
                    color: EcoRutaColors.error,
                    icon: Icons.error_outline_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatBubble(
                    count: visitasPendientes.length,
                    label: 'Visitas\npendientes',
                    color: EcoRutaColors.primary,
                    icon: Icons.analytics_rounded,
                  ),
                ),
              ],
            ).animate().fadeIn(),
          ),

          // List content
          Expanded(
            child: totalPendiente == 0
                ? _EmptyQueue()
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      if (fincasError.isNotEmpty) ...[
                        _GroupHeader(
                            title: 'Fincas con error',
                            color: EcoRutaColors.error),
                        ...fincasError.asMap().entries.map(
                              (e) => _FincaSyncTile(
                                finca: e.value,
                                index: e.key,
                              ).animate().fadeIn(delay: (e.key * 60).ms),
                            ),
                        const SizedBox(height: 8),
                      ],
                      if (fincasPendientes.isNotEmpty) ...[
                        _GroupHeader(
                            title: 'Fincas por subir',
                            color: EcoRutaColors.tertiary),
                        ...fincasPendientes.asMap().entries.map(
                              (e) => _FincaSyncTile(
                                finca: e.value,
                                index: e.key,
                              ).animate().fadeIn(delay: (e.key * 60).ms),
                            ),
                        const SizedBox(height: 8),
                      ],
                      if (visitasPendientes.isNotEmpty) ...[
                        _GroupHeader(
                            title: 'Visitas por subir',
                            color: EcoRutaColors.primary),
                        ...visitasPendientes.asMap().entries.map(
                              (e) => _VisitaSyncTile(
                                visita: e.value,
                                fincas: ref.read(fincasProvider),
                                index: e.key,
                              ).animate().fadeIn(delay: (e.key * 60).ms),
                            ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
          ),

          // Sync button
          if (totalPendiente > 0)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed:
                      (!isOnline || _isSyncing) ? null : _sync,
                  icon: _isSyncing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.cloud_sync_rounded),
                  label: Text(
                    _isSyncing
                        ? 'Sincronizando...'
                        : isOnline
                            ? 'Sincronizar $totalPendiente registros'
                            : 'Sin conexión',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EcoRutaColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _sync() async {
    setState(() => _isSyncing = true);
    await Future.delayed(const Duration(seconds: 2));
    ref.read(fincasProvider.notifier).syncAll();
    ref.read(visitasProvider.notifier).syncAll();
    if (mounted) {
      setState(() => _isSyncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('¡Sincronización completada exitosamente!'),
          backgroundColor: EcoRutaColors.secondary,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _StatBubble extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  final IconData icon;

  const _StatBubble(
      {required this.count,
      required this.label,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: color.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  final String title;
  final Color color;

  const _GroupHeader({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}

class _FincaSyncTile extends StatelessWidget {
  final Finca finca;
  final int index;

  const _FincaSyncTile({required this.finca, required this.index});

  @override
  Widget build(BuildContext context) {
    final isError = finca.syncStatus == SyncStatus.error;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isError
                ? EcoRutaColors.errorContainer
                : EcoRutaColors.tertiaryFixed,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isError ? Icons.error_outline_rounded : Icons.agriculture_rounded,
            color: isError ? EcoRutaColors.error : EcoRutaColors.tertiary,
            size: 20,
          ),
        ),
        title: Text(finca.nombre,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${finca.propietario} • ${finca.municipioNombre}'),
        trailing: SyncStatusChip(status: finca.syncStatus),
      ),
    );
  }
}

class _VisitaSyncTile extends StatelessWidget {
  final Visita visita;
  final List<Finca> fincas;
  final int index;

  const _VisitaSyncTile(
      {required this.visita, required this.fincas, required this.index});

  @override
  Widget build(BuildContext context) {
    final finca = fincas.firstWhere(
      (f) => f.id == visita.fincaId,
      orElse: () => const Finca(
          nombre: 'Desconocida',
          propietario: '',
          vereda: '',
          hectareas: 0,
          variedadCafe: '',
          municipioId: 1),
    );
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: EcoRutaColors.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.analytics_rounded,
              color: EcoRutaColors.onPrimaryContainer, size: 20),
        ),
        title: Text('Visita: ${finca.nombre}',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
            '${visita.tecnicoNombre} • ${_fmt(visita.fecha)}'),
        trailing: SyncStatusChip(status: visita.syncStatus),
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _EmptyQueue extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_done_rounded,
              size: 72, color: EcoRutaColors.secondary),
          const SizedBox(height: 16),
          Text(
            'Todo sincronizado',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: EcoRutaColors.secondary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'No hay registros pendientes de sincronización.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: EcoRutaColors.onSurfaceVariant,
                ),
          ),
        ],
      ).animate().scale(begin: const Offset(0.8, 0.8)).fadeIn(),
    );
  }
}
