import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../models/models.dart';
import '../services/location_service.dart';
import '../services/providers.dart';
import '../services/routing_service.dart';
import '../theme/app_theme.dart';

// ─── Estado de tracking GPS ───────────────────────────────────────────────────

enum GpsTrackingStatus { idle, recording, paused }

class GpsRouteData {
  final GpsTrackingStatus status;
  final int elapsedSeconds;
  final int gpsPoints;
  final double distanceMeters;
  final List<LatLng> routePoints;
  final RutaVisita? selectedRoute;
  final List<LatLng> plannedPoints;
  final List<LatLng> fincaWaypoints;
  final double plannedDistanceMeters;   // distancia total ruta planificada (OSRM)
  final LatLng? userLocation;

  const GpsRouteData({
    this.status = GpsTrackingStatus.idle,
    this.elapsedSeconds = 0,
    this.gpsPoints = 0,
    this.distanceMeters = 0.0,
    this.routePoints = const [],
    this.selectedRoute,
    this.plannedPoints = const [],
    this.fincaWaypoints = const [],
    this.plannedDistanceMeters = 0.0,
    this.userLocation,
  });

  GpsRouteData copyWith({
    GpsTrackingStatus? status,
    int? elapsedSeconds,
    int? gpsPoints,
    double? distanceMeters,
    List<LatLng>? routePoints,
    RutaVisita? selectedRoute,
    List<LatLng>? plannedPoints,
    List<LatLng>? fincaWaypoints,
    double? plannedDistanceMeters,
    LatLng? userLocation,
    bool clearRoute = false,
  }) =>
      GpsRouteData(
        status: status ?? this.status,
        elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
        gpsPoints: gpsPoints ?? this.gpsPoints,
        distanceMeters: distanceMeters ?? this.distanceMeters,
        routePoints: routePoints ?? this.routePoints,
        selectedRoute: clearRoute ? null : (selectedRoute ?? this.selectedRoute),
        plannedPoints: clearRoute ? const [] : (plannedPoints ?? this.plannedPoints),
        fincaWaypoints: clearRoute ? const [] : (fincaWaypoints ?? this.fincaWaypoints),
        plannedDistanceMeters: clearRoute ? 0.0 : (plannedDistanceMeters ?? this.plannedDistanceMeters),
        userLocation: clearRoute ? null : (userLocation ?? this.userLocation),
      );

  String get formattedTime {
    final h = elapsedSeconds ~/ 3600;
    final m = (elapsedSeconds % 3600) ~/ 60;
    final s = elapsedSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }

