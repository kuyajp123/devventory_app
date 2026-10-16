import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:devventory_app/app/app_theme.dart';
import 'package:devventory_app/app/config/app_configuration.dart';
import 'package:devventory_app/app/devventory_app.dart';
import 'package:devventory_app/features/auth/index.dart';
import 'package:devventory_app/features/workspace/index.dart';
import 'package:devventory_app/shared/network/api_client.dart';
import 'package:devventory_app/shared/presentation/companion_layout.dart';

class BootstrapApp extends StatefulWidget {
  const BootstrapApp({super.key});
  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp> {
  ApiClient? _api;
  Widget? _application;
  String? _error;
  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    setState(() => _error = null);
    try {
      final config = AppConfiguration.forFlavor(appFlavor);
      await Firebase.initializeApp(options: config.firebaseOptions);
      final auth = FirebaseAuthRepository(FirebaseAuth.instance);
      final api = ApiClient(tokens: auth);
      if (!mounted) {
        api.close();
        return;
      }
      _api = api;
      setState(
        () => _application = DevventoryApp(
          auth: auth,
          workspaces: CloudWorkspaceRepository(api),
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Could not initialize this mobile build. '
              'Check your connection and the Firebase configuration for the selected flavor. '
              'See docs/mobile-setup.md for setup instructions.',
        );
      }
    }
  }

  @override
  void dispose() {
    _api?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _application ??
      MaterialApp(
        title: 'Devventory Mobile',
        debugShowCheckedModeBanner: false,
        theme: companionTheme(),
        home: CompanionLayout(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _error == null
                    ? 'Starting Devventory…'
                    : 'Setup needs attention',
                style: const TextStyle(
                  fontSize: 26,
                  color: Color(0xFFE2E8F0),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              if (_error == null)
                const Center(child: CircularProgressIndicator())
              else ...[
                StatusNotice(_error!, isError: true),
                const SizedBox(height: 24),
                ActionButton(label: 'Try again', onPressed: _start),
              ],
            ],
          ),
        ),
      );
}
