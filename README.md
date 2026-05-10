# EcoRuta Cafetera 🌿☕

**Sistema Territorial de Censo Cafetero - Santander, Colombia**

Aplicación móvil y web Flutter para el registro georreferenciado de fincas cafeteras en los municipios de Vélez, Barbosa, Landázuri, El Carmen de Chucurí, San Vicente de Chucurí y Betulia.

**Desarrollado por:** Neider Alirio Piza Basto  
**Asignatura:** Ingeniería de Software II - UIS  
**Versión:** 2.4.0

---

## 🗂 Estructura del proyecto

```
lib/
├── main.dart                 # Entry point - ProviderScope + MaterialApp.router
├── theme/
│   └── app_theme.dart        # Material 3 color system + typography (Hanken Grotesk)
├── models/
│   └── models.dart           # Finca, Usuario, Indicador, Municipio, enums
├── services/
│   └── providers.dart        # Riverpod providers (auth, fincas, connectivity)
├── widgets/
│   └── widgets.dart          # Design system: FincaCard, QuickActionButton, etc.
├── screens/
│   ├── splash_screen.dart    # Pantalla de inicio (mobile + desktop)
│   ├── login_screen.dart     # Autenticación (RF-01, RF-02)
│   ├── register_screen.dart  # Registro de usuarios (RF-05)
│   ├── home_screen.dart      # Panel técnico con navegación adaptativa
│   └── nueva_finca_screen.dart # Formulario de registro de finca (RF-01, RF-03, RNF-09)
└── utils/
    └── app_router.dart       # go_router con guard de roles
```

## 🏗 Arquitectura

```
UI Layer (Screens) 
    ↓
State (Riverpod Providers)
    ↓
Domain (Models, Business Logic)
    ↓
[Future] Data Layer (SQLite + API REST)
```

## 📦 Stack tecnológico implementado

| Dependencia | Versión | Propósito |
|---|---|---|
| `flutter_riverpod` | ^2.6.1 | Gestión de estado reactivo |
| `go_router` | ^14.6.1 | Navegación declarativa con guards de rol |
| `google_fonts` | ^6.2.1 | Hanken Grotesk (diseño system) |
| `flutter_animate` | ^4.5.0 | Animaciones fluidas y micro-interactions |
| `connectivity_plus` | ^6.1.1 | Detección de red (online/offline) |

## 🚀 Cómo ejecutar

```bash
# 1. Instalar dependencias
flutter pub get

# 2. Ejecutar en modo debug
flutter run -d chrome        # Web
flutter run -d android       # Android
flutter run                  # Dispositivo conectado

# 3. Verificar calidad de código
flutter analyze

# 4. Ejecutar pruebas
flutter test
```

## 🎨 Sistema de diseño

Paleta Material 3 basada en el ecosistema cafetero de Santander:

- **Primary** `#00450D` — Verde bosque profundo  
- **Secondary** `#006E1C` — Verde vibrante  
- **Tertiary** `#4D352B` — Tierra cálida (café)  
- **Fuente:** Hanken Grotesk (Google Fonts)

## 📱 Responsividad

| Breakpoint | Layout |
|---|---|
| < 700px | Mobile - NavigationBar inferior |
| 700–900px | Tablet - Layout de dos columnas |
| > 900px | Desktop - NavigationRail lateral |

## 📋 Requisitos funcionales implementados

- ✅ **RF-01** Registro de finca cafetera (formulario offline)
- ✅ **RF-02** Autenticación con roles (ADMIN, TÉCNICO, CONSULTOR)
- ✅ **RF-05** Gestión de usuarios y roles
- 🔄 **RF-03** Módulo GPS offline (Sprint 4 - en progreso)
- 🔄 **RF-04** Sincronización automática (Sprint 5 - pendiente)
- 🔄 **RF-07** Generación de reportes (Sprint 6 - pendiente)

## 🔒 Estándares aplicados

- **RNF-03** Cifrado: TLS 1.3 en tránsito, AES-256 en reposo
- **RNF-04** Usabilidad: elementos táctiles ≥ 48dp, operación con guantes
- **RNF-06** DartDoc en todos los métodos públicos
- **RNF-09** Consentimiento informado Ley 1581/2012
- **WCAG 2.1 AA** Contraste mínimo 4.5:1, soporte TalkBack

---

*EcoRuta Cafetera · CapStone Completo · Ingeniería de Software II · UIS · 2026*
