import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:devventory_app/app/config/app_configuration.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);
  test('explicit flavors select matching registered native Firebase apps', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final apps = <String>{};
    for (final flavor in ['development', 'production']) {
      final options = AppConfiguration.forFlavor(flavor).firebaseOptions;
      final native = jsonDecode(
        File('android/app/src/$flavor/google-services.json').readAsStringSync(),
      ) as Map;
      final package =
          'com.devventory.devventory_app${flavor == 'development' ? '.dev' : ''}';
      final client = (native['client'] as List).cast<Map>().singleWhere(
        (client) =>
            ((client['client_info'] as Map)['android_client_info']
                as Map)['package_name'] ==
            package,
      );
      final info = client['client_info'] as Map;
      expect(options.projectId, 'devventory');
      expect(options.appId, info['mobilesdk_app_id']);
      expect((info['android_client_info'] as Map)['package_name'], package);
      apps.add(options.appId);
    }
    expect(apps, hasLength(2));
  });
  test('unknown flavors and unconfigured platforms fail closed', () {
    expect(() => AppConfiguration.forFlavor(null), throwsFormatException);
    expect(() => AppConfiguration.forFlavor('staging'), throwsFormatException);
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(
      () => AppConfiguration.forFlavor('production').firebaseOptions,
      throwsUnsupportedError,
    );
  });
}
