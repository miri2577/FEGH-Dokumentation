import 'package:flutter/material.dart';
import '../services/retention_service.dart';

/// Zeigt Aufbewahrungsfristen-Warnungen auf dem Dashboard an.
class RetentionWarningCard extends StatelessWidget {
  final List<RetentionWarning> warnings;

  const RetentionWarningCard({super.key, required this.warnings});

  @override
  Widget build(BuildContext context) {
    if (warnings.isEmpty) return const SizedBox.shrink();

    final expired = warnings.where((w) => w.type == RetentionType.expired).toList();
    final expiring = warnings.where((w) => w.type == RetentionType.expiringSoon).toList();
    final theme = Theme.of(context);

    return Card(
      color: expired.isNotEmpty
          ? Colors.red.withValues(alpha: 0.08)
          : Colors.orange.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  expired.isNotEmpty ? Icons.warning : Icons.schedule,
                  color: expired.isNotEmpty ? Colors.red : Colors.orange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Aufbewahrungsfristen',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Chip(
                  label: Text('${warnings.length}'),
                  backgroundColor: expired.isNotEmpty ? Colors.red.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
                ),
              ],
            ),
            if (expired.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Abgelaufen (Loeschung empfohlen):',
                  style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold, color: Colors.red)),
              const SizedBox(height: 4),
              ...expired.take(5).map((w) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.error, size: 14, color: Colors.red),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text('${w.entityType}: ${w.entityName}',
                              style: theme.textTheme.bodySmall),
                        ),
                      ],
                    ),
                  )),
              if (expired.length > 5)
                Text('... und ${expired.length - 5} weitere',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.red)),
            ],
            if (expiring.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Laeuft bald ab:',
                  style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold, color: Colors.orange)),
              const SizedBox(height: 4),
              ...expiring.take(5).map((w) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule, size: 14, color: Colors.orange),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text('${w.entityType}: ${w.entityName}',
                              style: theme.textTheme.bodySmall),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
