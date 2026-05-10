import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/providers.dart';

class NuevaFincaScreen extends ConsumerStatefulWidget {
  const NuevaFincaScreen({super.key});

  @override
  ConsumerState<NuevaFincaScreen> createState() => _NuevaFincaScreenState();
}

class _NuevaFincaScreenState extends ConsumerState<NuevaFincaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _propietarioController = TextEditingController();
  final _veredaController = TextEditingController();
  final _hectareasController = TextEditingController();
  Municipio? _selectedMunicipio;
  String _selectedVariedad = 'Castillo';
  bool _capturedGps = false;
  bool _isLoading = false;
  bool _consentAccepted = false;

  static const List<String> _variedades = [
    'Castillo',
    'Caturra',
    'Colombia',
    'Tabi',
    'Cenicafé 1',
    'Geisha',
    'Bourbon',
    'Otro',
  ];

  @override
  void dispose() {
    _nombreController.dispose();
    _propietarioController.dispose();
    _veredaController.dispose();
    _hectareasController.dispose();
    super.dispose();
  }

  Future<void> _simulateCaptureGps() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _capturedGps = true;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('GPS capturado: 6.1833°N, 73.6167°O'),
          backgroundColor: EcoRutaColors.secondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _saveFinca() {
    if (!_formKey.currentState!.validate()) return;
    if (!_consentAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('El propietario debe aceptar el consentimiento informado'),
          backgroundColor: EcoRutaColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final finca = Finca(
      nombre: _nombreController.text.trim(),
      propietario: _propietarioController.text.trim(),
      vereda: _veredaController.text.trim(),
      hectareas: double.tryParse(_hectareasController.text) ?? 0,
      variedadCafe: _selectedVariedad,
      latitud: _capturedGps ? 6.1833 : null,
      longitud: _capturedGps ? -73.6167 : null,
      municipioId: _selectedMunicipio?.id ?? 2,
    );

    ref.read(fincasProvider.notifier).addFinca(finca);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Finca registrada y guardada offline'),
        backgroundColor: EcoRutaColors.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 700;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Registrar Finca'),
      ),
      body: isWide
          ? Row(
              children: [
                Expanded(flex: 2, child: _buildInfoPanel()),
                const VerticalDivider(width: 1),
                Expanded(flex: 3, child: _buildForm()),
              ],
            )
          : _buildForm(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveFinca,
        backgroundColor: EcoRutaColors.secondary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.save_rounded),
        label: const Text('Guardar offline'),
      ),
    );
  }

  Widget _buildInfoPanel() {
    return Container(
      color: EcoRutaColors.primaryContainer,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_home_rounded, size: 80, color: EcoRutaColors.onPrimaryContainer),
              const SizedBox(height: 24),
              Text(
                'Nueva Finca',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: EcoRutaColors.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Registra los datos de una nueva unidad productiva cafetera. Los datos se guardan localmente y se sincronizarán cuando haya conexión.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: EcoRutaColors.onPrimaryContainer.withOpacity(0.8),
                      height: 1.6,
                    ),
              ),
              const SizedBox(height: 32),
              // RF tags
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: ['RF-01', 'RF-03', 'RF-09', 'RNF-09'].map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: EcoRutaColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        color: EcoRutaColors.onPrimaryContainer,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Consentimiento banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: EcoRutaColors.errorContainer.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: EcoRutaColors.error.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.shield_outlined, color: EcoRutaColors.error, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Consentimiento informado requerido',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: EcoRutaColors.onErrorContainer,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Según Ley 1581/2012 (Habeas Data), el propietario debe autorizar el registro de sus datos.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: EcoRutaColors.onErrorContainer,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Checkbox(
                              value: _consentAccepted,
                              onChanged: (v) => setState(() => _consentAccepted = v ?? false),
                            ),
                            Expanded(
                              child: Text(
                                'El propietario ha sido informado y acepta',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: EcoRutaColors.onErrorContainer,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(),

            const SizedBox(height: 24),
            _SectionTitle('Información básica'),
            const SizedBox(height: 12),

            _buildField(
              label: 'Nombre de la finca',
              controller: _nombreController,
              hint: 'Ej: La Esperanza',
              icon: Icons.home_outlined,
              delay: 50,
              validator: (v) => v?.trim().isEmpty ?? true ? 'Campo requerido' : null,
            ),

            const SizedBox(height: 16),

            _buildField(
              label: 'Nombre del propietario',
              controller: _propietarioController,
              hint: 'Nombre completo',
              icon: Icons.person_outline_rounded,
              delay: 100,
              validator: (v) => v?.trim().isEmpty ?? true ? 'Campo requerido' : null,
            ),

            const SizedBox(height: 16),

            _buildField(
              label: 'Vereda',
              controller: _veredaController,
              hint: 'Ej: El Palmar',
              icon: Icons.landscape_outlined,
              delay: 150,
              validator: (v) => v?.trim().isEmpty ?? true ? 'Campo requerido' : null,
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel('Municipio'),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<Municipio>(
                        value: _selectedMunicipio,
                        hint: const Text('Seleccionar'),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.location_city_outlined),
                        ),
                        items: Municipio.municipiosPiloto.map((m) {
                          return DropdownMenuItem(value: m, child: Text(m.nombre));
                        }).toList(),
                        onChanged: (v) => setState(() => _selectedMunicipio = v),
                        validator: (v) => v == null ? 'Requerido' : null,
                      ),
                    ],
                  ).animate().fadeIn(delay: 200.ms),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel('Hectáreas'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _hectareasController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          hintText: 'Ej: 3.5',
                          prefixIcon: Icon(Icons.square_foot_rounded),
                          suffixText: 'ha',
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Requerido';
                          if (double.tryParse(v) == null) return 'Número inválido';
                          return null;
                        },
                      ),
                    ],
                  ).animate().fadeIn(delay: 250.ms),
                ),
              ],
            ),

            const SizedBox(height: 16),

            _FieldLabel('Variedad de café'),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedVariedad,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.eco_outlined),
              ),
              items: _variedades.map((v) {
                return DropdownMenuItem(value: v, child: Text(v));
              }).toList(),
              onChanged: (v) => setState(() => _selectedVariedad = v!),
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 24),
            _SectionTitle('Georreferenciación'),
            const SizedBox(height: 12),

            // GPS capture
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _capturedGps
                    ? EcoRutaColors.secondaryContainer.withOpacity(0.4)
                    : EcoRutaColors.surfaceContainer,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _capturedGps
                      ? EcoRutaColors.secondary.withOpacity(0.3)
                      : EcoRutaColors.outlineVariant,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _capturedGps ? Icons.gps_fixed_rounded : Icons.gps_not_fixed_rounded,
                    color: _capturedGps ? EcoRutaColors.secondary : EcoRutaColors.onSurfaceVariant,
                    size: 28,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _capturedGps ? 'GPS capturado' : 'Capturar coordenadas GPS',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: _capturedGps
                                    ? EcoRutaColors.secondary
                                    : EcoRutaColors.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        Text(
                          _capturedGps
                              ? '6.1833°N, 73.6167°O • Precisión: 2.5m'
                              : 'GPS + GLONASS • sub-métrico',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: EcoRutaColors.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (!_capturedGps)
                    ElevatedButton(
                      onPressed: _isLoading ? null : _simulateCaptureGps,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(80, 40),
                        backgroundColor: EcoRutaColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Capturar'),
                    ),
                ],
              ),
            ).animate().fadeIn(delay: 350.ms),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required int delay,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
          ),
          validator: validator,
        ),
      ],
    ).animate().fadeIn(delay: Duration(milliseconds: delay));
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: EcoRutaColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: EcoRutaColors.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}
