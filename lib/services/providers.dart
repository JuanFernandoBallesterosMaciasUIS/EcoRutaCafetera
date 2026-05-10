import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';

// ─── Connectivity State ────────────────────────────────────────────────────

/// Simulates connectivity state (in real app, uses connectivity_plus)
class ConnectivityNotifier extends StateNotifier<bool> {
  ConnectivityNotifier() : super(false); // starts offline for demo

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
    // Simulates API call
    await Future.delayed(const Duration(milliseconds: 800));
    if (username.isNotEmpty && password.length >= 4) {
      state = demoUser;
      return true;
    }
    return false;
  }

  void logout() => state = null;
}

final authProvider = StateNotifierProvider<AuthNotifier, AppUser?>((ref) {
  return AuthNotifier();
});

// ─── Fincas State ────────────────────────────────────────────────────────

class FincasNotifier extends StateNotifier<List<Finca>> {
  FincasNotifier() : super(demoFincas);

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

  int get pendingCount =>
      state.where((f) => f.syncStatus == SyncStatus.pendiente).length;
}

final fincasProvider = StateNotifierProvider<FincasNotifier, List<Finca>>((ref) {
  return FincasNotifier();
});

final pendingSyncCountProvider = Provider<int>((ref) {
  return ref.watch(fincasProvider.notifier).pendingCount;
});

// ─── Navigation ──────────────────────────────────────────────────────────

final selectedNavIndexProvider = StateProvider<int>((ref) => 0);
