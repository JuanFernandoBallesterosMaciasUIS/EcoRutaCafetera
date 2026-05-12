import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/location_service.dart';
import '../services/providers.dart';
import '../widgets/widgets.dart';

class MapaFincasScreen extends ConsumerStatefulWidget {
  final bool embedded;

  const MapaFincasScreen({super.key, this.embedded = false});

  @override
  ConsumerState<MapaFincasScreen> createState() => _MapaFincasScreenState();
}

class _MapaFincasScreenState extends ConsumerState<MapaFincasScreen> {
  final _mapController = MapController();
  int? _selectedMunicipio;
  Finca? _selectedFinca;
  LatLng? _myLocation;
  bool _loadingLocation = false;

  // Centro del cordón cafetero de Santander (Barbosa / Vélez)
  static const _center = LatLng(6.1900, -73.6100);

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _goToMyLocation() async {
    setState(() => _loadingLocation = true);
    final loc = await LocationService.getCurrentLocation();
    if (!mounted) return;
    setState(() {
      _loadingLocation = false;
      _myLocation = loc;
    });
    if (loc != null) {
      _mapController.move(loc, 15);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo obtener la ubicación. Verifica los permisos.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fincas = ref.watch(fincasProvider);
    final filtered = _selectedMunicipio == null
        ? fincas
        : fincas.where((f) => f.municipioId == _selectedMunicipio).toList();

    final withCoords = filtered.where((f) => f.latitud != null).toList();

    return Scaffold(
      appBar: AppBar(
        leading: widget.embedded
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => context.go('/home'),
              ),
        title: const Text('Mapa territorial de fincas'),
        actions: [
          IconButton(
            icon: _loadingLocation
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    _myLocation != null
                        ? Icons.my_location_rounded
                        : Icons.location_searching_rounded,
                  ),
            tooltip: 'Mi ubicación',
            onPressed: _loadingLocation ? null : _goToMyLocation,
          ),
          IconButton(
            icon: const Icon(Icons.center_focus_strong_rounded),
            tooltip: 'Centrar región',
            onPressed: () {
              _mapController.move(_center, 13);
              setState(() => _selectedFinca = null);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            color: EcoRutaColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _ChipFilter(
                    label: 'Todos (${fincas.length})',
                    isSelected: _selectedMunicipio == null,
                    onTap: () => setState(() => _selectedMunicipio = null),
                  ),
                  ...Municipio.municipiosPiloto.map((m) {
                    final count =
                        fincas.where((f) => f.municipioId == m.id).length;
                    if (count == 0) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _ChipFilter(
                        label: '${m.nombre} ($count)',
                        isSelected: _selectedMunicipio == m.id,
                        onTap: () => setState(() => _selectedMunicipio =
                            _selectedMunicipio == m.id ? null : m.id),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Map
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _center,
                    initialZoom: 12.5,
                    onTap: (_, __) => setState(() => _selectedFinca = null),
                  ),
                  children: [
                    // OpenStreetMap tiles
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.ecoruta.cafetera',
                      maxZoom: 19,
                    ),

                    // User location marker
                    if (_myLocation != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _myLocation!,
                            width: 48,
                            height: 48,
                            child: _MyLocationMarker(),
                          ),
                        ],
                      ),

                    // Farm markers
                    MarkerLayer(
                      markers: withCoords.map((f) {
                        final isSelected = _selectedFinca?.id == f.id;
                        return Marker(
                          point: LatLng(f.latitud!, f.longitud!),
                          width: isSelected ? 52 : 40,
                          height: isSelected ? 52 : 40,
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _selectedFinca = f);
                              _mapController.move(
                                LatLng(f.latitud!, f.longitud!),
                                15,
                              );
                            },
                            child: _FarmMarkerWidget(
                              syncStatus: f.syncStatus,
                              isSelected: isSelected,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),

                // Legend top-right
                Positioned(
                  top: 12,
                  right: 12,
                  child: _MapLegend(),
                ),

                // Stats bottom-left
                Positioned(
                  bottom: _selectedFinca != null ? 180 : 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                        )
                      ],
                    ),
                    child: Text(
                      '${withCoords.length} finca${withCoords.length != 1 ? 's' : ''} en mapa',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: EcoRutaColors.primary,
                      ),
                    ),
                  ).animate().fadeIn(delay: 400.ms),
                ),

                // OSM attribution
                Positioned(
                  bottom: _selectedFinca != null ? 180 : 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '© OpenStreetMap',
                      style: TextStyle(fontSize: 9, color: Colors.black54),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Selected finca card
          if (_selectedFinca != null)
            _SelectedFincaCard(
              finca: _selectedFinca!,
              onClose: () => setState(() => _selectedFinca = null),
              onViewDetail: () =>
                  context.go('/finca/${_selectedFinca!.id}'),
            ).animate().slideY(begin: 1, end: 0, duration: 250.ms),
        ],
      ),
    );
  }
}

