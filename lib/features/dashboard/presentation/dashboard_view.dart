import 'package:flutter/material.dart';
import 'package:devventory_app/features/projects/index.dart';
import 'package:devventory_app/features/dashboard/project_analytics.dart';
import 'package:devventory_app/features/dashboard/presentation/project_type_chart.dart';
import 'package:devventory_app/shared/presentation/action_button.dart';
import 'package:devventory_app/shared/presentation/soft_card.dart';
import 'package:devventory_app/shared/presentation/venty_mascot.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({
    super.key,
    required this.projects,
    required this.selected,
    required this.selectionMissing,
    required this.status,
    required this.onBrowse,
    required this.onDetails,
    required this.onRefresh,
    required this.loading,
    this.sessionNotice,
  });
  final List<Project>? projects;
  final Project? selected;
  final bool selectionMissing, loading;
  final Widget status;
  final Widget? sessionNotice;
  final VoidCallback onBrowse, onDetails;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final analytics = projects == null ? null : ProjectAnalytics(projects!);
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        key: const PageStorageKey('dashboard-scroll'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'WORKSPACE OVERVIEW',
                            style: text.labelSmall?.copyWith(
                              color: colors.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Semantics(
                            header: true,
                            child: Text(
                              'A little clarity.\nAll in one place.',
                              style: text.headlineLarge,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (MediaQuery.textScalerOf(context).scale(14) < 22)
                      const VentyMascot(size: 88),
                  ],
                ),
                const SizedBox(height: 24),
                if (sessionNotice != null) ...[
                  sessionNotice!,
                  const SizedBox(height: 24),
                ],
                if (selected != null || selectionMissing) ...[
                  SoftCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Selected project',
                          style: text.labelLarge?.copyWith(
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          selectionMissing
                              ? 'Project no longer published'
                              : selected!.name,
                          style: text.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          selectionMissing
                              ? 'Choose another project or return to All projects.'
                              : selected!.description?.trim().isNotEmpty == true
                              ? selected!.description!
                              : 'No description published.',
                        ),
                        const SizedBox(height: 20),
                        ActionButton(
                          label: selectionMissing
                              ? 'Choose another project'
                              : 'View project details',
                          icon: Icons.arrow_forward_rounded,
                          onPressed: selectionMissing ? onBrowse : onDetails,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                SoftCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Your workspace', style: text.titleLarge),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 32,
                        runSpacing: 20,
                        children: [
                          _metric(
                            context,
                            analytics == null ? '—' : '${analytics.total}',
                            'Published projects',
                          ),
                          _metric(
                            context,
                            analytics == null
                                ? '—'
                                : '${analytics.types.length}',
                            'Project types',
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      ActionButton(
                        label: 'Browse projects',
                        icon: Icons.folder_open_rounded,
                        onPressed: onBrowse,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (analytics != null)
                  ProjectTypeChart(analytics: analytics)
                else
                  SoftCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          loading
                              ? 'Getting your overview ready'
                              : 'Projects not downloaded',
                          style: text.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'A complete project download will populate your analytics. Connect and refresh; unavailable data is not shown as zero.',
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                status,
                const SizedBox(height: 24),
                const Text(
                  'Workspace totals use your last complete download. File inventory stays on desktop. Usage, environment coverage, and validation analytics arrive in later phases.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _metric(BuildContext context, String value, String label) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(value, style: Theme.of(context).textTheme.headlineLarge),
      const SizedBox(height: 4),
      Text(label),
    ],
  );
}
