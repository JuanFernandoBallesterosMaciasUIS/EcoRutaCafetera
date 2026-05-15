import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/location_service.dart';
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
  final _mapController = MapController();

  String _selectedVariedad = 'Castillo';
  bool _consentAccepted = false;
  bool _isLocating = false;
  bool _isGeocoding = false;

  LatLng? _selectedPoint;
  String? _detectedMunicipio;
  String? _detectedDepartamento;
  Municipio? _detectedMunicipioObj;

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

  static const _initialCenter = LatLng(6.55, -73.60);

  @override
  void dispose() {
    _nombreController.dispose();
    _propietarioController.dispose();
    _veredaController.dispose();
    _hectareasController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _onMapTap(TapPosition _, LatLng point) {
    setState(() {
      _selectedPoint = point;
      _detectedMunicipio = null;
      _detectedDepartamento = null;
      _detectedMunicipioObj = null;
      _isGeocoding = true;
    });
    _reverseGeocode(point.latitude, point.longitude);
  }

  Future<void> _useGpsLocation() async {
    setState(() => _isLocating = true);
    final loc = await LocationService.getCurrentLocation();
    if (!mounted) return;
    if (loc == null) {
      setState(() => _isLocating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No se pudo obtener el GPS. Toca el mapa manualmente.'),
          backgroundColor: EcoRutaColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    final point = LatLng(loc.latitude, loc.longitude);
    setState(() {
      _selectedPoint = point;
      _isLocating = false;
      _detectedMunicipio = null;
      _detectedDepartamento = null;
      _detectedMunicipioObj = null;
      _isGeocoding = true;
    });
    _mapController.move(point, 13.5);
    _reverseGeocode(loc.latitude, loc.longitude);
  }

  Future<void> _reverseGeocode(double lat, double lng) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=$lat&lon=$lng&format=json&addressdetails=1',
      );
      final response = await http.get(uri, headers: {
        'Accept-Language': 'es',
        'User-Agent': 'EcoRutaCafetera/1.0',
      });
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final address = (data['address'] as Map<String, dynamic>?) ?? {};
        final rawMun = (address['municipality'] ??
                address['city'] ??
                address['town'] ??
                address['village'] ??
                address['county'] ??
                '') as String;
        final rawDep = (address['state'] ?? '') as String;

        // Match against pilot list (case-insensitive contains)
        Municipio? matched;
        final munNorm = rawMun.toLowerCase().trim();
        for (final m in Municipio.municipiosPiloto) {
          final mNorm = m.nombre.toLowerCase();
          if (munNorm.contains(mNorm) || mNorm.contains(munNorm)) {
            matched = m;
            break;
          }
        }

        setState(() {
          _detectedMunicipio = rawMun.isNotEmpty ? rawMun : 'Fuera de cobertura';
          _detectedDepartamento = rawDep;
          _detectedMunicipioObj = matched;
          _isGeocoding = false;
        });
      } else {
        setState(() => _isGeocoding = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isGeocoding = false);
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
    if (_selectedPoint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Selecciona la ubicación de la finca en el mapa'),
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
      latitud: _selectedPoint!.latitude,
      longitud: _selectedPoint!.longitude,
      municipioId: _detectedMunicipioObj?.id ?? 0,
      municipioNombreCustom:
          _detectedMunicipioObj == null ? _detectedMunicipio : null,
      departamentoCustom:
          _detectedMunicipioObj == null ? _detectedDepartamento : null,
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
              const Icon(Icons.add_home_rounded,
                  size: 80, color: EcoRutaColors.onPrimaryContainer),
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
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: ['RF-01', 'RF-03', 'RF-09', 'RNF-09'].map((tag) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
            // Consent banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: EcoRutaColors.errorContainer.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: EcoRutaColors.error.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.shield_outlined,
                      color: EcoRutaColors.error, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Consentimiento informado requerido',
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: EcoRutaColors.onErrorContainer,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Según Ley 1581/2012 (Habeas Data), el propietario debe autorizar el registro de sus datos.',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: EcoRutaColors.onErrorContainer,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Checkbox(
                              value: _consentAccepted,
                              onChanged: (v) =>
                                  setState(() => _consentAccepted = v ?? false),
                            ),
                            Expanded(
                              child: Text(
                                'El propietario ha sido informado y acepta',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                        color: EcoRutaColors.onErrorContainer),
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
              validator: (v) =>
                  v?.trim().isEmpty ?? true ? 'Campo requerido' : null,
            ),

            const SizedBox(height: 16),

            _buildField(
              label: 'Nombre del propietario',
              controller: _propietarioController,
              hint: 'Nombre completo',
              icon: Icons.person_outline_rounded,
              delay: 100,
              validator: (v) =>
                  v?.trim().isEmpty ?? true ? 'Campo requerido' : null,
            ),

            const SizedBox(height: 16),

            _buildField(
              label: 'Vereda',
              controller: _veredaController,
              hint: 'Ej: El Palmar',
              icon: Icons.landscape_outlined,
              delay: 150,
              validator: (v) =>
                  v?.trim().isEmpty ?? true ? 'Campo requerido' : null,
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel('Hectáreas'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _hectareasController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          hintText: 'Ej: 3.5',
                          prefixIcon: Icon(Icons.square_foot_rounded),
                          suffixText: 'ha',
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Requerido';
                          if (double.tryParse(v) == null)
                            return 'Número inválido';
                          return null;
                        },
                      ),
                    ],
                  ).animate().fadeIn(delay: 200.ms),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                        onChanged: (v) =>
                            setState(() => _selectedVariedad = v!),
                      ),
                    ],
                  ).animate().fadeIn(delay: 250.ms),
                ),
              ],
            ),

            const SizedBox(height: 28),
            _SectionTitle('Ubicación en el mapa'),
            const SizedBox(height: 4),
            Text(
              'Toca el mapa para marcar la ubicación exacta de la finca. El municipio y departamento se detectan automáticamente.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: EcoRutaColors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),

            _buildMapPicker(),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildMapPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Map container
        Container(
          height: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _selectedPoint != null
                  ? EcoRutaColors.secondary.withOpacity(0.5)
                  : EcoRutaColors.outlineVariant,
              width: _selectedPoint != null ? 2 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _initialCenter,
                  initialZoom: 8.5,
                  onTap: _onMapTap,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.ecoruta.cafetera',
                    maxZoom: 19,
                  ),
                  if (_selectedPoint != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _selectedPoint!,
                          width: 48,
                          height: 48,
                          alignment: Alignment.topCenter,
                          child: const Icon(
                            Icons.location_pin,
                            color: EcoRutaColors.primary,
                            size: 48,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              // Hint overlay when no point selected
              if (_selectedPoint == null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.touch_app_rounded,
                                color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Toca el mapa para marcar la ubicación',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // GPS button
              Positioned(
                top: 10,
                right: 10,
                child: Material(
                  elevation: 4,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: _isLocating ? null : _useGpsLocation,
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: _isLocating
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: EcoRutaColors.primary),
                            )
                          : const Icon(Icons.my_location_rounded,
                              color: EcoRutaColors.primary, size: 22),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 300.ms),

        // Detected location info
        if (_selectedPoint != null) ...[
          const SizedBox(height: 10),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _detectedMunicipioObj != null
                  ? EcoRutaColors.secondaryContainer.withOpacity(0.35)
                  : EcoRutaColors.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _detectedMunicipioObj != null
                    ? EcoRutaColors.secondary.withOpacity(0.4)
                    : EcoRutaColors.outlineVariant,
              ),
            ),
            child: _isGeocoding
                ? const Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: EcoRutaColors.secondary),
                      ),
                      SizedBox(width: 12),
                      Text('Detectando municipio...'),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _detectedMunicipioObj != null
                            ? Icons.location_on_rounded
                            : Icons.location_searching_rounded,
                        color: _detectedMunicipioObj != null
                            ? EcoRutaColors.secondary
                            : EcoRutaColors.onSurfaceVariant,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _detectedMunicipio ?? 'Sin municipio detectado',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            if (_detectedDepartamento?.isNotEmpty == true)
                              Text(
                                _detectedDepartamento!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                        color:
                                            EcoRutaColors.onSurfaceVariant),
                              ),
                            const SizedBox(height: 2),
                            Text(
                              '${_selectedPoint!.latitude.toStringAsFixed(5)}°N, '
                              '${_selectedPoint!.longitude.abs().toStringAsFixed(5)}°O',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                      color: EcoRutaColors.onSurfaceVariant,
                                      fontFamily: 'monospace'),
                            ),
                          ],
                        ),
                      ),
                      if (_detectedMunicipioObj != null)
                        const Icon(Icons.check_circle_rounded,
                            color: EcoRutaColors.secondary, size: 20),
                    ],
                  ),
          ),
        ],
      ],
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
