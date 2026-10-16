// Test-only database factory; never imported by application code.
// ignore_for_file: depend_on_referenced_packages
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:devventory_app/shared/cache/metadata_cache.dart';

MetadataCache testCache() {
  sqfliteFfiInit();
  final cache = MetadataCache(
    factory: databaseFactoryFfiNoIsolate,
    path: inMemoryDatabasePath,
  );
  addTearDown(cache.close);
  return cache;
}

/// SQLite may schedule real I/O; keep it outside the widget fake-async clock.
void testCachedWidgets(
  String description,
  WidgetTesterCallback callback, {
  bool contrast = false,
}) {
  testWidgets(description, (tester) async {
    try {
      await tester.runAsync(() => callback(tester));
      // This guideline internally calls runAsync, so evaluate after leaving it.
      if (contrast) {
        await expectLater(tester, meetsGuideline(textContrastGuideline));
      }
    } finally {
      await tester.runAsync(() async {
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      });
    }
  });
}
