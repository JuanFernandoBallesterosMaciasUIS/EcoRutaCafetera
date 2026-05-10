import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/providers.dart';
import '../widgets/widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final isOnline = ref.watch(connectivityProvider);
    final pendingCount = ref.watch(pendingSyncCountProvider);
    final fincas = ref.watch(fincasProvider);
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 900;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/'));
      return const SizedBox.shrink();
    }

    if (isWide) {
      return _WideHomeLayout(
        user: user,
        isOnline: isOnline,
        pendingCount: pendingCount,
        fincas: fincas,
      );
    }

    return _MobileHomeLayout(
      user: user,
      isOnline: isOnline,
      pendingCount: pendingCount,
      fincas: fincas,
    );
  }
}

// ─── Mobile Layout ──────────────────────────────────────────────────────────

class _MobileHomeLayout extends ConsumerStatefulWidget {
  final AppUser user;
  final bool isOnline;
  final int pendingCount;
  final List<Finca> fincas;

  const _MobileHomeLayout({
    required this.user,
    required this.isOnline,
    required this.pendingCount,
    required this.fincas,
  });

  @override
  ConsumerState<_MobileHomeLayout> createState() => _MobileHomeLayoutState();
}

class _MobileHomeLayoutState extends ConsumerState<_MobileHomeLayout> {
  int _navIndex = 0;

  static const _destinations = [
    NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home_rounded),
        label: 'Inicio'),
    NavigationDestination(
        icon: Icon(Icons.agriculture_outlined),
        selectedIcon: Icon(Icons.agriculture_rounded),
        label: 'Fincas'),
    NavigationDestination(
        icon: Icon(Icons.map_outlined),
        selectedIcon: Icon(Icons.map_rounded),
        label: 'Mapa'),
    NavigationDestination(
        icon: Icon(Icons.grid_view_outlined),
        selectedIcon: Icon(Icons.grid_view_rounded),
        label: 'Más'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: IndexedStack(
        index: _navIndex,
        children: [
          _HomeTab(
              user: widget.user,
              isOnline: widget.isOnline,
              pendingCount: widget.pendingCount),
          _FincasTab(fincas: widget.fincas),
          const _MapTab(),
          _MoreTab(user: widget.user),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (i) => setState(() => _navIndex = i),
        destinations: _destinations,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: EcoRutaColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.eco_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Text(
            'EcoRuta',
            style: Theme.of(context).appBarTheme.titleTextStyle,
          ),
        ],
      ),
      actions: [
        // Connectivity toggle (for demo)
        Consumer(
          builder: (context, ref, _) {
            final isOnline = ref.watch(connectivityProvider);
            return IconButton(
              onPressed: () => ref.read(connectivityProvider.notifier).toggle(),
              icon: Icon(
                isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                color: isOnline ? EcoRutaColors.secondary : EcoRutaColors.error,
              ),
              tooltip: isOnline ? 'Conectado' : 'Sin conexión',
            );
          },
        ),
        IconButton(
          onPressed: () {
            _showSyncDialog(context);
          },
          icon: const Icon(Icons.sync_rounded),
          style: IconButton.styleFrom(
            foregroundColor: EcoRutaColors.primary,
          ),
        ),
      ],
    );
  }

  void _showSyncDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sincronizar datos'),
        content: Text(
          widget.isOnline
              ? 'Se sincronizarán ${widget.pendingCount} registros pendientes.'
              : 'No hay conexión disponible. Los datos se sincronizarán automáticamente cuando haya internet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          if (widget.isOnline)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Sincronización iniciada...'),
                    backgroundColor: EcoRutaColors.secondary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
              child: const Text('Sincronizar'),
            ),
        ],
      ),
    );
  }
}

// ─── Wide / Desktop Layout ─────────────────────────────────────────────────

class _WideHomeLayout extends ConsumerStatefulWidget {
  final AppUser user;
  final bool isOnline;
  final int pendingCount;
  final List<Finca> fincas;

