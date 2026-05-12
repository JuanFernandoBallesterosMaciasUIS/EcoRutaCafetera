import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/providers.dart';
import '../widgets/widgets.dart';

class MapaFincasScreen extends ConsumerStatefulWidget {
  final bool embedded;

  const MapaFincasScreen({super.key, this.embedded = false});

  @override
  ConsumerState<MapaFincasScreen> createState() => _MapaFincasScreenState();
}

class _MapaFincasScreenState extends ConsumerState<MapaFincasScreen> {
  int? _selectedMunicipio;
  Finca? _selectedFinca;
  final TransformationController _transformController =
      TransformationController();

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fincas = ref.watch(fincasProvider);
    final filtered = _selectedMunicipio == null
        ? fincas
        : fincas.where((f) => f.municipioId == _selectedMunicipio).toList();

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
            icon: const Icon(Icons.center_focus_strong_rounded),
            tooltip: 'Centrar mapa',
            onPressed: () {
              _transformController.value = Matrix4.identity();
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
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _ChipFilter(
                    label: 'Todos (${fincas.length})',
                    isSelected: _selectedMunicipio == null,
                    onTap: () =>
                        setState(() => _selectedMunicipio = null),
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

          // Map area
          Expanded(
            child: Stack(
              children: [
                InteractiveViewer(
                  transformationController: _transformController,
                  minScale: 0.5,
                  maxScale: 4.0,
                  boundaryMargin: const EdgeInsets.all(80),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedFinca = null),
                    child: SizedBox(
                      width: 600,
                      height: 600,
                      child: CustomPaint(
                        painter: _MapPainter(
                          fincas: filtered,
                          selectedFinca: _selectedFinca,
                        ),
                        child: Stack(
                          children: filtered
                              .map((f) => _FincaMarker(
                                    finca: f,
                                    allFincas: filtered,
                                    isSelected: _selectedFinca?.id == f.id,
                                    onTap: () => setState(
                                        () => _selectedFinca = f),
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 600.ms),

                // Legend
                Positioned(
                  top: 12,
                  right: 12,
                  child: _MapLegend(),
                ),

                // Stats overlay bottom-left
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                        )
                      ],
                    ),
                    child: Text(
                      '${filtered.length} finca${filtered.length != 1 ? 's' : ''} visibles',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: EcoRutaColors.primary,
                      ),
                    ),
                  ).animate().fadeIn(delay: 400.ms),
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

// ─── Map Painter ─────────────────────────────────────────────────────────────

class _MapPainter extends CustomPainter {
  final List<Finca> fincas;
  final Finca? selectedFinca;

  const _MapPainter({required this.fincas, this.selectedFinca});

  @override
  void paint(Canvas canvas, Size size) {
    // Background terrain
    final bgPaint = Paint()..color = const Color(0xFFE8F5E9);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Topographic contour lines
    final contourPaint = Paint()
      ..color = EcoRutaColors.primary.withOpacity(0.07)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (var i = 1; i <= 8; i++) {
      final path = Path();
      final y = size.height * i / 9;
      path.moveTo(0, y);
      for (var x = 0.0; x <= size.width; x += 5) {
        final offset = 15 *
            math.sin(x * 0.05 + i) *
            math.cos(x * 0.02 - i * 0.5);
        path.lineTo(x, y + offset);
      }
      canvas.drawPath(path, contourPaint);
    }

    // Roads
    final roadPaint = Paint()
      ..color = const Color(0xFFBCAAA4).withOpacity(0.5)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final road1 = Path();
    road1.moveTo(0, size.height * 0.6);
    road1.cubicTo(
        size.width * 0.3, size.height * 0.55,
        size.width * 0.6, size.height * 0.65,
        size.width, size.height * 0.5);
    canvas.drawPath(road1, roadPaint);

    final road2 = Path();
    road2.moveTo(size.width * 0.5, 0);
    road2.cubicTo(
        size.width * 0.45, size.height * 0.3,
        size.width * 0.55, size.height * 0.6,
        size.width * 0.5, size.height);
    canvas.drawPath(road2, roadPaint);

    // River
    final riverPaint = Paint()
      ..color = const Color(0xFF64B5F6).withOpacity(0.4)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final river = Path();
    river.moveTo(0, size.height * 0.35);
    river.cubicTo(
        size.width * 0.25, size.height * 0.4,
        size.width * 0.5, size.height * 0.3,
        size.width * 0.75, size.height * 0.45);
    river.cubicTo(
        size.width * 0.85, size.height * 0.5,
        size.width * 0.9, size.height * 0.55,
        size.width, size.height * 0.6);
    canvas.drawPath(river, riverPaint);

    // Grid
    final gridPaint = Paint()
      ..color = EcoRutaColors.primary.withOpacity(0.04)
      ..strokeWidth = 0.5;
    for (var i = 1; i < 6; i++) {
      canvas.drawLine(
          Offset(size.width * i / 6, 0),
          Offset(size.width * i / 6, size.height),
          gridPaint);
      canvas.drawLine(
          Offset(0, size.height * i / 6),
          Offset(size.width, size.height * i / 6),
          gridPaint);
    }

    // Compass
    _drawCompass(canvas, size);
  }

  void _drawCompass(Canvas canvas, Size size) {
    final cx = size.width - 30;
    final cy = size.height - 30;
    final compassPaint = Paint()
      ..color = EcoRutaColors.primary.withOpacity(0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final fillPaint = Paint()
      ..color = EcoRutaColors.primary.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(cx, cy), 16, compassPaint);

    // North arrow
    final arrowPath = Path();
    arrowPath.moveTo(cx, cy - 12);
    arrowPath.lineTo(cx - 4, cy + 4);
    arrowPath.lineTo(cx, cy);
    arrowPath.close();
    canvas.drawPath(arrowPath, fillPaint);

    final arrowPath2 = Path();
    arrowPath2.moveTo(cx, cy - 12);
    arrowPath2.lineTo(cx + 4, cy + 4);
    arrowPath2.lineTo(cx, cy);
    arrowPath2.close();
    canvas.drawPath(arrowPath2,
        Paint()..color = Colors.grey.withOpacity(0.5));
  }

  @override
  bool shouldRepaint(_MapPainter old) =>
      old.fincas != fincas || old.selectedFinca != selectedFinca;
}

// ─── Farm Marker ─────────────────────────────────────────────────────────────

class _FincaMarker extends StatelessWidget {
  final Finca finca;
  final List<Finca> allFincas;
  final bool isSelected;
  final VoidCallback onTap;

  const _FincaMarker({
    required this.finca,
    required this.allFincas,
    required this.isSelected,
    required this.onTap,
  });

  // Normalize coordinates to 600x600 canvas
  Offset _toCanvasPos(double lat, double lng, Size canvas) {
    if (allFincas.isEmpty) return Offset(canvas.width / 2, canvas.height / 2);

    final lats = allFincas
        .where((f) => f.latitud != null)
        .map((f) => f.latitud!);
    final lngs = allFincas
        .where((f) => f.longitud != null)
        .map((f) => f.longitud!);

    if (lats.isEmpty) return Offset(canvas.width / 2, canvas.height / 2);

    final minLat = lats.reduce(math.min) - 0.02;
    final maxLat = lats.reduce(math.max) + 0.02;
    final minLng = lngs.reduce(math.min) - 0.02;
    final maxLng = lngs.reduce(math.max) + 0.02;

    final x = (lng - minLng) / (maxLng - minLng) * canvas.width * 0.8 +
        canvas.width * 0.1;
    // Lat inverted: higher lat = lower y
    final y = (1 - (lat - minLat) / (maxLat - minLat)) *
            canvas.height *
            0.8 +
        canvas.height * 0.1;

    return Offset(x, y);
  }

  Color get _markerColor => switch (finca.syncStatus) {
        SyncStatus.subido => EcoRutaColors.secondary,
        SyncStatus.pendiente => EcoRutaColors.tertiary,
        SyncStatus.subiendo => EcoRutaColors.primary,
        SyncStatus.error => EcoRutaColors.error,
      };

  @override
  Widget build(BuildContext context) {
    if (finca.latitud == null) return const SizedBox.shrink();

    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final pos = _toCanvasPos(
            finca.latitud!,
            finca.longitud!,
            Size(constraints.maxWidth, constraints.maxHeight),
          );

          return Stack(
            children: [
              Positioned(
                left: pos.dx - (isSelected ? 22 : 18),
                top: pos.dy - (isSelected ? 44 : 36),
                child: GestureDetector(
                  onTap: onTap,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Pulse ring
                        if (isSelected)
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _markerColor.withOpacity(0.4),
                                width: 3,
                              ),
                            ),
                            child: Container(
                              margin: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: _markerColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: _markerColor.withOpacity(0.4),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  )
                                ],
                              ),
                              child: const Icon(Icons.agriculture_rounded,
                                  color: Colors.white, size: 18),
                            ),
                          )
                        else
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: _markerColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _markerColor.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: const Icon(Icons.agriculture_rounded,
                                color: Colors.white, size: 16),
                          ),

                        // Stem
                        Container(
                          width: 2,
                          height: 8,
                          color: _markerColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Label
              if (isSelected)
                Positioned(
                  left: pos.dx - 60,
                  top: pos.dy - 70,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 120),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 6,
                        )
                      ],
                    ),
                    child: Text(
                      finca.nombre,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _markerColor,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
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
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)
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
          _LegendItem(
              color: EcoRutaColors.secondary, label: 'Sincronizado'),
          _LegendItem(
              color: EcoRutaColors.tertiary, label: 'Pendiente'),
          _LegendItem(color: EcoRutaColors.error, label: 'Error'),
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

// ─── Selected Finca Card ─────────────────────────────────────────────────────

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
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, -2))
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: EcoRutaColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Text(
                      '${finca.propietario} • ${finca.municipioNombre}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: EcoRutaColors.onSurfaceVariant,
                          ),
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
          const SizedBox(height: 12),
          Row(
            children: [
              _InfoPill(
                  icon: Icons.landscape_rounded,
                  label: '${finca.hectareas} ha'),
              const SizedBox(width: 8),
              _InfoPill(icon: Icons.eco_rounded, label: finca.variedadCafe),
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

// ─── Filter Chip ─────────────────────────────────────────────────────────────

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
