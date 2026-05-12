import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../theme/app_theme.dart';

// ─── Estado de tracking GPS ───────────────────────────────────────────────────

enum GpsTrackingStatus { idle, recording, paused }

class GpsRouteData {
  final GpsTrackingStatus status;
  final int elapsedSeconds;
  final int gpsPoints;
  final double distanceMeters;
  final List<LatLng> routePoints;

  const GpsRouteData({
    this.status = GpsTrackingStatus.idle,
    this.elapsedSeconds = 0,
    this.gpsPoints = 0,
    this.distanceMeters = 0.0,
    this.routePoints = const [],
  });

  GpsRouteData copyWith({
    GpsTrackingStatus? status,
    int? elapsedSeconds,
    int? gpsPoints,
    double? distanceMeters,
    List<LatLng>? routePoints,
  }) =>
      GpsRouteData(
        status: status ?? this.status,
        elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
        gpsPoints: gpsPoints ?? this.gpsPoints,
        distanceMeters: distanceMeters ?? this.distanceMeters,
        routePoints: routePoints ?? this.routePoints,
      );

  String get formattedTime {
    final h = elapsedSeconds ~/ 3600;
    final m = (elapsedSeconds % 3600) ~/ 60;
    final s = elapsedSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }

  String get formattedDistance {
    if (distanceMeters >= 1000) {
      return '${(distanceMeters / 1000).toStringAsFixed(2)} km';
    }
    return '${distanceMeters.toStringAsFixed(0)} m';
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class GpsRouteNotifier extends StateNotifier<GpsRouteData> {
  GpsRouteNotifier() : super(const GpsRouteData()) {
    _initDemoRoute();
  }

  Timer? _timer;
  final _rng = math.Random(42);

  // Ruta demo — coordenadas reales zona cafetera Barbosa/Vélez, Santander
  static const _demoRoute = <LatLng>[
    LatLng(6.1780, -73.6200),
    LatLng(6.1820, -73.6160),
    LatLng(6.1860, -73.6120),
    LatLng(6.1900, -73.6090),
    LatLng(6.1940, -73.6050),
    LatLng(6.1970, -73.6010),
    LatLng(6.2010, -73.5970),
    LatLng(6.2050, -73.5940),
  ];

  void _initDemoRoute() {
    state = const GpsRouteData(
      routePoints: _demoRoute,
      distanceMeters: 235.0,
      gpsPoints: 0,
    );
  }

  void start() {
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
    _initDemoRoute();
  }

  void _tick() {
    final elapsed = state.elapsedSeconds + 1;
    final distance = state.distanceMeters + 0.55 + _rng.nextDouble() * 0.5;
    final points = elapsed % 3 == 0 ? state.gpsPoints + 1 : state.gpsPoints;

    List<LatLng> route = state.routePoints;
    if (elapsed % 5 == 0 && route.isNotEmpty) {
      final last = route.last;
      final dlat = (_rng.nextDouble() - 0.3) * 0.0005;
      final dlng = (_rng.nextDouble() - 0.3) * 0.0005;
      route = [...route, LatLng(last.latitude + dlat, last.longitude + dlng)];
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

// ─── Tab principal (embebible en HomeScreen) ──────────────────────────────────

class GpsRouteTab extends ConsumerStatefulWidget {
  const GpsRouteTab({super.key});

  @override
  ConsumerState<GpsRouteTab> createState() => _GpsRouteTabState();
}

class _GpsRouteTabState extends ConsumerState<GpsRouteTab> {
  final _mapController = MapController();

  static const _defaultCenter = LatLng(6.1900, -73.6050);
  static const _defaultZoom = 14.0;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _centerOnRoute(List<LatLng> points) {
    if (points.isEmpty) return;
    _mapController.move(points.last, _defaultZoom);
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(gpsRouteProvider);
    final notifier = ref.read(gpsRouteProvider.notifier);

    return Stack(
      children: [
        // Mapa real OpenStreetMap
        FlutterMap(
          mapController: _mapController,
          options: const MapOptions(
            initialCenter: _defaultCenter,
            initialZoom: _defaultZoom,
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.ecoruta.cafetera',
              maxZoom: 19,
            ),

            // Traza de la ruta
            if (data.routePoints.length >= 2)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: data.routePoints,
                    strokeWidth: 5,
                    color: const Color(0xFF4CAF73),
                    borderStrokeWidth: 2,
                    borderColor: Colors.white.withValues(alpha: 0.6),
                  ),
                ],
              ),

            // Marcadores inicio y posicion actual
            if (data.routePoints.isNotEmpty)
              MarkerLayer(
                markers: [
                  // Inicio
                  Marker(
                    point: data.routePoints.first,
                    width: 28,
                    height: 28,
                    child: const _RouteMarker(
                      color: EcoRutaColors.primary,
                      icon: Icons.play_arrow_rounded,
                    ),
                  ),
                  // Posicion actual / fin
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
                        pulsing:
                            data.status == GpsTrackingStatus.recording,
                      ),
                    ),
                ],
              ),

            // Atribucion OSM
            const SimpleAttributionWidget(
              source: Text('© OpenStreetMap',
                  style: TextStyle(fontSize: 10, color: Colors.black54)),
            ),
          ],
        ),

        // Controles flotantes derecha
        _MapControlsColumn(
          onZoomIn: () => _mapController.move(
              _mapController.camera.center,
              _mapController.camera.zoom + 1),
          onZoomOut: () => _mapController.move(
              _mapController.camera.center,
              _mapController.camera.zoom - 1),
          onCenter: () => _centerOnRoute(data.routePoints),
        ),

        // Tarjeta de estadísticas + acciones (bottom)
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: _StatsCard(data: data, notifier: notifier)
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.1),
        ),
      ],
    );
  }
}

// ─── Marcador de ruta ─────────────────────────────────────────────────────────

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
  final VoidCallback onCenter;

  const _MapControlsColumn({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onCenter,
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
            _MapBtn(icon: Icons.my_location_rounded, onTap: onCenter),
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

  const _StatsCard({required this.data, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final isIdle = data.status == GpsTrackingStatus.idle;
    final isRecording = data.status == GpsTrackingStatus.recording;
    final isPaused = data.status == GpsTrackingStatus.paused;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
          // Indicador de estado
          if (!isIdle)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
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
                  const SizedBox(width: 8),
                  Text(
                    isRecording ? 'Grabando ruta...' : 'Ruta pausada',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isRecording
                          ? const Color(0xFF2A6B2C)
                          : const Color(0xFFBF6000),
                    ),
                  ),
                ],
              ),
            ),

          // Fila de estadisticas
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
                    label: 'Puntos GPS',
                    value: data.gpsPoints.toString(),
                    icon: Icons.pin_drop_outlined,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Botones de accion
          Row(
            children: [
              Expanded(
                child: _ActionBtn(
                  label: isPaused ? 'Reanudar' : 'Iniciar',
                  icon: Icons.play_arrow_rounded,
                  color: EcoRutaColors.primary,
                  enabled: !isRecording,
                  onTap: notifier.start,
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
