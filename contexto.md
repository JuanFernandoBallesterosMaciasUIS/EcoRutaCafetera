# SISTEMA ECORUTA CAFETERA

# EcoRuta Cafetera
## Ingeniería de Software II

**Desarrollado por:** Neider Alirio Piza Basto

CapStone2 para proyecto EcoRuta Cafetera

Universidad Industrial de Santander
8 de mayo de 2026

---

## Índice

1. Introducción .................................................................................................... 2
2. Requisitos Funcionales .................................................................................. 3
3. Requisitos No Funcionales ............................................................................ 4
4. Diagrama de Clases ........................................................................................ 6
5. Diagrama de Casos de Uso ............................................................................ 7
6. Work Breakdown Structure (EDT) y Burndown Chart .......................... 9
   6.1. Work Breakdown Structure (WBS / EDT) ........................................ 9
   6.2. Línea de tiempo del proyecto ................................................................ 13
7. Reporte SCRUM .............................................................................................. 15
   7.1. Actores del proceso SCRUM ................................................................. 15
   7.2. Historias de usuario principales ............................................................ 15
   7.3. Reportes por sprint .................................................................................. 16
        7.3.1. Sprint 1 – Autenticación ............................................................. 16
        7.3.2. Sprint 2 – Módulo de Fincas ....................................................... 17
        7.3.3. Sprint 3 – Módulo de Indicadores ............................................. 17
        7.3.4. Sprint 4 – GPS y Rutas (en progreso) ...................................... 17
        7.3.5. Sprints 5 y 6 – Planificados ....................................................... 18
8. Estándares de Ingeniería ............................................................................... 19
9. Selección de Herramientas ............................................................................ 21
   9.1. Arquitectura general del sistema .......................................................... 21
   9.2. Stack tecnológico ...................................................................................... 21
   9.3. Herramientas del servidor y DevOps ................................................... 22

---

## 1. Introducción

EcoRuta Cafetera es una plataforma digital de censo territorial diseñada para el cordón cafetero del departamento de Santander. La solución integra una aplicación móvil de campo, un módulo de georreferenciación y un servidor de consolidación de datos, articulados en una arquitectura que opera de manera autónoma en zonas sin conectividad y se sincroniza de forma automática al retornar a áreas con red disponible.

La herramienta está orientada a los técnicos agropecuarios de las alcaldías municipales y de la Federación Nacional de Cafeteros, quienes realizan recorridos sistemáticos por fincas ubicadas en terrenos de alta pendiente en municipios como Vélez, Barbosa, Landázuri, El Carmen de Chucurí, San Vicente de Chucurí y Betulia. El producto entrega a la institucionalidad territorial un flujo de datos estructurado, georreferenciado y auditable sobre el estado productivo y de sostenibilidad de las unidades agropecuarias cafeteras.

La plataforma está compuesta por tres componentes integrados: un módulo de captura móvil con funcionamiento offline-first, un motor de geolocalización con trazado de rutas en tiempo real, y una consola web de administración, reportería y visualización cartográfica. El diseño de la interfaz responde a las condiciones reales del trabajo en campo: operación con una sola mano, visibilidad en luz solar directa y compatibilidad con dispositivos de grado industrial resistentes al agua y al polvo.

---

## 2. Requisitos Funcionales

| ID | Nombre | Descripción |
| :--- | :--- | :--- |
| **RF-01** | Registro de finca cafetera | El sistema permitirá registrar los datos básicos de cada finca: nombre, propietario, municipio, vereda, coordenadas GPS y variedad de café cultivada. |
| **RF-02** | Captura de indicadores de sostenibilidad | El técnico podrá registrar indicadores ambientales, económicos y sociales de cada finca mediante formularios digitales configurables. |
| **RF-03** | Módulo GPS offline | La aplicación trazará la ruta del técnico en tiempo real y registrará coordenadas GPS sin requerir conexión a internet, almacenando los datos localmente en el dispositivo. |
| **RF-04** | Sincronización automática | Al detectar una red WiFi o datos móviles estable, la aplicación sincronizará automáticamente todos los registros pendientes con el servidor central en la nube. |
| **RF-05** | Gestión de usuarios y roles | El sistema diferenciará tres roles: Administrador (configuración y reportes), Técnico de campo (captura de datos) y Consultor (solo lectura). Cada rol tendrá permisos específicos. |
| **RF-06** | Visualización cartográfica | El administrador podrá visualizar en un mapa digital las fincas registradas, con filtros por municipio, variedad y estado de sincronización. |
| **RF-07** | Generación de reportes | El sistema generará reportes en formato PDF y Excel con los indicadores consolidados por municipio, por vereda o por finca, exportables para la Gobernación y Fedecafe. |
| **RF-08** | Historial de visitas | Cada finca tendrá un historial cronológico de las visitas realizadas por los técnicos, con fecha, técnico responsable e indicadores capturados en cada visita. |
| **RF-09** | Modo de edición offline | El técnico podrá crear, editar y eliminar registros sin conexión. Los cambios se marcarán como "pendientes de sincronización" hasta que haya red disponible. |
| **RF-10** | Notificaciones de sincronización | La app notificará al técnico cuando la sincronización haya sido exitosa, cuando existan conflictos de datos o cuando un registro haya sido rechazado por el servidor. |