  const _WideHomeLayout({
    required this.user,
    required this.isOnline,
    required this.pendingCount,
    required this.fincas,
  });

  @override
  ConsumerState<_WideHomeLayout> createState() => _WideHomeLayoutState();
}

class _WideHomeLayoutState extends ConsumerState<_WideHomeLayout> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Navigation Rail
          NavigationRail(
            selectedIndex: _navIndex,
            onDestinationSelected: (i) => setState(() => _navIndex = i),
            extended: true,
            minExtendedWidth: 220,
            backgroundColor: EcoRutaColors.surfaceContainerLow,
            leading: Column(
              children: [
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: EcoRutaColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.eco_rounded,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'EcoRuta',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: EcoRutaColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Consumer(
                  builder: (context, ref, _) {
                    final isOnline = ref.watch(connectivityProvider);
                    return ConnectivityBadge(isOnline: isOnline);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
            trailing: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  // Sync button
                  Consumer(builder: (context, ref, _) {
                    final isOnline = ref.watch(connectivityProvider);
                    return TextButton.icon(
                      onPressed: () =>
                          ref.read(connectivityProvider.notifier).toggle(),
                      icon: Icon(
                        isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                        color: isOnline
                            ? EcoRutaColors.secondary
                            : EcoRutaColors.error,
                      ),
                      label: Text(
                        isOnline ? 'Online' : 'Offline',
                        style: TextStyle(
                          color: isOnline
                              ? EcoRutaColors.secondary
                              : EcoRutaColors.error,
                        ),
                      ),
                    );
                  }),
                  OutlinedButton.icon(
                    onPressed: () {
                      ref.read(authProvider.notifier).logout();
                      context.go('/');
                    },
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Salir'),
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size(180, 40)),
                  ),
                ],
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: Text('Inicio'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.agriculture_outlined),
                selectedIcon: Icon(Icons.agriculture_rounded),
                label: Text('Fincas'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.map_outlined),
                selectedIcon: Icon(Icons.map_rounded),
                label: Text('Mapa'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.grid_view_outlined),
                selectedIcon: Icon(Icons.grid_view_rounded),
                label: Text('Más'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),

          // Main content
          Expanded(
            child: IndexedStack(
              index: _navIndex,
              children: [
                _HomeTab(
                    user: widget.user,
                    isOnline: widget.isOnline,
                    pendingCount: widget.pendingCount),
                _FincasTab(fincas: widget.fincas),
                const _MapTab(),
                _MoreTab(user: widget.user),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Home Tab ────────────────────────────────────────────────────────────────

class _HomeTab extends ConsumerWidget {
  final AppUser user;
  final bool isOnline;
  final int pendingCount;

  const _HomeTab({
    required this.user,
    required this.isOnline,
    required this.pendingCount,
  });

  String get _municipioNombre => Municipio.municipiosPiloto
      .firstWhere((m) => m.id == (user.municipioAsignado ?? 0),
          orElse: () => const Municipio(
              id: 0, nombre: 'Sin asignar', departamento: '', codigoDane: ''))
      .nombre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fincas = ref.watch(fincasProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile section
            _ProfileCard(user: user, municipio: _municipioNombre)
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: -0.05),

            const SizedBox(height: 24),

            // Stats row
            Row(
              children: [
                Expanded(
                  child: StatsCard(
                    value: fincas.length.toString(),
                    label: 'Fincas registradas',
                    icon: Icons.agriculture_rounded,
                    color: EcoRutaColors.primary,
                  ).animate().fadeIn(delay: 100.ms),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatsCard(
                    value: pendingCount.toString(),
                    label: 'Pendientes sync',
                    icon: Icons.cloud_upload_rounded,
                    color: pendingCount > 0
                        ? EcoRutaColors.tertiary
                        : EcoRutaColors.secondary,
                  ).animate().fadeIn(delay: 150.ms),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatsCard(
                    value: fincas
                        .where((f) => f.syncStatus == SyncStatus.subido)
                        .length
                        .toString(),
                    label: 'Sincronizadas',
                    icon: Icons.cloud_done_rounded,
                    color: EcoRutaColors.secondary,
                  ).animate().fadeIn(delay: 200.ms),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Pending sync card
            if (pendingCount > 0)
              _PendingSyncCard(count: pendingCount, isOnline: isOnline)
                  .animate()
                  .fadeIn(delay: 250.ms),

            if (pendingCount > 0) const SizedBox(height: 24),

            // Quick actions
            const SectionHeader(title: 'Acciones rápidas'),
            const SizedBox(height: 16),

            QuickActionButton(
              icon: Icons.add_home_rounded,
              title: 'Registrar Finca',
              subtitle: 'Dar de alta un nuevo predio',
              onTap: () => context.go('/finca/nueva'),
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 12),

            QuickActionButton(
              isPrimary: true,
              icon: Icons.route_rounded,
              title: 'Iniciar Ruta GPS',
              subtitle: 'Trazar recorrido de campo',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Módulo GPS en desarrollo (Sprint 4)'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
            ).animate().fadeIn(delay: 350.ms),

            const SizedBox(height: 12),

            QuickActionButton(
              icon: Icons.analytics_rounded,
              title: 'Capturar Indicadores',
              subtitle: 'Formularios de sostenibilidad',
              iconBgColor: EcoRutaColors.tertiaryContainer,
              iconColor: EcoRutaColors.onTertiaryContainer,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Selecciona primero una finca'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
            ).animate().fadeIn(delay: 400.ms),

            const SizedBox(height: 32),

            // Recent fincas
            SectionHeader(
              title: 'Fincas recientes',
              actionLabel: 'Ver todas',
              onAction: () {},
            ),
            const SizedBox(height: 16),

            ...fincas.take(3).map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FincaCard(
                      finca: f, onTap: () => context.go('/finca/${f.id}')),
                )),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─── Fincas Tab ─────────────────────────────────────────────────────────────

class _FincasTab extends ConsumerStatefulWidget {
  final List<Finca> fincas;

  const _FincasTab({required this.fincas});

  @override
  ConsumerState<_FincasTab> createState() => _FincasTabState();
}

class _FincasTabState extends ConsumerState<_FincasTab> {
  String _searchQuery = '';
  int? _selectedMunicipio;

  @override
  Widget build(BuildContext context) {
    final fincas = ref.watch(fincasProvider);
    final filtered = fincas.where((f) {
      final matchesSearch =
          f.nombre.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              f.propietario.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesMunicipio =
          _selectedMunicipio == null || f.municipioId == _selectedMunicipio;
      return matchesSearch && matchesMunicipio;
    }).toList();

    return Column(
      children: [
        // Search & filter bar
        Container(
          color: EcoRutaColors.surface,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            children: [
              TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: const InputDecoration(
                  hintText: 'Buscar finca o propietario...',
                  prefixIcon: Icon(Icons.search_rounded),
                  filled: true,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'Todos',
                      isSelected: _selectedMunicipio == null,
                      onTap: () => setState(() => _selectedMunicipio = null),
                    ),
                    ...Municipio.municipiosPiloto.map((m) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _FilterChip(
                            label: m.nombre,
                            isSelected: _selectedMunicipio == m.id,
                            onTap: () => setState(() => _selectedMunicipio =
                                _selectedMunicipio == m.id ? null : m.id),
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Fincas list
        Expanded(
          child: filtered.isEmpty
              ? _EmptyState(
                  icon: Icons.agriculture_outlined,
                  title: 'Sin resultados',
                  subtitle: 'No se encontraron fincas con ese criterio',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => FincaCard(
                    finca: filtered[i],
                    onTap: () => context.go('/finca/${filtered[i].id}'),
                  ),
                ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? EcoRutaColors.primary
              : EcoRutaColors.surfaceContainer,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color:
                    isSelected ? Colors.white : EcoRutaColors.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
        ),
      ),
    );
  }
}

// ─── Map Tab ─────────────────────────────────────────────────────────────────

class _MapTab extends StatelessWidget {
  const _MapTab();

  @override
  Widget build(BuildContext context) {
    return _EmptyState(
      icon: Icons.map_outlined,
      title: 'Mapa Territorial',
      subtitle: 'Módulo GPS y cartografía en desarrollo (Sprint 4)',
      action: ElevatedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.construction_rounded),
        label: const Text('En desarrollo'),
      ),
    );
  }
}

// ─── More Tab ────────────────────────────────────────────────────────────────

class _MoreTab extends ConsumerWidget {
  final AppUser user;

  const _MoreTab({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configuración',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: EcoRutaColors.primary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 20),
          _SettingsTile(
            icon: Icons.person_outline_rounded,
            title: 'Perfil',
            subtitle: user.email,
          ),
          _SettingsTile(
            icon: Icons.sync_rounded,
            title: 'Sincronización',
            subtitle: 'Gestionar cola de sincronización',
          ),
          _SettingsTile(
            icon: Icons.security_rounded,
            title: 'Seguridad',
            subtitle: 'TLS 1.3 • AES-256',
          ),
          _SettingsTile(
            icon: Icons.gavel_rounded,
            title: 'Privacidad',
            subtitle: 'Ley 1581/2012 - Habeas Data',
          ),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            title: 'Acerca de',
            subtitle: 'EcoRuta Cafetera v2.4.0 • UIS',
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                ref.read(authProvider.notifier).logout();
                context.go('/');
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Cerrar sesión'),
              style: OutlinedButton.styleFrom(
                foregroundColor: EcoRutaColors.error,
                side: const BorderSide(color: EcoRutaColors.error),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: EcoRutaColors.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: EcoRutaColors.onPrimaryContainer, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded,
            color: EcoRutaColors.outline),
        onTap: () {},
      ),
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final AppUser user;
  final String municipio;

  const _ProfileCard({required this.user, required this.municipio});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: EcoRutaColors.primaryContainer,
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: EcoRutaColors.primaryFixed, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      user.nombre.split(' ').map((n) => n[0]).take(2).join(),
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: EcoRutaColors.onPrimaryContainer,
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: EcoRutaColors.secondary,
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: EcoRutaColors.surface, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hola,',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: EcoRutaColors.onSurfaceVariant,
                        ),
                  ),
                  Text(
                    user.nombre,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: EcoRutaColors.primary,
                        ),
                  ),
                  Text(
                    user.rol.displayName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: EcoRutaColors.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          size: 14, color: EcoRutaColors.primary),
                      const SizedBox(width: 2),
                      Text(
                        'Municipio: $municipio',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: EcoRutaColors.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingSyncCard extends StatelessWidget {
  final int count;
  final bool isOnline;

  const _PendingSyncCard({required this.count, required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EcoRutaColors.tertiaryFixed,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: EcoRutaColors.tertiaryFixedDim.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: EcoRutaColors.tertiaryContainer.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cloud_sync_rounded,
                color: EcoRutaColors.tertiary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pendientes Sync',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: EcoRutaColors.onTertiaryFixed,
                      ),
                ),
                Text(
                  '$count registros por sincronizar',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: EcoRutaColors.onTertiaryFixed.withOpacity(0.9),
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.arrow_forward_rounded,
                color: EcoRutaColors.tertiary),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 72, color: EcoRutaColors.outlineVariant),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: EcoRutaColors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: EcoRutaColors.onSurfaceVariant,
                ),
          ),
          if (action != null) ...[
            const SizedBox(height: 24),
            action!,
          ],
        ],
      ),
    );
  }
}
