import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_models.dart';
import '../theme/app_theme.dart';
import '../providers/auth_providers.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData? icon;
  final Color? color;
  final String? subtitle;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    this.icon,
    this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                ),
                if (icon != null)
                  Icon(icon, size: 20, color: color ?? AppTheme.brandPrimary),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryNavy,
                  ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.brandSuccess,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class JobCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String status;
  final double? amount;
  final VoidCallback onTap;
  final String? trade;

  const JobCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.status,
    this.amount,
    required this.onTap,
    this.trade,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subtitle != null) Text(subtitle!),
            const SizedBox(height: 4),
            Row(
              children: [
                if (trade != null) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.brandPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      trade!.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.brandPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                _StatusBadge(status: status),
              ],
            ),
          ],
        ),
        trailing: amount != null
            ? Text(
                '£${amount!.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.primaryNavy,
                ),
              )
            : const Icon(Icons.chevron_right),
      ),
    );
  }
}

class ReliabilityBadge extends StatelessWidget {
  final double score; // 0.0 to 5.0
  final int reviewCount;

  const ReliabilityBadge({
    super.key,
    required this.score,
    required this.reviewCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getScoreColor(score).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _getScoreColor(score).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_user, size: 16, color: _getScoreColor(score)),
          const SizedBox(width: 6),
          Text(
            score.toStringAsFixed(1),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _getScoreColor(score),
            ),
          ),
          Text(
            ' ($reviewCount)',
            style: TextStyle(
              fontSize: 12,
              color: _getScoreColor(score).withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 4.5) return AppTheme.brandSuccess;
    if (score >= 3.5) return AppTheme.brandPrimary;
    if (score >= 2.5) return AppTheme.brandSecondary;
    return AppTheme.brandDanger;
  }
}

class RoleSwitcherBar extends ConsumerWidget {
  const RoleSwitcherBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).value;
    if (profile == null || profile.accountType != AccountType.both) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          _RoleButton(
            label: 'Contractor',
            isActive: true, // Logic to be linked with a RoleProvider
            onTap: () {},
          ),
          _RoleButton(
            label: 'Customer',
            isActive: false,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _RoleButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(21),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? AppTheme.brandPrimary : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toLowerCase()) {
      case 'open':
      case 'sent':
        color = AppTheme.brandPrimary;
        break;
      case 'in_progress':
      case 'accepted':
        color = AppTheme.brandSecondary;
        break;
      case 'completed':
      case 'paid':
        color = AppTheme.brandSuccess;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

class PAIActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isSecondary;
  final IconData? icon;

  const PAIActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final style = ElevatedButton.styleFrom(
      backgroundColor: isSecondary ? Colors.white : AppTheme.brandPrimary,
      foregroundColor: isSecondary ? AppTheme.brandPrimary : Colors.white,
      side: isSecondary ? const BorderSide(color: AppTheme.brandPrimary) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    );

    if (isLoading) {
      return ElevatedButton(
        onPressed: null,
        style: style,
        child: const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        ),
      );
    }

    if (icon != null) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        style: style,
        icon: Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: style,
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}