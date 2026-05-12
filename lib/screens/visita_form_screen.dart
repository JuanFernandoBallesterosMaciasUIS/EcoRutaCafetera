import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/providers.dart';

class VisitaFormScreen extends ConsumerStatefulWidget {
  final String fincaId;

  const VisitaFormScreen({super.key, required this.fincaId});

  @override
  ConsumerState<VisitaFormScreen> createState() => _VisitaFormScreenState();
}

class _VisitaFormScreenState extends ConsumerState<VisitaFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Ambiental
  double _coberturaVegetal = 60;
  bool _tieneFuenteAgua = true;
  bool _manejoAdecuadoResiduos = false;
  bool _usoAgroquimicos = false;
  bool _practicasAgroforestales = false;

  // Económico
  final _produccionCtrl = TextEditingController(text: '2000');
  final _precioKgCtrl = TextEditingController(text: '2200');
  final _costoProduccionCtrl = TextEditingController(text: '3000000');
  bool _tieneOtrosIngresos = false;

  // Social
  int _personasHogar = 4;
  int _menoresEdad = 1;
  String _nivelEducativo = 'Secundaria';
  bool _seguridadAlimentaria = true;
  bool _accesoProgramasGobierno = false;

  final _observacionesCtrl = TextEditingController();

  bool _isSaving = false;

  static const _nivelesEducativos = [
    'Ninguno',
    'Primaria',
    'Secundaria',
    'Técnico',
    'Universitario',
  ];

  @override
  void dispose() {
    _produccionCtrl.dispose();
    _precioKgCtrl.dispose();
    _costoProduccionCtrl.dispose();
    _observacionesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fincas = ref.watch(fincasProvider);
    final finca = fincas.firstWhere(
      (f) => f.id.toString() == widget.fincaId,
      orElse: () => const Finca(
          nombre: 'Finca',
          propietario: '',
          vereda: '',
          hectareas: 0,
          variedadCafe: '',
          municipioId: 1),
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.go('/finca/${widget.fincaId}'),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Capturar indicadores'),
            Text(
              finca.nombre,
              style: const TextStyle(
                  fontSize: 12,
                  color: EcoRutaColors.onSurfaceVariant,
                  fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: EcoRutaColors.primaryContainer.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        color: EcoRutaColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Fecha de visita: ${_today()}',
                      style: const TextStyle(
                          color: EcoRutaColors.primary,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ).animate().fadeIn(),

              const SizedBox(height: 24),

              // ── Ambiental ──────────────────────────────────────────────
              _SectionHeader(
                title: 'Indicadores Ambientales',
                icon: Icons.eco_rounded,
                color: EcoRutaColors.secondary,
              ).animate().fadeIn(delay: 50.ms),

              const SizedBox(height: 16),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cobertura vegetal: ${_coberturaVegetal.toInt()}%',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Slider(
                        value: _coberturaVegetal,
                        min: 0,
                        max: 100,
                        divisions: 20,
                        activeColor: EcoRutaColors.secondary,
                        label: '${_coberturaVegetal.toInt()}%',
                        onChanged: (v) =>
                            setState(() => _coberturaVegetal = v),
                      ),
                      const Divider(height: 24),
                      _BigToggle(
                        label: 'Fuente de agua propia',
                        value: _tieneFuenteAgua,
                        icon: Icons.water_drop_rounded,
                        onChanged: (v) =>
                            setState(() => _tieneFuenteAgua = v),
                      ),
                      _BigToggle(
                        label: 'Manejo adecuado de residuos',
                        value: _manejoAdecuadoResiduos,
                        icon: Icons.recycling_rounded,
                        onChanged: (v) =>
                            setState(() => _manejoAdecuadoResiduos = v),
                      ),
                      _BigToggle(
                        label: 'Uso de agroquímicos',
                        value: _usoAgroquimicos,
                        icon: Icons.science_rounded,
                        onChanged: (v) =>
                            setState(() => _usoAgroquimicos = v),
                      ),
                      _BigToggle(
                        label: 'Prácticas agroforestales',
                        value: _practicasAgroforestales,
                        icon: Icons.park_rounded,
                        onChanged: (v) =>
                            setState(() => _practicasAgroforestales = v),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 24),

              // ── Económico ─────────────────────────────────────────────
              _SectionHeader(
                title: 'Indicadores Económicos',
                icon: Icons.attach_money_rounded,
                color: EcoRutaColors.tertiary,
              ).animate().fadeIn(delay: 150.ms),

              const SizedBox(height: 16),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _produccionCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Producción anual (kg)',
                          prefixIcon:
                              Icon(Icons.scale_rounded),
                          suffixText: 'kg/año',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _precioKgCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Precio por kg (COP)',
                          prefixIcon:
                              Icon(Icons.attach_money_rounded),
                          prefixText: '\$ ',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _costoProduccionCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Costo de producción anual (COP)',
                          prefixIcon:
                              Icon(Icons.receipt_long_rounded),
                          prefixText: '\$ ',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 8),

                      // Live margin preview
                      _MarginPreview(
                        produccion: double.tryParse(_produccionCtrl.text) ?? 0,
                        precio: double.tryParse(_precioKgCtrl.text) ?? 0,
                        costo: double.tryParse(_costoProduccionCtrl.text) ?? 0,
                        controller1: _produccionCtrl,
                        controller2: _precioKgCtrl,
                        controller3: _costoProduccionCtrl,
                      ),
                      const Divider(height: 24),
                      _BigToggle(
                        label: 'Tiene otros ingresos',
                        value: _tieneOtrosIngresos,
                        icon: Icons.savings_rounded,
                        onChanged: (v) =>
                            setState(() => _tieneOtrosIngresos = v),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 24),

              // ── Social ────────────────────────────────────────────────
              _SectionHeader(
                title: 'Indicadores Sociales',
                icon: Icons.people_rounded,
                color: EcoRutaColors.primary,
              ).animate().fadeIn(delay: 250.ms),

              const SizedBox(height: 16),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _CounterField(
                        label: 'Personas en el hogar',
                        value: _personasHogar,
                        min: 1,
                        max: 20,
                        onChanged: (v) =>
                            setState(() => _personasHogar = v),
                      ),
                      const Divider(height: 20),
                      _CounterField(
                        label: 'Menores de edad',
                        value: _menoresEdad,
                        min: 0,
                        max: _personasHogar,
                        onChanged: (v) =>
                            setState(() => _menoresEdad = v),
                      ),
                      const Divider(height: 20),
                      DropdownButtonFormField<String>(
                        value: _nivelEducativo,
                        decoration: const InputDecoration(
                          labelText: 'Nivel educativo del propietario',
                          prefixIcon: Icon(Icons.school_rounded),
                        ),
                        items: _nivelesEducativos
                            .map((n) => DropdownMenuItem(
                                value: n, child: Text(n)))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _nivelEducativo = v!),
                      ),
                      const Divider(height: 20),
                      _BigToggle(
                        label: 'Seguridad alimentaria garantizada',
                        value: _seguridadAlimentaria,
                        icon: Icons.restaurant_rounded,
                        onChanged: (v) =>
                            setState(() => _seguridadAlimentaria = v),
                      ),
                      _BigToggle(
                        label: 'Acceso a programas de gobierno',
                        value: _accesoProgramasGobierno,
                        icon: Icons.account_balance_rounded,
                        onChanged: (v) =>
                            setState(() => _accesoProgramasGobierno = v),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 24),

              // ── Observaciones ─────────────────────────────────────────
              TextFormField(
                controller: _observacionesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Observaciones (opcional)',
                  prefixIcon: Icon(Icons.notes_rounded),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                maxLength: 500,
              ).animate().fadeIn(delay: 350.ms),

              const SizedBox(height: 32),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(_isSaving ? 'Guardando...' : 'Guardar visita'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EcoRutaColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 600));

    final user = ref.read(authProvider)!;
    final visita = Visita(
      fincaId: int.tryParse(widget.fincaId) ?? 0,
      tecnicoId: user.id,
      tecnicoNombre: user.nombre,
      fecha: DateTime.now(),
      coberturaVegetal: _coberturaVegetal,
      tieneFuenteAgua: _tieneFuenteAgua,
      manejoAdecuadoResiduos: _manejoAdecuadoResiduos,
      usoAgroquimicos: _usoAgroquimicos,
      practicasAgroforestales: _practicasAgroforestales,
      produccionKgAnio: double.tryParse(_produccionCtrl.text) ?? 0,
      precioKgCOP: double.tryParse(_precioKgCtrl.text) ?? 0,
      costoProduccionCOP: double.tryParse(_costoProduccionCtrl.text) ?? 0,
      tieneOtrosIngresos: _tieneOtrosIngresos,
      personasHogar: _personasHogar,
      menoresEdad: _menoresEdad,
      nivelEducativo: _nivelEducativo,
      seguridadAlimentaria: _seguridadAlimentaria,
      accesoProgramasGobierno: _accesoProgramasGobierno,
      observaciones: _observacionesCtrl.text.isEmpty
          ? null
          : _observacionesCtrl.text,
    );

    ref.read(visitasProvider.notifier).addVisita(visita);

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Visita guardada. Pendiente de sincronización.'),
          backgroundColor: EcoRutaColors.secondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      context.go('/finca/${widget.fincaId}');
    }
  }

  String _today() {
    final n = DateTime.now();
    return '${n.day.toString().padLeft(2, '0')}/${n.month.toString().padLeft(2, '0')}/${n.year}';
  }
}

