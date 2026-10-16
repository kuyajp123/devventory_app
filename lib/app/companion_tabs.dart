import 'package:flutter/material.dart';

class CompanionTabs extends StatelessWidget {
  const CompanionTabs({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
  });
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      decoration: BoxDecoration(
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(28),
      ),
      clipBehavior: Clip.antiAlias,
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: colors.surfaceContainerLow,
          indicatorColor: colors.primary.withValues(alpha: .16),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontFamily: 'Inter',
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
              fontSize: 12,
              color: states.contains(WidgetState.selected)
                  ? colors.primary
                  : colors.onSurfaceVariant,
            ),
          ),
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? colors.primary
                  : colors.onSurfaceVariant,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onSelect,
          destinations: const [
            NavigationDestination(
              key: Key('home-tab'),
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              key: Key('usage-tab'),
              icon: Icon(Icons.donut_large_rounded),
              label: 'Usage',
            ),
            NavigationDestination(
              key: Key('tracker-tab'),
              icon: Icon(Icons.layers_outlined),
              label: 'Tracker',
            ),
            NavigationDestination(
              key: Key('account-tab'),
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }
}
