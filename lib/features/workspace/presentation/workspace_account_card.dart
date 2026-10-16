import 'package:flutter/material.dart';
import 'package:devventory_app/shared/presentation/soft_card.dart';

class WorkspaceAccountCard extends StatelessWidget {
  const WorkspaceAccountCard({
    super.key,
    required this.email,
    required this.ready,
    required this.fetchedAt,
  });

  final String? email;
  final bool ready;
  final DateTime? fetchedAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                ready ? Icons.link_rounded : Icons.desktop_windows_rounded,
                color: theme.colorScheme.primary,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  ready ? 'Desktop linked' : 'Waiting for desktop',
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'CLOUD ACCOUNT',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            email ?? 'Signed-in account',
            style: theme.textTheme.titleMedium,
          ),
          if (ready && fetchedAt != null) ...[
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Connection checked at ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(fetchedAt!.toLocal()))} (device time).',
            ),
          ],
        ],
      ),
    );
  }
}
