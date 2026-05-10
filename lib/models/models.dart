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
  final String email;
  final UserRole rol;
  final int? municipioAsignado;

  const AppUser({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    this.municipioAsignado,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      email: json['email'] as String,
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

  const Municipio({
    required this.id,
    required this.nombre,
    required this.departamento,
    required this.codigoDane,
  });

  static const List<Municipio> municipiosPiloto = [
    Municipio(id: 1, nombre: 'Vélez', departamento: 'Santander', codigoDane: '68861'),
    Municipio(id: 2, nombre: 'Barbosa', departamento: 'Santander', codigoDane: '68081'),
    Municipio(id: 3, nombre: 'Landázuri', departamento: 'Santander', codigoDane: '68397'),
    Municipio(id: 4, nombre: 'El Carmen de Chucurí', departamento: 'Santander', codigoDane: '68147'),
    Municipio(id: 5, nombre: 'San Vicente de Chucurí', departamento: 'Santander', codigoDane: '68770'),
    Municipio(id: 6, nombre: 'Betulia', departamento: 'Santander', codigoDane: '68092'),
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
                  id: 0, nombre: 'Desconocido', departamento: '', codigoDane: ''))
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

/// Datos demo del técnico
const AppUser demoUser = AppUser(
  id: 1,
  nombre: 'Iván Martínez',
  email: 'ivan.martinez@gobsantander.gov.co',
  rol: UserRole.tecnicoCampo,
  municipioAsignado: 2,
);

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