  // Cuando idle muestra distancia planificada; cuando graba muestra recorrida
  String get formattedDistance {
    final d = status == GpsTrackingStatus.idle ? plannedDistanceMeters : distanceMeters;
    if (d >= 1000) return '${(d / 1000).toStringAsFixed(2)} km';
    return '${d.toStringAsFixed(0)} m';
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class GpsRouteNotifier extends StateNotifier<GpsRouteData> {
  GpsRouteNotifier() : super(const GpsRouteData());

  Timer? _timer;
  final _rng = math.Random();

  void selectRoute(
    RutaVisita route,
    List<LatLng> plannedPoints,
    List<LatLng> fincaWaypoints,
    LatLng userLocation,
    double plannedDistanceMeters,
  ) {
    _timer?.cancel();
    _timer = null;
    state = GpsRouteData(
      selectedRoute: route,
      plannedPoints: plannedPoints,
      fincaWaypoints: fincaWaypoints,
      plannedDistanceMeters: plannedDistanceMeters,
      userLocation: userLocation,
      routePoints: [userLocation],
    );
  }

  void clearRoute() {
    _timer?.cancel();
    _timer = null;
    state = const GpsRouteData();
  }

  void start() {
    if (state.selectedRoute == null) return;
    state = state.copyWith(status: GpsTrackingStatus.recording);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void pause() {
    _timer?.cancel();
    _timer = null;
    state = state.copyWith(status: GpsTrackingStatus.paused);
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    state = GpsRouteData(
      selectedRoute: state.selectedRoute,
      plannedPoints: state.plannedPoints,
      fincaWaypoints: state.fincaWaypoints,
      userLocation: state.userLocation,
      routePoints: state.userLocation != null ? [state.userLocation!] : const [],
    );
  }

  void _tick() {
    final elapsed = state.elapsedSeconds + 1;
    final distance = state.distanceMeters + 3.5 + _rng.nextDouble() * 2;
    final points = elapsed % 5 == 0 ? state.gpsPoints + 1 : state.gpsPoints;

    // Añade punto GPS cada 8 segundos moviéndose hacia siguiente waypoint planificado
    List<LatLng> route = state.routePoints;
    if (elapsed % 8 == 0 && route.isNotEmpty && state.plannedPoints.length > 1) {
      final current = route.last;
      // Busca siguiente waypoint planificado no alcanzado
      LatLng? target;
      for (final p in state.plannedPoints) {
        final dlat = (p.latitude - current.latitude).abs();
        final dlng = (p.longitude - current.longitude).abs();
        if (dlat > 0.001 || dlng > 0.001) {
          target = p;
          break;
        }
      }
      if (target != null) {
        // Avanza 10% hacia el target + pequeño ruido
        final lat = current.latitude + (target.latitude - current.latitude) * 0.10
            + (_rng.nextDouble() - 0.5) * 0.0002;
        final lng = current.longitude + (target.longitude - current.longitude) * 0.10
            + (_rng.nextDouble() - 0.5) * 0.0002;
        route = [...route, LatLng(lat, lng)];
      }
    }

    state = state.copyWith(
      elapsedSeconds: elapsed,
      distanceMeters: distance,
      gpsPoints: points,
      routePoints: route,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final gpsRouteProvider =
    StateNotifierProvider.autoDispose<GpsRouteNotifier, GpsRouteData>(
  (_) => GpsRouteNotifier(),
);

// ─── Tab principal ────────────────────────────────────────────────────────────

class GpsRouteTab extends ConsumerStatefulWidget {
  const GpsRouteTab({super.key});

  @override
  ConsumerState<GpsRouteTab> createState() => _GpsRouteTabState();
}

class _GpsRouteTabState extends ConsumerState<GpsRouteTab> {
  final _mapController = MapController();
  bool _loadingRoute = false;

  static const _defaultCenter = LatLng(6.1900, -73.6050);
  static const _defaultZoom = 13.0;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _fitRoute(GpsRouteData data) {
    // Usa solo plannedPoints para el encuadre (ruta completa visible)
    final points = data.plannedPoints.isNotEmpty
        ? data.plannedPoints
        : data.routePoints;
    if (points.isEmpty) return;
    if (points.length == 1) {
      _mapController.move(points.first, 15.0);
      return;
    }
    _mapController.fitCamera(
      CameraFit.coordinates(
        coordinates: points,
        padding: const EdgeInsets.fromLTRB(40, 80, 40, 200),
      ),
    );
  }

  void _centerOnUser(GpsRouteData data) {
    final userLoc = data.userLocation;
    if (userLoc != null) {
      _mapController.move(userLoc, 15.5);
    }
  }

  void _centerOnContent(GpsRouteData data) => _fitRoute(data);

  Future<void> _showRoutePicker() async {
    final fincas = ref.read(fincasProvider);
    final notifier = ref.read(gpsRouteProvider.notifier);

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _RoutePickerSheet(
        fincas: fincas,
        onRouteSelected: (route) async {
          Navigator.of(context).pop();
          setState(() => _loadingRoute = true);

          // Obtiene ubicación real del usuario
          LatLng? userLoc = await LocationService.getCurrentLocation();

          // Fallback si GPS no disponible: centro de la región cafetera
          userLoc ??= const LatLng(6.1900, -73.6100);

          // Waypoints: user → finca1 → finca2 → ...
          final waypoints = <LatLng>[userLoc];
          for (final fincaId in route.fincaIds) {
            final finca = fincas.firstWhere(
              (f) => f.id == fincaId,
              orElse: () => fincas.first,
            );
            if (finca.latitud != null && finca.longitud != null) {
              waypoints.add(LatLng(finca.latitud!, finca.longitud!));
            }
          }

          // fincaWaypoints = solo posiciones fincas (sin user), para markers
          final fincaWaypoints = waypoints.skip(1).toList();

          // Intenta obtener ruta real por carretera vía OSRM
          final result = await RoutingService.getRoute(waypoints);

          // Fallback haversine si OSRM falla
          double fallbackDist = 0;
          for (int i = 0; i < waypoints.length - 1; i++) {
            fallbackDist += RoutingService.haversineMeters(waypoints[i], waypoints[i + 1]);
          }

          final plannedPoints = result?.points ?? waypoints;
          final plannedDist = result?.distanceMeters ?? fallbackDist;

          notifier.selectRoute(route, plannedPoints, fincaWaypoints, userLoc, plannedDist);

          if (mounted) {
            setState(() => _loadingRoute = false);
            // Centra mapa en la ruta
            await Future.delayed(const Duration(milliseconds: 200));
            if (mounted) _centerOnContent(ref.read(gpsRouteProvider));
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(gpsRouteProvider);
    final notifier = ref.read(gpsRouteProvider.notifier);
    final hasRoute = data.selectedRoute != null;

    return Stack(
      children: [
        // Mapa OpenStreetMap
        FlutterMap(
          mapController: _mapController,
          options: const MapOptions(
            initialCenter: _defaultCenter,
            initialZoom: _defaultZoom,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.ecoruta.cafetera',
              maxZoom: 19,
            ),

            // Ruta planificada (azul) — user → fincas
            if (data.plannedPoints.length >= 2)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: data.plannedPoints,
                    strokeWidth: 4,
                    color: const Color(0xFF1565C0).withValues(alpha: 0.75),
                  ),
                ],
              ),

            // Trayectoria grabada (verde)
            if (data.routePoints.length >= 2)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: data.routePoints,
                    strokeWidth: 4,
                    color: const Color(0xFF4CAF73),
                  ),
                ],
              ),

            // Markers de fincas — solo las fincas reales (2-4 puntos máx)
            if (hasRoute && data.fincaWaypoints.isNotEmpty)
              MarkerLayer(
                markers: [
                  for (int i = 0; i < data.fincaWaypoints.length; i++)
                    Marker(
                      point: data.fincaWaypoints[i],
                      width: 32,
                      height: 32,
                      child: _FincaWaypointMarker(index: i + 1),
                    ),
                ],
              ),

            // Markers: inicio (usuario) y posición actual
            if (data.routePoints.isNotEmpty)
              MarkerLayer(
                markers: [
                  // Ubicación de inicio (usuario)
                  Marker(
                    point: data.routePoints.first,
                    width: 30,
                    height: 30,
                    child: const _RouteMarker(
                      color: Color(0xFF1565C0),
                      icon: Icons.person_pin_circle_rounded,
                    ),
                  ),
                  // Posición actual grabada
                  if (data.routePoints.length > 1)
                    Marker(
                      point: data.routePoints.last,
                      width: 32,
                      height: 32,
                      child: _RouteMarker(
                        color: data.status == GpsTrackingStatus.recording
                            ? const Color(0xFF4CAF73)
                            : data.status == GpsTrackingStatus.paused
                                ? const Color(0xFFF57C00)
                                : EcoRutaColors.onSurfaceVariant,
                        icon: Icons.my_location_rounded,
                        pulsing: data.status == GpsTrackingStatus.recording,
                      ),
                    ),
                ],
              ),

            const SimpleAttributionWidget(
              source: Text('© OpenStreetMap',
                  style: TextStyle(fontSize: 10, color: Colors.black54)),
            ),
          ],
        ),

        // Botón "Elegir Ruta" — parte superior
        Positioned(
          top: 12,
          left: 16,
          right: 72,
          child: _RouteChip(
            selectedRoute: data.selectedRoute,
            loading: _loadingRoute,
            onTap: _showRoutePicker,
            onClear: hasRoute ? notifier.clearRoute : null,
          ).animate().fadeIn(duration: 300.ms),
        ),

        // Controles flotantes derecha
        _MapControlsColumn(
          onZoomIn: () => _mapController.move(
              _mapController.camera.center,
              _mapController.camera.zoom + 1),
          onZoomOut: () => _mapController.move(
              _mapController.camera.center,
              _mapController.camera.zoom - 1),
          onFitRoute: () => _fitRoute(data),
          onCenterUser: () => _centerOnUser(data),
        ),

        // Pantalla vacía cuando no hay ruta seleccionada
        if (!hasRoute && !_loadingRoute)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _EmptyRouteCard(onSelectRoute: _showRoutePicker)
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.1),
          ),

        // Card de estadísticas cuando hay ruta seleccionada
        if (hasRoute)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _StatsCard(
              data: data,
              notifier: notifier,
              onStart: () {
                notifier.start();
                _centerOnUser(data);
              },
            )
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.1),
          ),
      ],
    );
  }
}