---

## 3. Requisitos No Funcionales

| ID | Atributo | Descripción |
| :--- | :--- | :--- |
| **RNF-01** | Rendimiento | La aplicación móvil debe responder a las interacciones del usuario en menos de 2 segundos, incluso en modo offline con un mínimo de 500 registros almacenados localmente. |
| **RNF-02** | Disponibilidad | El servidor de sincronización en la nube deberá mantener una disponibilidad del 99,5 % (SLA). Los tiempos de mantenimiento programado serán notificados con 24 horas de antelación. |
| **RNF-03** | Seguridad | Todos los datos en tránsito serán cifrados con TLS 1.3. Los datos en reposo, tanto en el dispositivo móvil como en el servidor, serán cifrados con AES-256. Se requerirá autenticación con usuario y contraseña para acceder a la app. |
| **RNF-04** | Usabilidad | La interfaz deberá ser operable con una sola mano y funcionar correctamente con guantes de trabajo. El tamaño mínimo de los elementos interactivos será de 48×48 píxeles. Se cumplirá con WCAG 2.1 nivel AA. |
| **RNF-05** | Portabilidad | La aplicación móvil deberá ser compatible con Android 12 o superior. Los dispositivos de campo tendrán resolución mínima de 1280×800 px y pantalla de al menos 10 pulgadas. |
| **RNF-06** | Mantenibilidad | El código fuente estará documentado según el estándar DartDoc (Flutter). La cobertura de pruebas automatizadas deberá ser igual o superior al 75 %. El repositorio se gestionará en Git con ramas por funcionalidad. |
| **RNF-07** | Escalabilidad | La arquitectura del servidor deberá soportar la incorporación de nuevos departamentos cafeteros (Huila, Nariño, Cauca) sin cambios en el núcleo del sistema, mediante configuración de nuevas entidades territoriales. |
| **RNF-08** | Conectividad | La app deberá funcionar en zonas con cobertura de señal GNSS (GPS + GLONASS) con precisión sub-métrica. En ausencia total de señal, el sistema almacenará la última posición conocida con marca de tiempo. |
| **RNF-09** | Privacidad | El tratamiento de datos personales de propietarios de fincas se regirá por la Ley 1581 de 2012 (Habeas Data). El consentimiento informado de cada propietario se capturará digitalmente antes del registro de su predio. |
| **RNF-10** | Interoperabilidad | El sistema exportará datos en formatos estándar GIS (GeoJSON, Shapefile) compatibles con IGAC y con el sistema de información de Fedecafe. La API REST usará OAuth 2.0 y estará documentada con OpenAPI 3.0. |

---

## 4. Diagrama de Clases

El siguiente diagrama describe la estructura estática del sistema. Esta representación es la base para el diseño de la base de datos y la arquitectura del módulo de sincronización offline.

*(Figura 1: Diagrama de Clases de EcoRuta Cafetera - Se incluye esquema relacional con entidades: Finca, Municipio, Indicador, Usuario, SincronizadorCloud, RolEnum, TipoIndicador).*

### Descripción de entidades principales

*   **Finca:** Entidad central del sistema. Representa una unidad productiva cafetera. Se vincula a un Municipio (N:1) y puede tener múltiples Indicadores (1:N).
*   **Municipio:** Catálogo de los municipios cafeteros priorizados de Santander. Permite filtrar y agrupar fincas por territorio.
*   **Indicador:** Registra cada medición de sostenibilidad capturada en una visita. Incluye el atributo "sincronizado" para gestionar el estado offline.
*   **Usuario:** Gestiona los tres roles del sistema (Administrador, Técnico de Campo, Consultor) con sus respectivos permisos.
*   **SincronizadorCloud:** Servicio de infraestructura que gestiona la cola de registros pendientes, detecta la red disponible y resuelve conflictos de datos entre el dispositivo y el servidor.

---

## 5. Diagrama de Casos de Uso

El diagrama de casos de uso representa las interacciones entre los actores del sistema y las funcionalidades que este les ofrece.

*(Figura 2: Diagrama de Casos de Uso de EcoRuta Cafetera - Muestra a los actores Técnico de Campo, Administrador, Consultor interactuando con el sistema local y Servidor Nube AWS).*

