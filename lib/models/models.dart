/// Roles del sistema EcoRuta Cafetera
enum UserRole {
  administrador,
  tecnicoCampo,
  consultor;

  String get displayName {
    switch (this) {
      case UserRole.administrador:
        return 'Administrador';
      case UserRole.tecnicoCampo:
        return 'Técnico de campo';
      case UserRole.consultor:
        return 'Consultor';
    }
  }
}

/// Tipos de indicadores de sostenibilidad
enum TipoIndicador {
  produccion,
  plagas,
  suelo,
  clima,
  otro;

  String get displayName {
    switch (this) {
      case TipoIndicador.produccion:
        return 'Producción';
      case TipoIndicador.plagas:
        return 'Plagas';
      case TipoIndicador.suelo:
        return 'Suelo';
      case TipoIndicador.clima:
        return 'Clima';
      case TipoIndicador.otro:
        return 'Otro';
    }
  }
}

/// Estado de sincronización
enum SyncStatus {
  pendiente,
  subiendo,
  subido,
  error;

  String get displayName {
    switch (this) {
      case SyncStatus.pendiente:
        return 'Pendiente';
      case SyncStatus.subiendo:
        return 'Subiendo';
      case SyncStatus.subido:
        return 'Sincronizado';
      case SyncStatus.error:
        return 'Error';
    }
  }
}

/// Modelo de usuario
class AppUser {
  final int id;
  final String nombre;
  final String username;
  final String email;
  final UserRole rol;
  final int? municipioAsignado;

