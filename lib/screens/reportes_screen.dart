import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/providers.dart';

class ReportesScreen extends ConsumerStatefulWidget {
  const ReportesScreen({super.key});

  @override
  ConsumerState<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends ConsumerState<ReportesScreen> {
  int? _selectedMunicipio;
  String _tipoReporte = 'PDF';
  String _agrupacion = 'Municipio';
  DateTimeRange? _dateRange;
  bool _isGenerating = false;
  String? _lastGenerated;

  static const _tiposReporte = ['PDF', 'Excel'];
  static const _agrupaciones = ['Municipio', 'Vereda', 'Finca'];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    if (user?.rol == UserRole.tecnicoCampo) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.go('/home'),
          ),
          title: const Text('Reportes'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_rounded, size: 64, color: EcoRutaColors.error),
              SizedBox(height: 16),
              Text('Solo accesible para Administrador y Consultor',
                  style: TextStyle(color: EcoRutaColors.onSurfaceVariant)),
            ],
          ),
        ),
      );
    }

    final fincas = ref.watch(fincasProvider);
    final visitas = ref.watch(visitasProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Generación de reportes'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary cards
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    icon: Icons.agriculture_rounded,
                    value: '${fincas.length}',
                    label: 'Fincas totales',
                    color: EcoRutaColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SummaryCard(
                    icon: Icons.analytics_rounded,
                    value: '${visitas.length}',
                    label: 'Visitas totales',
                    color: EcoRutaColors.secondary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SummaryCard(
                    icon: Icons.cloud_done_rounded,
                    value: '${fincas.where((f) => f.syncStatus == SyncStatus.subido).length}',
                    label: 'Sincronizadas',
                    color: EcoRutaColors.tertiary,
                  ),
                ),
              ],
            ).animate().fadeIn(),

            const SizedBox(height: 28),

            _SectionTitle(title: 'Configurar reporte')
                .animate()
                .fadeIn(delay: 100.ms),

            const SizedBox(height: 16),

            // Filters card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tipo de reporte
                    const Text('Formato',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(
                      children: _tiposReporte.map((t) {
                        final isSelected = _tipoReporte == t;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  t == 'PDF'
                                      ? Icons.picture_as_pdf_rounded
                                      : Icons.table_chart_rounded,
                                  size: 16,
                                  color: isSelected
                                      ? Colors.white
                                      : EcoRutaColors.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(t),
                              ],
                            ),
                            selected: isSelected,
                            selectedColor: EcoRutaColors.primary,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : EcoRutaColors.onSurfaceVariant,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                            onSelected: (_) =>
                                setState(() => _tipoReporte = t),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),

                    // Agrupación
                    const Text('Agrupar por',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _agrupaciones.map((a) {
                        final isSelected = _agrupacion == a;
                        return ChoiceChip(
                          label: Text(a),
                          selected: isSelected,
                          selectedColor: EcoRutaColors.primary,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : EcoRutaColors.onSurfaceVariant,
                          ),
                          onSelected: (_) =>
                              setState(() => _agrupacion = a),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    // Municipio filter
                    DropdownButtonFormField<int?>(
                      value: _selectedMunicipio,
                      decoration: const InputDecoration(
                        labelText: 'Municipio',
                        prefixIcon: Icon(Icons.location_on_rounded),
                      ),
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('Todos los municipios')),
                        ...Municipio.municipiosPiloto.map((m) =>
                            DropdownMenuItem(
                                value: m.id, child: Text(m.nombre))),
                      ],
                      onChanged: (v) =>
                          setState(() => _selectedMunicipio = v),
                    ),

                    const SizedBox(height: 16),

                    // Date range
                    InkWell(
                      onTap: () => _selectDateRange(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: EcoRutaColors.outline.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.date_range_rounded,
                                color: EcoRutaColors.primary, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _dateRange == null
                                    ? 'Seleccionar rango de fechas'
                                    : '${_fmt(_dateRange!.start)} — ${_fmt(_dateRange!.end)}',
                                style: TextStyle(
                                  color: _dateRange == null
                                      ? EcoRutaColors.onSurfaceVariant
                                      : null,
                                ),
                              ),
                            ),
                            if (_dateRange != null)
                              IconButton(
                                icon: const Icon(Icons.clear_rounded,
                                    size: 18),
                                onPressed: () =>
                                    setState(() => _dateRange = null),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 150.ms),

            const SizedBox(height: 24),

            // Preview of what will be included
            _SectionTitle(title: 'Vista previa del contenido')
                .animate()
                .fadeIn(delay: 200.ms),
            const SizedBox(height: 12),

            _ReportPreview(
              fincas: _filteredFincas(fincas),
              visitas: _filteredVisitas(visitas, fincas),
              agrupacion: _agrupacion,
              municipioNombre: _selectedMunicipio == null
                  ? 'Todos los municipios'
                  : Municipio.municipiosPiloto
                      .firstWhere((m) => m.id == _selectedMunicipio)
                      .nombre,
            ).animate().fadeIn(delay: 250.ms),

            const SizedBox(height: 24),

            // Generate button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generate,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(
                        _tipoReporte == 'PDF'
                            ? Icons.picture_as_pdf_rounded
                            : Icons.table_chart_rounded,
                      ),
                label: Text(
                  _isGenerating
                      ? 'Generando $_tipoReporte...'
                      : 'Generar reporte $_tipoReporte',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EcoRutaColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ).animate().fadeIn(delay: 300.ms),

            // Last generated
            if (_lastGenerated != null) ...[
              const SizedBox(height: 16),
              _LastGeneratedCard(filename: _lastGenerated!),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  List<Finca> _filteredFincas(List<Finca> all) {
    return all.where((f) {
      if (_selectedMunicipio != null && f.municipioId != _selectedMunicipio)
        return false;
      if (_dateRange != null && f.fechaRegistro != null) {
        if (f.fechaRegistro!.isBefore(_dateRange!.start) ||
            f.fechaRegistro!.isAfter(_dateRange!.end)) return false;
      }
      return true;
    }).toList();
  }

  List<Visita> _filteredVisitas(List<Visita> all, List<Finca> fincas) {
    final fincaIds = _filteredFincas(fincas).map((f) => f.id).toSet();
    return all.where((v) {
      if (!fincaIds.contains(v.fincaId)) return false;
      if (_dateRange != null) {
        if (v.fecha.isBefore(_dateRange!.start) ||
            v.fecha.isAfter(_dateRange!.end)) return false;
      }
      return true;
    }).toList();
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 90)),
            end: DateTime.now(),
          ),
    );
    if (range != null) setState(() => _dateRange = range);
  }

  Future<void> _generate() async {
    setState(() => _isGenerating = true);
    await Future.delayed(const Duration(seconds: 2));

    final municipio = _selectedMunicipio == null
        ? 'santander'
        : Municipio.municipiosPiloto
            .firstWhere((m) => m.id == _selectedMunicipio)
            .nombre
            .toLowerCase()
            .replaceAll(' ', '_');

    final now = DateTime.now();
    final fecha =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final ext = _tipoReporte == 'PDF' ? 'pdf' : 'xlsx';
    final filename =
        'ecoruta_${municipio}_${_agrupacion.toLowerCase()}_$fecha.$ext';

    if (mounted) {
      setState(() {
        _isGenerating = false;
        _lastGenerated = filename;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reporte generado: $filename'),
          backgroundColor: EcoRutaColors.secondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          action: SnackBarAction(
            label: 'Compartir',
            textColor: Colors.white,
            onPressed: () => _shareReport(filename),
          ),
        ),
      );
    }
  }

  void _shareReport(String filename) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Compartir reporte'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ShareOption(
                icon: Icons.message_rounded,
                label: 'WhatsApp',
                color: const Color(0xFF25D366)),
            _ShareOption(
                icon: Icons.email_rounded,
                label: 'Correo electrónico',
                color: EcoRutaColors.primary),
            _ShareOption(
                icon: Icons.print_rounded,
                label: 'Imprimir',
                color: EcoRutaColors.onSurfaceVariant),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cerrar'))
        ],
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: EcoRutaColors.primary,
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _SummaryCard(
      {required this.icon,
      required this.value,
      required this.label,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: color)),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 11, color: EcoRutaColors.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _ReportPreview extends StatelessWidget {
  final List<Finca> fincas;
  final List<Visita> visitas;
  final String agrupacion;
  final String municipioNombre;

  const _ReportPreview({
    required this.fincas,
    required this.visitas,
    required this.agrupacion,
    required this.municipioNombre,
  });

  @override
  Widget build(BuildContext context) {
    // Group fincas by selected grouping
    final Map<String, List<Finca>> groups = {};
    for (final f in fincas) {
      final key = switch (agrupacion) {
        'Municipio' => f.municipioNombre,
        'Vereda' => f.vereda,
        _ => f.nombre,
      };
      groups.putIfAbsent(key, () => []).add(f);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.preview_rounded,
                    color: EcoRutaColors.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    municipioNombre,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: EcoRutaColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                Text('${fincas.length} finca${fincas.length != 1 ? 's' : ''}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: EcoRutaColors.onSurfaceVariant,
                        )),
              ],
            ),
            const Divider(height: 16),
            if (groups.isEmpty)
              const Text('Sin datos para los filtros seleccionados',
                  style:
                      TextStyle(color: EcoRutaColors.onSurfaceVariant))
            else
              ...groups.entries.take(4).map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: EcoRutaColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            e.key,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        Text(
                          '${e.value.length} finca${e.value.length != 1 ? 's' : ''} • '
                          '${visitas.where((v) => e.value.any((f) => f.id == v.fincaId)).length} visita${visitas.where((v) => e.value.any((f) => f.id == v.fincaId)).length != 1 ? 's' : ''}',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                  color: EcoRutaColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  )),
            if (groups.length > 4)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '... y ${groups.length - 4} más',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: EcoRutaColors.onSurfaceVariant),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LastGeneratedCard extends StatelessWidget {
  final String filename;

  const _LastGeneratedCard({required this.filename});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EcoRutaColors.secondaryContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: EcoRutaColors.secondary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded,
              color: EcoRutaColors.secondary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Último reporte generado',
                    style: TextStyle(
                        fontSize: 11,
                        color: EcoRutaColors.onSurfaceVariant)),
                Text(
                  filename,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: EcoRutaColors.secondary,
                      fontSize: 13),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            child: const Text('Descargar'),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.3, end: 0);
  }
}

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ShareOption(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(label),
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Compartiendo por $label...'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
    );
  }
}
