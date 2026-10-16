import 'package:flutter/material.dart';

String metadataTime(BuildContext context, DateTime time) {
  final local = time.toLocal(), labels = MaterialLocalizations.of(context);
  return '${labels.formatShortDate(local)} · ${labels.formatTimeOfDay(TimeOfDay.fromDateTime(local))}';
}

class ProjectFreshness extends StatelessWidget {
  const ProjectFreshness({super.key, required this.label, required this.time});
  final String label;
  final DateTime time;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        Text(metadataTime(context, time)),
      ],
    ),
  );
}
