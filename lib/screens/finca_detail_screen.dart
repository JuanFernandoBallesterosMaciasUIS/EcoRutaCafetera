import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/providers.dart';
import '../widgets/widgets.dart';

class FincaDetailScreen extends ConsumerStatefulWidget {
  final String fincaId;

  const FincaDetailScreen({super.key, required this.fincaId});

  @override
  ConsumerState<FincaDetailScreen> createState() => _FincaDetailScreenState();
}

class _FincaDetailScreenState extends ConsumerState<FincaDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fincas = ref.watch(fincasProvider);
    final finca = fincas.firstWhere(
      (f) => f.id.toString() == widget.fincaId,
      orElse: () => const Finca(
        nombre: 'No encontrada',
        propietario: '',
        vereda: '',
        hectareas: 0,
        variedadCafe: '',
        municipioId: 1,
      ),
    );
    final visitas = ref.watch(visitasProvider.notifier).forFinca(finca.id ?? 0);
    final user = ref.watch(authProvider);
    final isReadOnly = user?.rol == UserRole.consultor;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/home'),
        ),
        title: Text(finca.nombre),
        actions: [
          if (!isReadOnly)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Eliminar finca',
              onPressed: () => _confirmDelete(context, finca),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.info_outline_rounded), text: 'Información'),
            Tab(icon: Icon(Icons.history_rounded), text: 'Historial'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _InfoTab(finca: finca),
          _HistorialTab(visitas: visitas, fincaNombre: finca.nombre),
        ],
      ),
      floatingActionButton: (isReadOnly || finca.id == null)
          ? null
          : FloatingActionButton.extended(
              onPressed: () =>
                  context.go('/visita/nueva/${finca.id}'),
              backgroundColor: EcoRutaColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_chart_rounded),
              label: const Text('Capturar indicadores'),
            ),
    );
  }

  void _confirmDelete(BuildContext context, Finca finca) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar finca'),
        content: Text(
            '¿Eliminar "${finca.nombre}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: EcoRutaColors.error,
                foregroundColor: Colors.white),
            onPressed: () {
              ref.read(fincasProvider.notifier).deleteFinca(finca.id!);
              Navigator.pop(ctx);
              context.go('/home');
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

// ─── Info Tab ─────────────────────────────────────────────────────────────

class _InfoTab extends StatelessWidget {
  final Finca finca;

  const _InfoTab({required this.finca});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _syncColor(finca.syncStatus).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: _syncColor(finca.syncStatus).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(_syncIcon(finca.syncStatus),
                    color: _syncColor(finca.syncStatus), size: 20),
                const SizedBox(width: 8),
                Text(
                  'Estado: ${finca.syncStatus.displayName}',
                  style: TextStyle(
                    color: _syncColor(finca.syncStatus),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(),

          const SizedBox(height: 20),

          _SectionCard(
            title: 'Datos del predio',
            icon: Icons.agriculture_rounded,
            children: [
              _DetailRow('Propietario', finca.propietario),
              _DetailRow('Vereda', finca.vereda),
              _DetailRow('Municipio', finca.municipioNombre),
              _DetailRow('Hectáreas', '${finca.hectareas} ha'),
              _DetailRow('Variedad de café', finca.variedadCafe),
            ],
          ).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 16),

          _SectionCard(
            title: 'Georreferenciación',
            icon: Icons.location_on_rounded,
            children: [
              if (finca.latitud != null) ...[
                _DetailRow('Latitud',
                    '${finca.latitud!.toStringAsFixed(6)}°N'),
                _DetailRow('Longitud',
                    '${finca.longitud!.toStringAsFixed(6)}°O'),
                _CoordMapPreview(lat: finca.latitud!, lng: finca.longitud!),
              ] else
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.gps_off_rounded,
                          color: EcoRutaColors.onSurfaceVariant, size: 16),
                      SizedBox(width: 8),
                      Text('Coordenadas GPS no capturadas',
                          style:
                              TextStyle(color: EcoRutaColors.onSurfaceVariant)),
                    ],
                  ),
                ),
            ],
          ).animate().fadeIn(delay: 200.ms),

          if (finca.fechaRegistro != null) ...[
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Registro',
              icon: Icons.calendar_today_rounded,
              children: [
                _DetailRow(
                  'Fecha de registro',
                  '${finca.fechaRegistro!.day.toString().padLeft(2, '0')}/'
                      '${finca.fechaRegistro!.month.toString().padLeft(2, '0')}/'
                      '${finca.fechaRegistro!.year}',
                ),
              ],
            ).animate().fadeIn(delay: 300.ms),
          ],

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Color _syncColor(SyncStatus s) => switch (s) {
        SyncStatus.subido => EcoRutaColors.secondary,
        SyncStatus.pendiente => EcoRutaColors.onSurfaceVariant,
        SyncStatus.subiendo => EcoRutaColors.primary,
        SyncStatus.error => EcoRutaColors.error,
      };

  IconData _syncIcon(SyncStatus s) => switch (s) {
        SyncStatus.subido => Icons.cloud_done_rounded,
        SyncStatus.pendiente => Icons.cloud_upload_rounded,
        SyncStatus.subiendo => Icons.cloud_sync_rounded,
        SyncStatus.error => Icons.cloud_off_rounded,
      };
}

