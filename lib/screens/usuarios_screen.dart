import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/providers.dart';

class UsuariosScreen extends ConsumerWidget {
  const UsuariosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    if (user?.rol != UserRole.administrador) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.go('/home'),
          ),
          title: const Text('Gestión de usuarios'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_rounded, size: 64, color: EcoRutaColors.error),
              SizedBox(height: 16),
              Text('Acceso restringido a administradores',
                  style: TextStyle(color: EcoRutaColors.onSurfaceVariant)),
            ],
          ),
        ),
      );
    }

    final usuarios = ref.watch(usuariosProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Gestión de usuarios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            tooltip: 'Agregar usuario',
            onPressed: () => _showAddUserDialog(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats bar
          Container(
            padding: const EdgeInsets.all(16),
            color: EcoRutaColors.primaryContainer.withOpacity(0.3),
            child: Row(
              children: [
                _StatChip(
                  label: '${usuarios.length} total',
                  icon: Icons.group_rounded,
                  color: EcoRutaColors.primary,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label:
                      '${usuarios.where((u) => u.activo).length} activos',
                  icon: Icons.check_circle_rounded,
                  color: EcoRutaColors.secondary,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label:
                      '${usuarios.where((u) => !u.activo).length} inactivos',
                  icon: Icons.cancel_rounded,
                  color: EcoRutaColors.onSurfaceVariant,
                ),
              ],
            ),
          ),

          // Role legend
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: UserRole.values.map((r) {
                  final count = usuarios.where((u) => u.rol == r).length;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _roleColor(r).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                            color: _roleColor(r).withOpacity(0.4)),
                      ),
                      child: Text(
                        '${r.displayName}: $count',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _roleColor(r),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // User list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: usuarios.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final u = usuarios[i];
                return _UsuarioCard(
                  usuario: u,
                  onToggle: () =>
                      ref.read(usuariosProvider.notifier).toggleActivo(u.id),
                ).animate().fadeIn(delay: (i * 60).ms).slideX(begin: 0.03);
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _roleColor(UserRole r) => switch (r) {
        UserRole.administrador => EcoRutaColors.primary,
        UserRole.tecnicoCampo => EcoRutaColors.secondary,
        UserRole.consultor => EcoRutaColors.tertiary,
      };

  void _showAddUserDialog(BuildContext context, WidgetRef ref) {
    final nombreCtrl = TextEditingController();
    final usernameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    UserRole selectedRole = UserRole.tecnicoCampo;
    int? selectedMunicipio;
    bool obscurePassword = true;
    String? errorMsg;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.person_add_rounded, color: EcoRutaColors.primary),
              SizedBox(width: 8),
              Text('Nuevo usuario'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (errorMsg != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      errorMsg!,
                      style: const TextStyle(color: EcoRutaColors.error, fontSize: 13),
                    ),
                  ),
                TextField(
                  controller: nombreCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo',
                    prefixIcon: Icon(Icons.person_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: usernameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Usuario (para iniciar sesión)',
                    prefixIcon: Icon(Icons.account_circle_rounded),
                  ),
                  autocorrect: false,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordCtrl,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () =>
                          setDialogState(() => obscurePassword = !obscurePassword),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<UserRole>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Rol',
                    prefixIcon: Icon(Icons.badge_rounded),
                  ),
                  items: UserRole.values
                      .map((r) => DropdownMenuItem(
                          value: r, child: Text(r.displayName)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedRole = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int?>(
                  value: selectedMunicipio,
                  decoration: const InputDecoration(
                    labelText: 'Municipio asignado',
                    prefixIcon: Icon(Icons.location_on_rounded),
                  ),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('Sin asignar')),
                    ...Municipio.municipiosPiloto.map((m) =>
                        DropdownMenuItem(value: m.id, child: Text(m.nombre))),
                  ],
                  onChanged: (v) => setDialogState(() => selectedMunicipio = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final nombre = nombreCtrl.text.trim();
                final username = usernameCtrl.text.trim();
                final password = passwordCtrl.text;
                if (nombre.isEmpty || username.isEmpty || password.length < 4) {
                  setDialogState(() => errorMsg =
                      'Completa todos los campos. Contraseña mínimo 4 caracteres.');
                  return;
                }
                final ok = await ref.read(authProvider.notifier).register(
                      username: username,
                      password: password,
                      nombre: nombre,
                      rol: selectedRole,
                      municipioAsignado: selectedMunicipio,
                    );
                if (!ok) {
                  setDialogState(
                      () => errorMsg = 'El usuario "$username" ya existe.');
                  return;
                }
                ref.read(usuariosProvider.notifier).addUsuario(
                      UsuarioSistema(
                        id: 0,
                        nombre: nombre,
                        email: '',
                        rol: selectedRole,
                        municipioAsignado: selectedMunicipio,
                      ),
                    );
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Usuario "$username" creado correctamente.'),
                      backgroundColor: EcoRutaColors.secondary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              },
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _UsuarioCard extends StatelessWidget {
  final UsuarioSistema usuario;
  final VoidCallback onToggle;

  const _UsuarioCard({required this.usuario, required this.onToggle});

  Color get _roleColor => switch (usuario.rol) {
        UserRole.administrador => EcoRutaColors.primary,
        UserRole.tecnicoCampo => EcoRutaColors.secondary,
        UserRole.consultor => EcoRutaColors.tertiary,
      };

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: usuario.activo
                        ? _roleColor.withOpacity(0.15)
                        : EcoRutaColors.surfaceContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      usuario.nombre
                          .split(' ')
                          .map((n) => n[0])
                          .take(2)
                          .join(),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: usuario.activo
                            ? _roleColor
                            : EcoRutaColors.onSurfaceVariant,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                if (!usuario.activo)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        color: EcoRutaColors.onSurfaceVariant,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.block_rounded,
                          size: 8, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          usuario.nombre,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: usuario.activo
                                    ? null
                                    : EcoRutaColors.onSurfaceVariant,
                                decoration: usuario.activo
                                    ? null
                                    : TextDecoration.lineThrough,
                              ),
                        ),
                      ),
                      _RoleBadge(rol: usuario.rol),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    usuario.email,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: EcoRutaColors.onSurfaceVariant,
                        ),
                  ),
                  if (usuario.municipioNombre != 'Sin asignar')
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_rounded,
                              size: 12,
                              color: EcoRutaColors.onSurfaceVariant),
                          const SizedBox(width: 2),
                          Text(
                            usuario.municipioNombre,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                    color: EcoRutaColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Toggle button
            Column(
              children: [
                Switch(
                  value: usuario.activo,
                  onChanged: (_) => _confirmToggle(context),
                  activeColor: EcoRutaColors.secondary,
                ),
                Text(
                  usuario.activo ? 'Activo' : 'Inactivo',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: usuario.activo
                            ? EcoRutaColors.secondary
                            : EcoRutaColors.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmToggle(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(usuario.activo ? 'Desactivar usuario' : 'Activar usuario'),
        content: Text(
          usuario.activo
              ? '¿Desactivar a "${usuario.nombre}"? No podrá acceder al sistema.'
              : '¿Activar a "${usuario.nombre}"? Recuperará acceso al sistema.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: usuario.activo
                  ? EcoRutaColors.error
                  : EcoRutaColors.secondary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              onToggle();
              Navigator.pop(ctx);
            },
            child: Text(usuario.activo ? 'Desactivar' : 'Activar'),
          ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final UserRole rol;

  const _RoleBadge({required this.rol});

  Color get _color => switch (rol) {
        UserRole.administrador => EcoRutaColors.primary,
        UserRole.tecnicoCampo => EcoRutaColors.secondary,
        UserRole.consultor => EcoRutaColors.tertiary,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _color.withOpacity(0.4)),
      ),
      child: Text(
        rol.displayName,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: _color,
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _StatChip(
      {required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }
}
