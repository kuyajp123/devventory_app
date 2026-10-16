import 'dart:async';

import 'package:flutter/material.dart';
import 'package:devventory_app/app/companion_home.dart';
import 'package:devventory_app/features/workspace/index.dart';
import 'package:devventory_app/features/projects/index.dart';
import 'package:devventory_app/shared/cache/metadata_cache.dart';
import 'package:devventory_app/shared/network/api_failure.dart';

/// This navigation tree is disposed as a unit when auth or workspace changes.
class CompanionSession extends StatefulWidget {
  const CompanionSession({
    super.key,
    required this.account,
    required this.workspaces,
    required this.projects,
    required this.email,
    required this.onSignOut,
    required this.onVerificationRequired,
    required this.refreshSignal,
    this.sessionError,
  });
  final CacheAccount account;
  final WorkspaceRepository workspaces;
  final ProjectsRepository projects;
  final String? email, sessionError;
  final VoidCallback? onSignOut;
  final VoidCallback onVerificationRequired;
  final int refreshSignal;
  @override
  State<CompanionSession> createState() => _CompanionSessionState();
}

class _CompanionSessionState extends State<CompanionSession> {
  late final _workspace = WorkspaceController(
    widget.workspaces,
    cache: widget.account,
  );
  String? _workspaceId;
  CacheScope? _scope;
  int _projectRefresh = 0;
  @override
  void initState() {
    super.initState();
    _workspace.addListener(_workspaceChanged);
    unawaited(_workspace.initialize());
  }

  void _workspaceChanged() {
    if (!mounted) return;
    final id = _workspace.workspace?.id;
    if (id != _workspaceId) {
      _workspaceId = id;
      _scope = null;
    }
    if (_workspace.failure?.kind == ApiFailureKind.verificationRequired) {
      widget.onVerificationRequired();
    }
    setState(() {});
  }

  Future<void> _checkWorkspace() async {
    await _workspace.refresh();
    if (!mounted || !(_scope?.valid ?? false)) throw const CacheRevoked();
    if (_workspace.failure != null) throw _workspace.failure!;
    if (_workspace.cacheNotice != null) {
      throw const ApiFailure(ApiFailureKind.unavailable);
    }
    if (_workspace.workspace?.id != _scope!.workspaceId) {
      throw const CacheRevoked();
    }
  }

  @override
  void didUpdateWidget(CompanionSession oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSignal != widget.refreshSignal) {
      if (_scope?.valid ?? false) {
        _projectRefresh++;
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) unawaited(_workspace.refresh());
        });
      }
    }
  }

  @override
  void dispose() {
    _workspace.removeListener(_workspaceChanged);
    _workspace.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workspace = _workspace.workspace;
    if (workspace?.hasPublisher ?? false) {
      if (!(_scope?.valid ?? false)) {
        _scope = widget.account.scope(workspace!.id!);
      }
    }
    final accountPage = WorkspacePage(
      controller: _workspace,
      email: widget.email,
      onSignOut: widget.onSignOut,
      onRefresh: _workspace.refresh,
      sessionError: widget.sessionError,
      showBrowseAction: false,
    );
    // Tab/detail state belongs to one shell, not a second navigation stack.
    // Replacing this keyed subtree also removes an open drawer on scope change.
    return (_scope?.valid ?? false)
        ? CompanionHome(
            key: ValueKey(_scope),
            repository: widget.projects,
            scope: _scope!,
            checkWorkspace: _checkWorkspace,
            onAccessFailure: _workspace.denyAccess,
            accountPage: accountPage,
            refreshSignal: _projectRefresh,
            sessionError: widget.sessionError,
          )
        : accountPage;
  }
}
