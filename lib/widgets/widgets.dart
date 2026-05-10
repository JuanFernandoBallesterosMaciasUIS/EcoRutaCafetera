import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';

// ─── Connectivity Badge ─────────────────────────────────────────────────────

class ConnectivityBadge extends StatelessWidget {
  final bool isOnline;

  const ConnectivityBadge({super.key, required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isOnline
            ? EcoRutaColors.secondaryContainer.withOpacity(0.5)
            : EcoRutaColors.errorContainer,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isOnline
              ? EcoRutaColors.secondary.withOpacity(0.2)
              : EcoRutaColors.error.withOpacity(0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          isOnline
              ? _PulsingDot(color: EcoRutaColors.secondary)
              : Icon(
                  Icons.cloud_off_rounded,
                  size: 16,
                  color: EcoRutaColors.onErrorContainer,
                ),
          const SizedBox(width: 8),
          Text(
            isOnline ? 'Conectado' : 'Sin internet - Modo offline disponible',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isOnline
                      ? EcoRutaColors.onSecondaryContainer
                      : EcoRutaColors.onErrorContainer,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withOpacity(0.5 + 0.5 * _controller.value),
        ),
      ),
    );
  }
}

// ─── Sync Status Chip ──────────────────────────────────────────────────────

class SyncStatusChip extends StatelessWidget {
  final SyncStatus status;

  const SyncStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, bgColor, icon) = switch (status) {
      SyncStatus.subido => (
          EcoRutaColors.secondary,
          EcoRutaColors.secondaryContainer,
          Icons.cloud_done_rounded,
        ),
      SyncStatus.pendiente => (
          EcoRutaColors.onSurfaceVariant,
          EcoRutaColors.surfaceContainer,
          Icons.cloud_upload_rounded,
        ),
      SyncStatus.subiendo => (
          EcoRutaColors.primary,
          EcoRutaColors.primaryFixed,
          Icons.cloud_sync_rounded,
        ),
      SyncStatus.error => (
          EcoRutaColors.error,
          EcoRutaColors.errorContainer,
          Icons.cloud_off_rounded,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            status.displayName,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

// ─── Finca Card ───────────────────────────────────────────────────────────

class FincaCard extends StatelessWidget {
  final Finca finca;
  final VoidCallback? onTap;

  const FincaCard({super.key, required this.finca, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: EcoRutaColors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.agriculture_rounded,
                      color: EcoRutaColors.onPrimaryContainer,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          finca.nombre,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: EcoRutaColors.primary,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          finca.propietario,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: EcoRutaColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SyncStatusChip(status: finca.syncStatus),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.location_on_rounded,
                    label: finca.municipioNombre,
                  ),
                  const SizedBox(width: 8),
                  _InfoChip(
                    icon: Icons.landscape_rounded,
                    label: '${finca.hectareas} ha',
                  ),
                  const SizedBox(width: 8),
                  _InfoChip(
                    icon: Icons.eco_rounded,
                    label: finca.variedadCafe,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: EcoRutaColors.onSurfaceVariant),
        const SizedBox(width: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: EcoRutaColors.onSurfaceVariant,
              ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ─── Quick Action Button ───────────────────────────────────────────────────

class QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool isPrimary;
  final Color? iconBgColor;
  final Color? iconColor;

  const QuickActionButton({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.isPrimary = false,
    this.iconBgColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isPrimary) {
      return Material(
        color: EcoRutaColors.primary,
        borderRadius: BorderRadius.circular(16),
        elevation: 4,
        shadowColor: EcoRutaColors.primary.withOpacity(0.4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: EcoRutaColors.primaryFixed,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: EcoRutaColors.primaryFixed,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconBgColor ?? EcoRutaColors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? EcoRutaColors.onPrimaryContainer,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: EcoRutaColors.primary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: EcoRutaColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: EcoRutaColors.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── EcoRuta Logo Widget ─────────────────────────────────────────────────────

class EcoRutaLogo extends StatelessWidget {
  final double size;
  final bool showName;

  const EcoRutaLogo({super.key, this.size = 56, this.showName = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: EcoRutaColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: EcoRutaColors.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            Icons.eco_rounded,
            color: Colors.white,
            size: size * 0.5,
          ),
        ),
        if (showName) ...[
          const SizedBox(height: 8),
          Text(
            'EcoRuta',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: EcoRutaColors.primary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          Text(
            'Cafetera',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: EcoRutaColors.primary,
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                ),
          ),
        ],
      ],
    );
  }
}

// ─── Section Header ──────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: EcoRutaColors.primary,
                fontWeight: FontWeight.w700,
              ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

// ─── Stats Card ──────────────────────────────────────────────────────────────

class StatsCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color? color;

  const StatsCard({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? EcoRutaColors.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: effectiveColor, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: effectiveColor,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: EcoRutaColors.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