// ─── Historial Tab ────────────────────────────────────────────────────────

class _HistorialTab extends StatelessWidget {
  final List<Visita> visitas;
  final String fincaNombre;

  const _HistorialTab({required this.visitas, required this.fincaNombre});

  @override
  Widget build(BuildContext context) {
    if (visitas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history_rounded,
                size: 64, color: EcoRutaColors.outlineVariant),
            const SizedBox(height: 16),
            Text(
              'Sin visitas registradas',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: EcoRutaColors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            const Text('Captura indicadores de sostenibilidad\npara esta finca.',
                textAlign: TextAlign.center,
                style: TextStyle(color: EcoRutaColors.onSurfaceVariant)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: visitas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final v = visitas[i];
        return _VisitaCard(visita: v)
            .animate()
            .fadeIn(delay: (i * 80).ms)
            .slideY(begin: 0.05, end: 0);
      },
    );
  }
}

class _VisitaCard extends StatelessWidget {
  final Visita visita;

  const _VisitaCard({required this.visita});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => _showDetail(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: EcoRutaColors.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.analytics_rounded,
                        color: EcoRutaColors.onPrimaryContainer, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Visita del ${_formatDate(visita.fecha)}',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                  color: EcoRutaColors.primary,
                                  fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Técnico: ${visita.tecnicoNombre}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                  color: EcoRutaColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  SyncStatusChip(status: visita.syncStatus),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  _MiniStat(
                      icon: Icons.eco_rounded,
                      label: 'Cobertura',
                      value: '${visita.coberturaVegetal.toInt()}%'),
                  const SizedBox(width: 16),
                  _MiniStat(
                      icon: Icons.scale_rounded,
                      label: 'Producción',
                      value: '${visita.produccionKgAnio.toInt()} kg'),
                  const SizedBox(width: 16),
                  _MiniStat(
                      icon: Icons.people_rounded,
                      label: 'Personas',
                      value: '${visita.personasHogar}'),
                ],
              ),
              if (visita.observaciones != null &&
                  visita.observaciones!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  visita.observaciones!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: EcoRutaColors.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _VisitaDetailSheet(visita: visita),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _VisitaDetailSheet extends StatelessWidget {
  final Visita visita;

  const _VisitaDetailSheet({required this.visita});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (_, controller) => Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: EcoRutaColors.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'Detalle de visita',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: EcoRutaColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const Spacer(),
                SyncStatusChip(status: visita.syncStatus),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  '${_fmt(visita.fecha)} • ${visita.tecnicoNombre}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: EcoRutaColors.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 20),

                // Ambiental
                _DetailSection(
                  title: 'Indicadores Ambientales',
                  icon: Icons.eco_rounded,
                  color: EcoRutaColors.secondary,
                  children: [
                    _DetailRow('Cobertura vegetal',
                        '${visita.coberturaVegetal.toInt()}%'),
                    _DetailRow('Fuente de agua',
                        visita.tieneFuenteAgua ? 'Disponible' : 'No disponible'),
                    _DetailRow('Manejo de residuos',
                        visita.manejoAdecuadoResiduos ? 'Adecuado' : 'Deficiente'),
                    _DetailRow('Uso de agroquímicos',
                        visita.usoAgroquimicos ? 'Sí' : 'No'),
                    _DetailRow('Prácticas agroforestales',
                        visita.practicasAgroforestales ? 'Sí' : 'No'),
                  ],
                ),
                const SizedBox(height: 16),

                // Económico
                _DetailSection(
                  title: 'Indicadores Económicos',
                  icon: Icons.attach_money_rounded,
                  color: EcoRutaColors.tertiary,
                  children: [
                    _DetailRow('Producción anual',
                        '${visita.produccionKgAnio.toInt()} kg'),
                    _DetailRow('Precio por kg',
                        '\$ ${_formatCOP(visita.precioKgCOP)}'),
                    _DetailRow('Costo de producción',
                        '\$ ${_formatCOP(visita.costoProduccionCOP)}'),
                    _DetailRow('Ingreso bruto anual',
                        '\$ ${_formatCOP(visita.ingresoBrutoAnual)}'),
                    _DetailRow('Margen neto',
                        '\$ ${_formatCOP(visita.margenNeto)}',
                        valueColor: visita.margenNeto >= 0
                            ? EcoRutaColors.secondary
                            : EcoRutaColors.error),
                    _DetailRow('Otros ingresos',
                        visita.tieneOtrosIngresos ? 'Sí' : 'No'),
                  ],
                ),
                const SizedBox(height: 16),

                // Social
                _DetailSection(
                  title: 'Indicadores Sociales',
                  icon: Icons.people_rounded,
                  color: EcoRutaColors.primary,
                  children: [
                    _DetailRow(
                        'Personas en hogar', '${visita.personasHogar}'),
                    _DetailRow('Menores de edad', '${visita.menoresEdad}'),
                    _DetailRow('Nivel educativo', visita.nivelEducativo),
                    _DetailRow('Seguridad alimentaria',
                        visita.seguridadAlimentaria ? 'Sí' : 'No'),
                    _DetailRow('Acceso a programas gov.',
                        visita.accesoProgramasGobierno ? 'Sí' : 'No'),
                  ],
                ),

                if (visita.observaciones != null &&
                    visita.observaciones!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _DetailSection(
                    title: 'Observaciones',
                    icon: Icons.notes_rounded,
                    color: EcoRutaColors.onSurfaceVariant,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(visita.observaciones!),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _formatCOP(double v) {
    final abs = v.abs();
    final prefix = v < 0 ? '-' : '';
    if (abs >= 1000000) {
      return '$prefix${(abs / 1000000).toStringAsFixed(2)} M';
    }
    if (abs >= 1000) {
      return '$prefix${(abs / 1000).toStringAsFixed(1)} K';
    }
    return '$prefix${abs.toStringAsFixed(0)}';
  }
}

// ─── Shared sub-widgets ───────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: EcoRutaColors.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: EcoRutaColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  const _DetailSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: EcoRutaColors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: valueColor,
                    fontWeight:
                        valueColor != null ? FontWeight.w600 : FontWeight.normal,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MiniStat(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: EcoRutaColors.primary),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: EcoRutaColors.primary,
                    )),
            Text(label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: EcoRutaColors.onSurfaceVariant,
                    )),
          ],
        ),
      ],
    );
  }
}

class _CoordMapPreview extends StatelessWidget {
  final double lat;
  final double lng;

  const _CoordMapPreview({required this.lat, required this.lng});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: EcoRutaColors.primaryContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: EcoRutaColors.primaryFixed),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Simulated terrain grid
            CustomPaint(
              size: const Size(double.infinity, 100),
              painter: _TerrainMiniPainter(),
            ),
            // Pin
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: EcoRutaColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.agriculture_rounded,
                      color: Colors.white, size: 16),
                ),
                Container(
                  width: 2,
                  height: 12,
                  color: EcoRutaColors.primary,
                ),
              ],
            ),
            Positioned(
              bottom: 6,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${lat.toStringAsFixed(4)}°N, ${lng.toStringAsFixed(4)}°O',
                  style: const TextStyle(
                      fontSize: 10,
                      color: EcoRutaColors.primary,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TerrainMiniPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = EcoRutaColors.primary.withOpacity(0.06)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < 5; i++) {
      final y = size.height * (i + 1) / 6;
      final path = Path();
      path.moveTo(0, y);
      for (var x = 0.0; x <= size.width; x += 10) {
        path.lineTo(x, y + (i % 2 == 0 ? 4 : -4) * (x / size.width));
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
