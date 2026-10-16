import 'package:flutter/material.dart';
import 'package:devventory_app/features/projects/projects_controller.dart';
import 'package:devventory_app/features/projects/presentation/projects_status.dart';
import 'package:devventory_app/shared/presentation/companion_layout.dart';
import 'package:devventory_app/shared/presentation/soft_card.dart';
import 'package:devventory_app/shared/presentation/venty_mascot.dart';

class ProjectsListView extends StatelessWidget {
  const ProjectsListView({
    super.key,
    required this.controller,
    required this.onSelect,
  });
  final ProjectsController controller;
  final ValueChanged<String> onSelect;
  Widget _content(Widget child) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: child,
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final projects = controller.projects;
    final text = Theme.of(context).textTheme;
    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _content(
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Your projects', style: text.headlineLarge),
                  const SizedBox(height: 12),
                  const Text('Published on desktop. Ready to explore here.'),
                  const SizedBox(height: 20),
                  ProjectsStatus(controller: controller),
                  const SizedBox(height: 12),
                  if (projects?.isNotEmpty == true)
                    Text(
                      '${projects!.length} published ${projects.length == 1 ? 'project' : 'projects'}',
                      style: text.labelLarge,
                    ),
                ],
              ),
            ),
          ),
          if (!controller.loading && (projects == null || projects.isEmpty))
            SliverToBoxAdapter(
              child: _content(
                SoftCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: VentyMascot(size: 96)),
                      const SizedBox(height: 20),
                      Text(
                        projects == null
                            ? 'Projects not downloaded'
                            : 'No published projects',
                        style: text.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        projects == null
                            ? 'Connect and refresh to save your project metadata for offline reading.'
                            : 'Add a project in Devventory desktop and publish Cloud Sync metadata, then refresh here.',
                      ),
                      const SizedBox(height: 24),
                      ActionButton(
                        label: projects == null
                            ? 'Try again'
                            : 'Refresh projects',
                        onPressed: controller.canRefresh
                            ? controller.refresh
                            : null,
                        icon: Icons.refresh_rounded,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (projects != null)
            SliverList.builder(
              itemCount: projects.length,
              itemBuilder: (context, index) {
                final project = projects[index];
                return _content(
                  SoftCard(
                    padding: EdgeInsets.zero,
                    child: Material(
                      color: Colors.transparent,
                      child: Semantics(
                        button: true,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(28),
                          onTap: () => onSelect(project.id),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  project.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: text.titleLarge,
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.folder_open_rounded,
                                      size: 20,
                                    ),
                                    Text(
                                      project.projectType.name,
                                      style: text.labelLarge,
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 20,
                                    ),
                                  ],
                                ),
                                if (project.description?.trim().isNotEmpty ==
                                    true) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    project.description!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}
