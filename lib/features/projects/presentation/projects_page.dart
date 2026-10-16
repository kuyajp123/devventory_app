import 'dart:async';

import 'package:flutter/material.dart';
import 'package:devventory_app/features/projects/projects_repository.dart';
import 'package:devventory_app/features/projects/projects_controller.dart';
import 'package:devventory_app/features/projects/presentation/projects_list_view.dart';
import 'package:devventory_app/features/projects/presentation/project_detail_view.dart';
import 'package:devventory_app/shared/cache/metadata_cache.dart';
import 'package:devventory_app/shared/network/api_failure.dart';

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({
    super.key,
    required this.repository,
    required this.scope,
    required this.checkWorkspace,
    required this.onAccessFailure,
    required this.onSignOut,
    this.refreshSignal = 0,
  });
  final ProjectsRepository repository;
  final CacheScope scope;
  final Future<void> Function() checkWorkspace;
  final Future<void> Function(ApiFailure) onAccessFailure;
  final VoidCallback? onSignOut;
  final int refreshSignal;
  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  late final _controller = ProjectsController(
    widget.repository,
    widget.scope,
    checkWorkspace: widget.checkWorkspace,
    onAccessFailure: widget.onAccessFailure,
  );
  String? _selectedId;
  @override
  void initState() {
    super.initState();
    unawaited(_controller.initialize());
  }

  @override
  void didUpdateWidget(ProjectsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSignal != widget.refreshSignal) {
      // Refresh notifies the owning workspace too; wait until this build ends.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_controller.refresh());
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _controller,
    builder: (context, _) {
      final selected = _controller.projects
          ?.where((project) => project.id == _selectedId)
          .firstOrNull;
      return PopScope(
        canPop: _selectedId == null,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && _selectedId != null) {
            setState(() => _selectedId = null);
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(_selectedId == null ? 'Projects' : 'Project details'),
            leading: _selectedId == null
                ? null
                : BackButton(
                    onPressed: () => setState(() => _selectedId = null),
                  ),
            actions: [
              IconButton(
                tooltip: 'Refresh projects',
                onPressed: _controller.canRefresh ? _controller.refresh : null,
                icon: const Icon(Icons.refresh_rounded),
              ),
              PopupMenuButton<String>(
                tooltip: 'Account',
                onSelected: (_) => widget.onSignOut?.call(),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'sign-out',
                    enabled: widget.onSignOut != null,
                    child: const Text('Sign out'),
                  ),
                ],
              ),
            ],
          ),
          body: SafeArea(
            top: false,
            child: _selectedId == null
                ? ProjectsListView(
                    controller: _controller,
                    onSelect: (id) => setState(() => _selectedId = id),
                  )
                : ProjectDetailView(project: selected, controller: _controller),
          ),
        ),
      );
    },
  );
}
