import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

// ─── Estado de tracking GPS ───────────────────────────────────────────────────

enum GpsTrackingStatus { idle, recording, paused }

class GpsRouteData {
  final GpsTrackingStatus status;
  final int elapsedSeconds;
  final int gpsPoints;
  final double distanceMeters;
  final List<Offset> routePoints;

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
    List<Offset>? routePoints,
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

  // Ruta de demostración que replica el diseño Figma
  static const _demoRoute = <Offset>[
    Offset(0.18, 0.82),
    Offset(0.28, 0.74),
    Offset(0.38, 0.63),
    Offset(0.46, 0.52),
    Offset(0.52, 0.42),
    Offset(0.61, 0.32),
    Offset(0.72, 0.22),
    Offset(0.81, 0.14),
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

    List<Offset> route = state.routePoints;
    if (elapsed % 5 == 0 && route.isNotEmpty) {
      final last = route.last;
      final nx =
          (last.dx + (_rng.nextDouble() - 0.45) * 0.04).clamp(0.05, 0.93);
      final ny =
          (last.dy + (_rng.nextDouble() - 0.65) * 0.04).clamp(0.05, 0.93);
      route = [...route, Offset(nx, ny)];
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

class GpsRouteTab extends ConsumerWidget {
  const GpsRouteTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(gpsRouteProvider);
    final notifier = ref.read(gpsRouteProvider.notifier);

    return Stack(
      children: [
        // Fondo de mapa simulado
        const _MapBackground(),

        // Overlay radial (efecto profesional)
        _RadialOverlay(),

        // Traza de la ruta
        Positioned.fill(
          child: CustomPaint(
            painter: _RoutePainter(
              points: data.routePoints,
              isRecording: data.status == GpsTrackingStatus.recording,
            ),
          ),
        ),

        // Controles flotantes derecha
        const _MapControlsColumn(),

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

// ─── Fondo del mapa ───────────────────────────────────────────────────────────

class _MapBackground extends StatelessWidget {
  const _MapBackground();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF142E17),
              Color(0xFF1F4A22),
              Color(0xFF2D6130),
              Color(0xFF3A7A3D),
              Color(0xFF2D6130),
              Color(0xFF1F4A22),
            ],
            stops: [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
          ),
        ),
        child: CustomPaint(
          painter: _TerrainPainter(),
        ),
      ),
    );
  }
}

class _TerrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final contourPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final roadPaint = Paint()
      ..color = Colors.white.withOpacity(0.10)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Lineas de contorno topograficas
    for (var i = 0; i < 18; i++) {
      final y = i * size.height / 17;
      final path = Path();
      path.moveTo(0, y);
      for (var x = 0.0; x <= size.width; x += 50) {
        final wave = math.sin(x / size.width * math.pi * 4 + i * 0.7) * 14;
        path.quadraticBezierTo(
          x + 25,
          y + wave,
          x + 50,
          y + math.sin((x + 50) / size.width * math.pi * 4 + i * 0.7) * 14,
        );
      }
      canvas.drawPath(path, contourPaint);
    }

    // Simulacion de caminos
    canvas.drawLine(
      Offset(0, size.height * 0.38),
      Offset(size.width, size.height * 0.46),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.42, 0),
      Offset(size.width * 0.55, size.height),
      roadPaint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.70),
      Offset(size.width * 0.60, size.height * 0.55),
      roadPaint,
    );
  }

  @override
  bool shouldRepaint(_TerrainPainter _) => false;
}

// ─── Overlay radial ───────────────────────────────────────────────────────────

class _RadialOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.35),
            ],
            stops: const [0.55, 1.0],
          ),
        ),
      ),
    );
  }
}

// ─── Painter de la ruta ───────────────────────────────────────────────────────

class _RoutePainter extends CustomPainter {
  final List<Offset> points;
  final bool isRecording;

  const _RoutePainter({required this.points, required this.isRecording});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final scaled = points
        .map((p) => Offset(p.dx * size.width, p.dy * size.height))
        .toList();

    // Sombra de la ruta
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.35)
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Linea de la ruta
    final routePaint = Paint()
      ..color = const Color(0xFF4CAF73)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path()..moveTo(scaled[0].dx, scaled[0].dy);
    for (var i = 1; i < scaled.length; i++) {
      path.lineTo(scaled[i].dx, scaled[i].dy);
    }

    canvas.drawPath(path, shadowPaint);
    canvas.drawPath(path, routePaint);

    // Marcador de inicio (circulo verde)
    _drawMarker(canvas, scaled.first, EcoRutaColors.primary);

    // Marcador de posicion actual / fin
    final endColor =
        isRecording ? const Color(0xFF4CAF73) : EcoRutaColors.error;
    _drawMarker(canvas, scaled.last, endColor);

    // Anillo pulsante si esta grabando
    if (isRecording) {
      final pulsePaint = Paint()
        ..color = const Color(0xFF4CAF73).withOpacity(0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawCircle(scaled.last, 18, pulsePaint);
    }
  }

  void _drawMarker(Canvas canvas, Offset center, Color color) {
    canvas.drawCircle(center, 11, Paint()..color = Colors.white);
    canvas.drawCircle(center, 8, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_RoutePainter old) =>
      old.points != points || old.isRecording != isRecording;
}

// ─── Controles flotantes del mapa ─────────────────────────────────────────────

class _MapControlsColumn extends StatelessWidget {
  const _MapControlsColumn();

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
            _MapBtn(icon: Icons.add_rounded),
            const SizedBox(height: 8),
            _MapBtn(icon: Icons.remove_rounded),
            const SizedBox(height: 8),
            _MapBtn(icon: Icons.my_location_rounded),
          ],
        ),
      ),
    );
  }
}

class _MapBtn extends StatelessWidget {
  final IconData icon;
  const _MapBtn({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: EcoRutaColors.surface,
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: Colors.black38,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {},
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
        color: EcoRutaColors.surface.withOpacity(0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: EcoRutaColors.outlineVariant.withOpacity(0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
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
                  color: EcoRutaColors.outlineVariant.withOpacity(0.5),
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
                  color: EcoRutaColors.outlineVariant.withOpacity(0.5),
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
