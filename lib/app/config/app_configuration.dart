import 'package:firebase_core/firebase_core.dart';
import 'package:devventory_app/app/config/firebase_development.dart'
    as development;
import 'package:devventory_app/app/config/firebase_production.dart'
    as production;

enum AppEnvironment { development, production }

class AppConfiguration {
  const AppConfiguration(this.environment);
  final AppEnvironment environment;
  factory AppConfiguration.forFlavor(String? flavor) => switch (flavor) {
    'development' => const AppConfiguration(AppEnvironment.development),
    'production' => const AppConfiguration(AppEnvironment.production),
    _ => throw const FormatException(
      'Select the development or production mobile flavor.',
    ),
  };
  FirebaseOptions get firebaseOptions => switch (environment) {
    AppEnvironment.development =>
      development.DefaultFirebaseOptions.currentPlatform,
    AppEnvironment.production =>
      production.DefaultFirebaseOptions.currentPlatform,
  };
}
