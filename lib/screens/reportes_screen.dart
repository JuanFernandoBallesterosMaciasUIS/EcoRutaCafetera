import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/providers.dart';
import '../utils/download_service.dart';

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
  List<int>? _lastBytes;
  String? _lastMime;

  static const _tiposReporte = ['PDF', 'CSV'];
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
                    value:
                        '${fincas.where((f) => f.syncStatus == SyncStatus.subido).length}',
                    label: 'Sincronizadas',
                    color: EcoRutaColors.tertiary,
                  ),
                ),
              ],
            ).animate().fadeIn(),

            const SizedBox(height: 28),

            const _SectionTitle(title: 'Configurar reporte')
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
                    // Format picker
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
                          onSelected: (_) => setState(() => _agrupacion = a),
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
                            value: null,
                            child: Text('Todos los municipios')),
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

            const _SectionTitle(title: 'Vista previa del contenido')
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
                onPressed: _isGenerating
                    ? null
                    : () => _generate(
                          _filteredFincas(fincas),
                          _filteredVisitas(visitas, fincas),
                        ),
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
                      : 'Descargar reporte $_tipoReporte',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EcoRutaColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ).animate().fadeIn(delay: 300.ms),

            if (_lastGenerated != null) ...[
              const SizedBox(height: 16),
              _LastGeneratedCard(
                filename: _lastGenerated!,
                onDownload: () =>
                    downloadFile(_lastBytes!, _lastGenerated!, _lastMime!),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ─── Filtering ──────────────────────────────────────────────────────────────

  List<Finca> _filteredFincas(List<Finca> all) {
    return all.where((f) {
      if (_selectedMunicipio != null && f.municipioId != _selectedMunicipio) {
        return false;
      }
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

  // ─── Date picker ────────────────────────────────────────────────────────────

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

  // ─── Generation ─────────────────────────────────────────────────────────────

  Future<void> _generate(List<Finca> fincas, List<Visita> visitas) async {
    setState(() => _isGenerating = true);

    try {
      final municipioSlug = _selectedMunicipio == null
          ? 'santander'
          : Municipio.municipiosPiloto
              .firstWhere((m) => m.id == _selectedMunicipio)
              .nombre
              .toLowerCase()
              .replaceAll(' ', '_');

      final now = DateTime.now();
      final fecha =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

      List<int> bytes;
      String filename;
      String mime;

      if (_tipoReporte == 'PDF') {
        final pdf = await _buildPdf(fincas, visitas);
        bytes = pdf;
        filename = 'ecoruta_${municipioSlug}_${_agrupacion.toLowerCase()}_$fecha.pdf';
        mime = 'application/pdf';
      } else {
        final csv = _buildCsv(fincas, visitas);
        bytes = utf8.encode(csv);
        filename = 'ecoruta_${municipioSlug}_${_agrupacion.toLowerCase()}_$fecha.csv';
        mime = 'text/csv;charset=utf-8';
      }

      await downloadFile(bytes, filename, mime);

      if (mounted) {
        setState(() {
          _isGenerating = false;
          _lastGenerated = filename;
          _lastBytes = bytes;
          _lastMime = mime;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Descargando $filename'),
            backgroundColor: EcoRutaColors.secondary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar reporte: $e'),
            backgroundColor: EcoRutaColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  // ─── PDF Builder ────────────────────────────────────────────────────────────

  Future<Uint8List> _buildPdf(List<Finca> fincas, List<Visita> visitas) async {
    final doc = pw.Document();
    final now = DateTime.now();
    final totalHa =
        fincas.fold(0.0, (sum, f) => sum + f.hectareas);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (ctx) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.green800, width: 1.5)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('EcoRuta Cafetera',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green800,
                      fontSize: 13)),
              pw.Text('Generado: ${_fmt(now)}',
                  style: const pw.TextStyle(
                      fontSize: 9, color: PdfColors.grey600)),
            ],
          ),
        ),
        footer: (ctx) => pw.Container(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('Página ${ctx.pageNumber} de ${ctx.pagesCount}',
              style:
                  const pw.TextStyle(fontSize: 9, color: PdfColors.grey500)),
        ),
        build: (ctx) => [
          // Title block
          pw.Text(
            'Reporte de Censo Cafetero',
            style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.green900),
          ),
          pw.Text(
            _selectedMunicipio == null
                ? 'Todos los municipios • Santander'
                : '${Municipio.municipiosPiloto.firstWhere((m) => m.id == _selectedMunicipio).nombre} • Santander',
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 20),

          // Stats row
          pw.Row(children: [
            _pdfStat('Fincas', '${fincas.length}'),
            pw.SizedBox(width: 12),
            _pdfStat('Visitas', '${visitas.length}'),
            pw.SizedBox(width: 12),
            _pdfStat('Hectáreas', '${totalHa.toStringAsFixed(1)} ha'),
            pw.SizedBox(width: 12),
            _pdfStat(
                'Agrupación',
                _agrupacion),
          ]),
          pw.SizedBox(height: 24),

          // Fincas table
          pw.Text('Fincas registradas',
              style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green800)),
          pw.SizedBox(height: 8),
          if (fincas.isEmpty)
            pw.Text('Sin fincas para los filtros seleccionados',
                style: const pw.TextStyle(
                    color: PdfColors.grey600, fontSize: 10))
          else
            pw.Table.fromTextArray(
              headers: [
                'Nombre',
                'Propietario',
                'Municipio',
                'Vereda',
                'Ha',
                'Variedad',
                'Sync'
              ],
              data: fincas
                  .map((f) => [
                        f.nombre,
                        f.propietario,
                        f.municipioNombre,
                        f.vereda,
                        f.hectareas.toStringAsFixed(1),
                        f.variedadCafe,
                        f.syncStatus.name,
                      ])
                  .toList(),
              headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  fontSize: 9),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.green800),
              cellStyle: const pw.TextStyle(fontSize: 9),
              oddRowDecoration:
                  const pw.BoxDecoration(color: PdfColors.green50),
              border: pw.TableBorder.all(
                  color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(1.8),
                3: const pw.FlexColumnWidth(1.5),
                4: const pw.FlexColumnWidth(0.8),
                5: const pw.FlexColumnWidth(1.5),
                6: const pw.FlexColumnWidth(1),
              },
            ),

          if (visitas.isNotEmpty) ...[
            pw.SizedBox(height: 24),
            pw.Text('Visitas de campo',
                style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green800)),
            pw.SizedBox(height: 8),
            pw.Table.fromTextArray(
              headers: [
                'Fecha',
                'Técnico',
                'Finca',
                'Cob. Vegetal',
                'Agua',
                'Prod. kg/año',
                'Personas'
              ],
              data: visitas.map((v) {
                final fincaNombre = fincas
                    .where((f) => f.id == v.fincaId)
                    .map((f) => f.nombre)
                    .firstOrNull ?? 'ID ${v.fincaId}';
                return [
                  _fmt(v.fecha),
                  v.tecnicoNombre,
                  fincaNombre,
                  '${v.coberturaVegetal.toStringAsFixed(0)}%',
                  v.tieneFuenteAgua ? 'Sí' : 'No',
                  v.produccionKgAnio.toStringAsFixed(0),
                  '${v.personasHogar}',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  fontSize: 9),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.green700),
              cellStyle: const pw.TextStyle(fontSize: 9),
              oddRowDecoration:
                  const pw.BoxDecoration(color: PdfColors.lightGreen50),
              border: pw.TableBorder.all(
                  color: PdfColors.grey300, width: 0.5),
            ),
          ],

          pw.SizedBox(height: 32),
          pw.Divider(color: PdfColors.grey300),
          pw.Text(
            'EcoRuta Cafetera — Sistema Territorial de Censo Cafetero — Santander, Colombia',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          ),
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _pdfStat(String label, String value) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          color: PdfColors.green50,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          border: pw.Border.all(color: PdfColors.green200, width: 0.5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(value,
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 14,
                    color: PdfColors.green800)),
            pw.Text(label,
                style: const pw.TextStyle(
                    fontSize: 8, color: PdfColors.grey600)),
          ],
        ),
      ),
    );
  }

  // ─── CSV Builder ────────────────────────────────────────────────────────────

  String _buildCsv(List<Finca> fincas, List<Visita> visitas) {
    final buf = StringBuffer();
    // UTF-8 BOM so Excel opens with correct encoding
    buf.write('﻿');
    buf.writeln('EcoRuta Cafetera - Reporte de Censo Cafetero');
    buf.writeln('Generado:,${_fmt(DateTime.now())}');
    buf.writeln('Total fincas:,${fincas.length}');
    buf.writeln('Total visitas:,${visitas.length}');
    buf.writeln(
        'Hectáreas totales:,${fincas.fold(0.0, (s, f) => s + f.hectareas).toStringAsFixed(2)}');
    buf.writeln();

    buf.writeln('FINCAS');
    buf.writeln(
        'Nombre,Propietario,Municipio,Departamento,Vereda,Hectáreas,Variedad,Latitud,Longitud,Estado Sync,Fecha Registro');
    for (final f in fincas) {
      buf.writeln([
        _q(f.nombre),
        _q(f.propietario),
        _q(f.municipioNombre),
        'Santander',
        _q(f.vereda),
        f.hectareas,
        _q(f.variedadCafe),
        f.latitud ?? '',
        f.longitud ?? '',
        f.syncStatus.name,
        f.fechaRegistro != null ? _fmt(f.fechaRegistro!) : '',
      ].join(','));
    }

    if (visitas.isNotEmpty) {
      buf.writeln();
      buf.writeln('VISITAS');
      buf.writeln(
          'Fecha,Técnico,Finca,Cobertura Vegetal (%),Fuente Agua,Manejo Residuos,Uso Agroquímicos,Prácticas Agroforestales,Producción kg/año,Precio kg COP,Costo Producción COP,Personas Hogar,Menores Edad,Nivel Educativo,Seg. Alimentaria,Prog. Gobierno,Estado Sync');
      for (final v in visitas) {
        final fincaNombre = fincas
            .where((f) => f.id == v.fincaId)
            .map((f) => f.nombre)
            .firstOrNull ?? 'ID ${v.fincaId}';
        buf.writeln([
          _fmt(v.fecha),
          _q(v.tecnicoNombre),
          _q(fincaNombre),
          v.coberturaVegetal.toStringAsFixed(1),
          v.tieneFuenteAgua ? 'Sí' : 'No',
          v.manejoAdecuadoResiduos ? 'Sí' : 'No',
          v.usoAgroquimicos ? 'Sí' : 'No',
          v.practicasAgroforestales ? 'Sí' : 'No',
          v.produccionKgAnio.toStringAsFixed(0),
          v.precioKgCOP.toStringAsFixed(0),
          v.costoProduccionCOP.toStringAsFixed(0),
          v.personasHogar,
          v.menoresEdad,
          _q(v.nivelEducativo),
          v.seguridadAlimentaria ? 'Sí' : 'No',
          v.accesoProgramasGobierno ? 'Sí' : 'No',
          v.syncStatus.name,
        ].join(','));
      }
    }

    return buf.toString();
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _q(String s) => '"${s.replaceAll('"', '""')}"';
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
                    fontSize: 11,
                    color: EcoRutaColors.onSurfaceVariant)),
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
                Text(
                    '${fincas.length} finca${fincas.length != 1 ? 's' : ''}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: EcoRutaColors.onSurfaceVariant,
                        )),
              ],
            ),
            const Divider(height: 16),
            if (groups.isEmpty)
              const Text('Sin datos para los filtros seleccionados',
                  style: TextStyle(color: EcoRutaColors.onSurfaceVariant))
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
                          child: Text(e.key,
                              style: Theme.of(context).textTheme.bodySmall),
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
  final VoidCallback onDownload;

  const _LastGeneratedCard(
      {required this.filename, required this.onDownload});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EcoRutaColors.secondaryContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: EcoRutaColors.secondary.withOpacity(0.3)),
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
          TextButton.icon(
            onPressed: onDownload,
            icon: const Icon(Icons.download_rounded, size: 16),
            label: const Text('Descargar'),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.3, end: 0);
  }
}