### Descripción de los casos de uso principales

| ID | Nombre | Actor | Descripción |
| :--- | :--- | :--- | :--- |
| **UC-01** | Registrar Finca | Técnico de Campo | El técnico captura los datos identificativos de una nueva finca cafetera, incluyendo coordenadas GPS y datos del propietario. |
| **UC-02** | Capturar Indicadores | Técnico de Campo | Registra los indicadores de sostenibilidad (ambiental, económico, social) de una finca ya registrada durante una visita. |
| **UC-03** | Trazar Ruta GPS Offline | Técnico de Campo | El sistema registra automáticamente la ruta del técnico en tiempo real usando GPS del dispositivo, sin necesidad de conexión. |
| **UC-04** | Sincronizar Datos | Técnico de Campo | Al detectar red estable, la app envía los registros pendientes al servidor y recibe actualizaciones del catálogo de fincas. |
| **UC-05** | Ver Mapa de Fincas | Administrador | Visualización cartográfica de todas las fincas registradas con filtros por municipio, vereda y estado de sincronización. |
| **UC-06** | Generar Reporte | Administrador | Produce reportes PDF/Excel de indicadores consolidados por municipio para entrega a la Gobernación y Fedecafe. |
| **UC-07** | Gestionar Usuarios | Administrador | Creación, edición y desactivación de cuentas de usuarios. Asignación de roles y municipios de trabajo. |
| **UC-08** | Consultar Historial | Consultor / Admin | Revisión del historial cronológico de visitas de una finca específica con todos los indicadores registrados. |
| **UC-09** | Autenticar Usuario | Todos los actores | Ingreso al sistema mediante usuario y contraseña. Obligatorio para acceder a cualquier otro caso de uso. |

---

## 6. Work Breakdown Structure (EDT) y Burndown Chart

### 6.1. Work Breakdown Structure (WBS / EDT)

El WBS desglosa el proyecto en paquetes de trabajo entregables organizados por sprint. La estimación de tiempo se realiza en dos niveles: **por actividad** (tareas individuales asignables a un desarrollador) y **por producto final** (entregable funcional de cada sprint). La convención de identificadores es `P.M.T`: P = proyecto, M = módulo, T = tarea.

#### 1.0 — Preparación y configuración del proyecto

| ID | Actividad | Descripción | Sprint | Días |
| :--- | :--- | :--- | :--- | :--- |
| 1.0.1 | Repositorio Git | Crear repo en GitHub con estructura Flutter (`lib/`, `test/`, `assets/`), ramas `main`/`dev`/`feature`, `.gitignore` y README. | S0 | 1 |
| 1.0.2 | Entorno Flutter | Instalación Flutter 3.22, Android SDK, emuladores en todos los equipos. Archivo `pubspec.yaml` base con dependencias iniciales. | S0 | 1 |
| 1.0.3 | Pipeline CI/CD | GitHub Actions: `flutter analyze` + `flutter test` en cada *push* a `main`. Badge de estado en README. | S0 | 1 |
| 1.0.4 | Tablero SCRUM | Trello: columnas Backlog / Sprint Activo / En Progreso / En Revisión / Hecho. Tarjetas de todos los RF y RNF creadas. | S0 | 0.5 |
| **Producto final S0:** | *Entorno de desarrollo configurado y operativo* | | | **3.5** |

#### 1.1 — Módulo de Autenticación (RF-01, RF-02)

| ID | Actividad | Descripción | Sprint | Días |
| :--- | :--- | :--- | :--- | :--- |
| 1.1.1 | Modelo Usuario | Clase `Usuario` en Dart con campos id, nombre, email, rol (enum), municipioAsignado. Serialización JSON para API. | S1 | 1 |
| 1.1.2 | Pantalla de Login | Widget `LoginScreen`: campos usuario/contraseña, validación *inline*, indicador de carga, tema de la app. | S1 | 2 |
| 1.1.3 | Servicio autenticación | `AuthService`: login online (POST `/api/auth/login`), token en Android Keystore via `flutter_secure_storage`, login offline con credenciales cacheadas. | S1 | 2 |
| 1.1.4 | Guard de roles | Middleware de navegación (`go_router`) que redirige al panel según el rol. Pruebas unitarias de los 3 roles. | S1 | 1 |
| 1.1.5 | Indicador offline | Widget en el *header* que detecta conectividad con `connectivity_plus` y muestra el estado visual. | S1 | 1 |
| **Producto final S1:** | *Login funcional online/offline con control de roles* | | | **7** |

#### 1.2 — Módulo de Fincas (RF-03, RF-04)

