// Colocated tests are dev-only.
// ignore_for_file: depend_on_referenced_packages
import 'package:devventory_app/features/dashboard/project_analytics.dart';
import 'package:devventory_app/features/projects/index.dart';
import 'package:devventory_app/features/projects/tests/project_test.dart'
    show projectFixture;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'counts the complete download by canonical type without synthetic history',
    () {
      final second = projectFixture()..['data']['projectType'] = 'web';
      final analytics = ProjectAnalytics([
        Project.fromJson(projectFixture()),
        Project.fromJson(second),
      ]);
      expect(analytics.total, 2);
      expect(analytics.types.values.reduce((a, b) => a + b), 2);
      expect(analytics.types[ProjectType.web], 1);
      expect(ProjectAnalytics([]).types, isEmpty);
    },
  );
}