// ─── My Location Marker ───────────────────────────────────────────────────────

class _MyLocationMarker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.4),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Farm Marker Widget ───────────────────────────────────────────────────────

class _FarmMarkerWidget extends StatelessWidget {
  final SyncStatus syncStatus;
  final bool isSelected;

  const _FarmMarkerWidget(
      {required this.syncStatus, required this.isSelected});

  Color get _color => switch (syncStatus) {
        SyncStatus.subido => EcoRutaColors.secondary,
        SyncStatus.pendiente => EcoRutaColors.tertiary,
        SyncStatus.subiendo => EcoRutaColors.primary,
        SyncStatus.error => EcoRutaColors.error,
      };

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isSelected ? 44 : 32,
          height: isSelected ? 44 : 32,
          decoration: BoxDecoration(
            color: _color,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: isSelected ? 3 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: _color.withValues(alpha: isSelected ? 0.5 : 0.3),
                blurRadius: isSelected ? 12 : 6,
                spreadRadius: isSelected ? 3 : 0,
              ),
            ],
          ),
          child: Icon(
            Icons.agriculture_rounded,
            color: Colors.white,
            size: isSelected ? 22 : 16,
          ),
        ),
        Container(
          width: 2,
          height: 6,
          color: _color,
        ),
      ],
    );
  }
}

// ─── Legend ───────────────────────────────────────────────────────────────────

class _MapLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Estado',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const _LegendItem(
              color: EcoRutaColors.secondary, label: 'Sincronizado'),
          const _LegendItem(
              color: EcoRutaColors.tertiary, label: 'Pendiente'),
          const _LegendItem(color: EcoRutaColors.error, label: 'Error'),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms);
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: EcoRutaColors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

// ─── Selected Finca Card ──────────────────────────────────────────────────────

class _SelectedFincaCard extends StatelessWidget {
  final Finca finca;
  final VoidCallback onClose;
  final VoidCallback onViewDetail;

  const _SelectedFincaCard({
    required this.finca,
    required this.onClose,
    required this.onViewDetail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: EcoRutaColors.surface,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, -2))
        ],
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: EcoRutaColors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.agriculture_rounded,
                    color: EcoRutaColors.onPrimaryContainer, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      finca.nombre,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                            color: EcoRutaColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Text(
                      '${finca.propietario} • ${finca.municipioNombre}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                              color: EcoRutaColors.onSurfaceVariant),
                    ),
                    if (finca.latitud != null)
                      Text(
                        '${finca.latitud!.toStringAsFixed(5)}°N, '
                        '${finca.longitud!.toStringAsFixed(5)}°O',
                        style: const TextStyle(
                            fontSize: 10,
                            color: EcoRutaColors.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _InfoPill(
                  icon: Icons.landscape_rounded,
                  label: '${finca.hectareas} ha'),
              const SizedBox(width: 8),
              _InfoPill(
                  icon: Icons.eco_rounded, label: finca.variedadCafe),
              const SizedBox(width: 8),
              SyncStatusChip(status: finca.syncStatus),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onViewDetail,
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: const Text('Ver detalle completo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: EcoRutaColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: EcoRutaColors.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: EcoRutaColors.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: EcoRutaColors.onSurfaceVariant,
                  )),
        ],
      ),
    );
  }
}

// ─── Filter Chip ──────────────────────────────────────────────────────────────

class _ChipFilter extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ChipFilter(
      {required this.label,
      required this.isSelected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? EcoRutaColors.primary
              : EcoRutaColors.surfaceContainer,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isSelected
                    ? Colors.white
                    : EcoRutaColors.onSurfaceVariant,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
        ),
      ),
    );
  }
}
