import 'package:flutter/material.dart';

/// Decorative brand illustration; nearby text always carries the actual state.
class VentyMascot extends StatelessWidget {
  const VentyMascot({super.key, this.size = 128});
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Image.asset(
      'assets/mascot/venty-welcome.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).ceil(),
    ),
  );
}
