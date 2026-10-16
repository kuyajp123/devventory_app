import 'package:devventory_app/app/app_theme.dart';
import 'package:devventory_app/features/dashboard/project_analytics.dart';
import 'package:devventory_app/features/dashboard/presentation/project_type_chart.dart';
import 'package:devventory_app/features/projects/index.dart';
import 'package:devventory_app/features/projects/tests/project_test.dart'
    show projectFixture;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('chart renders each real category and honors reduced motion', (
    tester,
  ) async {
    final projects = [
      for (final type in ProjectType.values)
        Project.fromJson(projectFixture()..['data']['projectType'] = type.name),
    ];
    await tester.pumpWidget(
      MaterialApp(
        theme: companionTheme(),
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: SingleChildScrollView(
              child: ProjectTypeChart(analytics: ProjectAnalytics(projects)),
            ),
          ),
        ),
      ),
    );
    final chart = tester.widget<PieChart>(find.byType(PieChart));
    expect(chart.duration, Duration.zero);
    expect(
      chart.data.sections.map((section) => section.value),
      everyElement(1),
    );
    expect(chart.data.sections, hasLength(7));
    for (final type in ProjectType.values) {
      expect(find.text('${type.name} · 1 project'), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });
}
