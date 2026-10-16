import 'dart:async';

import 'package:flutter/material.dart';
import 'package:devventory_app/app/companion_tabs.dart';
import 'package:devventory_app/features/dashboard/index.dart';
import 'package:devventory_app/features/projects/index.dart';
import 'package:devventory_app/shared/cache/metadata_cache.dart';
import 'package:devventory_app/shared/network/api_failure.dart';
import 'package:devventory_app/shared/presentation/soft_card.dart';
import 'package:devventory_app/shared/presentation/companion_layout.dart';

/// Presentation state is scoped to the current UID/workspace navigation tree.
class CompanionHome extends StatefulWidget {
  const CompanionHome({
    super.key,
    required this.repository,
    required this.scope,
    required this.checkWorkspace,
    required this.onAccessFailure,
    required this.accountPage,
    required this.refreshSignal,
    this.sessionError,
  });
  final ProjectsRepository repository;
  final CacheScope scope;
  final Future<void> Function() checkWorkspace;
  final Future<void> Function(ApiFailure) onAccessFailure;
  final Widget accountPage;
  final int refreshSignal;
  final String? sessionError;
  @override
  State<CompanionHome> createState() => _CompanionHomeState();
}

class _CompanionHomeState extends State<CompanionHome> {
  late final _projects = ProjectsController(
    widget.repository,
    widget.scope,
    checkWorkspace: widget.checkWorkspace,
    onAccessFailure: widget.onAccessFailure,
  );
  final _scaffold = GlobalKey<ScaffoldState>();
  int _tab = 0;
  String? _selectedId;
  bool _details = false, _drawerOpen = false;

  @override
  void initState() {
    super.initState();
    unawaited(_projects.initialize());
  }

  @override
  void didUpdateWidget(CompanionHome oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSignal != widget.refreshSignal) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_projects.refresh());
      });
    }
  }

  @override
  void dispose() {
    _projects.dispose();
    super.dispose();
  }

  void _browse() => _scaffold.currentState?.openEndDrawer();
  void _select(String? id) {
    FocusManager.instance.primaryFocus?.unfocus();
    _scaffold.currentState?.closeEndDrawer();
    setState(() {
      _selectedId = id;
      _details = false;
      _tab = 0;
    });
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _projects,
    builder: (context, _) {
      final selected = _projects.projects
          ?.where((project) => project.id == _selectedId)
          .firstOrNull;
      final colors = Theme.of(context).colorScheme;
      return PopScope(
        canPop: _drawerOpen || (!_details && _tab == 0),
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            setState(() {
              _details = false;
              _tab = 0;
            });
          }
        },
        child: Scaffold(
          key: _scaffold,
          restorationId: 'companion-shell',
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: colors.surface,
            surfaceTintColor: Colors.transparent,
            toolbarHeight: 72,
            leading: _details
                ? BackButton(onPressed: () => setState(() => _details = false))
                : Icon(Icons.inventory_2_rounded, color: colors.primary),
            title: Text(
              _details
                  ? 'Project details'
                  : const [
                      'Dashboard',
                      'Agent usage',
                      'Environment Tracker',
                      'Account',
                    ][_tab],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              IconButton(
                tooltip: 'Refresh projects',
                onPressed: _projects.canRefresh ? _projects.refresh : null,
                icon: const Icon(Icons.refresh_rounded),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: IconButton.filledTonal(
                  key: const Key('project-selector'),
                  tooltip: 'Choose project',
                  onPressed: _browse,
                  icon: const Icon(Icons.folder_copy_outlined),
                  style: IconButton.styleFrom(
                    backgroundColor: colors.surfaceContainerHigh,
                    foregroundColor: colors.primary,
                    minimumSize: const Size(48, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
          drawerScrimColor: colors.scrim.withValues(alpha: .3),
          endDrawerEnableOpenDragGesture: false,
          onEndDrawerChanged: (open) => setState(() => _drawerOpen = open),
          endDrawer: ProjectDrawer(
            projects: _projects.projects,
            selectedId: _selectedId,
            loading: _projects.loading,
            onSelect: _select,
            onClose: () {
              FocusManager.instance.primaryFocus?.unfocus();
              _scaffold.currentState?.closeEndDrawer();
            },
          ),
          body: SafeArea(
            top: false,
            bottom: false,
            child: switch (_tab) {
              0 =>
                _details
                    ? ProjectDetailView(
                        project: selected,
                        controller: _projects,
                      )
                    : DashboardView(
                        projects: _projects.projects,
                        selected: selected,
                        selectionMissing:
                            _selectedId != null && selected == null,
                        loading: _projects.loading,
                        sessionNotice: widget.sessionError == null
                            ? null
                            : StatusNotice(widget.sessionError!, isError: true),
                        status: ProjectsStatus(controller: _projects),
                        onBrowse: _browse,
                        onDetails: () => setState(() => _details = true),
                        onRefresh: _projects.refresh,
                      ),
              1 => const _FutureFeature(
                title: 'Agent usage is on its way',
                message: 'Account quotas, reset times, and usage insights will arrive with the Agent Usage phase. No usage data has been downloaded yet.',
                icon: Icons.donut_large_rounded,
              ),
              2 => const _FutureFeature(
                title: 'Your environments, in focus',
                message: 'Environment Tracker and validation summaries will arrive in their planned phase. Environment values and secrets will stay on desktop.',
                icon: Icons.layers_outlined,
              ),
              _ => widget.accountPage,
            },
          ),
          bottomNavigationBar: CompanionTabs(
            selectedIndex: _tab,
            onSelect: (value) => setState(() {
              _tab = value;
              _details = false;
            }),
          ),
        ),
      );
    },
  );
}

class _FutureFeature extends StatelessWidget {
  const _FutureFeature({
    required this.title,
    required this.message,
    required this.icon,
  });
  final String title, message;
  final IconData icon;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'COMING LATER',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 12),
              Text(title, style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 16),
              Text(message),
            ],
          ),
        ),
      ),
    ),
  );
}