| ID | Actividad | Descripción | Sprint | Días |
| :--- | :--- | :--- | :--- | :--- |
| 1.2.1 | BD SQLite cifrada | Configuración de `sqflite_sqlcipher` (AES-256), tabla `fincas` con índices en `municipio_id` y `nombre`. Clase `FincaDao`. | S2 | 2 |
| 1.2.2 | Formulario finca | `FincaFormScreen`: campos de texto, dropdown municipios (6 piloto), dropdown variedad café, campo foto con cámara. | S2 | 3 |
| 1.2.3 | Captura GPS | Botón «Capturar ubicación» con `geolocator`. Permiso `ACCESS_FINE_LOCATION`. Indicador cuando el GPS no está disponible. | S2 | 1.5 |
| 1.2.4 | Listado y búsqueda | `FincaListScreen` con `ListView`, búsqueda reactiva en SQLite local, `FincaCard` con estado de sincronización y vista de estado vacío. | S2 | 2 |
| 1.2.5 | Consentimiento | Pantalla de consentimiento (Ley 1581/2012) obligatoria antes del formulario. Captura foto de firma del propietario. | S2 | 1.5 |
| **Producto final S2:** | *CRUD de fincas 100 % offline con GPS y consentimiento* | | | **10** |

#### 1.3 — Módulo de Indicadores (RF-05, RF-06)

| ID | Actividad | Descripción | Sprint | Días |
| :--- | :--- | :--- | :--- | :--- |
| 1.3.1 | Modelo Indicador | Clase `Indicador` en Dart con campos ambiental, económico, social, observaciones, `sincronizado` (bool) y `fechaCreacion`. Tabla SQLite. | S3 | 1.5 |
| 1.3.2 | Formulario visita | `VisitaFormScreen`: secciones colapsables Ambiental (toggles, porcentajes), Económico (valores en COP), Social (toggles). Área táctil 56dp para uso con guantes. | S3 | 3 |
| 1.3.3 | Historial de visitas | `HistorialTab` en `FincaDetailScreen`. Lista cronológica desde SQLite. Pantalla de detalle en modo solo lectura. | S3 | 2 |
| 1.3.4 | Pruebas unitarias | Cobertura ≥75 % en `IndicadorRepository` e `IndicadorValidador`. Casos: valores límite, campos vacíos, indicadores sin GPS. | S3 | 1.5 |
| **Producto final S3:** | *Captura completa de indicadores e historial de visitas* | | | **8** |

#### 1.4 — Módulo GPS y Rutas (RF-07, RF-08)

| ID | Actividad | Descripción | Sprint | Días |
| :--- | :--- | :--- | :--- | :--- |
| 1.4.1 | Servicio ruta GPS | `RutaService` en Isolate dedicado. Un punto GNSS cada 30 s en cola SQLite. Distancia acumulada con fórmula de Haversine. | S4 | 3 |
| 1.4.2 | Tiles mapa offline | Descarga de tiles MBTiles de los 6 municipios piloto. Integración con `flutter_map` + `flutter_map_mbtiles`. | S4 | 2.5 |
| 1.4.3 | Pantalla mapa ruta | `MapaRutaScreen`: punto azul (posición actual), *polyline* verde (ruta), barra de estado con tiempo, distancia y puntos GPS, controles inicio/pausa/fin. | S4 | 2.5 |
| 1.4.4 | Mapa fincas Admin | `MapaFincasScreen` con *MarkerLayer*, *clustering*, *popup* de finca y filtro por municipio. Solo rol ADMIN. | S4 | 2 |
| **Producto final S4:** | *Ruta GPS offline trazada y mapa territorial de fincas* | | | **10** |

#### 1.5 — Módulo de Sincronización (RF-09, RF-10)

| ID | Actividad | Descripción | Sprint | Días |
| :--- | :--- | :--- | :--- | :--- |
| 1.5.1 | Cola sincronización | Tabla `sync_queue` FIFO en SQLite con estados PENDIENTE / SUBIENDO / SUBIDO / ERROR. Se reanuda tras cierre de la app. | S5 | 2.5 |
| 1.5.2 | Sync automática | *Listener* de red con `connectivity_plus`. `flutter_background_service` procesa la cola en lotes de 50 registros al detectar conexión estable. | S5 | 3 |
| 1.5.3 | Notificaciones | `flutter_local_notifications`: notificación de progreso («Subiendo X registros») y resultado («Completado» o «Error en Y registros»). | S5 | 1.5 |
| 1.5.4 | Dashboard pendientes | Tarjeta de resumen en el panel principal. `PendientesScreen` con lista detallada por estado y botón de sincronización manual. | S5 | 1.5 |
| 1.5.5 | Pruebas integración | Flujo completo: crear 50 registros offline → conectar → verificar 100 % subidos. Simulación de error HTTP 422 en el servidor. | S5 | 2 |
| **Producto final S5:** | *Sincronización automática y manual con 0 % pérdida de datos* | | | **10.5** |