// ─── Chip de ruta seleccionada ────────────────────────────────────────────────

class _RouteChip extends StatelessWidget {
  final RutaVisita? selectedRoute;
  final bool loading;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _RouteChip({
    required this.selectedRoute,
    required this.loading,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: EcoRutaColors.surface,
      borderRadius: BorderRadius.circular(24),
      elevation: 4,
      shadowColor: Colors.black26,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: loading ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              if (loading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  selectedRoute != null
                      ? Icons.route_rounded
                      : Icons.add_road_rounded,
                  size: 18,
                  color: selectedRoute != null
                      ? EcoRutaColors.primary
                      : EcoRutaColors.onSurfaceVariant,
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  loading
                      ? 'Obteniendo ubicación...'
                      : selectedRoute?.nombre ?? 'Seleccionar ruta',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selectedRoute != null
                        ? EcoRutaColors.primary
                        : EcoRutaColors.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onClear != null && !loading)
                GestureDetector(
                  onTap: onClear,
                  child: const Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: EcoRutaColors.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Card vacía sin ruta ──────────────────────────────────────────────────────

class _EmptyRouteCard extends StatelessWidget {
  final VoidCallback onSelectRoute;

  const _EmptyRouteCard({required this.onSelectRoute});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: EcoRutaColors.surface.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.route_rounded,
              size: 40, color: EcoRutaColors.primary.withValues(alpha: 0.7)),
          const SizedBox(height: 10),
          Text(
            'Ninguna ruta seleccionada',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: EcoRutaColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Elige una ruta para ver los puntos a visitar\ny comenzar el seguimiento GPS.',
            textAlign: TextAlign.center,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 12,
              color: EcoRutaColors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: onSelectRoute,
              icon: const Icon(Icons.add_road_rounded, size: 18),
              label: Text(
                'Elegir Ruta',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bottom sheet selector de rutas ──────────────────────────────────────────

class _RoutePickerSheet extends StatelessWidget {
  final List<Finca> fincas;
  final void Function(RutaVisita) onRouteSelected;

  const _RoutePickerSheet({
    required this.fincas,
    required this.onRouteSelected,
  });

  @override
  Widget build(BuildContext context) {
    final rutas = RutaVisita.rutasPredefinidas;

    return Container(
      decoration: const BoxDecoration(
        color: EcoRutaColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: EcoRutaColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Seleccionar Ruta',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: EcoRutaColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'La ruta inicia desde tu ubicación actual',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 12,
              color: EcoRutaColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          ...rutas.map((ruta) {
            final fincasEnRuta = fincas
                .where((f) => ruta.fincaIds.contains(f.id))
                .toList();
            return _RouteItem(
              ruta: ruta,
              fincasEnRuta: fincasEnRuta,
              onTap: () => onRouteSelected(ruta),
            );
          }),
        ],
      ),
    );
  }
}

class _RouteItem extends StatelessWidget {
  final RutaVisita ruta;
  final List<Finca> fincasEnRuta;
  final VoidCallback onTap;

  const _RouteItem({
    required this.ruta,
    required this.fincasEnRuta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: EcoRutaColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: EcoRutaColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.route_rounded,
                      color: EcoRutaColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ruta.nombre,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: EcoRutaColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ruta.descripcion,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 12,
                          color: EcoRutaColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.agriculture_rounded,
                              size: 13, color: EcoRutaColors.secondary),
                          const SizedBox(width: 4),
                          Text(
                            '${fincasEnRuta.length} finca${fincasEnRuta.length != 1 ? 's' : ''}',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: EcoRutaColors.secondary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.location_on_outlined,
                              size: 13, color: EcoRutaColors.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            'Inicia desde tu GPS',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 11,
                              color: EcoRutaColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: EcoRutaColors.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Marker numerado de finca waypoint ───────────────────────────────────────

class _FincaWaypointMarker extends StatelessWidget {
  final int index;

  const _FincaWaypointMarker({required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: EcoRutaColors.primary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: EcoRutaColors.primary.withValues(alpha: 0.4),
            blurRadius: 6,
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$index',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ─── Marcador genérico de ruta ────────────────────────────────────────────────

class _RouteMarker extends StatelessWidget {
  final Color color;
  final IconData icon;
  final bool pulsing;

  const _RouteMarker({
    required this.color,
    required this.icon,
    this.pulsing = false,
  });

  @override
  Widget build(BuildContext context) {
    final Widget marker = Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 8,
            spreadRadius: pulsing ? 3 : 0,
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 14),
    );

    if (pulsing) {
      return marker
          .animate(onPlay: (c) => c.repeat())
          .scaleXY(begin: 1.0, end: 1.2, duration: 700.ms)
          .then()
          .scaleXY(begin: 1.2, end: 1.0, duration: 700.ms);
    }
    return marker;
  }
}

// ─── Controles flotantes del mapa ─────────────────────────────────────────────

class _MapControlsColumn extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onFitRoute;
  final VoidCallback onCenterUser;

  const _MapControlsColumn({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onFitRoute,
    required this.onCenterUser,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      top: 0,
      bottom: 0,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MapBtn(icon: Icons.add_rounded, onTap: onZoomIn),
            const SizedBox(height: 8),
            _MapBtn(icon: Icons.remove_rounded, onTap: onZoomOut),
            const SizedBox(height: 8),
            _MapBtn(icon: Icons.my_location_rounded, onTap: onCenterUser),
            const SizedBox(height: 8),
            _MapBtn(icon: Icons.route_rounded, onTap: onFitRoute),
          ],
        ),
      ),
    );
  }
}

class _MapBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MapBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: EcoRutaColors.surface,
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: Colors.black38,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: EcoRutaColors.onSurfaceVariant, size: 22),
        ),
      ),
    );
  }
}

