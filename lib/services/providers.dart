import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';

// ─── Connectivity State ────────────────────────────────────────────────────

class ConnectivityNotifier extends StateNotifier<bool> {
  ConnectivityNotifier() : super(false);

  void setOnline(bool isOnline) => state = isOnline;
  void toggle() => state = !state;
}

final connectivityProvider =
    StateNotifierProvider<ConnectivityNotifier, bool>((ref) {
  return ConnectivityNotifier();
});

// ─── Auth State ───────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AppUser?> {
  AuthNotifier() : super(null);

  Future<bool> login(String username, String password) async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (username.isEmpty || password.length < 4) return false;
    
    final u = username.toLowerCase().trim();
    
    // Buscar el usuario en la lista de usuarios del sistema
    try {
      final usuario = demoUsuarios.firstWhere(
        (user) => user.nombre.toLowerCase() == u || user.email.toLowerCase() == u,
      );
      
      // Convertir UsuarioSistema a AppUser
      state = AppUser(
        id: usuario.id,
        nombre: usuario.nombre,
        email: usuario.email,
        rol: usuario.rol,
        municipioAsignado: usuario.municipioAsignado,
      );
      return true;
    } catch (e) {
      // Usuario no encontrado, retorna false
      return false;
    }
  }

  void logout() => state = null;
}

final authProvider = StateNotifierProvider<AuthNotifier, AppUser?>((ref) {
  return AuthNotifier();
});

// ─── Fincas State ────────────────────────────────────────────────────────

class FincasNotifier extends StateNotifier<List<Finca>> {
  FincasNotifier() : super(List.from(demoFincas));

  void addFinca(Finca finca) {
    final newFinca = finca.copyWith(
      id: state.length + 1,
      fechaRegistro: DateTime.now(),
      syncStatus: SyncStatus.pendiente,
    );
    state = [...state, newFinca];
  }

  void updateFinca(Finca updated) {
    state = state.map((f) => f.id == updated.id ? updated : f).toList();
  }

  void deleteFinca(int id) {
    state = state.where((f) => f.id != id).toList();
  }

  void syncAll() {
    state = state.map((f) {
      if (f.syncStatus == SyncStatus.pendiente ||
          f.syncStatus == SyncStatus.error) {
        return f.copyWith(syncStatus: SyncStatus.subido);
      }
      return f;
    }).toList();
  }

  int get pendingCount =>
      state.where((f) => f.syncStatus == SyncStatus.pendiente).length;
  int get errorCount =>
      state.where((f) => f.syncStatus == SyncStatus.error).length;
}

final fincasProvider =
    StateNotifierProvider<FincasNotifier, List<Finca>>((ref) {
  return FincasNotifier();
});

final pendingSyncCountProvider = Provider<int>((ref) {
  final fincas = ref.watch(fincasProvider);
  final visitas = ref.watch(visitasProvider);
  final fincasPending =
      fincas.where((f) => f.syncStatus == SyncStatus.pendiente).length;
  final visitasPending =
      visitas.where((v) => v.syncStatus == SyncStatus.pendiente).length;
  return fincasPending + visitasPending;
});

// ─── Visitas State ────────────────────────────────────────────────────────

class VisitasNotifier extends StateNotifier<List<Visita>> {
  VisitasNotifier() : super(List.from(demoVisitas));

  void addVisita(Visita visita) {
    final newVisita = Visita(
      id: state.length + 1,
      fincaId: visita.fincaId,
      tecnicoId: visita.tecnicoId,
      tecnicoNombre: visita.tecnicoNombre,
      fecha: visita.fecha,
      coberturaVegetal: visita.coberturaVegetal,
      tieneFuenteAgua: visita.tieneFuenteAgua,
      manejoAdecuadoResiduos: visita.manejoAdecuadoResiduos,
      usoAgroquimicos: visita.usoAgroquimicos,
      practicasAgroforestales: visita.practicasAgroforestales,
      produccionKgAnio: visita.produccionKgAnio,
      precioKgCOP: visita.precioKgCOP,
      costoProduccionCOP: visita.costoProduccionCOP,
      tieneOtrosIngresos: visita.tieneOtrosIngresos,
      personasHogar: visita.personasHogar,
      menoresEdad: visita.menoresEdad,
      nivelEducativo: visita.nivelEducativo,
      seguridadAlimentaria: visita.seguridadAlimentaria,
      accesoProgramasGobierno: visita.accesoProgramasGobierno,
      observaciones: visita.observaciones,
      syncStatus: SyncStatus.pendiente,
    );
    state = [...state, newVisita];
  }

  List<Visita> forFinca(int fincaId) =>
      state.where((v) => v.fincaId == fincaId).toList()
        ..sort((a, b) => b.fecha.compareTo(a.fecha));

  void syncAll() {
    state = state
        .map((v) => v.syncStatus == SyncStatus.pendiente
            ? v.copyWith(syncStatus: SyncStatus.subido)
            : v)
        .toList();
  }
}

final visitasProvider =
    StateNotifierProvider<VisitasNotifier, List<Visita>>((ref) {
  return VisitasNotifier();
});

// ─── Usuarios State (admin only) ──────────────────────────────────────────

class UsuariosNotifier extends StateNotifier<List<UsuarioSistema>> {
  UsuariosNotifier() : super(List.from(demoUsuarios));

  void toggleActivo(int id) {
    state = state.map((u) {
      if (u.id == id) {
        return UsuarioSistema(
          id: u.id,
          nombre: u.nombre,
          email: u.email,
          rol: u.rol,
          municipioAsignado: u.municipioAsignado,
          activo: !u.activo,
        );
      }
      return u;
    }).toList();
  }

  void addUsuario(UsuarioSistema usuario) {
    final newUser = UsuarioSistema(
      id: state.length + 1,
      nombre: usuario.nombre,
      email: usuario.email,
      rol: usuario.rol,
      municipioAsignado: usuario.municipioAsignado,
      activo: true,
    );
    state = [...state, newUser];
  }
}

final usuariosProvider =
    StateNotifierProvider<UsuariosNotifier, List<UsuarioSistema>>((ref) {
  return UsuariosNotifier();
});

// ─── Navigation ──────────────────────────────────────────────────────────

final selectedNavIndexProvider = StateProvider<int>((ref) => 0);
