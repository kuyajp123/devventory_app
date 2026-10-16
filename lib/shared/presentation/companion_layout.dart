import 'package:flutter/material.dart';

export 'package:devventory_app/shared/presentation/action_button.dart';

class CompanionLayout extends StatelessWidget {
  const CompanionLayout({super.key, required this.child, this.trailing});
  final Widget child;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 10,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.inventory_2_rounded,
                            color: Theme.of(context).colorScheme.primary,
                            size: 22,
                          ),
                        ),
                        const Text(
                          'devventory',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.7,
                          ),
                        ),
                      ],
                    ),
                    ?trailing,
                  ],
                ),
                const SizedBox(height: 32),
                child,
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class StatusNotice extends StatelessWidget {
  const StatusNotice(this.message, {super.key, this.isError = false});
  final String message;
  final bool isError;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isError ? colors.errorContainer : colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                isError
                    ? Icons.error_outline_rounded
                    : Icons.info_outline_rounded,
                size: 20,
                color: isError ? colors.onErrorContainer : colors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: isError ? colors.onErrorContainer : colors.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