// ─── Tarjeta de estadísticas ──────────────────────────────────────────────────

class _StatsCard extends StatelessWidget {
  final GpsRouteData data;
  final GpsRouteNotifier notifier;
  final VoidCallback? onStart;

  const _StatsCard({required this.data, required this.notifier, this.onStart});

  @override
  Widget build(BuildContext context) {
    final isIdle = data.status == GpsTrackingStatus.idle;
    final isRecording = data.status == GpsTrackingStatus.recording;
    final isPaused = data.status == GpsTrackingStatus.paused;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: EcoRutaColors.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: EcoRutaColors.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Nombre de ruta + estado
          Row(
            children: [
              const Icon(Icons.route_rounded,
                  size: 15, color: EcoRutaColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  data.selectedRoute?.nombre ?? '',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: EcoRutaColors.primary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!isIdle)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isRecording
                            ? const Color(0xFF4CAF73)
                            : const Color(0xFFF57C00),
                      ),
                    )
                        .animate(
                            onPlay: (c) => c.repeat(),
                            target: isRecording ? 1 : 0)
                        .fadeIn(duration: 600.ms)
                        .then()
                        .fadeOut(duration: 600.ms),
                    const SizedBox(width: 6),
                    Text(
                      isRecording ? 'Grabando' : 'Pausado',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isRecording
                            ? const Color(0xFF2A6B2C)
                            : const Color(0xFFBF6000),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          const SizedBox(height: 10),

          // Leyenda de colores
          Row(
            children: [
              _LegendDot(color: const Color(0xFF1565C0), label: 'Ruta planificada'),
              const SizedBox(width: 14),
              _LegendDot(color: const Color(0xFF4CAF73), label: 'Trayectoria GPS'),
            ],
          ),

          const SizedBox(height: 10),

          // Estadísticas
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _StatCell(
                    label: 'Distancia',
                    value: data.formattedDistance,
                    icon: Icons.straighten_rounded,
                  ),
                ),
                VerticalDivider(
                  width: 1,
                  color: EcoRutaColors.outlineVariant.withValues(alpha: 0.5),
                ),
                Expanded(
                  child: _StatCell(
                    label: 'Tiempo',
                    value: data.formattedTime,
                    icon: Icons.timer_outlined,
                  ),
                ),
                VerticalDivider(
                  width: 1,
                  color: EcoRutaColors.outlineVariant.withValues(alpha: 0.5),
                ),
                Expanded(
                  child: _StatCell(
                    label: 'Fincas',
                    value: '${data.fincaWaypoints.length}',
                    icon: Icons.agriculture_rounded,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Botones
          Row(
            children: [
              Expanded(
                child: _ActionBtn(
                  label: isPaused ? 'Reanudar' : 'Iniciar',
                  icon: Icons.play_arrow_rounded,
                  color: EcoRutaColors.primary,
                  enabled: !isRecording,
                  onTap: onStart ?? notifier.start,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionBtn(
                  label: 'Pausar',
                  icon: Icons.pause_rounded,
                  color: const Color(0xFFF57C00),
                  enabled: isRecording,
                  onTap: notifier.pause,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionBtn(
                  label: 'Finalizar',
                  icon: Icons.stop_rounded,
                  color: EcoRutaColors.error,
                  enabled: !isIdle,
                  onTap: notifier.stop,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 10,
            color: EcoRutaColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCell({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: EcoRutaColors.onSurfaceVariant),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: EcoRutaColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: EcoRutaColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1.0 : 0.4,
      child: SizedBox(
        height: 44,
        child: ElevatedButton.icon(
          onPressed: enabled ? onTap : null,
          icon: Icon(icon, size: 18),
          label: Text(
            label,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            disabledBackgroundColor: color,
            disabledForegroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }
}
