import 'package:flutter/material.dart';
import 'package:devventory_app/features/projects/projects_controller.dart';
import 'package:devventory_app/features/projects/presentation/project_freshness.dart';
import 'package:devventory_app/shared/network/api_failure.dart';
import 'package:devventory_app/shared/presentation/companion_layout.dart';

class ProjectsStatus extends StatelessWidget {
  const ProjectsStatus({super.key, required this.controller});
  final ProjectsController controller;
  @override
  Widget build(BuildContext context) {
    final failure = controller.failure;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (controller.loading) ...[
          const LinearProgressIndicator(semanticsLabel: 'Downloading projects'),
          const SizedBox(height: 12),
          Text(
            controller.received == 0
                ? 'Checking for desktop updates…'
                : '${controller.received} projects received. Finishing the download…',
          ),
        ],
        if (controller.fetchedAt != null) ...[
          Text(
            'Downloaded ${metadataTime(context, controller.fetchedAt!)} (device time).',
          ),
          const SizedBox(height: 8),
          Text(
            controller.saved
                ? 'Saved for offline reading.'
                : 'The latest download is not saved on this device.',
          ),
        ],
        if (failure != null)
          StatusNotice(
            '${failure.kind == ApiFailureKind.offline ? 'Offline. ' : ''}${failure.message}'
            '${controller.projects != null ? ' Showing the last complete download.' : ''}',
            isError: failure.kind != ApiFailureKind.offline,
          ),
        if (failure?.retryAt != null)
          StatusNotice(
            'Retry after ${metadataTime(context, failure!.retryAt!)} (device time).',
          ),
        if (controller.cacheNotice != null)
          StatusNotice(controller.cacheNotice!, isError: true),
      ],
    );
  }
}
