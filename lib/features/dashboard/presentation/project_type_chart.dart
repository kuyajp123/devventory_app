import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:devventory_app/features/dashboard/project_analytics.dart';
import 'package:devventory_app/shared/presentation/soft_card.dart';

class ProjectTypeChart extends StatelessWidget {
  const ProjectTypeChart({super.key, required this.analytics});
  final ProjectAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final palette = [
      colors.primary,
      colors.secondary,
      colors.onSurfaceVariant,
      colors.outline,
      colors.error,
      colors.onSurface,
      colors.primaryContainer,
    ];
    final types = analytics.types.entries.toList();
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Project mix', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text('All published projects, grouped by type.'),
          const SizedBox(height: 24),
          if (analytics.total == 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Your chart will appear after you publish a project.',
              ),
            )
          else ...[
            // Visible text below is the authoritative accessible chart equivalent.
            ExcludeSemantics(
              child: SizedBox(
                height: 180,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 3,
                        centerSpaceRadius: 62,
                        startDegreeOffset: -90,
                        pieTouchData: PieTouchData(enabled: false),
                        sections: [
                          for (var index = 0; index < types.length; index++)
                            PieChartSectionData(
                              value: types[index].value.toDouble(),
                              color: palette[types[index].key.index],
                              radius: 22,
                              showTitle: false,
                            ),
                        ],
                      ),
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 180),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${analytics.total}',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const Text('projects'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            for (final entry in types)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Icon(
                        Icons.circle,
                        size: 12,
                        color: palette[entry.key.index],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${entry.key.name} · ${entry.value} ${entry.value == 1 ? 'project' : 'projects'}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${(100 * entry.value / analytics.total).round()}%'),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
