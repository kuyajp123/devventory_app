import 'dart:async';

import 'package:flutter/material.dart';
import 'package:devventory_app/features/workspace/workspace_repository.dart';
import 'package:devventory_app/features/workspace/workspace_controller.dart';
import 'package:devventory_app/shared/network/api_failure.dart';
import 'package:devventory_app/shared/presentation/companion_layout.dart';
import 'package:devventory_app/shared/presentation/companion_hero.dart';
import 'package:devventory_app/features/workspace/presentation/workspace_account_card.dart';

class WorkspacePage extends StatefulWidget {
  const WorkspacePage({
    super.key,
    required this.repository,
    required this.email,
    required this.onSignOut,
    required this.onVerificationRequired,
    required this.refreshSignal,
    this.sessionError,
  });
  final WorkspaceRepository repository;
  final String? email;
  final VoidCallback? onSignOut;
  final VoidCallback onVerificationRequired;
  final int refreshSignal;
  final String? sessionError;
  @override
  State<WorkspacePage> createState() => _WorkspacePageState();
}

class _WorkspacePageState extends State<WorkspacePage> {
  late final _controller = WorkspaceController(widget.repository);
  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
  }

  @override
  void didUpdateWidget(WorkspacePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSignal != widget.refreshSignal) unawaited(_refresh());
  }

  Future<void> _refresh() async {
    await _controller.refresh();
    if (mounted &&
        _controller.failure?.kind == ApiFailureKind.verificationRequired) {
      widget.onVerificationRequired();
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
      final failure = _controller.failure;
      final ready = _controller.workspace?.hasPublisher ?? false;
      final loading = _controller.loading;
      final title = loading
          ? 'Connecting your workspace'
          : failure != null
          ? switch (failure.kind) {
              ApiFailureKind.unauthorized => 'Session expired',
              ApiFailureKind.offline => 'Connection unavailable',
              ApiFailureKind.rateLimited => 'Taking a short pause',
              ApiFailureKind.workspaceRequired => 'Finish setup on desktop',
              _ => 'Workspace unavailable',
            }
          : ready
          ? 'Workspace connected'
          : 'Finish setup on desktop';
      final message = loading
          ? 'Checking Cloud Sync for your desktop workspace…'
          : failure?.message ??
                (ready
                    ? 'You’re connected to the private workspace for your desktop account.'
                    : 'Open Devventory desktop, sign in with this same account, and enable Cloud Sync. '
                          'Publish your metadata, then check again here.');
      return CompanionLayout(
        trailing: TextButton(
          onPressed: widget.onSignOut,
          child: const Text('Sign out'),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CompanionHero(
              eyebrow: ready ? 'PRIVATE WORKSPACE' : 'CLOUD CONNECTION',
              title: title,
              message: message,
              icon: failure != null
                  ? Icons.cloud_off_rounded
                  : ready
                  ? Icons.cloud_done_rounded
                  : Icons.cloud_queue_rounded,
            ),
            const SizedBox(height: 28),
            WorkspaceAccountCard(
              email: widget.email,
              ready: ready,
              fetchedAt: _controller.fetchedAt,
            ),
            if (widget.sessionError != null)
              StatusNotice(widget.sessionError!, isError: true),
            if (failure?.retryAt != null)
              StatusNotice(
                'You can retry after '
                '${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(failure!.retryAt!.toLocal()))} (device time).',
              ),
            const SizedBox(height: 24),
            ActionButton(
              label: failure?.kind == ApiFailureKind.unauthorized
                  ? 'Sign in again'
                  : loading
                  ? 'Connecting…'
                  : failure != null
                  ? 'Try again'
                  : ready
                  ? 'Refresh connection'
                  : 'Check again',
              busy: loading,
              icon: failure?.kind == ApiFailureKind.unauthorized
                  ? Icons.login_rounded
                  : Icons.refresh_rounded,
              onPressed: failure?.kind == ApiFailureKind.unauthorized
                  ? widget.onSignOut
                  : _controller.canRetry
                  ? _refresh
                  : null,
            ),
            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'This companion only reads published metadata. '
              'Your files, environment values, and secrets remain on desktop.',
            ),
            if (ready) ...[
              const SizedBox(height: 16),
              const Text(
                'Project browsing and offline reading are coming in the next implementation phase. '
                'A connected publisher does not confirm that metadata has been uploaded yet.',
              ),
            ],
          ],
        ),
      );
    },
  );
}
