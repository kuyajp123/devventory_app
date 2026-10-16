import 'package:flutter/material.dart';
import 'package:devventory_app/features/workspace/workspace_controller.dart';
import 'package:devventory_app/shared/network/api_failure.dart';
import 'package:devventory_app/shared/presentation/companion_layout.dart';
import 'package:devventory_app/shared/presentation/companion_hero.dart';
import 'package:devventory_app/features/workspace/presentation/workspace_account_card.dart';

class WorkspacePage extends StatelessWidget {
  const WorkspacePage({
    super.key,
    required this.controller,
    required this.email,
    required this.onSignOut,
    required this.onRefresh,
    this.onBrowseProjects,
    this.showBrowseAction = true,
    this.sessionError,
  });
  final WorkspaceController controller;
  final String? email;
  final VoidCallback? onSignOut;
  final Future<void> Function() onRefresh;
  final VoidCallback? onBrowseProjects;
  final bool showBrowseAction;
  final String? sessionError;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final failure = controller.failure;
      final ready = controller.workspace?.hasPublisher ?? false;
      final loading = controller.loading;
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
          onPressed: onSignOut,
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
              email: email,
              ready: ready,
              fetchedAt: controller.fetchedAt,
            ),
            if (sessionError != null)
              StatusNotice(sessionError!, isError: true),
            if (controller.usingSaved && ready)
              const StatusNotice(
                'Your saved workspace is available. Open projects to read the last complete download while offline.',
              ),
            if (controller.cacheNotice != null)
              StatusNotice(controller.cacheNotice!, isError: true),
            if (failure?.retryAt != null)
              StatusNotice(
                'You can retry after '
                '${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(failure!.retryAt!.toLocal()))} (device time).',
              ),
            const SizedBox(height: 24),
            ActionButton(
              label: ready && !showBrowseAction
                  ? 'Refresh connection'
                  : ready
                  ? 'Browse projects'
                  : failure?.kind == ApiFailureKind.unauthorized
                  ? 'Sign in again'
                  : loading
                  ? 'Connecting…'
                  : failure != null
                  ? 'Try again'
                  : 'Check again',
              busy: loading && !ready,
              icon: ready
                  ? Icons.folder_open_rounded
                  : failure?.kind == ApiFailureKind.unauthorized
                  ? Icons.login_rounded
                  : Icons.refresh_rounded,
              onPressed: ready && !showBrowseAction
                  ? controller.canRetry
                        ? onRefresh
                        : null
                  : ready
                  ? onBrowseProjects
                  : failure?.kind == ApiFailureKind.unauthorized
                  ? onSignOut
                  : controller.canRetry
                  ? onRefresh
                  : null,
            ),
            if (ready && showBrowseAction) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: controller.canRetry ? onRefresh : null,
                child: const Text('Refresh connection'),
              ),
            ],
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
                'Projects are saved for offline reading after a complete download. '
                'A linked desktop alone does not confirm that metadata has been uploaded.',
              ),
            ],
          ],
        ),
      );
    },
  );
}