#### 1.6 — Reportes y Gestión de Usuarios (RF-11, RF-12)

| ID | Actividad | Descripción | Sprint | Días |
| :--- | :--- | :--- | :--- | :--- |
| 1.6.1 | Pantalla reportes | `ReportesScreen`: filtros municipio + rango de fechas + tipo (PDF/Excel). Indicador de carga mientras el servidor genera el archivo. | S6 | 2 |
| 1.6.2 | Descarga y compartir | dio para descarga, `share_plus` para compartir por WhatsApp, correo o imprimir desde el menú nativo del SO. | S6 | 1.5 |
| 1.6.3 | Gestión usuarios | `UsuariosScreen`: listado con estado activo/inactivo, formulario de creación/edición, modal de confirmación de desactivación. Solo ADMIN. | S6 | 2 |
| 1.6.4 | Pruebas en campo | Pruebas de usabilidad con 5 técnicos municipales. Tasa de éxito en tareas clave ≥90 %. Ajustes de UI según retroalimentación. | S6 | 2 |
| 1.6.5 | Entrega final | APK *release* firmado, documentación DartDoc completa, informe final para la Gobernación y el SGR. | S6 | 1 |
| **Producto final S6:** | *APK de producción entregado con documentación completa* | | | **8.5** |

| **Total estimado** | **— días hábiles de desarrollo** | | | **57.5 días** |
| :--- | :--- | :--- | :--- | :--- |

### 6.2. Línea de tiempo del proyecto

El proyecto se divide en **6 sprints de 3 semanas cada uno** (90 días hábiles en total), más un sprint cero de preparación. La siguiente línea de tiempo muestra los hitos principales y el estado de avance al corte de este reporte.

*(Figura 3: Línea de tiempo del proyecto EcoRuta Cafetera - 90 días hábiles, 6 sprints. Muestra S0 Prep., S1 Autent., S2 Fincas, S3 Indicad. completados; S4 GPS en curso; S5 Sync y S6 Report. pendientes).*

---

## 7. Reporte SCRUM

**Cuadro 4: Resumen de velocidad por sprint – EcoRuta Cafetera**

| Sprint | Módulo | RFs | SP Plan. | SP Comp. | Días | Estado |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | Autenticación | RF-01, RF-02 | 40 | 38 | 15 | **Completado*** |
| 2 | Fincas | RF-03, RF-04 | 52 | 52 | 15 | **Completado** |
| 3 | Indicadores | RF-05, RF-06 | 48 | 45 | 15 | **Completado*** |
| 4 | GPS y Rutas | RF-07, RF-08 | 55 | 50 | 15 | **En progreso** |
| 5 | Sincronización | RF-09, RF-10 | 50 | — | 15 | Pendiente |
| 6 | Reportes y Admin | RF-11, RF-12 | 44 | — | 15 | Pendiente |
| **Total** | | | **289** | **185+** | **90** | |

*\*Completado con arrastre: 2–3 SP pasan al sprint siguiente por bloqueo técnico menor.*

### 7.1. Actores del proceso SCRUM

| Rol | Responsable | Responsabilidades |
| :--- | :--- | :--- |
| **Product Owner** | Investigador Principal / Gobernación de Santander | Define y prioriza el backlog. Acepta o rechaza entregables al cierre de cada sprint. Representa los intereses de Fedecafe y las alcaldías. |
| **Scrum Master** | Neider Alirio Piza Basto | Facilita ceremonias SCRUM. Elimina impedimentos técnicos. Actualiza el tablero Trello diariamente. |
| **Dev Flutter** | Desarrollador principal | Implementa RF y RNF. Escribe pruebas unitarias y de widget. Realiza code review en pull requests. |
| **Dev Backend** | Desarrollador Node.js | API REST, servidor AWS, generación de reportes PDF/Excel, base de datos PostgreSQL. |
| **QA / GIS** | Especialista GIS | Pruebas en campo con dispositivos reales. Generación de tiles MBTiles. Validación GeoJSON/Shapefile. |

### 7.2. Historias de usuario principales