// ─── Form sub-widgets ─────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _SectionHeader(
      {required this.title, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _BigToggle extends StatelessWidget {
  final String label;
  final bool value;
  final IconData icon;
  final ValueChanged<bool> onChanged;

  const _BigToggle({
    required this.label,
    required this.value,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              Icon(icon,
                  size: 20,
                  color: value
                      ? EcoRutaColors.primary
                      : EcoRutaColors.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight:
                            value ? FontWeight.w600 : FontWeight.normal,
                      ),
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: EcoRutaColors.primary,
                materialTapTargetSize: MaterialTapTargetSize.padded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CounterField extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _CounterField({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w500)),
        ),
        IconButton(
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline_rounded),
          color: EcoRutaColors.primary,
          iconSize: 28,
        ),
        SizedBox(
          width: 40,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: EcoRutaColors.primary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        IconButton(
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add_circle_outline_rounded),
          color: EcoRutaColors.primary,
          iconSize: 28,
        ),
      ],
    );
  }
}

class _MarginPreview extends StatefulWidget {
  final double produccion;
  final double precio;
  final double costo;
  final TextEditingController controller1;
  final TextEditingController controller2;
  final TextEditingController controller3;

  const _MarginPreview({
    required this.produccion,
    required this.precio,
    required this.costo,
    required this.controller1,
    required this.controller2,
    required this.controller3,
  });

