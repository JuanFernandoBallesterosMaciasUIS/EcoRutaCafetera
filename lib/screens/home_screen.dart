import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/providers.dart';
import '../widgets/widgets.dart';
import 'gps_route_screen.dart';
import 'mapa_fincas_screen.dart';

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
            pendingCount: widget.pendingCount,
            onSwitchToFincas: () => setState(() => _navIndex = 1),
            onSwitchToMap: () => setState(() => _navIndex = 2),
          ),
          const _FincasTab(),
          _MapTab(user: widget.user),
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
          Text('EcoRuta', style: Theme.of(context).appBarTheme.titleTextStyle),
        ],
      ),
      actions: [
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
          onPressed: () => context.go('/pendientes'),
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.sync_rounded),
              if (widget.pendingCount > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      color: EcoRutaColors.tertiary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${widget.pendingCount > 9 ? '9+' : widget.pendingCount}',
                        style: const TextStyle(
                            fontSize: 8,
                            color: Colors.white,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          style: IconButton.styleFrom(foregroundColor: EcoRutaColors.primary),
        ),
      ],
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
          Expanded(
            child: IndexedStack(
              index: _navIndex,
              children: [
                _HomeTab(
                  user: widget.user,
                  isOnline: widget.isOnline,
                  pendingCount: widget.pendingCount,
                  onSwitchToFincas: () => setState(() => _navIndex = 1),
                  onSwitchToMap: () => setState(() => _navIndex = 2),
                ),
                const _FincasTab(),
                _MapTab(user: widget.user),
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
  final VoidCallback onSwitchToFincas;
  final VoidCallback onSwitchToMap;

  const _HomeTab({
    required this.user,
    required this.isOnline,
    required this.pendingCount,
    required this.onSwitchToFincas,
    required this.onSwitchToMap,
  });

  String get _municipioNombre => Municipio.municipiosPiloto
      .firstWhere((m) => m.id == (user.municipioAsignado ?? 0),
          orElse: () => const Municipio(
              id: 0, nombre: 'Sin asignar', departamento: '', codigoDane: ''))
      .nombre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fincas = ref.watch(fincasProvider);
    final isAdmin = user.rol == UserRole.administrador;
    final isTecnico = user.rol == UserRole.tecnicoCampo;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
              _PendingSyncCard(
                count: pendingCount,
                isOnline: isOnline,
                onTap: () => context.go('/pendientes'),
              ).animate().fadeIn(delay: 250.ms),

            if (pendingCount > 0) const SizedBox(height: 24),

            // Quick actions — role-aware
            const SectionHeader(title: 'Acciones rápidas'),
            const SizedBox(height: 16),

            if (isTecnico || user.rol == UserRole.consultor) ...[
              QuickActionButton(
                icon: Icons.add_home_rounded,
                title: 'Registrar Finca',
                subtitle: 'Dar de alta un nuevo predio',
                onTap: user.rol == UserRole.consultor
                    ? null
                    : () => context.go('/finca/nueva'),
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 12),
              QuickActionButton(
                isPrimary: true,
                icon: Icons.route_rounded,
                title: 'Iniciar Ruta GPS',
                subtitle: 'Trazar recorrido de campo',
                onTap: onSwitchToMap,
              ).animate().fadeIn(delay: 350.ms),
              const SizedBox(height: 12),
              QuickActionButton(
                icon: Icons.analytics_rounded,
                title: 'Capturar Indicadores',
                subtitle: 'Selecciona una finca para registrar visita',
                iconBgColor: EcoRutaColors.tertiaryContainer,
                iconColor: EcoRutaColors.onTertiaryContainer,
                onTap: onSwitchToFincas,
              ).animate().fadeIn(delay: 400.ms),
            ],

            if (isAdmin) ...[
              QuickActionButton(
                isPrimary: true,
                icon: Icons.map_rounded,
                title: 'Mapa territorial',
                subtitle: 'Ver todas las fincas geolocalizadas',
                onTap: onSwitchToMap,
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 12),
              QuickActionButton(
                icon: Icons.add_home_rounded,
                title: 'Registrar Finca',
                subtitle: 'Dar de alta un nuevo predio',
                onTap: () => context.go('/finca/nueva'),
              ).animate().fadeIn(delay: 350.ms),
              const SizedBox(height: 12),
              QuickActionButton(
                icon: Icons.assessment_rounded,
                title: 'Generar Reporte',
                subtitle: 'PDF / Excel por municipio',
                iconBgColor: EcoRutaColors.tertiaryContainer,
                iconColor: EcoRutaColors.onTertiaryContainer,
                onTap: () => context.go('/reportes'),
              ).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 12),
              QuickActionButton(
                icon: Icons.manage_accounts_rounded,
                title: 'Gestión de usuarios',
                subtitle: 'Crear, activar y desactivar cuentas',
                iconBgColor: EcoRutaColors.secondaryContainer,
                iconColor: EcoRutaColors.onSecondaryContainer,
                onTap: () => context.go('/usuarios'),
              ).animate().fadeIn(delay: 450.ms),
            ],

            const SizedBox(height: 32),

            // Recent fincas
            SectionHeader(
              title: 'Fincas recientes',
              actionLabel: 'Ver todas',
              onAction: onSwitchToFincas,
            ),
            const SizedBox(height: 16),

            ...(fincas.toList()
                  ..sort((a, b) => (b.fechaRegistro ?? DateTime(1970))
                      .compareTo(a.fechaRegistro ?? DateTime(1970))))
                .take(3)
                .map((f) => Padding(
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
  const _FincasTab();

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
    }).toList()
      ..sort((a, b) => (b.fechaRegistro ?? DateTime(1970))
          .compareTo(a.fechaRegistro ?? DateTime(1970)));

    return Column(
      children: [
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
        Expanded(
          child: filtered.isEmpty
              ? _EmptyState(
                  icon: Icons.agriculture_outlined,
                  title: 'Sin resultados',
                  subtitle: 'No se encontraron fincas con ese criterio',
                  action: ElevatedButton.icon(
                    onPressed: () => context.go('/finca/nueva'),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Registrar finca'),
                  ),
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

// ─── Map Tab (role-aware) ─────────────────────────────────────────────────────

class _MapTab extends ConsumerWidget {
  final AppUser user;

  const _MapTab({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (user.rol == UserRole.administrador) {
      return const MapaFincasScreen(embedded: true);
    }
    return const GpsRouteTab();
  }
}

// ─── More Tab ────────────────────────────────────────────────────────────────

class _MoreTab extends ConsumerWidget {
  final AppUser user;

  const _MoreTab({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = user.rol == UserRole.administrador;

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
          const SizedBox(height: 8),

          // User role badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _roleColor(user.rol).withOpacity(0.1),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: _roleColor(user.rol).withOpacity(0.4)),
            ),
            child: Text(
              user.rol.displayName,
              style: TextStyle(
                color: _roleColor(user.rol),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Admin-only section
          if (isAdmin) ...[
            Text(
              'Administración',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: EcoRutaColors.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
            ),
            const SizedBox(height: 8),
            _SettingsTile(
              icon: Icons.manage_accounts_rounded,
              title: 'Gestión de usuarios',
              subtitle: 'Crear, editar y desactivar cuentas',
              onTap: () => context.go('/usuarios'),
            ),
            _SettingsTile(
              icon: Icons.assessment_rounded,
              title: 'Reportes',
              subtitle: 'Generar PDF / Excel por municipio',
              onTap: () => context.go('/reportes'),
            ),
            _SettingsTile(
              icon: Icons.map_rounded,
              title: 'Mapa territorial',
              subtitle: 'Ver fincas geolocalizadas',
              onTap: () => context.go('/mapa-fincas'),
            ),
            const SizedBox(height: 16),
          ],

          // Sync section
          Text(
            'Sincronización',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: EcoRutaColors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
          ),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.sync_rounded,
            title: 'Cola de sincronización',
            subtitle: 'Ver registros pendientes de subir',
            onTap: () => context.go('/pendientes'),
          ),

          const SizedBox(height: 16),

          Text(
            'Cuenta',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: EcoRutaColors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
          ),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.person_outline_rounded,
            title: 'Perfil',
            subtitle: user.email,
          ),
          _SettingsTile(
            icon: Icons.security_rounded,
            title: 'Seguridad',
            subtitle: 'TLS 1.3 • AES-256',
          ),
          _SettingsTile(
            icon: Icons.gavel_rounded,
            title: 'Privacidad',
            subtitle: 'Ley 1581/2012 — Habeas Data',
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

  Color _roleColor(UserRole r) => switch (r) {
        UserRole.administrador => EcoRutaColors.primary,
        UserRole.tecnicoCampo => EcoRutaColors.secondary,
        UserRole.consultor => EcoRutaColors.tertiary,
      };
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
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
        trailing: onTap != null
            ? const Icon(Icons.chevron_right_rounded,
                color: EcoRutaColors.outline)
            : null,
        onTap: onTap,
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
                  Text('Hola,',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: EcoRutaColors.onSurfaceVariant)),
                  Text(
                    user.nombre,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(color: EcoRutaColors.primary),
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
  final VoidCallback onTap;

  const _PendingSyncCard({
    required this.count,
    required this.isOnline,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: EcoRutaColors.tertiaryFixed,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: EcoRutaColors.tertiaryFixedDim.withOpacity(0.5)),
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
                    '$count registros por sincronizar — toca para gestionar',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: EcoRutaColors.onTertiaryFixed.withOpacity(0.9),
                        ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded,
                color: EcoRutaColors.tertiary),
          ],
        ),
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
