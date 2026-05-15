import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

class _RegisteredUser {
  final AppUser user;
  final String password;
  const _RegisteredUser(this.user, this.password);
}

// Provider para SharedPreferences — se override en main() con instancia ya cargada
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Override in main()');
});

class AuthNotifier extends StateNotifier<AppUser?> {
  AuthNotifier(this._prefs) : super(null) {
    _restoreSessionSync();
  }

  static const _keyUser = 'session_user';
  static const _keyTimestamp = 'session_ts';
  static const _keyRegistered = 'registered_users';
  static const _sessionMs = 30 * 60 * 1000;

  final SharedPreferences _prefs;
  final Map<String, _RegisteredUser> _registeredUsers = {};

  // Síncrono: prefs ya está cargado antes de runApp()
  void _restoreSessionSync() {
    final regJson = _prefs.getString(_keyRegistered);
    if (regJson != null) {
      try {
        final regMap = jsonDecode(regJson) as Map<String, dynamic>;
        for (final entry in regMap.entries) {
          final data = entry.value as Map<String, dynamic>;
          final u = AppUser.fromJson(data['user'] as Map<String, dynamic>);
          _registeredUsers[entry.key] = _RegisteredUser(u, data['password'] as String);
        }
      } catch (_) {}
    }

    final ts = _prefs.getInt(_keyTimestamp) ?? 0;
    final elapsed = DateTime.now().millisecondsSinceEpoch - ts;
    if (elapsed >= _sessionMs) {
      _prefs.remove(_keyUser);
      _prefs.remove(_keyTimestamp);
      return;
    }
    final userJson = _prefs.getString(_keyUser);
    if (userJson == null) return;
    try {
      state = AppUser.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
    } catch (_) {}
  }

  void _saveSession(AppUser user) {
    _prefs.setString(_keyUser, jsonEncode(user.toJson()));
    _prefs.setInt(_keyTimestamp, DateTime.now().millisecondsSinceEpoch);
  }

  void _saveRegisteredUsers() {
    final map = <String, dynamic>{};
    for (final entry in _registeredUsers.entries) {
      map[entry.key] = {
        'user': entry.value.user.toJson(),
        'password': entry.value.password,
      };
    }
    _prefs.setString(_keyRegistered, jsonEncode(map));
  }

  Future<bool> register({
    required String username,
    required String password,
    required String nombre,
    required UserRole rol,
    int? municipioAsignado,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final key = username.toLowerCase().trim();
    if (key.isEmpty || password.length < 8) return false;
    if (_registeredUsers.containsKey(key)) return false;
    final user = AppUser(
      id: 1000 + _registeredUsers.length,
      nombre: nombre,
      username: key,
      rol: rol,
      municipioAsignado: municipioAsignado,
    );
    _registeredUsers[key] = _RegisteredUser(user, password);
    _saveRegisteredUsers();
    return true;
  }

  Future<bool> login(String username, String password) async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (username.isEmpty || password.length < 4) return false;
    final key = username.toLowerCase().trim();
    final registered = _registeredUsers[key];
    if (registered != null) {
      if (registered.password != password) return false;
      state = registered.user;
      _saveSession(registered.user);
      return true;
    }
    // Usuarios demo: usuario=primer nombre, contraseña=1234
    const demoPassword = '1234';
    if (password != demoPassword) return false;
    AppUser? user;
    if (key == 'laura') {
      user = demoAdmin;
    } else if (key == 'jorge') {
      user = demoConsultor;
    } else if (key == 'ivan') {
      user = demoUser;
    } else {
      return false;
    }
    state = user;
    _saveSession(user);
    return true;
  }

  void logout() {
    _prefs.remove(_keyUser);
    _prefs.remove(_keyTimestamp);
    state = null;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AppUser?>((ref) {
  return AuthNotifier(ref.read(sharedPreferencesProvider));
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
