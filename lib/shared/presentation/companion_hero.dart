import 'package:flutter/material.dart';
import 'package:devventory_app/shared/presentation/venty_mascot.dart';

class CompanionHero extends StatelessWidget {
  const CompanionHero({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.message,
    this.icon = Icons.laptop_rounded,
  });

  final String eyebrow, title, message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Icon(icon, size: 16, color: theme.colorScheme.primary),
            Text(
              eyebrow,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Semantics(
          header: true,
          child: Text(title, style: theme.textTheme.headlineLarge),
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked =
                constraints.maxWidth < 350 ||
                MediaQuery.textScalerOf(context).scale(16) > 22;
            return stacked
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(child: VentyMascot(size: 112)),
                      const SizedBox(height: 20),
                      heading,
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: heading),
                      const SizedBox(width: 12),
                      VentyMascot(size: constraints.maxWidth < 380 ? 88 : 112),
                    ],
                  );
          },
        ),
        const SizedBox(height: 16),
        Text(message, style: theme.textTheme.bodyLarge),
      ],
    );
  }
}