| ID | Actor | Historia de usuario |
| :--- | :--- | :--- |
| HU-01 | Técnico de campo | *“Como técnico de campo, quiero iniciar sesión con mi usuario y contraseña para acceder a las funciones de la app según mi rol, incluso cuando estoy sin internet en la finca.”* |
| HU-02 | Técnico de campo | *“Como técnico de campo, quiero registrar una nueva finca con su ubicación GPS para poder asociarle indicadores de sostenibilidad en visitas futuras, aunque no tenga señal móvil.”* |
| HU-03 | Técnico de campo | *“Como técnico de campo, quiero que la app registre mi ruta de desplazamiento automáticamente mientras visito fincas en terrenos de alta pendiente, para tener evidencia del recorrido realizado.”* |
| HU-04 | Técnico de campo | *“Como técnico de campo, quiero que todos los registros capturados sin internet se suban automáticamente cuando llegue al casco urbano, sin que yo tenga que hacer nada adicional.”* |
| HU-05 | Administrador | *“Como administrador, quiero ver en un mapa todas las fincas registradas con sus coordenadas para tener una visión territorial del censo cafetero del departamento.”* |
| HU-06 | Administrador | *“Como administrador, quiero generar un reporte PDF con los indicadores consolidados por municipio para entregarlo a la Gobernación de Santander y a Fedecafe.”* |
| HU-07 | Propietario de finca | *“Como propietario de finca, quiero que el técnico me muestre y me explique el consentimiento informado antes de registrar mis datos, para saber cómo se usará mi información.”* |

### 7.3. Reportes por sprint

#### 7.3.1. Sprint 1 – Autenticación

**Sprint 1: Autenticación | RFs: RF-01, RF-02 | 40 SP planeados / 38 completados**
*   **Objetivo:** Login funcional con sesión persistente offline y control de roles (ADMIN, TECNICO, CONSULTOR).
*   **Resultado:** **COMPLETADO con arrastre.** Los 3 roles redirigen correctamente. Token almacenado en Android Keystore.
*   **Historias:** HU-01 completada.
*   **Arrastre:** 2 SP: indicador visual de modo offline en el header pasa al Sprint 2.
*   **Problemas:**
    *   **P1:** `flutter_secure_storage` arrojaba excepción en Android 12 con encriptación de hardware. *Solución:* flag `resetOnError: true` y migración a Android Keystore directo.
    *   **P2:** Token offline expiraba antes de llegar al municipio (10h sin internet). *Solución:* validez ampliada a 7 días con renovación automática en cada sincronización.
*   **Demo:** Login en Samsung Galaxy A33 con modo avión activado. Tres roles verificados con credenciales de prueba.

#### 7.3.2. Sprint 2 – Módulo de Fincas

**Sprint 2: Fincas | RFs: RF-03, RF-04 | 52 SP planeados / 52 completados**
*   **Objetivo:** CRUD completo de fincas 100 % offline con captura GPS y consentimiento informado (Ley 1581/2012).
*   **Resultado:** **COMPLETADO.** Formulario, listado con búsqueda reactiva y captura GPS funcionando en campo.
*   **Historias:** HU-02 completada. HU-07 (consentimiento) completada.
*   **Problemas:**
    *   **P1:** GPS tardaba >20s en zonas montañosas. *Solución:* activar GLONASS en `LocationSettings`, mostrar indicador de espera.
    *   **P2:** Fotos de finca consumían >4 MB cada una. *Solución:* compresión JPEG 85 % con `flutter_image_compress`.
*   **Demo:** Registro de finca “La Esperanza” en Barbosa con coordenadas GPS verificadas. Búsqueda offline por nombre.

#### 7.3.3. Sprint 3 – Módulo de Indicadores

**Sprint 3: Indicadores | RFs: RF-05, RF-06 | 48 SP planeados / 45 completados**
*   **Objetivo:** Captura completa de indicadores de sostenibilidad e historial de visitas por finca.
*   **Resultado:** **COMPLETADO con arrastre.** Formulario de visita operativo con secciones Ambiental, Económico y Social.
*   **Historias:** HU-03 parcial (captura completada, GPS de ruta pasa a Sprint 4).
*   **Arrastre:** 3 SP: pruebas unitarias de `IndicadorValidador` pasan al Sprint 4.
*   **Problemas:**
    *   **P1:** Toggle switches no respondían con guantes de látex. *Solución:* área táctil ampliada a 56dp y mayor espaciado entre toggles.
    *   **P2:** Valores en COP sin separador de miles. *Solución:* formateo automático con `intl` al perder el foco.
*   **Demo:** Captura de visita en finca de El Carmen de Chucurí. Historial con 3 visitas previas visible offline.

#### 7.3.4. Sprint 4 – GPS y Rutas (en progreso)

**Sprint 4: GPS y Rutas | RFs: RF-07, RF-08 | 55 SP planeados / 50 completados (día 12)**
*   **Objetivo:** Trazado de ruta GPS offline en tiempo real y mapa de fincas para el Administrador.
*   **Resultado:** **EN PROGRESO.** Ruta GPS funcional. Pendiente: mapa de fincas Admin (5 SP, días 13–15).
*   **Historias:** HU-03 completada (ruta GPS). HU-05 en curso (mapa fincas Admin).
*   **Problema activo:** **P1 (ABIERTO):** Tiles MBTiles de San Vicente de Chucurí presentan artefactos visuales a zoom >15. Posible corrupción en generación con QGIS 3.34. En investigación.
*   **Demo parcial:** Ruta GPS trazada en recorrido de 3 km en terreno de alta pendiente en modo avión.

