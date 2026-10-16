import 'package:devventory_app/features/projects/index.dart';

/// Summaries of the current complete download, not historical activity metrics.
class ProjectAnalytics {
  ProjectAnalytics(List<Project> projects)
    : total = projects.length,
      types = Map.unmodifiable({
        for (final type in ProjectType.values)
          if (projects.any((project) => project.projectType == type))
            type: projects
                .where((project) => project.projectType == type)
                .length,
      });
  final int total;
  final Map<ProjectType, int> types;
}
