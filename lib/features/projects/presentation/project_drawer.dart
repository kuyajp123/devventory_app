import 'package:flutter/material.dart';
import 'package:devventory_app/features/projects/project.dart';

/// Workspace-local selection; never selects an authenticated server workspace.
class ProjectDrawer extends StatefulWidget {
  const ProjectDrawer({
    super.key,
    required this.projects,
    required this.selectedId,
    required this.loading,
    required this.onSelect,
    required this.onClose,
  });
  final List<Project>? projects;
  final String? selectedId;
  final bool loading;
  final ValueChanged<String?> onSelect;
  final VoidCallback onClose;

  @override
  State<ProjectDrawer> createState() => _ProjectDrawerState();
}

class _ProjectDrawerState extends State<ProjectDrawer> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context).width;
    final largeText = MediaQuery.textScalerOf(context).scale(14) > 21;
    final width = (screen * (largeText ? .78 : .62)).clamp(0.0, 420.0);
    final colors = Theme.of(context).colorScheme;
    final projects = widget.projects;
    final matching = projects
        ?.where(
          (project) =>
              project.name.toLowerCase().contains(_query.trim().toLowerCase()),
        )
        .toList();
    return Drawer(
      width: width,
      semanticLabel: 'Project selector',
      backgroundColor: colors.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(left: Radius.circular(28)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Projects',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      autofocus: true,
                      tooltip: 'Close projects',
                      onPressed: widget.onClose,
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Switch your focus. Your workspace stays the same.',
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              key: const Key('project-search'),
                              onChanged: (value) =>
                                  setState(() => _query = value),
                              decoration: const InputDecoration(
                                labelText: 'Search projects',
                                prefixIcon: Icon(Icons.search_rounded),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _option(
                              context,
                              label: 'All projects',
                              selected: widget.selectedId == null,
                              onTap: () => widget.onSelect(null),
                              icon: Icons.grid_view_rounded,
                            ),
                            const SizedBox(height: 16),
                            if (widget.loading)
                              const LinearProgressIndicator(
                                semanticsLabel: 'Loading available projects',
                              ),
                            const SizedBox(height: 8),
                            Text(
                              projects == null
                                  ? 'Projects not downloaded'
                                  : '${projects.length} published ${projects.length == 1 ? 'project' : 'projects'}',
                            ),
                            if (projects == null)
                              const Text(
                                'Connect and refresh Home to download projects.',
                              ),
                            if (projects?.isEmpty == true)
                              const Text(
                                'Publish your projects from desktop, then refresh Home.',
                              ),
                            if (projects?.isNotEmpty == true &&
                                matching!.isEmpty)
                              const Padding(
                                padding: EdgeInsets.only(top: 16),
                                child: Text('No matching projects'),
                              ),
                          ],
                        ),
                      ),
                    ),
                    SliverList.builder(
                      itemCount: matching?.length ?? 0,
                      itemBuilder: (context, index) {
                        final project = matching![index];
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: _option(
                            context,
                            label: project.name,
                            subtitle: project.projectType.name,
                            selected: project.id == widget.selectedId,
                            onTap: () => widget.onSelect(project.id),
                            icon: Icons.folder_open_rounded,
                          ),
                        );
                      },
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _option(
    BuildContext context, {
    required String label,
    String? subtitle,
    required bool selected,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected
            ? colors.surfaceContainerHigh
            : colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(icon, color: colors.primary, size: 20),
                    const Spacer(),
                    if (selected)
                      Icon(
                        Icons.check_circle_rounded,
                        color: colors.primary,
                        size: 20,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(label, style: Theme.of(context).textTheme.titleSmall),
                if (subtitle != null) Text(subtitle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