  @override
  State<_MarginPreview> createState() => _MarginPreviewState();
}

class _MarginPreviewState extends State<_MarginPreview> {
  @override
  void initState() {
    super.initState();
    widget.controller1.addListener(_rebuild);
    widget.controller2.addListener(_rebuild);
    widget.controller3.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    widget.controller1.removeListener(_rebuild);
    widget.controller2.removeListener(_rebuild);
    widget.controller3.removeListener(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prod = double.tryParse(widget.controller1.text) ?? 0;
    final precio = double.tryParse(widget.controller2.text) ?? 0;
    final costo = double.tryParse(widget.controller3.text) ?? 0;
    final bruto = prod * precio;
    final margen = bruto - costo;
    final isPositive = margen >= 0;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isPositive ? EcoRutaColors.secondary : EcoRutaColors.error)
            .withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: (isPositive ? EcoRutaColors.secondary : EcoRutaColors.error)
              .withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Ingreso bruto: \$ ${_fmt(bruto)}',
              style: const TextStyle(fontSize: 12)),
          Text(
            'Margen: \$ ${_fmt(margen)}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isPositive ? EcoRutaColors.secondary : EcoRutaColors.error,
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    final abs = v.abs();
    final prefix = v < 0 ? '-' : '';
    if (abs >= 1000000) return '$prefix${(abs / 1000000).toStringAsFixed(2)}M';
    if (abs >= 1000) return '$prefix${(abs / 1000).toStringAsFixed(1)}K';
    return '$prefix${abs.toStringAsFixed(0)}';
  }
}