#### 7.3.5. Sprints 5 y 6 – Planificados

| Sprint | Módulo | Objetivo e historias | Riesgo identificado |
| :--- | :--- | :--- | :--- |
| 5 | Sincronización | Cola FIFO, sync automática background, notificaciones, dashboard. HU-04. | Conflictos si un registro fue editado en 2 dispositivos. Estrategia: last-write-wins con timestamp del servidor. |
| 6 | Reportes y Admin | Reportes PDF/Excel, gestión de usuarios, APK firmado. HU-05, HU-06. | Generación de Shapefile puede exceder tiempo de respuesta. Solución: proceso asíncrono con notificación. |

---

## 8. Estándares de Ingeniería

| Estándar | Área de aplicación | Aplicación en EcoRuta Cafetera |
| :--- | :--- | :--- |
| **ISO/IEC 25010:2011** (SQuaRE) | Calidad del producto | Los 10 RNF están mapeados a las 8 características del estándar: funcionalidad, eficiencia, compatibilidad, usabilidad, fiabilidad, seguridad, mantenibilidad y portabilidad. Las métricas de cada RNF son los criterios de verificación. |
| **IEEE 830 / ISO 29148** | Especificación de requisitos | El documento de requisitos usa identificadores únicos (RF-XX, RNF-XX), criterios DADO/CUANDO/ENTONCES trazables, prioridad por sprint e historia de usuario como base de cada RF. |
| **Git Flow** | Control de versiones | Ramas: `main` (producción), `dev` (integración), `feature/RF-XX` (desarrollo), `hotfix/` (urgentes). Pull Requests obligatorios con al menos 1 code review antes de merge a `dev`. |
| **Dart / Flutter Style Guide** (Google) | Estilo de código | `lowerCamelCase` para variables y funciones, `UpperCamelCase` para clases, `snake_case` para archivos. Análisis estático con `flutter analyze` integrado en el pipeline CI/CD. |
| **DartDoc** | Documentación | Todos los métodos públicos documentados con `///`. Generación automática con `dart doc` publicada en GitHub Pages. Ningún método público sin documentación puede mergear a `main`. |
| **OWASP Mobile Top 10** | Seguridad móvil | Los 10 riesgos revisados en la auditoría de seguridad del Sprint 4. Controles: almacenamiento cifrado (RNF-03), SSL pinning (RNF-04), validación de entradas, sin logs de datos sensibles. |
| **WCAG 2.1 Nivel AA** | Accesibilidad | Contraste mínimo 4:5:1, elementos táctiles ≥48dp, compatibilidad con TalkBack. Modo de alto contraste para uso bajo luz solar directa en campo (RNF-04, RNF-05). |
| **Ley 1581/2012** (Habeas Data) | Privacidad | Consentimiento informado obligatorio antes del registro de finca. Captura de firma del propietario. Política de datos accesible desde la app. No se comparten datos con terceros (RNF-09). |
| **OAuth 2.0 / OpenAPI 3.0** | API y autenticación | La API REST implementa OAuth 2.0 con tokens JWT. Especificación documentada en OpenAPI 3.0, accesible vía Swagger UI en el servidor de desarrollo (RNF-10). |
| **Conventional Commits** | Mensajes de commit | Formato: `tipo(alcance): descripción`. Tipos: `feat`, `fix`, `docs`, `test`, `refactor`. Ejemplo: `feat(RF-03): agregar captura GPS con geolocator`. |

---

## 9. Selección de Herramientas

### 9.1. Arquitectura general del sistema

*(Figura 4: Arquitectura general del sistema EcoRuta Cafetera)*
*   **Dispositivo móvil:** App Flutter (Android 12+) -> GPS / GNSS (Isolate) | Tiles MBTiles (`flutter_map`) -> SQLite + SQLCipher (offline-first) -> Cola FIFO `sync_queue`.
*   **Conexión:** HTTPS / TLS 1.3
*   **Servidor AWS (Colombia):** API REST Node.js + Express -> PostgreSQL 16 + PostGIS | AWS S3 (reportes + tiles).

### 9.2. Stack tecnológico

**Cuadro 9: Herramienta principal – Flutter 3.x**

| Flutter 3.x (Dart) – Framework de desarrollo móvil |
| :--- |
| **Versión** Flutter 3.22 / Dart 3.4 |
| **Justificación** (1) Compilación nativa ARM: garantiza respuesta <2s requerida por RNF-01. (2) Un solo código base para Android (e iOS en fases futuras). (3) Soporte offline maduro con sqflite, geolocator y background services. (4) Sin costos de licencia: crítico para un proyecto financiado con recursos SGR. |
| **Descartado** React Native: mayor consumo de batería (puente JavaScript). Kotlin nativo: solo Android, mayor tiempo de desarrollo. |

