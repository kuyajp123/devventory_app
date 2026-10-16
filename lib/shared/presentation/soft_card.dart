import 'package:flutter/material.dart';
import 'package:devventory_app/shared/presentation/companion_style.dart';

class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(CompanionStyle.cardRadius),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      boxShadow: CompanionStyle.softShadow,
    ),
    child: child,
  );
}