  const AppUser({
    required this.id,
    required this.nombre,
    this.username = '',
    this.email = '',
    required this.rol,
    this.municipioAsignado,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      rol: UserRole.values.firstWhere(
        (r) => r.name == json['rol'],
        orElse: () => UserRole.consultor,
      ),
      municipioAsignado: json['municipioAsignado'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'username': username,
        'email': email,
        'rol': rol.name,
        'municipioAsignado': municipioAsignado,
      };
}

/// Municipios cafeteros de Santander
class Municipio {
  final int id;
  final String nombre;
  final String departamento;
  final String codigoDane;
  final double latCenter;
  final double lngCenter;

  const Municipio({
    required this.id,
    required this.nombre,
    required this.departamento,
    required this.codigoDane,
    required this.latCenter,
    required this.lngCenter,
  });

  static const List<Municipio> municipiosPiloto = [
    Municipio(id: 1, nombre: 'Vélez',                  departamento: 'Santander', codigoDane: '68861', latCenter: 6.0113,  lngCenter: -73.6775),
    Municipio(id: 2, nombre: 'Barbosa',                 departamento: 'Santander', codigoDane: '68081', latCenter: 6.1833,  lngCenter: -73.6167),
    Municipio(id: 3, nombre: 'Landázuri',               departamento: 'Santander', codigoDane: '68397', latCenter: 6.2278,  lngCenter: -73.8136),
    Municipio(id: 4, nombre: 'El Carmen de Chucurí',    departamento: 'Santander', codigoDane: '68147', latCenter: 6.7017,  lngCenter: -73.5167),
    Municipio(id: 5, nombre: 'San Vicente de Chucurí',  departamento: 'Santander', codigoDane: '68770', latCenter: 6.8931,  lngCenter: -73.3703),
    Municipio(id: 6, nombre: 'Betulia',                 departamento: 'Santander', codigoDane: '68092', latCenter: 6.9833,  lngCenter: -73.7000),
  ];
}

/// Rutas de visita predefinidas
class RutaVisita {
  final int id;
  final String nombre;
  final String descripcion;
  final List<int> fincaIds;

  const RutaVisita({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.fincaIds,
  });

  static const List<RutaVisita> rutasPredefinidas = [
    RutaVisita(
      id: 1,
      nombre: 'Ruta Barbosa Norte',
      descripcion: 'La Esperanza → El Paraíso',
      fincaIds: [1, 2],
    ),
    RutaVisita(
      id: 2,
      nombre: 'Ruta Vélez - El Carmen',
      descripcion: 'San Carlos → Los Arrayanes',
      fincaIds: [3, 4],
    ),
    RutaVisita(
      id: 3,
      nombre: 'Ruta Completa',
      descripcion: 'Todas las fincas registradas',
      fincaIds: [1, 2, 3, 4],
    ),
  ];
}

/// Modelo de finca
class Finca {
  final int? id;
  final String nombre;
  final String propietario;
  final String vereda;
  final double hectareas;
  final String variedadCafe;
  final double? latitud;
  final double? longitud;
  final int municipioId;
  final SyncStatus syncStatus;
  final DateTime? fechaRegistro;

  const Finca({
    this.id,
    required this.nombre,
    required this.propietario,
    required this.vereda,
    required this.hectareas,
    required this.variedadCafe,
    this.latitud,
    this.longitud,
    required this.municipioId,
    this.syncStatus = SyncStatus.pendiente,
    this.fechaRegistro,
  });

  String get municipioNombre =>
      Municipio.municipiosPiloto
          .firstWhere((m) => m.id == municipioId,
              orElse: () => const Municipio(
                  id: 0, nombre: 'Desconocido', departamento: '', codigoDane: '', latCenter: 6.1900, lngCenter: -73.6100))
          .nombre;

  Finca copyWith({
    int? id,
    String? nombre,
    String? propietario,
    String? vereda,
    double? hectareas,
    String? variedadCafe,
    double? latitud,
    double? longitud,
    int? municipioId,
    SyncStatus? syncStatus,
    DateTime? fechaRegistro,
  }) {
    return Finca(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      propietario: propietario ?? this.propietario,
      vereda: vereda ?? this.vereda,
      hectareas: hectareas ?? this.hectareas,
      variedadCafe: variedadCafe ?? this.variedadCafe,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      municipioId: municipioId ?? this.municipioId,
      syncStatus: syncStatus ?? this.syncStatus,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
    );
  }
}

/// Modelo de indicador de sostenibilidad
class Indicador {
  final int? id;
  final int fincaId;
  final TipoIndicador tipoIndicador;
  final double valor;
  final String? observaciones;
  final bool sincronizado;
  final DateTime fecha;

  const Indicador({
    this.id,
    required this.fincaId,
    required this.tipoIndicador,
    required this.valor,
    this.observaciones,
    this.sincronizado = false,
    required this.fecha,
  });
}

/// Modelo de visita (indicadores de sostenibilidad por visita a finca)
class Visita {
  final int? id;
  final int fincaId;
  final int tecnicoId;
  final String tecnicoNombre;
  final DateTime fecha;

  // Sección Ambiental
  final double coberturaVegetal; // 0-100%
  final bool tieneFuenteAgua;
  final bool manejoAdecuadoResiduos;
  final bool usoAgroquimicos;
  final bool practicasAgroforestales;

  // Sección Económica
  final double produccionKgAnio;
  final double precioKgCOP;
  final double costoProduccionCOP;
  final bool tieneOtrosIngresos;

  // Sección Social
  final int personasHogar;
  final int menoresEdad;
  final String nivelEducativo;
  final bool seguridadAlimentaria;
  final bool accesoProgramasGobierno;

  final String? observaciones;
  final SyncStatus syncStatus;

  const Visita({
    this.id,
    required this.fincaId,
    required this.tecnicoId,
    required this.tecnicoNombre,
    required this.fecha,
    required this.coberturaVegetal,
    required this.tieneFuenteAgua,
    required this.manejoAdecuadoResiduos,
    required this.usoAgroquimicos,
    required this.practicasAgroforestales,
    required this.produccionKgAnio,
    required this.precioKgCOP,
    required this.costoProduccionCOP,
    required this.tieneOtrosIngresos,
    required this.personasHogar,
    required this.menoresEdad,
    required this.nivelEducativo,
    required this.seguridadAlimentaria,
    required this.accesoProgramasGobierno,
    this.observaciones,
    this.syncStatus = SyncStatus.pendiente,
  });

  double get ingresoBrutoAnual => produccionKgAnio * precioKgCOP;
  double get margenNeto => ingresoBrutoAnual - costoProduccionCOP;

  Visita copyWith({SyncStatus? syncStatus}) {
    return Visita(
      id: id,
      fincaId: fincaId,
      tecnicoId: tecnicoId,
      tecnicoNombre: tecnicoNombre,
      fecha: fecha,
      coberturaVegetal: coberturaVegetal,
      tieneFuenteAgua: tieneFuenteAgua,
      manejoAdecuadoResiduos: manejoAdecuadoResiduos,
      usoAgroquimicos: usoAgroquimicos,
      practicasAgroforestales: practicasAgroforestales,
      produccionKgAnio: produccionKgAnio,
      precioKgCOP: precioKgCOP,
      costoProduccionCOP: costoProduccionCOP,
      tieneOtrosIngresos: tieneOtrosIngresos,
      personasHogar: personasHogar,
      menoresEdad: menoresEdad,
      nivelEducativo: nivelEducativo,
      seguridadAlimentaria: seguridadAlimentaria,
      accesoProgramasGobierno: accesoProgramasGobierno,
      observaciones: observaciones,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}

/// Modelo de usuario del sistema (para gestión admin)
class UsuarioSistema {
  final int id;
  final String nombre;
  final String email;
  final UserRole rol;
  final int? municipioAsignado;
  final bool activo;

  const UsuarioSistema({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    this.municipioAsignado,
    this.activo = true,
  });

  String get municipioNombre => municipioAsignado == null
      ? 'Sin asignar'
      : Municipio.municipiosPiloto
          .firstWhere((m) => m.id == municipioAsignado,
              orElse: () => const Municipio(
                  id: 0, nombre: 'Desconocido', departamento: '', codigoDane: '', latCenter: 6.1900, lngCenter: -73.6100))
          .nombre;
}

/// Datos demo del técnico
const AppUser demoUser = AppUser(
  id: 1,
  nombre: 'Iván Martínez',
  username: 'ivan',
  email: 'ivan.martinez@gobsantander.gov.co',
  rol: UserRole.tecnicoCampo,
  municipioAsignado: 2,
);

const AppUser demoAdmin = AppUser(
  id: 2,
  nombre: 'Laura Pedraza',
  username: 'laura',
  email: 'laura.pedraza@gobsantander.gov.co',
  rol: UserRole.administrador,
);

const AppUser demoConsultor = AppUser(
  id: 3,
  nombre: 'Jorge Cárdenas',
  username: 'jorge',
  email: 'jorge.cardenas@fedecafe.com.co',
  rol: UserRole.consultor,
  municipioAsignado: 4,
);

/// Usuarios demo del sistema
final List<UsuarioSistema> demoUsuarios = [
  const UsuarioSistema(
    id: 1,
    nombre: 'Iván Martínez',
    email: 'ivan.martinez@gobsantander.gov.co',
    rol: UserRole.tecnicoCampo,
    municipioAsignado: 2,
  ),
  const UsuarioSistema(
    id: 2,
    nombre: 'Laura Pedraza',
    email: 'laura.pedraza@gobsantander.gov.co',
    rol: UserRole.administrador,
  ),
  const UsuarioSistema(
    id: 3,
    nombre: 'Jorge Cárdenas',
    email: 'jorge.cardenas@fedecafe.com.co',
    rol: UserRole.consultor,
    municipioAsignado: 4,
  ),
  const UsuarioSistema(
    id: 4,
    nombre: 'Rosa Elena Vargas',
    email: 'rosa.vargas@gobsantander.gov.co',
    rol: UserRole.tecnicoCampo,
    municipioAsignado: 1,
    activo: false,
  ),
];

/// Fincas demo
final List<Finca> demoFincas = [
  Finca(
    id: 1,
    nombre: 'La Esperanza',
    propietario: 'Carlos Ruiz',
    vereda: 'El Palmar',
    hectareas: 3.5,
    variedadCafe: 'Castillo',
    latitud: 6.1833,
    longitud: -73.6167,
    municipioId: 2,
    syncStatus: SyncStatus.subido,
    fechaRegistro: DateTime(2024, 3, 15),
  ),
  Finca(
    id: 2,
    nombre: 'El Paraíso',
    propietario: 'María González',
    vereda: 'La Cumbre',
    hectareas: 5.2,
    variedadCafe: 'Caturra',
    latitud: 6.1750,
    longitud: -73.6250,
    municipioId: 2,
    syncStatus: SyncStatus.pendiente,
    fechaRegistro: DateTime(2024, 4, 2),
  ),
  Finca(
    id: 3,
    nombre: 'San Carlos',
    propietario: 'Pedro Morales',
    vereda: 'Agua Blanca',
    hectareas: 2.8,
    variedadCafe: 'Colombia',
    latitud: 6.1900,
    longitud: -73.6100,
    municipioId: 1,
    syncStatus: SyncStatus.error,
    fechaRegistro: DateTime(2024, 4, 10),
  ),
  Finca(
    id: 4,
    nombre: 'Los Arrayanes',
    propietario: 'Ana Bernal',
    vereda: 'San Isidro',
    hectareas: 4.1,
    variedadCafe: 'Tabi',
    latitud: 6.2100,
    longitud: -73.5900,
    municipioId: 4,
    syncStatus: SyncStatus.subido,
    fechaRegistro: DateTime(2024, 4, 18),
  ),
];

/// Visitas demo
final List<Visita> demoVisitas = [
  Visita(
    id: 1,
    fincaId: 1,
    tecnicoId: 1,
    tecnicoNombre: 'Iván Martínez',
    fecha: DateTime(2024, 3, 20),
    coberturaVegetal: 75,
    tieneFuenteAgua: true,
    manejoAdecuadoResiduos: true,
    usoAgroquimicos: false,
    practicasAgroforestales: true,
    produccionKgAnio: 2800,
    precioKgCOP: 2200,
    costoProduccionCOP: 3500000,
    tieneOtrosIngresos: false,
    personasHogar: 5,
    menoresEdad: 2,
    nivelEducativo: 'Secundaria',
    seguridadAlimentaria: true,
    accesoProgramasGobierno: true,
    observaciones: 'Finca en buen estado. Propietario comprometido con prácticas sostenibles.',
    syncStatus: SyncStatus.subido,
  ),
  Visita(
    id: 2,
    fincaId: 1,
    tecnicoId: 1,
    tecnicoNombre: 'Iván Martínez',
    fecha: DateTime(2024, 5, 10),
    coberturaVegetal: 80,
    tieneFuenteAgua: true,
    manejoAdecuadoResiduos: true,
    usoAgroquimicos: false,
    practicasAgroforestales: true,
    produccionKgAnio: 3100,
    precioKgCOP: 2350,
    costoProduccionCOP: 3800000,
    tieneOtrosIngresos: true,
    personasHogar: 5,
    menoresEdad: 2,
    nivelEducativo: 'Secundaria',
    seguridadAlimentaria: true,
    accesoProgramasGobierno: true,
    observaciones: 'Mejora notable en producción. Se incorporaron 200 matas nuevas.',
    syncStatus: SyncStatus.subido,
  ),
  Visita(
    id: 3,
    fincaId: 2,
    tecnicoId: 1,
    tecnicoNombre: 'Iván Martínez',
    fecha: DateTime(2024, 4, 5),
    coberturaVegetal: 55,
    tieneFuenteAgua: false,
    manejoAdecuadoResiduos: false,
    usoAgroquimicos: true,
    practicasAgroforestales: false,
    produccionKgAnio: 4200,
    precioKgCOP: 2200,
    costoProduccionCOP: 6000000,
    tieneOtrosIngresos: false,
    personasHogar: 7,
    menoresEdad: 3,
    nivelEducativo: 'Primaria',
    seguridadAlimentaria: false,
    accesoProgramasGobierno: false,
    observaciones: 'Se recomienda capacitación en manejo sostenible. Sin acceso a fuente hídrica propia.',
    syncStatus: SyncStatus.pendiente,
  ),
];