| Dependencia Flutter | Versión | Propósito – RF/RNF cubierto |
| :--- | :--- | :--- |
| `sqflite` | ^2.3.3 | Base de datos SQLite local para almacenamiento offline de fincas, indicadores y cola de sincronización. RF-01 al RF-10. |
| `sqflite_sqlcipher` | ^2.2.1 | Cifrado AES-256 de la BD local. Misma API que sqflite. RNF-03. |
| `flutter_secure_storage` | ^9.2.2 | Tokens JWT en Android Keystore / iOS Keychain. Evita texto plano. RNF-03, RF-01. |
| `geolocator` | ^12.0.0 | GPS + GNSS (GPS + GLONASS), permisos Android 12+. RF-03, RF-07. |
| `flutter_map` | ^7.0.2 | Mapa interactivo OpenStreetMap, sin costos por petición vs. Google Maps. RF-07, RF-08. |
| `flutter_map_mbtiles` | ^0.3.0 | Tiles desde archivos MBTiles locales: mapa 100 % offline. RF-07. |
| `flutter_map_marker_cluster` | ^1.3.2 | Agrupación de marcadores de fincas en el mapa Admin. RF-08. |
| `connectivity_plus` | ^6.1.1 | Detecta WiFi/datos para disparar sincronización automática. RF-04, RF-09. |
| `flutter_background_service` | ^5.0.10 | Sincronización en background aunque la app esté minimizada. RF-09. |
| `flutter_local_notifications` | ^17.2.4 | Notificaciones de progreso y resultado de sincronización. RF-10. |
| `dio` | ^5.7.0 | Cliente HTTP con interceptores JWT, reintentos y descarga de archivos. RF-11. |
| `share_plus` | ^10.1.2 | Menú nativo para compartir PDF/Excel generados. RF-11. |
| `image_picker` | ^1.1.2 | Cámara para foto de finca y firma de consentimiento. RF-03, RNF-09. |
| `flutter_image_compress` | ^2.3.0 | Compresión JPEG 85 % antes de guardar en SQLite. RNF-12. |
| `intl` | ^0.19.0 | Formato de números COP y fechas dd/MM/yyyy. RF-05. |
| `go_router` | ^14.6.1 | Navegación declarativa con guard de roles. RF-02. |
| `riverpod` | ^2.6.1 | Gestión de estado reactivo. Streams de BD actualizan la UI en tiempo real. |
| `mockito` + `flutter_test` | SDK | Pruebas unitarias, de widget e integración. RNF-06. |

### 9.3. Herramientas del servidor y DevOps

| Herramienta | Versión | Propósito y justificación |
| :--- | :--- | :--- |
| **Node.js + Express** | 22 LTS | API REST del servidor. Rendimiento óptimo para I/O asíncrono con múltiples dispositivos sincronizando simultáneamente. |
| **PostgreSQL 16 + PostGIS** | 16.x | BD central con soporte nativo GeoJSON para coordenadas GPS y exportación Shapefile (RNF-10). |
| **AWS EC2 + RDS** | — | Infraestructura cloud. EC2 t3.medium para el servidor, RDS con réplica de lectura. SLA 99,5 % (RNF-07). |
| **pdfmake + ExcelJS** | — | Generación de reportes PDF y .xlsx en el servidor. ExcelJS soporta tablas formateadas para análisis por la Gobernación (RF-11). |
| **QGIS 3.34** | 3.34 | Generación de tiles MBTiles de los 6 municipios piloto. Exportación GeoJSON/Shapefile para validación IGAC (RNF-10). |
| **Git + GitHub** | — | Control de versiones con Git Flow. Pipeline CI/CD con GitHub Actions: analyze + test en cada push, APK release en cada merge a main. |
| **Trello** | — | Tablero SCRUM con columnas Backlog / Sprint Activo / En Progreso / En Revisión / Hecho. Acceso del Product Owner para visibilidad del avance. |
| **Android Studio / VS Code** | — | Android Studio para depuración en dispositivo real (Samsung Galaxy A33, Lenovo Tab M10). VS Code con extensión Flutter para desarrollo diario. |
| **Firebase Crashlytics** | — | Monitoreo de crashes en producción. Reportes automáticos con stack trace para detectar errores en condiciones de campo reales. |
| **AWS CloudWatch** | — | Monitoreo del servidor. Alertas si disponibilidad cae bajo 99,5 %. Dashboard de sincronizaciones exitosas y latencia (RNF-07). |