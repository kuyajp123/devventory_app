import 'package:flutter/material.dart';
import 'package:devventory_app/features/projects/project.dart';
import 'package:devventory_app/features/projects/projects_controller.dart';
import 'package:devventory_app/features/projects/presentation/project_freshness.dart';
import 'package:devventory_app/features/projects/presentation/projects_status.dart';
import 'package:devventory_app/shared/presentation/soft_card.dart';

class ProjectDetailView extends StatelessWidget {
  const ProjectDetailView({
    super.key,
    required this.project,
    required this.controller,
  });
  final Project? project;
  final ProjectsController controller;
  @override
  Widget build(BuildContext context) {
    final project = this.project;
    final text = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ProjectsStatus(controller: controller),
              const SizedBox(height: 24),
              if (project == null) ...[
                Text('Project no longer published', style: text.headlineLarge),
                const SizedBox(height: 16),
                const Text(
                  'The latest complete refresh no longer includes this project. Go back to your project list.',
                ),
              ] else ...[
                Semantics(
                  header: true,
                  child: Text(project.name, style: text.headlineLarge),
                ),
                const SizedBox(height: 12),
                Text(
                  project.projectType.name.toUpperCase(),
                  style: text.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),
                SoftCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('About this project', style: text.titleLarge),
                      const SizedBox(height: 12),
                      Text(
                        project.description?.trim().isNotEmpty == true
                            ? project.description!
                            : 'No description published.',
                      ),
                      const SizedBox(height: 20),
                      ProjectFreshness(
                        label: 'Project created',
                        time: project.createdAt,
                      ),
                      ProjectFreshness(
                        label: 'Project updated',
                        time: project.updatedAt,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SoftCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Metadata freshness', style: text.titleLarge),
                      const SizedBox(height: 12),
                      ProjectFreshness(
                        label: 'Desktop observed',
                        time: project.observedAt,
                      ),
                      ProjectFreshness(
                        label: 'Cloud received',
                        time: project.receivedAt,
                      ),
                      if (controller.fetchedAt != null)
                        ProjectFreshness(
                          label: 'Mobile downloaded',
                          time: controller.fetchedAt!,
                        ),
                      const SizedBox(height: 12),
                      const Text(
                        'Times use this device’s timezone. A successful refresh does not mean the desktop has published newer changes.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Read-only project metadata. Files, paths, environment values, and secrets stay on desktop.',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
